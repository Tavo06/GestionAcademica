import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/app_routes.dart';
import '../../core/logic/puntualidad.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/curso.dart';
import '../../models/jornada.dart';
import '../../models/sesion.dart';
import '../../providers/academico_provider.dart';
import '../../providers/jornada_provider.dart';
import '../../services/jornada_service.dart';
import '../../widgets/academicos.dart';
import '../../widgets/comunes.dart';
import '../../widgets/encabezado.dart';

/// Reloj de jornada: una entrada y una salida por cada sesión del día,
/// comparadas con el horario del curso.
class JornadaScreen extends StatefulWidget {
  const JornadaScreen({super.key});

  @override
  State<JornadaScreen> createState() => _JornadaScreenState();
}

class _JornadaScreenState extends State<JornadaScreen> {
  late final Timer _reloj;
  DateTime _ahora = DateTime.now();

  /// Sesión que se está marcando (deshabilita sus botones).
  String? _procesando;

  @override
  void initState() {
    super.initState();
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _ahora = DateTime.now());
    });
  }

  @override
  void dispose() {
    _reloj.cancel();
    super.dispose();
  }

  Future<void> _marcar(String sesionId, Future<void> Function() accion, String ok) async {
    setState(() => _procesando = sesionId);
    try {
      await accion();
      if (mounted) showMessage(context, ok);
    } on JornadaFailure catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _procesando = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final academico = context.watch<AcademicoProvider>();
    final jornadas = context.watch<JornadaProvider>();
    final hoy = academico.sesionesDeHoy;
    final trabajado = jornadas.deHoy().fold<Duration>(Duration.zero, (s, j) => s + (j.duracion ?? Duration.zero));

    return Scaffold(
      appBar: EncabezadoSeccion(
        titulo: 'Jornada',
        subtitulo: 'Entrada y salida por sesión',
        acciones: accionesSeccion(),
      ),
      body: SafeArea(
        top: false,
        child: PageList(
          children: [
            BannerDestacado(
              insignia: Insignia(texto: 'Trabajado ${formatDuracion(trabajado)}', icono: Icons.timer_rounded),
              child: Column(
                children: [
                  Text(
                    formatFechaLarga(_ahora, conAnio: true),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatHora(_ahora)}:${_ahora.second.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text('${hoy.length} ${hoy.length == 1 ? 'sesión' : 'sesiones'} hoy'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (academico.cargando || jornadas.cargando)
              const CargandoView()
            else if (jornadas.error != null)
              LoadErrorView(message: jornadas.error!, onRetry: jornadas.reintentar)
            else if (hoy.isEmpty)
              EmptyState(
                icon: Icons.event_available_rounded,
                title: 'Sin clases hoy',
                message: 'Tus jornadas se registran en cada sesión según el horario del curso.',
                action: OutlinedButton.icon(
                  onPressed: () => context.goNamed(AppRoutes.historial),
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('Ver historial'),
                ),
              )
            else ...[
              const SectionHeader(title: 'Sesiones de hoy', subtitle: 'Marca tu entrada y tu salida.'),
              for (final item in hoy)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _JornadaSesionCard(
                    curso: item.curso,
                    sesion: item.sesion,
                    jornada: jornadas.porSesion[item.sesion.id],
                    ahora: _ahora,
                    procesando: _procesando == item.sesion.id,
                    onEntrada: () => _marcar(
                      item.sesion.id,
                      () => jornadas.marcarEntrada(item.curso, item.sesion),
                      'Entrada registrada en ${item.curso.nombre}.',
                    ),
                    onSalida: (j) => _marcar(
                      item.sesion.id,
                      () => jornadas.marcarSalida(j),
                      'Salida registrada en ${item.curso.nombre}.',
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _JornadaSesionCard extends StatelessWidget {
  final Curso curso;
  final Sesion sesion;
  final Jornada? jornada;
  final DateTime ahora;
  final bool procesando;
  final VoidCallback onEntrada;
  final ValueChanged<Jornada> onSalida;

  const _JornadaSesionCard({
    required this.curso,
    required this.sesion,
    required this.jornada,
    required this.ahora,
    required this.procesando,
    required this.onEntrada,
    required this.onSalida,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final jornada = this.jornada;
    final motivo = jornada == null ? validarEntrada(inicio: sesion.inicio, fin: sesion.fin, ahora: ahora) : null;
    final estado = switch (jornada) {
      null => StatusChip(label: 'Pendiente', color: tokens.textSecondary, icon: Icons.schedule_rounded),
      final j when j.abierta => StatusChip(
        label: 'En curso',
        color: context.colors.secondary,
        icon: Icons.play_circle_rounded,
      ),
      _ => StatusChip(label: 'Finalizada', color: tokens.success, icon: Icons.verified_rounded),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                        curso.titulo,
                        style: TextStyle(fontWeight: FontWeight.w800, color: tokens.textPrimary),
                      ),
                      InfoLine(icon: Icons.schedule_rounded, text: 'Programado: ${sesion.horario}'),
                      InfoLine(
                        icon: Icons.event_note_rounded,
                        text: 'Sesión ${sesion.numero} de ${curso.totalSesiones}',
                      ),
                    ],
                  ),
                ),
                estado,
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MarcaTile(
                    label: 'Entrada',
                    hora: jornada?.entrada,
                    resultado: jornada?.resultadoEntrada,
                    icon: Icons.login_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MarcaTile(
                    label: 'Salida',
                    hora: jornada?.salida,
                    resultado: jornada?.resultadoSalida,
                    icon: Icons.logout_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (jornada == null) ...[
              FilledButton.icon(
                onPressed: procesando || motivo != null ? null : onEntrada,
                icon: const Icon(Icons.login_rounded),
                label: Text(procesando ? 'Registrando...' : 'Marcar entrada'),
              ),
              if (motivo != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    motivo,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: tokens.textSecondary),
                  ),
                ),
            ] else if (jornada.abierta)
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: context.colors.secondary),
                onPressed: procesando ? null : () => onSalida(jornada),
                icon: const Icon(Icons.logout_rounded),
                label: Text(procesando ? 'Registrando...' : 'Marcar salida'),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: tokens.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Jornada completada · ${formatDuracion(jornada.duracion)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: tokens.success, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
