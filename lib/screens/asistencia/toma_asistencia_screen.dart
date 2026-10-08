import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/app_routes.dart';
import '../../core/logic/horario.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/asistencia.dart';
import '../../models/curso.dart';
import '../../models/estudiante.dart';
import '../../models/resumen_asistencia.dart';
import '../../models/sesion.dart';
import '../../providers/academico_provider.dart';
import '../../services/academico_service.dart';
import '../../widgets/academicos.dart';
import '../../widgets/comunes.dart';
import '../../widgets/encabezado.dart';

enum _Filtro { todos, presente, tarde, falta, sinMarcar }

/// Toma la asistencia de una sesión. Las marcas viven en esta pantalla
/// (setState) hasta "Guardar asistencia", que las guarda con el
/// [AcademicoProvider] y devuelve el resultado a la pantalla anterior.
class TomaAsistenciaScreen extends StatefulWidget {
  final String? sesionId;
  final Sesion? sesion;

  const TomaAsistenciaScreen({super.key, this.sesionId, this.sesion});

  @override
  State<TomaAsistenciaScreen> createState() => _TomaAsistenciaScreenState();
}

class _TomaAsistenciaScreenState extends State<TomaAsistenciaScreen> {
  /// Copia de las marcas guardadas, tomada cuando la sesión está disponible.
  Map<String, EstadoAsistencia>? _marcas;
  Map<String, EstadoAsistencia> get _seleccion => _marcas!;
  _Filtro _filtro = _Filtro.todos;
  bool _hayCambios = false;
  bool _guardando = false;

  void _marcar(String estudianteId, EstadoAsistencia? estado) {
    setState(() {
      if (estado == null) {
        _seleccion.remove(estudianteId);
      } else {
        _seleccion[estudianteId] = estado;
      }
      _hayCambios = true;
    });
  }

  void _marcarPendientesPresentes(Iterable<Estudiante> estudiantes) {
    setState(() {
      for (final e in estudiantes) {
        _seleccion.putIfAbsent(e.id, () => EstadoAsistencia.presente);
      }
      _hayCambios = true;
    });
  }

  bool _pasaFiltro(EstadoAsistencia? estado) => switch (_filtro) {
    _Filtro.todos => true,
    _Filtro.presente => estado == EstadoAsistencia.presente,
    _Filtro.tarde => estado == EstadoAsistencia.tarde,
    _Filtro.falta => estado == EstadoAsistencia.falta,
    _Filtro.sinMarcar => estado == null,
  };

  static const _etiquetas = {
    _Filtro.todos: 'Todos',
    _Filtro.presente: 'Presentes',
    _Filtro.tarde: 'Tardanzas',
    _Filtro.falta: 'Faltas',
    _Filtro.sinMarcar: 'Sin marcar',
  };

  Future<void> _guardar(Sesion sesion) async {
    setState(() => _guardando = true);
    try {
      final resultado = await context.read<AcademicoProvider>().guardarAsistencia(sesion.id, _seleccion);
      if (!mounted) return;
      setState(() => _hayCambios = false);
      context.pop(resultado);
    } on AcademicoFailure catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      showMessage(context, e.message, error: true);
    }
  }

  Future<void> _salirSinGuardar() async {
    final salir = await confirmar(
      context,
      titulo: 'Cambios sin guardar',
      mensaje: 'Si sales ahora se perderán las marcas que no guardaste.',
      accion: 'Salir',
    );
    if (salir && mounted) {
      setState(() => _hayCambios = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final academico = context.watch<AcademicoProvider>();
    final id = widget.sesionId ?? widget.sesion?.id;
    final sesion = (id == null ? null : academico.sesionPorId(id)) ?? (academico.cargando ? widget.sesion : null);
    final curso = sesion == null ? null : academico.cursoPorId(sesion.cursoId);

    if (sesion == null || curso == null) {
      return Scaffold(
        appBar: const EncabezadoSeccion(titulo: 'Asistencia', leading: VolverButton()),
        body: SafeArea(
          child: academico.cargando
              ? const CargandoView()
              : const UnavailableView(
                  icon: Icons.event_busy_rounded,
                  title: 'Sesión no disponible',
                  message: 'La sesión no existe o fue eliminada.',
                  destino: AppRoutes.asistencia,
                  destinoTexto: 'Ir a Asistencia',
                ),
        ),
      );
    }

    _marcas ??= Map.of(sesion.asistencias);
    final hoy = academico.hoy;
    final editable = puedeRegistrarAsistencia(sesion.fecha, hoy);
    final estudiantes = academico.matriculadosEn(curso.id);
    final bloqueados = {
      for (final e in estudiantes)
        if (academico.bloqueado(e.id, sesion)) e.id,
    };
    final marcables = estudiantes.where((e) => !bloqueados.contains(e.id)).toList();
    final resumen = ResumenAsistencia.contar([for (final e in marcables) ?_seleccion[e.id]]);
    final pendientes = marcables.length - resumen.total;
    final visibles = estudiantes.where((e) => _pasaFiltro(_seleccion[e.id])).toList();
    final estadisticas = {for (final a in academico.resumenDe(curso).estudiantes) a.estudiante.id: a};

    return PopScope(
      canPop: !_hayCambios,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_guardando) _salirSinGuardar();
      },
      child: Scaffold(
        appBar: EncabezadoSeccion(
          titulo: 'Sesión ${sesion.numero} · ${curso.codigo}',
          subtitulo: '${formatFechaLarga(sesion.fecha)} · ${sesion.horario}',
          leading: const VolverButton(),
        ),
        bottomNavigationBar: !editable || marcables.isEmpty
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: anchoMaximoContenido),
                      child: ElevatedButton.icon(
                        onPressed: _guardando ? null : () => _guardar(sesion),
                        icon: _guardando
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.save_rounded),
                        label: Text(_guardando ? 'Guardando...' : 'Guardar asistencia'),
                      ),
                    ),
                  ),
                ),
              ),
        body: SafeArea(
          top: false,
          child: PageList(
            children: [
              _Cabecera(curso: curso, sesion: sesion, resumen: resumen, pendientes: pendientes),
              if (!editable) ...[const SizedBox(height: 12), _AvisoBloqueo(sesion: sesion, hoy: hoy)],
              const SizedBox(height: 16),
              if (estudiantes.isEmpty)
                EmptyState(
                  icon: Icons.groups_rounded,
                  title: 'Sin matriculados',
                  message: 'Matricula estudiantes en ${curso.nombre} para tomar su asistencia.',
                  action: OutlinedButton.icon(
                    onPressed: () => context.abrirMatricula(curso: curso),
                    icon: const Icon(Icons.how_to_reg_rounded),
                    label: const Text('Matricular'),
                  ),
                )
              else ...[
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final filtro in _Filtro.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(_etiquetas[filtro]!),
                            selected: _filtro == filtro,
                            onSelected: (_) => setState(() => _filtro = filtro),
                          ),
                        ),
                    ],
                  ),
                ),
                if (editable && pendientes > 0)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _guardando ? null : () => _marcarPendientesPresentes(marcables),
                      icon: const Icon(Icons.done_all_rounded),
                      label: Text('Marcar $pendientes sin marcar como presentes'),
                    ),
                  ),
                const SizedBox(height: 8),
                if (visibles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'Ningún estudiante coincide con el filtro.',
                        style: TextStyle(color: context.tokens.textSecondary),
                      ),
                    ),
                  ),
                for (final e in visibles)
                  bloqueados.contains(e.id)
                      ? EstudianteTile(
                          estudiante: e,
                          color: context.tokens.error,
                          detalle: 'En LDI · ${estadisticas[e.id]?.faltasTexto ?? ''}',
                          extra: Text(
                            'Alcanzó el 30% de faltas; ya no se registra su asistencia.',
                            style: TextStyle(fontSize: 12, color: context.tokens.textSecondary),
                          ),
                          trailing: Icon(Icons.lock_rounded, color: context.tokens.error),
                        )
                      : _FilaAsistencia(
                          estudiante: e,
                          estado: _seleccion[e.id],
                          faltasTexto: estadisticas[e.id]?.faltasTexto,
                          enabled: editable && !_guardando,
                          onChanged: (estado) => _marcar(e.id, estado),
                        ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  final Curso curso;
  final Sesion sesion;
  final ResumenAsistencia resumen;
  final int pendientes;

  const _Cabecera({required this.curso, required this.sesion, required this.resumen, required this.pendientes});

  @override
  Widget build(BuildContext context) {
    return BannerDestacado(
      insignia: Insignia(texto: 'Sesión ${sesion.numero}/${curso.totalSesiones}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            curso.nombre,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          Text(formatFechaLarga(sesion.fecha, conAnio: true)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DatoBanner(valor: '${resumen.presentes}', etiqueta: 'Presentes'),
              ),
              Expanded(
                child: DatoBanner(valor: '${resumen.tardes}', etiqueta: 'Tardanzas'),
              ),
              Expanded(
                child: DatoBanner(valor: '${resumen.faltas}', etiqueta: 'Faltas'),
              ),
              Expanded(
                child: DatoBanner(valor: '$pendientes', etiqueta: 'Sin marcar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvisoBloqueo extends StatelessWidget {
  final Sesion sesion;
  final DateTime hoy;

  const _AvisoBloqueo({required this.sesion, required this.hoy});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final cerrada = semanaDe(sesion.fecha, hoy) == SemanaSesion.anterior;
    final color = cerrada ? tokens.textSecondary : tokens.info;
    return Card(
      color: color.withValues(alpha: 0.1),
      child: ListTile(
        leading: Icon(cerrada ? Icons.lock_rounded : Icons.lock_clock_rounded, color: color),
        title: Text(cerrada ? 'Semana cerrada' : 'Sesión programada'),
        subtitle: Text(
          cerrada
              ? 'Esta sesión es de una semana anterior: su asistencia ya no se puede modificar.'
              : 'Podrás registrar la asistencia el día de la sesión.',
        ),
      ),
    );
  }
}

class _FilaAsistencia extends StatelessWidget {
  final Estudiante estudiante;
  final EstadoAsistencia? estado;
  final String? faltasTexto;
  final bool enabled;
  final ValueChanged<EstadoAsistencia?> onChanged;

  const _FilaAsistencia({
    required this.estudiante,
    required this.estado,
    required this.faltasTexto,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = estado?.colorEn(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  InitialsAvatar(text: estudiante.iniciales, color: color, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          estudiante.nombreVisible,
                          style: TextStyle(fontWeight: FontWeight.w800, color: tokens.textPrimary),
                        ),
                        Text(
                          [estudiante.codigo, ?faltasTexto].join(' · '),
                          style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  EstadoChip(estado),
                ],
              ),
              const SizedBox(height: 10),
              SegmentedButton<EstadoAsistencia>(
                segments: [
                  for (final opcion in EstadoAsistencia.values)
                    ButtonSegment(value: opcion, label: Text(opcion.etiqueta)),
                ],
                selected: {?estado},
                emptySelectionAllowed: true,
                showSelectedIcon: false,
                onSelectionChanged: enabled ? (s) => onChanged(s.isEmpty ? null : s.first) : null,
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected) ? color?.withValues(alpha: 0.2) : null,
                  ),
                  foregroundColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected) ? color : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
