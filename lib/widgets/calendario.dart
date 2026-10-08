import 'package:flutter/material.dart';

import '../core/logic/horario.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';

const _meses = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];
const _iniciales = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

/// "Octubre 2026".
String nombreMes(DateTime mes) => '${_meses[mes.month - 1]} ${mes.year}';

bool _mismoDia(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// Calendario mensual propio (agenda): cabecera con degradado, días de la
/// semana, puntos de color por día ([marcadores]), hoy resaltado y un día
/// [seleccionado] o un [rango] marcado. El mes visible es estado local.
class CalendarioMensual extends StatefulWidget {
  final DateTime? seleccionado;
  final DateTimeRange? rango;

  /// Colores de los puntos de cada día (fecha sin hora → colores). Se
  /// muestran como máximo tres.
  final Map<DateTime, List<Color>> marcadores;
  final ValueChanged<DateTime> onDiaTocado;
  final ValueChanged<DateTime>? onMesCambiado;
  final DateTime? mesInicial;

  /// Fecha de hoy (por defecto, la del dispositivo).
  final DateTime? hoy;

  const CalendarioMensual({
    super.key,
    required this.onDiaTocado,
    this.seleccionado,
    this.rango,
    this.marcadores = const {},
    this.onMesCambiado,
    this.mesInicial,
    this.hoy,
  });

  @override
  State<CalendarioMensual> createState() => _CalendarioMensualState();
}

class _CalendarioMensualState extends State<CalendarioMensual> {
  late DateTime _mes = _primerDia(widget.mesInicial ?? widget.seleccionado ?? widget.rango?.start ?? DateTime.now());

  /// 1 avanza, -1 retrocede: decide hacia dónde se desliza el mes.
  int _direccion = 1;

  static DateTime _primerDia(DateTime fecha) => DateTime(fecha.year, fecha.month);

  void _irA(DateTime mes) {
    final nuevo = _primerDia(mes);
    if (nuevo == _mes) return;
    setState(() {
      _direccion = nuevo.isAfter(_mes) ? 1 : -1;
      _mes = nuevo;
    });
    widget.onMesCambiado?.call(nuevo);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final hoy = soloFecha(widget.hoy ?? DateTime.now());
    final esMesActual = _mes == _primerDia(hoy);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cabecera: mes, flechas y "Hoy" sobre el degradado de la marca.
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          decoration: BoxDecoration(gradient: tokens.gradient, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    nombreMes(_mes),
                    key: ValueKey(_mes),
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              if (!esMesActual)
                TextButton(
                  onPressed: () => _irA(hoy),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    minimumSize: const Size(40, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Text('Hoy'),
                ),
              IconButton(
                tooltip: 'Mes anterior',
                color: Colors.white,
                onPressed: () => _irA(DateTime(_mes.year, _mes.month - 1)),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                tooltip: 'Mes siguiente',
                color: Colors.white,
                onPressed: () => _irA(DateTime(_mes.year, _mes.month + 1)),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Text(
                  _iniciales[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: i >= 5 ? context.colors.secondary : tokens.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder: (child, animacion) {
            final entra = child.key == ValueKey(_mes);
            final desde = Offset((entra ? 0.25 : -0.25) * _direccion, 0);
            return FadeTransition(
              opacity: animacion,
              child: SlideTransition(
                position: Tween(begin: desde, end: Offset.zero).animate(animacion),
                child: child,
              ),
            );
          },
          layoutBuilder: (actual, anteriores) =>
              Stack(alignment: Alignment.topCenter, children: [...anteriores, ?actual]),
          child: _Cuadricula(
            key: ValueKey(_mes),
            mes: _mes,
            hoy: hoy,
            seleccionado: widget.seleccionado,
            rango: widget.rango,
            marcadores: widget.marcadores,
            onDiaTocado: (dia) {
              if (dia.month != _mes.month) _irA(dia);
              widget.onDiaTocado(dia);
            },
          ),
        ),
      ],
    );
  }
}

/// Seis semanas de lunes a domingo que contienen el [mes].
class _Cuadricula extends StatelessWidget {
  final DateTime mes;
  final DateTime hoy;
  final DateTime? seleccionado;
  final DateTimeRange? rango;
  final Map<DateTime, List<Color>> marcadores;
  final ValueChanged<DateTime> onDiaTocado;

  const _Cuadricula({
    super.key,
    required this.mes,
    required this.hoy,
    required this.seleccionado,
    required this.rango,
    required this.marcadores,
    required this.onDiaTocado,
  });

  @override
  Widget build(BuildContext context) {
    final inicio = DateTime(mes.year, mes.month, 1 - (mes.weekday - DateTime.monday));
    final rango = this.rango;
    return Column(
      children: [
        for (var semana = 0; semana < 6; semana++)
          Row(
            children: [
              for (var d = 0; d < 7; d++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final dia = DateTime(inicio.year, inicio.month, inicio.day + semana * 7 + d);
                      final enRango =
                          rango != null && !dia.isBefore(soloFecha(rango.start)) && !dia.isAfter(soloFecha(rango.end));
                      return _Dia(
                        dia: dia,
                        delMes: dia.month == mes.month,
                        hoy: _mismoDia(dia, hoy),
                        seleccionado:
                            (seleccionado != null && _mismoDia(dia, seleccionado!)) ||
                            (rango != null && (_mismoDia(dia, rango.start) || _mismoDia(dia, rango.end))),
                        enRango: enRango,
                        inicioRango: rango != null && _mismoDia(dia, rango.start),
                        finRango: rango != null && _mismoDia(dia, rango.end),
                        finDeSemana: d >= 5,
                        puntos: marcadores[dia] ?? const [],
                        onTap: () => onDiaTocado(dia),
                      );
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _Dia extends StatelessWidget {
  final DateTime dia;
  final bool delMes;
  final bool hoy;
  final bool seleccionado;
  final bool enRango;
  final bool inicioRango;
  final bool finRango;
  final bool finDeSemana;
  final List<Color> puntos;
  final VoidCallback onTap;

  const _Dia({
    required this.dia,
    required this.delMes,
    required this.hoy,
    required this.seleccionado,
    required this.enRango,
    required this.inicioRango,
    required this.finRango,
    required this.finDeSemana,
    required this.puntos,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = context.colors.primary;
    final colorTexto = seleccionado
        ? Colors.white
        : !delMes
        ? tokens.textSecondary.withValues(alpha: 0.45)
        : finDeSemana
        ? context.colors.secondary
        : tokens.textPrimary;

    return SizedBox(
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Franja del rango (de borde a borde, redondeada en los extremos).
          if (enRango && !(inicioRango && finRango))
            Positioned.fill(
              top: 5,
              bottom: 5,
              left: inicioRango ? 6 : 0,
              right: finRango ? 6 : 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: context.isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(inicioRango ? 18 : 0),
                    right: Radius.circular(finRango ? 18 : 0),
                  ),
                ),
              ),
            ),
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: seleccionado ? context.tokens.gradient : null,
                  border: hoy && !seleccionado ? Border.all(color: context.colors.secondary, width: 2) : null,
                  boxShadow: seleccionado
                      ? [BoxShadow(color: primary.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${dia.day}',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.1,
                        fontWeight: hoy || seleccionado ? FontWeight.w800 : FontWeight.w600,
                        color: colorTexto,
                      ),
                    ),
                    SizedBox(
                      height: 7,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final color in puntos.take(3))
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: seleccionado ? Colors.white : color,
                              ),
                            ),
                        ],
                      ),
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

/// Punto y texto de la leyenda del calendario.
class LeyendaCalendario extends StatelessWidget {
  final List<(Color, String)> items;

  const LeyendaCalendario({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        for (final (color, texto) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(texto, style: TextStyle(fontSize: 12, color: context.tokens.textSecondary)),
            ],
          ),
      ],
    );
  }
}

/// Filtro por fechas con el calendario propio: atajos (esta semana, este
/// mes, últimos 30 días) y rango libre tocando el día inicial y el final.
/// Devuelve el rango elegido, o null si se canceló.
Future<DateTimeRange?> showRangoCalendario(
  BuildContext context, {
  DateTimeRange? inicial,
  Map<DateTime, List<Color>> marcadores = const {},
}) {
  return showDialog<DateTimeRange>(
    context: context,
    builder: (_) => _RangoDialog(inicial: inicial, marcadores: marcadores),
  );
}

class _RangoDialog extends StatefulWidget {
  final DateTimeRange? inicial;
  final Map<DateTime, List<Color>> marcadores;

  const _RangoDialog({required this.inicial, required this.marcadores});

  @override
  State<_RangoDialog> createState() => _RangoDialogState();
}

class _RangoDialogState extends State<_RangoDialog> {
  late DateTime? _inicio = widget.inicial?.start;
  late DateTime? _fin = widget.inicial?.end;

  DateTimeRange? get _rango {
    final inicio = _inicio;
    if (inicio == null) return null;
    return DateTimeRange(start: inicio, end: _fin ?? inicio);
  }

  void _tocar(DateTime dia) {
    setState(() {
      final inicio = _inicio;
      if (inicio == null || _fin != null) {
        // Empieza un rango nuevo.
        _inicio = dia;
        _fin = null;
      } else if (dia.isBefore(inicio)) {
        _inicio = dia;
        _fin = inicio;
      } else {
        _fin = dia;
      }
    });
  }

  void _atajo(DateTime inicio, DateTime fin) => setState(() {
    _inicio = inicio;
    _fin = fin;
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final hoy = soloFecha(DateTime.now());
    final lunes = hoy.subtract(Duration(days: hoy.weekday - DateTime.monday));
    final rango = _rango;
    final atajos = [
      ('Esta semana', lunes, lunes.add(const Duration(days: 6))),
      ('Este mes', DateTime(hoy.year, hoy.month), DateTime(hoy.year, hoy.month + 1, 0)),
      ('Últimos 30 días', hoy.subtract(const Duration(days: 29)), hoy),
    ];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Filtrar por fechas',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                rango == null
                    ? 'Toca el día inicial y luego el final.'
                    : _fin == null
                    ? 'Ahora toca el día final.'
                    : '${formatFechaCorta(rango.start)}  →  ${formatFechaCorta(rango.end)}',
                style: TextStyle(color: tokens.textSecondary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (texto, inicio, fin) in atajos)
                    ChoiceChip(
                      label: Text(texto),
                      selected: rango != null && _mismoDia(rango.start, inicio) && _mismoDia(rango.end, fin),
                      onSelected: (_) => _atajo(inicio, fin),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              CalendarioMensual(rango: rango, marcadores: widget.marcadores, onDiaTocado: _tocar),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Limpiar selección',
                    onPressed: rango == null
                        ? null
                        : () => setState(() {
                            _inicio = null;
                            _fin = null;
                          }),
                    icon: const Icon(Icons.restart_alt_rounded),
                  ),
                  const Spacer(),
                  Flexible(
                    child: TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FilledButton(
                      onPressed: rango == null ? null : () => Navigator.of(context).pop(rango),
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
