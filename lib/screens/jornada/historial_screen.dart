import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/logic/horario.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/curso.dart';
import '../../models/jornada.dart';
import '../../models/sesion.dart';
import '../../providers/academico_provider.dart';
import '../../providers/jornada_provider.dart';
import '../../widgets/academicos.dart';
import '../../widgets/calendario.dart';
import '../../widgets/comunes.dart';
import '../../widgets/encabezado.dart';

enum _Vista { agenda, lista }

/// Estado de una sesión en la agenda del docente.
enum _EstadoAgenda { completada, sinSalida, programada, sinRegistro }

/// Una sesión del día en la agenda: la sesión programada (si su curso
/// existe) y la jornada marcada (si la hay).
class _ItemAgenda {
  final Curso? curso;
  final Sesion? sesion;
  final Jornada? jornada;

  const _ItemAgenda({this.curso, this.sesion, this.jornada});

  String get titulo => curso?.titulo ?? jornada?.cursoNombre ?? 'Curso';
  int get numero => sesion?.numero ?? jornada?.sesionNumero ?? 0;
  String get inicio => sesion?.horaInicio.toString() ?? jornada?.horaProgramadaInicio?.toString() ?? '--:--';
  String get fin => sesion?.horaFin.toString() ?? jornada?.horaProgramadaFin?.toString() ?? '--:--';
  int get minutoInicio => sesion?.horaInicio.minutos ?? jornada?.horaProgramadaInicio?.minutos ?? 0;

  _EstadoAgenda estado(DateTime ahora) {
    final j = jornada;
    if (j != null) return j.abierta ? _EstadoAgenda.sinSalida : _EstadoAgenda.completada;
    final s = sesion;
    return s != null && s.fin.isAfter(ahora) ? _EstadoAgenda.programada : _EstadoAgenda.sinRegistro;
  }
}

/// Jornadas del docente en dos vistas (estado local con setState):
/// - Agenda: calendario mensual con puntos por día y la agenda del día
///   elegido (sesiones programadas + entradas y salidas marcadas).
/// - Lista: historial agrupado por día con filtro de fechas.
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  _Vista _vista = _Vista.agenda;
  late DateTime _dia = soloFecha(context.read<AcademicoProvider>().ahora);
  late DateTime _mes = DateTime(_dia.year, _dia.month);
  DateTimeRange? _rango;

  Color _colorDe(_EstadoAgenda estado) {
    final tokens = context.tokens;
    return switch (estado) {
      _EstadoAgenda.completada => tokens.success,
      _EstadoAgenda.sinSalida => tokens.warning,
      _EstadoAgenda.programada => context.colors.primary,
      _EstadoAgenda.sinRegistro => tokens.error,
    };
  }

  /// Todas las sesiones de los cursos unidas con sus jornadas, por día.
  Map<DateTime, List<_ItemAgenda>> _agenda(AcademicoProvider academico, JornadaProvider jornadas) {
    final porDia = <DateTime, List<_ItemAgenda>>{};
    final usadas = <String>{};
    for (final curso in academico.cursos) {
      for (final sesion in academico.sesionesDe(curso.id)) {
        final jornada = jornadas.porSesion[sesion.id];
        if (jornada != null) usadas.add(jornada.id);
        porDia.putIfAbsent(sesion.fecha, () => []).add(_ItemAgenda(curso: curso, sesion: sesion, jornada: jornada));
      }
    }
    // Jornadas de cursos que ya no existen: se siguen mostrando.
    for (final jornada in jornadas.jornadas) {
      if (!usadas.contains(jornada.id)) {
        porDia.putIfAbsent(jornada.fecha, () => []).add(_ItemAgenda(jornada: jornada));
      }
    }
    for (final items in porDia.values) {
      items.sort((a, b) => a.minutoInicio.compareTo(b.minutoInicio));
    }
    return porDia;
  }

  Future<void> _elegirRango(Map<DateTime, List<Color>> marcadores) async {
    final elegido = await showRangoCalendario(context, inicial: _rango, marcadores: marcadores);
    if (elegido != null) setState(() => _rango = elegido);
  }

  @override
  Widget build(BuildContext context) {
    final academico = context.watch<AcademicoProvider>();
    final jornadas = context.watch<JornadaProvider>();
    final ahora = academico.ahora;
    final agenda = _agenda(academico, jornadas);
    final marcadores = {
      for (final entrada in agenda.entries)
        entrada.key: [for (final item in entrada.value) _colorDe(item.estado(ahora))],
    };

    return Scaffold(
      appBar: EncabezadoSeccion(
        titulo: 'Historial',
        subtitulo: 'Agenda y registro de tus jornadas',
        acciones: [
          if (_vista == _Vista.lista)
            IconButton(
              onPressed: () => _elegirRango(marcadores),
              icon: const Icon(Icons.date_range_rounded),
              tooltip: 'Filtrar por fechas',
            ),
          ...accionesSeccion(),
        ],
      ),
      body: SafeArea(
        top: false,
        child: PageList(
          children: [
            Center(
              child: SegmentedButton<_Vista>(
                segments: const [
                  ButtonSegment(value: _Vista.agenda, icon: Icon(Icons.calendar_month_rounded), label: Text('Agenda')),
                  ButtonSegment(value: _Vista.lista, icon: Icon(Icons.view_list_rounded), label: Text('Lista')),
                ],
                selected: {_vista},
                onSelectionChanged: (v) => setState(() => _vista = v.first),
              ),
            ),
            const SizedBox(height: 16),
            if (jornadas.cargando || academico.cargando)
              const CargandoView()
            else if (jornadas.error != null)
              LoadErrorView(message: jornadas.error!, onRetry: jornadas.reintentar)
            else if (_vista == _Vista.agenda)
              _vistaAgenda(agenda, marcadores, jornadas, ahora)
            else
              _vistaLista(jornadas, marcadores),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ Agenda

  Widget _vistaAgenda(
    Map<DateTime, List<_ItemAgenda>> agenda,
    Map<DateTime, List<Color>> marcadores,
    JornadaProvider jornadas,
    DateTime ahora,
  ) {
    final tokens = context.tokens;
    final delMes = jornadas.jornadas.where((j) => j.fecha.year == _mes.year && j.fecha.month == _mes.month);
    final horasMes = delMes.fold<Duration>(Duration.zero, (s, j) => s + (j.duracion ?? Duration.zero));
    var programadasMes = 0;
    agenda.forEach((dia, items) {
      if (dia.year == _mes.year && dia.month == _mes.month) programadasMes += items.length;
    });

    final calendario = Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CalendarioMensual(
              seleccionado: _dia,
              hoy: ahora,
              mesInicial: _mes,
              marcadores: marcadores,
              onDiaTocado: (dia) => setState(() => _dia = dia),
              onMesCambiado: (mes) => setState(() => _mes = mes),
            ),
            const SizedBox(height: 10),
            Divider(height: 1, color: tokens.border),
            const SizedBox(height: 10),
            LeyendaCalendario(
              items: [
                (tokens.success, 'Completada'),
                (tokens.warning, 'Sin salida'),
                (context.colors.primary, 'Programada'),
                (tokens.error, 'Sin registro'),
              ],
            ),
          ],
        ),
      ),
    );

    final resumen = AdaptiveGrid(
      minAncho: 110,
      maxColumnas: 3,
      children: [
        _MiniDato(icono: Icons.event_note_rounded, valor: '$programadasMes', etiqueta: 'Sesiones del mes'),
        _MiniDato(icono: Icons.verified_rounded, valor: '${delMes.length}', etiqueta: 'Jornadas'),
        _MiniDato(icono: Icons.timer_rounded, valor: formatDuracion(horasMes), etiqueta: 'Trabajado'),
      ],
    );

    final delDia = _AgendaDelDia(dia: _dia, items: agenda[_dia] ?? const [], ahora: ahora, colorDe: _colorDe);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 860) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 380, child: Column(children: [calendario, const SizedBox(height: 12), resumen])),
              const SizedBox(width: 20),
              Expanded(child: delDia),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [calendario, const SizedBox(height: 12), resumen, const SizedBox(height: 8), delDia],
        );
      },
    );
  }

  // ------------------------------------------------------------------- Lista

  Widget _vistaLista(JornadaProvider estado, Map<DateTime, List<Color>> marcadores) {
    final rango = _rango;
    final registros = estado.jornadas.where((j) {
      if (rango == null) return true;
      return !j.fecha.isBefore(soloFecha(rango.start)) && !j.fecha.isAfter(soloFecha(rango.end));
    }).toList();
    final total = registros.fold<Duration>(Duration.zero, (s, j) => s + (j.duracion ?? Duration.zero));
    final grupos = agruparPorDia(registros);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: rango == null
              ? ActionChip(
                  avatar: const Icon(Icons.date_range_rounded, size: 18),
                  label: const Text('Filtrar por fechas'),
                  onPressed: () => _elegirRango(marcadores),
                )
              : InputChip(
                  avatar: const Icon(Icons.date_range_rounded, size: 18),
                  label: Text('${formatFechaCorta(rango.start)} - ${formatFechaCorta(rango.end)}'),
                  onPressed: () => _elegirRango(marcadores),
                  onDeleted: () => setState(() => _rango = null),
                  deleteButtonTooltipMessage: 'Quitar filtro',
                ),
        ),
        if (registros.isEmpty)
          EmptyState(
            icon: Icons.history_rounded,
            title: 'Sin registros',
            message: rango == null ? 'Aún no hay jornadas registradas.' : 'No hay jornadas en ese rango.',
          )
        else ...[
          const SizedBox(height: 12),
          AdaptiveGrid(
            minAncho: 150,
            children: [
              StatTile(
                icon: Icons.event_available_rounded,
                label: 'Jornadas',
                value: '${registros.length}',
                color: context.colors.primary,
              ),
              StatTile(
                icon: Icons.timer_rounded,
                label: 'Horas trabajadas',
                value: formatDuracion(total),
                color: context.colors.secondary,
              ),
            ],
          ),
          for (final entrada in grupos.entries) ...[
            SectionHeader(title: formatFechaLarga(entrada.key, conAnio: true)),
            for (final j in entrada.value)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _JornadaCard(jornada: j),
              ),
          ],
        ],
      ],
    );
  }
}

class _MiniDato extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String etiqueta;

  const _MiniDato({required this.icono, required this.valor, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: context.colors.secondary),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: tokens.textPrimary),
            ),
          ),
          Text(
            etiqueta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Agenda de un día: línea de tiempo con la hora de cada sesión, un punto
/// del color de su estado y una tarjeta con las marcas.
class _AgendaDelDia extends StatelessWidget {
  final DateTime dia;
  final List<_ItemAgenda> items;
  final DateTime ahora;
  final Color Function(_EstadoAgenda) colorDe;

  const _AgendaDelDia({required this.dia, required this.items, required this.ahora, required this.colorDe});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final esHoy = dia == soloFecha(ahora);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: esHoy ? 'Hoy · ${formatFechaLarga(dia)}' : formatFechaLarga(dia, conAnio: true),
          subtitle: items.isEmpty
              ? 'Sin sesiones este día'
              : '${items.length} ${items.length == 1 ? 'sesión' : 'sesiones'}',
        ),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(color: tokens.surfaceMuted, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Icon(Icons.free_breakfast_rounded, size: 34, color: tokens.textSecondary),
                const SizedBox(height: 8),
                Text(
                  'Día libre: no tienes clases programadas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: tokens.textSecondary),
                ),
              ],
            ),
          )
        else
          for (var i = 0; i < items.length; i++)
            _FilaAgenda(
              item: items[i],
              estado: items[i].estado(ahora),
              color: colorDe(items[i].estado(ahora)),
              ultima: i == items.length - 1,
            ),
      ],
    );
  }
}

class _FilaAgenda extends StatelessWidget {
  final _ItemAgenda item;
  final _EstadoAgenda estado;
  final Color color;
  final bool ultima;

  const _FilaAgenda({required this.item, required this.estado, required this.color, required this.ultima});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final jornada = item.jornada;
    final etiqueta = switch (estado) {
      _EstadoAgenda.completada => 'Completada · ${formatDuracion(jornada?.duracion)}',
      _EstadoAgenda.sinSalida => 'Sin salida',
      _EstadoAgenda.programada => 'Programada',
      _EstadoAgenda.sinRegistro => 'Sin registro',
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 52,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: [
                  Text(
                    item.inicio,
                    style: TextStyle(fontWeight: FontWeight.w800, color: tokens.textPrimary),
                  ),
                  Text(item.fin, style: TextStyle(fontSize: 12, color: tokens.textSecondary)),
                ],
              ),
            ),
          ),
          // Línea de tiempo.
          SizedBox(
            width: 24,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!ultima) Positioned(top: 18, bottom: 0, child: Container(width: 2, color: tokens.border)),
                Positioned(
                  top: 14,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.colors.surface, width: 2),
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border(left: BorderSide(color: color, width: 4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.titulo,
                      style: TextStyle(fontWeight: FontWeight.w800, color: tokens.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text('Sesión ${item.numero}', style: TextStyle(fontSize: 12.5, color: tokens.textSecondary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        StatusChip(label: etiqueta, color: color),
                        if (jornada?.entrada != null)
                          StatusChip(
                            label: 'Entrada ${formatHora(jornada!.entrada)}',
                            color: tokens.textSecondary,
                            icon: Icons.login_rounded,
                          ),
                        if (jornada?.salida != null)
                          StatusChip(
                            label: 'Salida ${formatHora(jornada!.salida)}',
                            color: tokens.textSecondary,
                            icon: Icons.logout_rounded,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de una jornada en la vista de lista.
class _JornadaCard extends StatelessWidget {
  final Jornada jornada;

  const _JornadaCard({required this.jornada});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final j = jornada;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        j.cursoNombre,
                        style: TextStyle(fontWeight: FontWeight.w800, color: tokens.textPrimary),
                      ),
                      Text(
                        '${j.horaProgramadaInicio ?? ''} - ${j.horaProgramadaFin ?? ''} · Sesión ${j.sesionNumero}',
                        style: TextStyle(fontSize: 12.5, color: tokens.textSecondary),
                      ),
                    ],
                  ),
                ),
                StatusChip(
                  label: j.abierta ? 'Sin salida' : formatDuracion(j.duracion),
                  color: j.abierta ? tokens.warning : tokens.success,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: MarcaTile(
                    label: 'Entrada',
                    hora: j.entrada,
                    resultado: j.resultadoEntrada,
                    icon: Icons.login_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MarcaTile(
                    label: 'Salida',
                    hora: j.salida,
                    resultado: j.resultadoSalida,
                    icon: Icons.logout_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
