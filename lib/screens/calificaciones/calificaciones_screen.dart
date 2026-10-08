import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_routes.dart';
import '../../core/logic/notas.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/curso.dart';
import '../../models/evaluacion.dart';
import '../../models/resumen_notas.dart';
import '../../providers/academico_provider.dart';
import '../../providers/calificaciones_provider.dart';
import '../../services/academico_service.dart';
import '../../widgets/academicos.dart';
import '../../widgets/comunes.dart';
import '../../widgets/encabezado.dart';
import 'evaluacion_form_dialog.dart';

/// Calificaciones de un curso: sus evaluaciones con peso, el registro
/// auxiliar (notas y promedio ponderado de cada estudiante) y el resumen
/// de aprobados. Curso elegido y filtro son estado local (setState); los
/// promedios vienen del [CalificacionesProvider].
class CalificacionesScreen extends StatefulWidget {
  const CalificacionesScreen({super.key});

  @override
  State<CalificacionesScreen> createState() => _CalificacionesScreenState();
}

class _CalificacionesScreenState extends State<CalificacionesScreen> {
  String? _cursoId;
  CondicionNota? _filtro;

  Future<void> _registrar(Evaluacion evaluacion) async {
    final r = await context.abrirRegistroNotas(evaluacion);
    if (r != null && mounted) {
      showMessage(
        context,
        '${r.evaluacion.nombre}: ${r.calificadas} notas · ${r.aprobadas} aprobados · '
        'promedio ${formatNota(r.promedio)}',
      );
    }
  }

  Future<void> _eliminar(Evaluacion evaluacion) async {
    final ok = await confirmar(
      context,
      titulo: 'Eliminar evaluación',
      mensaje: 'Se eliminará "${evaluacion.nombre}" con sus ${evaluacion.notas.length} notas.',
    );
    if (!ok || !mounted) return;
    try {
      await context.read<CalificacionesProvider>().eliminarEvaluacion(evaluacion);
      if (mounted) showMessage(context, 'Evaluación eliminada.');
    } on AcademicoFailure catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EncabezadoSeccion(
        titulo: 'Calificaciones',
        subtitulo: 'Evaluaciones, notas y promedios',
        acciones: accionesSeccion(),
      ),
      body: SafeArea(
        top: false,
        child: Consumer2<AcademicoProvider, CalificacionesProvider>(
          builder: (context, academico, calificaciones, _) {
            if (academico.cargando || calificaciones.cargando) return const CargandoView();
            if (academico.error != null) {
              return LoadErrorView(message: academico.error!, onRetry: academico.reintentar);
            }
            if (calificaciones.error != null) {
              return LoadErrorView(message: calificaciones.error!, onRetry: calificaciones.reintentar);
            }
            if (academico.cursos.isEmpty) {
              return const PageList(children: [
                EmptyState(
                  icon: Icons.grade_rounded,
                  title: 'Sin cursos',
                  message: 'Crea un curso y matricula estudiantes para registrar sus notas.',
                ),
              ]);
            }
            final curso = academico.cursoPorId(_cursoId ?? '') ?? academico.cursos.first;
            final resumen = calificaciones.resumenDe(curso);
            final filas = resumen.ranking.where((p) => _filtro == null || p.condicion == _filtro).toList();

            return PageList(
              children: [
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final c in academico.cursos)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(c.codigo.isEmpty ? c.nombre : c.codigo),
                            selected: c.id == curso.id,
                            onSelected: (_) => setState(() {
                              _cursoId = c.id;
                              _filtro = null;
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _Resumen(curso: curso, resumen: resumen),
                SectionHeader(
                  title: 'Evaluaciones',
                  subtitle: '${resumen.pesoAsignado}% asignado · ${resumen.pesoDisponible}% disponible',
                  trailing: FilledButton.tonalIcon(
                    onPressed: resumen.pesoDisponible == 0 ? null : () => showEvaluacionFormDialog(context, curso),
                    icon: const Icon(Icons.add_task_rounded, size: 18),
                    label: const Text('Nueva'),
                  ),
                ),
                if (resumen.evaluaciones.isEmpty)
                  Text(
                    'Este curso aún no tiene evaluaciones.',
                    style: TextStyle(color: context.tokens.textSecondary),
                  )
                else
                  AdaptiveGrid(
                    minAncho: 240,
                    maxColumnas: 3,
                    espacio: 10,
                    children: [
                      for (final ev in resumen.evaluaciones)
                        _EvaluacionCard(
                          evaluacion: ev,
                          matriculados: resumen.estudiantes.length,
                          onRegistrar: () => _registrar(ev),
                          onEliminar: () => _eliminar(ev),
                        ),
                    ],
                  ),
                SectionHeader(
                  title: 'Registro auxiliar',
                  subtitle: 'Promedio ponderado · aprueba con ${formatNota(notaAprobatoria)}',
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final (condicion, texto) in [
                      (null, 'Todos'),
                      (CondicionNota.aprobado, 'Aprobados'),
                      (CondicionNota.desaprobado, 'Desaprobados'),
                      (CondicionNota.sinNotas, 'Sin notas'),
                    ])
                      ChoiceChip(
                        label: Text(texto),
                        selected: _filtro == condicion,
                        onSelected: (_) => setState(() => _filtro = condicion),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (resumen.estudiantes.isEmpty)
                  Text(
                    'No hay estudiantes matriculados en este curso.',
                    style: TextStyle(color: context.tokens.textSecondary),
                  )
                else
                  _RegistroAuxiliar(resumen: resumen, filas: filas),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  final Curso curso;
  final ResumenNotasCurso resumen;

  const _Resumen({required this.curso, required this.resumen});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AdaptiveGrid(
      minAncho: 150,
      children: [
        StatTile(
          icon: Icons.functions_rounded,
          label: 'Promedio del curso',
          value: formatNota(resumen.promedioGeneral),
          color: context.colors.primary,
        ),
        StatTile(
          icon: Icons.verified_rounded,
          label: 'Aprobados',
          value: '${resumen.aprobados}',
          color: tokens.success,
        ),
        StatTile(
          icon: Icons.trending_down_rounded,
          label: 'Desaprobados',
          value: '${resumen.desaprobados}',
          color: tokens.error,
        ),
        StatTile(
          icon: Icons.emoji_events_rounded,
          label: 'Nota más alta',
          value: formatNota(resumen.notaMasAlta),
          color: tokens.accent,
        ),
      ],
    );
  }
}

class _EvaluacionCard extends StatelessWidget {
  final Evaluacion evaluacion;
  final int matriculados;
  final VoidCallback onRegistrar;
  final VoidCallback onEliminar;

  const _EvaluacionCard({
    required this.evaluacion,
    required this.matriculados,
    required this.onRegistrar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final completas = matriculados > 0 && evaluacion.notas.length >= matriculados;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusChip(label: '${evaluacion.peso}%', color: context.colors.secondary),
                const SizedBox(width: 8),
                StatusChip(label: evaluacion.tipo.etiqueta, color: tokens.info),
                const Spacer(),
                PopupMenuButton<String>(
                  tooltip: 'Opciones',
                  onSelected: (_) => onEliminar(),
                  itemBuilder: (_) => const [PopupMenuItem(value: 'eliminar', child: Text('Eliminar'))],
                ),
              ],
            ),
            Text(evaluacion.nombre, style: TextStyle(fontWeight: FontWeight.w800, color: tokens.textPrimary)),
            Text(formatFechaLarga(evaluacion.fecha), style: TextStyle(fontSize: 12.5, color: tokens.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  completas ? Icons.task_alt_rounded : Icons.pending_actions_rounded,
                  size: 16,
                  color: completas ? tokens.success : tokens.warning,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${evaluacion.notas.length}/$matriculados calificados',
                    style: TextStyle(fontSize: 12.5, color: tokens.textSecondary),
                  ),
                ),
                TextButton(onPressed: onRegistrar, child: const Text('Notas')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tabla de notas por evaluación y promedio de cada estudiante.
class _RegistroAuxiliar extends StatelessWidget {
  final ResumenNotasCurso resumen;
  final List<PromedioEstudiante> filas;

  const _RegistroAuxiliar({required this.resumen, required this.filas});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (filas.isEmpty) {
      return Text('Ningún estudiante coincide con el filtro.', style: TextStyle(color: tokens.textSecondary));
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(tokens.surfaceMuted),
          columnSpacing: 20,
          columns: [
            const DataColumn(label: Text('#')),
            const DataColumn(label: Text('Estudiante')),
            for (final ev in resumen.evaluaciones)
              DataColumn(
                numeric: true,
                label: Tooltip(message: ev.nombre, child: Text('${_abreviar(ev.nombre)}\n${ev.peso}%')),
              ),
            const DataColumn(numeric: true, label: Text('Promedio')),
            const DataColumn(label: Text('Condición')),
          ],
          rows: [
            for (var i = 0; i < filas.length; i++)
              DataRow(
                onSelectChanged: (_) => context.abrirEstudiante(filas[i].estudiante, curso: resumen.curso),
                cells: [
                  DataCell(Text('${i + 1}')),
                  DataCell(Text(filas[i].estudiante.nombreCompleto)),
                  for (final ev in resumen.evaluaciones) DataCell(Text(formatNota(filas[i].notas[ev.id]))),
                  DataCell(NotaBadge(filas[i].promedio)),
                  DataCell(CondicionChip(filas[i].condicion)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// "Práctica calificada 1" → "PC1".
  static String _abreviar(String nombre) {
    final palabras = nombre.trim().split(RegExp(r'\s+'));
    if (palabras.length == 1) return nombre.length <= 8 ? nombre : nombre.substring(0, 8);
    return palabras.map((p) => RegExp(r'^\d+$').hasMatch(p) ? p : p[0].toUpperCase()).join();
  }
}
