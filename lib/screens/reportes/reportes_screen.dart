import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/academico_provider.dart';
import '../../providers/calificaciones_provider.dart';
import '../../widgets/academicos.dart';
import '../../widgets/comunes.dart';
import '../../widgets/encabezado.dart';

/// Elige el curso del que se quiere ver el reporte.
class ReportesScreen extends StatelessWidget {
  const ReportesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EncabezadoSeccion(
        titulo: 'Reportes',
        subtitulo: 'Rendimiento y asistencia por curso',
        acciones: accionesSeccion(),
      ),
      body: SafeArea(
        top: false,
        child: Consumer2<AcademicoProvider, CalificacionesProvider>(
          builder: (context, academico, calificaciones, _) {
            if (academico.cargando || calificaciones.cargando) return const CargandoView();
            if (academico.cursos.isEmpty) {
              return const PageList(children: [
                EmptyState(
                  icon: Icons.assessment_rounded,
                  title: 'Sin reportes',
                  message: 'Los reportes aparecen cuando tienes cursos con matrículas y notas.',
                ),
              ]);
            }
            final tokens = context.tokens;
            return PageList(
              children: [
                Text(
                  'Toca un curso para ver su reporte completo.',
                  style: TextStyle(color: tokens.textSecondary),
                ),
                const SizedBox(height: 12),
                AdaptiveGrid(
                  minAncho: 300,
                  maxColumnas: 3,
                  children: [
                    for (final curso in academico.cursos)
                      Builder(builder: (context) {
                        final notas = calificaciones.resumenDe(curso);
                        final asistencia = academico.resumenDe(curso);
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => context.abrirReporte(curso),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              curso.codigo,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: context.colors.secondary,
                                              ),
                                            ),
                                            Text(
                                              curso.nombre,
                                              style: TextStyle(fontWeight: FontWeight.w800, color: tokens.textPrimary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      NotaBadge(notas.promedioGeneral),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ProgressLine(
                                    value: notas.estudiantes.isEmpty ? 0 : notas.aprobados / notas.estudiantes.length,
                                    label: 'Aprobados',
                                    detalle: '${notas.aprobados}/${notas.estudiantes.length}',
                                    color: tokens.success,
                                  ),
                                  const SizedBox(height: 10),
                                  ProgressLine(
                                    value: asistencia.promedioAsistencia / 100,
                                    label: 'Asistencia',
                                    detalle: formatPorcentaje(asistencia.promedioAsistencia),
                                    color: tokens.info,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
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
