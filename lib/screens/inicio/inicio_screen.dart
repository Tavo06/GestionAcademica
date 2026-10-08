import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/app_routes.dart';
import '../../core/logic/notas.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/curso.dart';
import '../../models/jornada.dart';
import '../../models/sesion.dart';
import '../../providers/academico_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/calificaciones_provider.dart';
import '../../providers/jornada_provider.dart';
import '../../widgets/academicos.dart';
import '../../widgets/comunes.dart';
import '../../widgets/encabezado.dart';

String saludoPara(DateTime ahora) {
  if (ahora.hour < 12) return 'Buenos días';
  if (ahora.hour < 19) return 'Buenas tardes';
  return 'Buenas noches';
}

/// Panel del docente: resumen de cursos, estudiantes, matrículas y
/// promedios (los tres providers académicos), clases de hoy y accesos.
class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EncabezadoSeccion(
        titulo: 'Inicio',
        subtitulo: 'Resumen de tu actividad académica',
        acciones: accionesSeccion(),
      ),
      body: SafeArea(
        top: false,
        child: Consumer2<AcademicoProvider, CalificacionesProvider>(
          builder: (context, academico, calificaciones, _) {
            final docente = context.watch<AuthProvider>().docente;
            final tokens = context.tokens;
            final ahora = academico.ahora;
            final hoy = academico.sesionesDeHoy;
            final promedio = calificaciones.promedioGeneral;

            return PageList(
              children: [
                BannerDestacado(
                  insignia: Insignia(
                    texto: hoy.isEmpty ? 'Sin clases hoy' : '${hoy.length} hoy',
                    icono: Icons.event_available_rounded,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatFechaLarga(ahora, conAnio: true).toUpperCase(),
                        style: TextStyle(
                          fontSize: 11.5,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${saludoPara(ahora)}, ${docente.nombreVisible}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 28,
                        runSpacing: 12,
                        children: [
                          DatoBanner(valor: '${academico.cursos.length}', etiqueta: 'Cursos'),
                          DatoBanner(valor: '${academico.estudiantes.length}', etiqueta: 'Estudiantes'),
                          DatoBanner(valor: '${academico.matriculasActivas}', etiqueta: 'Matrículas'),
                          DatoBanner(valor: formatNota(promedio), etiqueta: 'Promedio general'),
                        ],
                      ),
                    ],
                  ),
                ),
                if (docente.perfilIncompleto) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.info_outline_rounded, color: tokens.warning),
                      title: const Text('Completa tu perfil'),
                      subtitle: const Text('Agrega tus nombres, apellidos y DNI.'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.pushNamed(AppRoutes.perfil),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (academico.cargando || calificaciones.cargando)
                  const CargandoView()
                else if (academico.error != null)
                  LoadErrorView(message: academico.error!, onRetry: academico.reintentar)
                else ...[
                  AdaptiveGrid(
                    minAncho: 160,
                    children: [
                      StatTile(
                        icon: Icons.menu_book_rounded,
                        label: 'Cursos en dictado',
                        value: '${academico.cursosEnCurso.length}',
                        color: context.colors.primary,
                        onTap: () => context.goNamed(AppRoutes.cursos),
                      ),
                      StatTile(
                        icon: Icons.how_to_reg_rounded,
                        label: 'Matrículas activas',
                        value: '${academico.matriculasActivas}',
                        color: tokens.info,
                        onTap: () => context.goNamed(AppRoutes.matriculas),
                      ),
                      StatTile(
                        icon: Icons.trending_down_rounded,
                        label: 'Desaprobados',
                        value: '${calificaciones.totalDesaprobados}',
                        color: tokens.warning,
                        onTap: () => context.goNamed(AppRoutes.calificaciones),
                      ),
                      StatTile(
                        icon: Icons.block_rounded,
                        label: 'En LDI',
                        value: '${academico.totalEnLdi}',
                        color: tokens.error,
                        onTap: () => context.goNamed(AppRoutes.asistencia),
                      ),
                    ],
                  ),
                  SectionHeader(
                    title: 'Clases de hoy',
                    trailing: TextButton(
                      onPressed: () => context.goNamed(AppRoutes.jornada),
                      child: const Text('Ir a jornada'),
                    ),
                  ),
                  if (hoy.isEmpty)
                    Card(
                      child: EmptyState(
                        icon: Icons.free_breakfast_rounded,
                        title: 'No tienes clases hoy',
                        message: academico.cursos.isEmpty
                            ? 'Crea tu primer curso para empezar.'
                            : 'Tus próximas sesiones están en Cursos.',
                        action: academico.cursos.isEmpty
                            ? FilledButton.icon(
                                onPressed: () => context.crearCurso(),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Nuevo curso'),
                              )
                            : null,
                      ),
                    )
                  else
                    for (final item in hoy) _ClaseHoy(curso: item.curso, sesion: item.sesion),
                  const SectionHeader(title: 'Rendimiento por curso'),
                  if (academico.cursos.isEmpty)
                    Text('Aún no hay cursos.', style: TextStyle(color: tokens.textSecondary))
                  else
                    for (final curso in academico.cursos)
                      _RendimientoCurso(
                        curso: curso,
                        promedio: calificaciones.resumenDe(curso).promedioGeneral,
                        matriculados: academico.matriculadosEn(curso.id).length,
                        asistencia: academico.resumenDe(curso).promedioAsistencia,
                      ),
                ],
                const SectionHeader(title: 'Accesos rápidos'),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Nuevo curso'),
                      onPressed: () => context.crearCurso(),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.how_to_reg_rounded, size: 18),
                      label: const Text('Matricular'),
                      onPressed: () => context.abrirMatricula(),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.grade_rounded, size: 18),
                      label: const Text('Registrar notas'),
                      onPressed: () => context.goNamed(AppRoutes.calificaciones),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.assessment_rounded, size: 18),
                      label: const Text('Reportes'),
                      onPressed: () => context.goNamed(AppRoutes.reportes),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ClaseHoy extends StatelessWidget {
  final Curso curso;
  final Sesion sesion;

  const _ClaseHoy({required this.curso, required this.sesion});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final Jornada? jornada = context.watch<JornadaProvider>().porSesion[sesion.id];
    final (texto, color) = switch (jornada) {
      null => ('Jornada pendiente', tokens.textSecondary),
      final j when j.abierta => ('En curso desde ${formatHora(j.entrada)}', context.colors.secondary),
      _ => ('Jornada registrada', tokens.success),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          onTap: () => context.abrirCurso(curso),
          leading: Container(
            width: 52,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: context.colors.secondary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${sesion.horaInicio}',
              style: TextStyle(fontWeight: FontWeight.w800, color: context.colors.secondary),
            ),
          ),
          title: Text(curso.nombre, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text('Sesión ${sesion.numero} · ${sesion.horario}'),
          trailing: StatusChip(label: texto, color: color),
        ),
      ),
    );
  }
}

class _RendimientoCurso extends StatelessWidget {
  final Curso curso;
  final double? promedio;
  final int matriculados;
  final double asistencia;

  const _RendimientoCurso({
    required this.curso,
    required this.promedio,
    required this.matriculados,
    required this.asistencia,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.abrirReporte(curso),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        curso.titulo,
                        style: TextStyle(fontWeight: FontWeight.w800, color: tokens.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$matriculados matriculados · asistencia ${formatPorcentaje(asistencia)}',
                        style: TextStyle(fontSize: 12.5, color: tokens.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    NotaBadge(promedio),
                    const SizedBox(height: 4),
                    Text(
                      condicionDe(promedio).etiqueta,
                      style: TextStyle(fontSize: 11, color: condicionDe(promedio).colorEn(context)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
