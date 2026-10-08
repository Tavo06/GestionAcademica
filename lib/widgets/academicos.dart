import 'package:flutter/material.dart';

import '../core/logic/horario.dart';
import '../core/logic/notas.dart';
import '../core/logic/puntualidad.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/asistencia.dart';
import '../models/curso.dart';
import '../models/estudiante.dart';
import '../models/resumen_asistencia.dart';
import '../models/sesion.dart';
import 'comunes.dart';

// ------------------------------------------------------------- Asistencia

extension EstadoAsistenciaUi on EstadoAsistencia {
  Color colorEn(BuildContext context) {
    final tokens = context.tokens;
    return switch (this) {
      EstadoAsistencia.presente => tokens.success,
      EstadoAsistencia.tarde => tokens.warning,
      EstadoAsistencia.falta => tokens.error,
    };
  }

  IconData get icon => switch (this) {
        EstadoAsistencia.presente => Icons.check_circle_rounded,
        EstadoAsistencia.tarde => Icons.watch_later_rounded,
        EstadoAsistencia.falta => Icons.cancel_rounded,
      };
}

class EstadoChip extends StatelessWidget {
  final EstadoAsistencia? estado;

  const EstadoChip(this.estado, {super.key});

  @override
  Widget build(BuildContext context) {
    final estado = this.estado;
    if (estado == null) return StatusChip(label: 'Sin marcar', color: context.tokens.textSecondary);
    return StatusChip(label: estado.etiqueta, color: estado.colorEn(context), icon: estado.icon);
  }
}

/// "Regular" o "LDI" de un estudiante en un curso.
class LdiChip extends StatelessWidget {
  final bool enLdi;

  const LdiChip({super.key, required this.enLdi});

  @override
  Widget build(BuildContext context) => enLdi
      ? StatusChip(label: 'LDI', color: context.tokens.error, icon: Icons.block_rounded)
      : StatusChip(label: 'Regular', color: context.tokens.success, icon: Icons.check_rounded);
}

/// Situación de una sesión para editarla: semana cerrada, hoy, etc.
class SesionEstadoChip extends StatelessWidget {
  final Sesion sesion;
  final DateTime hoy;

  const SesionEstadoChip({super.key, required this.sesion, required this.hoy});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (sesion.fecha == soloFecha(hoy)) {
      return StatusChip(label: 'Hoy', color: context.colors.secondary, icon: Icons.today_rounded);
    }
    return switch (semanaDe(sesion.fecha, hoy)) {
      SemanaSesion.anterior =>
        StatusChip(label: 'Semana cerrada', color: tokens.textSecondary, icon: Icons.lock_rounded),
      SemanaSesion.futura =>
        StatusChip(label: 'Programada', color: tokens.info, icon: Icons.lock_clock_rounded),
      SemanaSesion.actual => sesion.fecha.isAfter(hoy)
          ? StatusChip(label: 'Programada', color: tokens.info, icon: Icons.lock_clock_rounded)
          : StatusChip(label: 'Esta semana', color: tokens.success, icon: Icons.edit_calendar_rounded),
    };
  }
}

/// Línea "✓ 3  ⏱ 1  ✕ 0".
class ResumenLine extends StatelessWidget {
  final ResumenAsistencia resumen;
  final int? pendientes;

  const ResumenLine({super.key, required this.resumen, this.pendientes});

  @override
  Widget build(BuildContext context) {
    Widget item(EstadoAsistencia estado, int valor) => Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(estado.icon, size: 14, color: estado.colorEn(context)),
              const SizedBox(width: 3),
              Text('$valor', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            ],
          ),
        );
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 4,
      children: [
        item(EstadoAsistencia.presente, resumen.presentes),
        item(EstadoAsistencia.tarde, resumen.tardes),
        item(EstadoAsistencia.falta, resumen.faltas),
        if (pendientes != null && pendientes! > 0)
          Text('$pendientes sin marcar', style: TextStyle(fontSize: 12, color: context.tokens.textSecondary)),
      ],
    );
  }
}

extension PuntualidadUi on ResultadoMarca {
  Color colorEn(BuildContext context) {
    final tokens = context.tokens;
    return switch (tipo) {
      Puntualidad.anticipada => tokens.info,
      Puntualidad.puntual => tokens.success,
      Puntualidad.tarde => tokens.warning,
      Puntualidad.incidencia => tokens.error,
    };
  }
}

// ------------------------------------------------------------------ Notas

extension CondicionNotaUi on CondicionNota {
  Color colorEn(BuildContext context) => switch (this) {
        CondicionNota.aprobado => context.tokens.success,
        CondicionNota.desaprobado => context.tokens.error,
        CondicionNota.sinNotas => context.tokens.textSecondary,
      };

  IconData get icon => switch (this) {
        CondicionNota.aprobado => Icons.verified_rounded,
        CondicionNota.desaprobado => Icons.trending_down_rounded,
        CondicionNota.sinNotas => Icons.hourglass_empty_rounded,
      };
}

class CondicionChip extends StatelessWidget {
  final CondicionNota condicion;

  const CondicionChip(this.condicion, {super.key});

  @override
  Widget build(BuildContext context) =>
      StatusChip(label: condicion.etiqueta, color: condicion.colorEn(context), icon: condicion.icon);
}

/// Nota o promedio en un recuadro: verde si aprueba (≥ 10.50), rojo si no.
class NotaBadge extends StatelessWidget {
  final double? nota;
  final double ancho;

  const NotaBadge(this.nota, {super.key, this.ancho = 58});

  @override
  Widget build(BuildContext context) {
    final color = condicionDe(nota).colorEn(context);
    return Container(
      width: ancho,
      padding: const EdgeInsets.symmetric(vertical: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        formatNota(nota),
        style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 14),
      ),
    );
  }
}

// --------------------------------------------------------------- Tarjetas

/// Tarjeta de un curso en el listado: bloque lateral con el código, datos
/// del horario, avance y cifras.
class CursoCard extends StatelessWidget {
  final Curso curso;
  final ResumenCurso resumen;
  final DateTime ahora;
  final double? promedio;
  final VoidCallback onTap;

  const CursoCard({
    super.key,
    required this.curso,
    required this.resumen,
    required this.ahora,
    required this.onTap,
    this.promedio,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = context.colors;
    final proxima = proximaSesion(resumen.sesiones, ahora);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 78,
                color: colors.primary.withValues(alpha: context.isDark ? 0.25 : 0.1),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.menu_book_rounded, color: colors.primary),
                    const SizedBox(height: 6),
                    Text(
                      curso.codigo,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: colors.primary),
                    ),
                    Text(
                      '${curso.creditos} cr.',
                      style: TextStyle(fontSize: 11, color: tokens.textSecondary),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        curso.nombre,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: tokens.textPrimary,
                            ),
                      ),
                      InfoLine(icon: Icons.calendar_today_rounded, text: '${curso.diasTexto} · ${curso.horario}'),
                      InfoLine(
                        icon: Icons.upcoming_rounded,
                        text: proxima == null
                            ? 'Curso finalizado'
                            : 'Próxima: ${formatFechaLarga(proxima.fecha)}',
                      ),
                      const SizedBox(height: 10),
                      ProgressLine(
                        value: resumen.progreso,
                        label: 'Sesiones dictadas',
                        detalle: '${resumen.realizadas}/${curso.totalSesiones}',
                        color: colors.secondary,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          StatusChip(
                            label: '${resumen.estudiantes.length} matriculados',
                            color: tokens.info,
                            icon: Icons.groups_rounded,
                          ),
                          if (promedio != null)
                            StatusChip(
                              label: 'Promedio ${formatNota(promedio)}',
                              color: condicionDe(promedio).colorEn(context),
                              icon: Icons.grade_rounded,
                            ),
                          if (resumen.enLdi > 0)
                            StatusChip(
                              label: '${resumen.enLdi} en LDI',
                              color: tokens.error,
                              icon: Icons.block_rounded,
                            ),
                        ],
                      ),
                    ],
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

/// Fila de un estudiante: avatar, nombre, línea secundaria y acción.
class EstudianteTile extends StatelessWidget {
  final Estudiante estudiante;
  final String? detalle;
  final Widget? extra;
  final Widget? trailing;
  final Color? color;
  final VoidCallback? onTap;

  const EstudianteTile({
    super.key,
    required this.estudiante,
    this.detalle,
    this.extra,
    this.trailing,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
            child: Row(
              children: [
                InitialsAvatar(text: estudiante.iniciales, color: color),
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
                        detalle ?? estudiante.codigo,
                        style: TextStyle(fontSize: 12.5, color: tokens.textSecondary),
                      ),
                      if (extra != null) ...[const SizedBox(height: 6), extra!],
                    ],
                  ),
                ),
                trailing ??
                    (onTap == null
                        ? const SizedBox(width: 8)
                        : Icon(Icons.chevron_right_rounded, color: tokens.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fila de una sesión: número, fecha, estado y resumen de asistencia.
class SesionTile extends StatelessWidget {
  final Curso curso;
  final Sesion sesion;
  final DateTime hoy;
  final int totalEstudiantes;
  final VoidCallback onTap;
  final Widget? trailing;

  /// Nombre del curso arriba (en listas que mezclan cursos).
  final bool mostrarCurso;

  const SesionTile({
    super.key,
    required this.curso,
    required this.sesion,
    required this.hoy,
    required this.totalEstudiantes,
    required this.onTap,
    this.trailing,
    this.mostrarCurso = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final resumen = ResumenAsistencia.contar(sesion.asistencias.values);
    final esHoy = sesion.fecha == soloFecha(hoy);
    final acento = esHoy ? context.colors.secondary : context.colors.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            child: Row(
              children: [
                Container(
                  width: 48,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: acento.withValues(alpha: 0.6), width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text('S', style: TextStyle(fontSize: 10, color: acento, fontWeight: FontWeight.w700)),
                      Text(
                        '${sesion.numero}',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: acento),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (mostrarCurso)
                        Text(
                          curso.nombre,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: acento),
                        ),
                      Text(
                        formatFechaLarga(sesion.fecha),
                        style: TextStyle(fontWeight: FontWeight.w800, color: tokens.textPrimary),
                      ),
                      Text(
                        '${sesion.horario} · sesión ${sesion.numero} de ${curso.totalSesiones}',
                        style: TextStyle(fontSize: 12.5, color: tokens.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SesionEstadoChip(sesion: sesion, hoy: hoy),
                          if (resumen.total > 0)
                            ResumenLine(resumen: resumen, pendientes: totalEstudiantes - resumen.total),
                        ],
                      ),
                    ],
                  ),
                ),
                trailing ??
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.chevron_right_rounded, color: tokens.textSecondary),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Hora real de una marca de jornada con su puntualidad ("17:02 · +2 min").
class MarcaTile extends StatelessWidget {
  final String label;
  final DateTime? hora;
  final ResultadoMarca? resultado;
  final IconData icon;

  const MarcaTile({
    super.key,
    required this.label,
    required this.hora,
    required this.resultado,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final resultado = this.resultado;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: tokens.textSecondary),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, color: tokens.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            formatHora(hora),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                ),
          ),
          if (resultado != null) ...[
            const SizedBox(height: 4),
            StatusChip(
              label: resultado.tipo == Puntualidad.tarde
                  ? resultado.etiqueta
                  : '${resultado.etiqueta} · ${resultado.diferencia}',
              color: resultado.colorEn(context),
            ),
          ],
        ],
      ),
    );
  }
}
