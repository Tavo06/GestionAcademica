import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/app_routes.dart';
import '../../core/logic/horario.dart';
import '../../core/logic/ldi.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/curso.dart';
import '../../models/resumen_asistencia.dart';
import '../../models/resumen_notas.dart';
import '../../models/sesion.dart';
import '../../providers/academico_provider.dart';
import '../../providers/calificaciones_provider.dart';
import '../../services/academico_service.dart';
import '../../widgets/academicos.dart';
import '../../widgets/comunes.dart';
import '../../widgets/dialogos.dart';
import '../../widgets/encabezado.dart';
import '../calificaciones/evaluacion_form_dialog.dart';

enum _Vista { sesiones, matriculados, evaluaciones }

/// Detalle de un curso. Recibe el [curso] (objeto enviado desde el listado)
/// y su [cursoId]; muestra los datos vivos del provider y, mientras cargan,
/// el objeto recibido.
class CursoDetalleScreen extends StatefulWidget {
  final String? cursoId;
  final Curso? curso;

  const CursoDetalleScreen({super.key, this.cursoId, this.curso});

  @override
  State<CursoDetalleScreen> createState() => _CursoDetalleScreenState();
}

class _CursoDetalleScreenState extends State<CursoDetalleScreen> {
  _Vista _vista = _Vista.sesiones;

  Future<void> _editar(Curso curso) async {
    final editado = await context.editarCurso(curso);
    if (editado != null && mounted) showMessage(context, 'Curso ${editado.codigo} actualizado.');
  }

  Future<void> _matricular(Curso curso) async {
    final resultado = await context.abrirMatricula(curso: curso);
    if (resultado != null && mounted) {
      setState(() => _vista = _Vista.matriculados);
      showMessage(
        context,
        '${resultado.cantidad} ${resultado.cantidad == 1 ? 'estudiante matriculado' : 'estudiantes matriculados'} '
        'en ${resultado.curso.nombre}.',
      );
    }
  }

  Future<void> _eliminar(Curso curso) async {
    final ok = await confirmar(
      context,
      titulo: 'Eliminar curso',
      mensaje:
          'Se eliminarán "${curso.nombre}", sus ${curso.totalSesiones} sesiones con su '
          'asistencia, sus matrículas y sus evaluaciones con notas. Tus jornadas se '
          'conservan en el historial.',
    );
    if (!ok || !mounted) return;
    final evaluaciones = context.read<CalificacionesProvider>().evaluacionesDe(curso.id);
    try {
      await context.read<AcademicoProvider>().eliminarCurso(curso.id, evaluacionIds: evaluaciones.map((e) => e.id));
      if (!mounted) return;
      showMessage(context, 'Curso eliminado.');
      context.goNamed(AppRoutes.cursos);
    } on AcademicoFailure catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    }
  }

  Future<void> _abrirSesion(Sesion sesion) async {
    final resultado = await context.abrirTomaAsistencia(sesion);
    if (resultado != null && mounted) await mostrarResultadoAsistencia(context, resultado);
  }

  Future<void> _retirar(Curso curso, AsistenciaEstudiante e) async {
    final academico = context.read<AcademicoProvider>();
    final matricula = academico.matriculaDe(curso.id, e.estudiante.id);
    if (matricula == null) return;
    final ok = await confirmar(
      context,
      titulo: 'Retirar del curso',
      mensaje:
          '${e.estudiante.nombreVisible} quedará como "retirado" en ${curso.nombre}. '
          'Sus notas y asistencia se conservan y puedes volver a matricularlo.',
      accion: 'Retirar',
    );
    if (!ok || !mounted) return;
    try {
      await academico.retirar(matricula);
      if (mounted) showMessage(context, 'Matrícula retirada.');
    } on AcademicoFailure catch (err) {
      if (mounted) showMessage(context, err.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final academico = context.watch<AcademicoProvider>();
    final calificaciones = context.watch<CalificacionesProvider>();
    final id = widget.cursoId ?? widget.curso?.id;
    // Datos vivos; el objeto recibido solo mientras cargan.
    final curso = (id == null ? null : academico.cursoPorId(id)) ?? (academico.cargando ? widget.curso : null);

    if (curso == null) {
      return Scaffold(
        appBar: const EncabezadoSeccion(titulo: 'Curso', leading: VolverButton()),
        body: SafeArea(
          child: academico.cargando && id != null
              ? const CargandoView()
              : academico.error != null
              ? LoadErrorView(message: academico.error!, onRetry: academico.reintentar)
              : const UnavailableView(
                  icon: Icons.menu_book_outlined,
                  title: 'Curso no disponible',
                  message: 'El curso no existe o fue eliminado.',
                  destino: AppRoutes.cursos,
                  destinoTexto: 'Ir a Cursos',
                ),
        ),
      );
    }

    final resumen = academico.resumenDe(curso);
    final notas = calificaciones.resumenDe(curso);
    final promedios = {for (final p in notas.estudiantes) p.estudiante.id: p};

    return Scaffold(
      appBar: EncabezadoSeccion(
        titulo: curso.nombre,
        subtitulo: curso.codigo,
        leading: const VolverButton(),
        acciones: [
          IconButton(
            tooltip: 'Reporte del curso',
            onPressed: () => context.abrirReporte(curso),
            icon: const Icon(Icons.assessment_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: 'Opciones',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (v) => v == 'editar' ? _editar(curso) : _eliminar(curso),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'editar', child: Text('Editar datos del curso')),
              PopupMenuItem(value: 'eliminar', child: Text('Eliminar curso')),
            ],
          ),
        ],
      ),
      floatingActionButton: switch (_vista) {
        _Vista.matriculados => FloatingActionButton.extended(
          onPressed: () => _matricular(curso),
          icon: const Icon(Icons.how_to_reg_rounded),
          label: const Text('Matricular'),
        ),
        _Vista.evaluaciones => FloatingActionButton.extended(
          onPressed: () => showEvaluacionFormDialog(context, curso),
          icon: const Icon(Icons.add_task_rounded),
          label: const Text('Evaluación'),
        ),
        _Vista.sesiones => null,
      },
      body: SafeArea(
        top: false,
        child: PageList(
          bottom: 96,
          children: [
            _Cabecera(resumen: resumen, notas: notas),
            const SizedBox(height: 20),
            SegmentedButton<_Vista>(
              segments: [
                ButtonSegment(
                  value: _Vista.sesiones,
                  icon: const Icon(Icons.event_note_rounded),
                  label: Text('Sesiones (${resumen.sesiones.length})'),
                ),
                ButtonSegment(
                  value: _Vista.matriculados,
                  icon: const Icon(Icons.groups_rounded),
                  label: Text('Matriculados (${resumen.estudiantes.length})'),
                ),
                ButtonSegment(
                  value: _Vista.evaluaciones,
                  icon: const Icon(Icons.grade_rounded),
                  label: Text('Notas (${notas.evaluaciones.length})'),
                ),
              ],
              selected: {_vista},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _vista = s.first),
            ),
            const SizedBox(height: 16),
            ...switch (_vista) {
              _Vista.sesiones => [
                for (final sesion in resumen.sesiones)
                  SesionTile(
                    curso: curso,
                    sesion: sesion,
                    hoy: academico.hoy,
                    totalEstudiantes: resumen.estudiantes.length,
                    onTap: () => _abrirSesion(sesion),
                    trailing: puedeEditarFecha(sesion.fecha, academico.hoy)
                        ? PopupMenuButton<String>(
                            tooltip: 'Opciones',
                            onSelected: (_) async {
                              if (await showCambiarFechaDialog(context, sesion) && context.mounted) {
                                showMessage(context, 'Fecha de la sesión actualizada.');
                              }
                            },
                            itemBuilder: (_) => const [PopupMenuItem(value: 'fecha', child: Text('Cambiar fecha'))],
                          )
                        : null,
                  ),
              ],
              _Vista.matriculados =>
                resumen.estudiantes.isEmpty
                    ? [
                        EmptyState(
                          icon: Icons.groups_rounded,
                          title: 'Sin matriculados',
                          message:
                              'Matricula estudiantes en este curso para tomar su '
                              'asistencia y registrar sus notas.',
                          action: FilledButton.icon(
                            onPressed: () => _matricular(curso),
                            icon: const Icon(Icons.how_to_reg_rounded),
                            label: const Text('Matricular'),
                          ),
                        ),
                      ]
                    : [
                        for (final e in resumen.estudiantes)
                          EstudianteTile(
                            estudiante: e.estudiante,
                            detalle: '${e.estudiante.codigo} · ${e.faltasTexto}',
                            color: e.enLdi ? context.tokens.error : null,
                            onTap: () => context.abrirEstudiante(e.estudiante, curso: curso),
                            extra: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                LdiChip(enLdi: e.enLdi),
                                if (promedios[e.estudiante.id] case final p?) CondicionChip(p.condicion),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                NotaBadge(promedios[e.estudiante.id]?.promedio),
                                PopupMenuButton<String>(
                                  tooltip: 'Opciones',
                                  onSelected: (_) => _retirar(curso, e),
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'retirar', child: Text('Retirar del curso')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
              _Vista.evaluaciones =>
                notas.evaluaciones.isEmpty
                    ? [
                        EmptyState(
                          icon: Icons.grade_rounded,
                          title: 'Sin evaluaciones',
                          message:
                              'Crea las evaluaciones del curso con su peso (%) para '
                              'registrar notas y calcular promedios.',
                          action: FilledButton.icon(
                            onPressed: () => showEvaluacionFormDialog(context, curso),
                            icon: const Icon(Icons.add_task_rounded),
                            label: const Text('Nueva evaluación'),
                          ),
                        ),
                      ]
                    : [
                        ProgressLine(
                          value: notas.pesoAsignado / 100,
                          label: 'Peso asignado en evaluaciones',
                          detalle: '${notas.pesoAsignado}% de 100%',
                          color: context.colors.secondary,
                        ),
                        const SizedBox(height: 12),
                        for (final ev in notas.evaluaciones)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Card(
                              child: ListTile(
                                onTap: () async {
                                  final r = await context.abrirRegistroNotas(ev);
                                  if (r != null && context.mounted) {
                                    showMessage(context, 'Notas de ${r.evaluacion.nombre} guardadas.');
                                  }
                                },
                                leading: CircleAvatar(
                                  backgroundColor: context.colors.secondary.withValues(alpha: 0.15),
                                  child: Text(
                                    '${ev.peso}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: context.colors.secondary,
                                    ),
                                  ),
                                ),
                                title: Text(ev.nombre, style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Text(
                                  '${ev.tipo.etiqueta} · ${formatFechaCorta(ev.fecha)} · '
                                  '${ev.notas.length}/${resumen.estudiantes.length} calificados',
                                ),
                                trailing: const Icon(Icons.edit_note_rounded),
                              ),
                            ),
                          ),
                      ],
            },
          ],
        ),
      ),
    );
  }
}

/// Banner del curso: datos, cifras y avance, con los créditos superpuestos.
class _Cabecera extends StatelessWidget {
  final ResumenCurso resumen;
  final ResumenNotasCurso notas;

  const _Cabecera({required this.resumen, required this.notas});

  @override
  Widget build(BuildContext context) {
    final curso = resumen.curso;
    final permitidas = faltasPermitidas(curso.totalSesiones);
    final tenue = Colors.white.withValues(alpha: 0.85);
    return BannerDestacado(
      insignia: Insignia(texto: '${curso.creditos} créditos', icono: Icons.workspace_premium_rounded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            curso.codigo,
            style: TextStyle(fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: tenue),
          ),
          Text(
            curso.nombre,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          if (curso.descripcion != null) Text(curso.descripcion!, style: TextStyle(color: tenue)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              InfoLine(icon: Icons.calendar_today_rounded, text: curso.diasTexto, color: Colors.white),
              InfoLine(icon: Icons.schedule_rounded, text: curso.horario, color: Colors.white),
              InfoLine(
                icon: Icons.flag_rounded,
                text: 'Inicio ${formatFechaCorta(curso.fechaInicio)}',
                color: Colors.white,
              ),
            ].map((w) => SizedBox(width: 190, child: w)).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DatoBanner(valor: '${resumen.realizadas}/${curso.totalSesiones}', etiqueta: 'Sesiones'),
              ),
              Expanded(
                child: DatoBanner(valor: '${resumen.estudiantes.length}', etiqueta: 'Matriculados'),
              ),
              Expanded(
                child: DatoBanner(valor: formatNota(notas.promedioGeneral), etiqueta: 'Promedio'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: resumen.progreso,
              minHeight: 6,
              color: context.tokens.accent,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'LDI desde ${permitidas + 1} faltas ($umbralLdi% de ${curso.totalSesiones} sesiones).',
            style: TextStyle(fontSize: 12, color: tenue),
          ),
        ],
      ),
    );
  }
}
