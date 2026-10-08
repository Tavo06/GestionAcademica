import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/sesion.dart';
import '../../providers/academico_provider.dart';
import '../../widgets/academicos.dart';
import '../../widgets/comunes.dart';
import '../../widgets/dialogos.dart';
import '../../widgets/encabezado.dart';

/// Asistencia: primero las sesiones de hoy y luego las del curso elegido
/// (estado local), con su estado de bloqueo.
class AsistenciaScreen extends StatefulWidget {
  const AsistenciaScreen({super.key});

  @override
  State<AsistenciaScreen> createState() => _AsistenciaScreenState();
}

class _AsistenciaScreenState extends State<AsistenciaScreen> {
  String? _cursoId;

  Future<void> _abrir(Sesion sesion) async {
    final resultado = await context.abrirTomaAsistencia(sesion);
    if (resultado != null && mounted) await mostrarResultadoAsistencia(context, resultado);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EncabezadoSeccion(
        titulo: 'Asistencia',
        subtitulo: 'Registro por sesión y control de LDI',
        acciones: accionesSeccion(),
      ),
      body: SafeArea(
        top: false,
        child: Consumer<AcademicoProvider>(
          builder: (context, academico, _) {
            if (academico.cargando) return const CargandoView();
            if (academico.error != null) {
              return LoadErrorView(message: academico.error!, onRetry: academico.reintentar);
            }
            if (academico.cursos.isEmpty) {
              return PageList(children: [
                EmptyState(
                  icon: Icons.fact_check_rounded,
                  title: 'Sin cursos',
                  message: 'Crea un curso para generar sus sesiones y tomar asistencia.',
                  action: FilledButton.icon(
                    onPressed: () => context.crearCurso(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Nuevo curso'),
                  ),
                ),
              ]);
            }
            final hoy = academico.sesionesDeHoy;
            final curso = academico.cursoPorId(_cursoId ?? '') ??
                (hoy.isNotEmpty ? hoy.first.curso : academico.cursos.first);
            final resumen = academico.resumenDe(curso);

            return PageList(
              children: [
                SectionHeader(title: 'Hoy', subtitle: hoy.isEmpty ? 'No tienes sesiones programadas hoy.' : null),
                for (final item in hoy)
                  SesionTile(
                    curso: item.curso,
                    sesion: item.sesion,
                    hoy: academico.hoy,
                    totalEstudiantes: academico.matriculadosEn(item.curso.id).length,
                    mostrarCurso: true,
                    onTap: () => _abrir(item.sesion),
                  ),
                const SectionHeader(title: 'Sesiones por curso'),
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final c in academico.cursos)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(c.nombre),
                            selected: c.id == curso.id,
                            onSelected: (_) => setState(() => _cursoId = c.id),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ProgressLine(
                          value: resumen.progreso,
                          label: 'Sesiones dictadas',
                          detalle: '${resumen.realizadas} / ${curso.totalSesiones}',
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${resumen.estudiantes.length} matriculados · ${resumen.enLdi} en LDI',
                                style: TextStyle(fontSize: 12.5, color: context.tokens.textSecondary),
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.abrirReporte(curso),
                              child: const Text('Ver reporte'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                for (final sesion in resumen.sesiones)
                  SesionTile(
                    curso: curso,
                    sesion: sesion,
                    hoy: academico.hoy,
                    totalEstudiantes: resumen.estudiantes.length,
                    onTap: () => _abrir(sesion),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
