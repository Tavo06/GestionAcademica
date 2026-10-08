import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/app_routes.dart';
import '../../core/logic/notas.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/estudiante.dart';
import '../../providers/academico_provider.dart';
import '../../providers/calificaciones_provider.dart';
import '../../services/academico_service.dart';
import '../../widgets/academicos.dart';
import '../../widgets/comunes.dart';
import '../../widgets/encabezado.dart';
import 'estudiante_form_dialog.dart';

/// Ficha de un estudiante: sus cursos con promedio y asistencia, el detalle
/// de notas y sesiones del curso elegido y su historial de matrículas.
class EstudianteDetalleScreen extends StatefulWidget {
  final String? estudianteId;
  final Estudiante? estudiante;
  final String? cursoId;

  const EstudianteDetalleScreen({super.key, this.estudianteId, this.estudiante, this.cursoId});

  @override
  State<EstudianteDetalleScreen> createState() => _EstudianteDetalleScreenState();
}

class _EstudianteDetalleScreenState extends State<EstudianteDetalleScreen> {
  // Local: curso cuyo detalle se muestra.
  late String? _cursoId = widget.cursoId;

  Future<void> _editar(Estudiante estudiante) async {
    final editado = await showEstudianteFormDialog(context, estudiante: estudiante);
    if (editado != null && mounted) showMessage(context, 'Datos de ${editado.nombreVisible} guardados.');
  }

  Future<void> _matricular(Estudiante estudiante) async {
    final r = await context.abrirMatricula(estudiante: estudiante);
    if (r != null && mounted) {
      setState(() => _cursoId = r.curso.id);
      showMessage(context, '${estudiante.nombreVisible} matriculado en ${r.curso.nombre}.');
    }
  }

  Future<void> _eliminar(Estudiante estudiante) async {
    final ok = await confirmar(
      context,
      titulo: 'Eliminar estudiante',
      mensaje: 'Se eliminarán ${estudiante.nombreVisible} y todas sus matrículas.',
    );
    if (!ok || !mounted) return;
    try {
      await context.read<AcademicoProvider>().eliminarEstudiante(estudiante.id);
      if (!mounted) return;
      showMessage(context, 'Estudiante eliminado.');
      context.goNamed(AppRoutes.estudiantes);
    } on AcademicoFailure catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final academico = context.watch<AcademicoProvider>();
    final calificaciones = context.watch<CalificacionesProvider>();
    final id = widget.estudianteId ?? widget.estudiante?.id;
    final estudiante =
        (id == null ? null : academico.estudiantePorId(id)) ?? (academico.cargando ? widget.estudiante : null);

    if (estudiante == null) {
      return Scaffold(
        appBar: const EncabezadoSeccion(titulo: 'Estudiante', leading: VolverButton()),
        body: SafeArea(
          child: academico.cargando && id != null
              ? const CargandoView()
              : const UnavailableView(
                  icon: Icons.person_off_outlined,
                  title: 'Estudiante no disponible',
                  message: 'El estudiante no existe o fue eliminado.',
                  destino: AppRoutes.estudiantes,
                  destinoTexto: 'Ir a Estudiantes',
                ),
        ),
      );
    }

    final tokens = context.tokens;
    final cursos = academico.cursosDe(estudiante.id);
    final promedios = calificaciones.promediosDeEstudiante(estudiante.id);
    final general = promedioSimple([for (final p in promedios) if (p.promedio != null) p.promedio!]);
    final seleccionado = cursos.where((c) => c.id == _cursoId).firstOrNull ?? cursos.firstOrNull;
    final historial = academico.matriculasDeEstudiante(estudiante.id);

    return Scaffold(
      appBar: EncabezadoSeccion(
        titulo: estudiante.nombreVisible,
        subtitulo: estudiante.codigo,
        leading: const VolverButton(),
        acciones: [
          IconButton(
            tooltip: 'Editar',
            onPressed: () => _editar(estudiante),
            icon: const Icon(Icons.edit_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: 'Opciones',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (_) => _eliminar(estudiante),
            itemBuilder: (_) => const [PopupMenuItem(value: 'eliminar', child: Text('Eliminar estudiante'))],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _matricular(estudiante),
        icon: const Icon(Icons.how_to_reg_rounded),
        label: const Text('Matricular'),
      ),
      body: SafeArea(
        top: false,
        child: PageList(
          bottom: 96,
          children: [
            BannerDestacado(
              insignia: general == null
                  ? null
                  : Insignia(
                      texto: condicionDe(general).etiqueta,
                      icono: condicionDe(general).icon,
                      color: estaAprobado(general) ? const Color(0xFF9BE3B0) : const Color(0xFFF7A8A8),
                    ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      estudiante.iniciales,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          estudiante.nombreVisible,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text('Código ${estudiante.codigo}'),
                        if (estudiante.correo != null) Text(estudiante.correo!),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 24,
                          runSpacing: 8,
                          children: [
                            DatoBanner(valor: '${cursos.length}', etiqueta: 'Cursos'),
                            DatoBanner(valor: formatNota(general), etiqueta: 'Promedio general'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (cursos.isEmpty)
              EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'Sin cursos',
                message: 'Este estudiante aún no está matriculado en ningún curso.',
                action: FilledButton.icon(
                  onPressed: () => _matricular(estudiante),
                  icon: const Icon(Icons.how_to_reg_rounded),
                  label: const Text('Matricular'),
                ),
              )
            else ...[
              const SectionHeader(title: 'Cursos matriculados', subtitle: 'Toca un curso para ver su detalle.'),
              for (final curso in cursos)
                Builder(builder: (context) {
                  final p = calificaciones.promedioDe(estudiante.id, curso.id);
                  final a = academico.asistenciaDe(estudiante.id, curso.id);
                  final activo = curso.id == seleccionado?.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: activo ? context.colors.secondary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        onTap: () => setState(() => _cursoId = curso.id),
                        title: Text(curso.titulo, style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text(
                          a == null
                              ? 'Sin asistencia'
                              : '${a.faltasTexto} · asistencia ${formatPorcentaje(a.porcentajeAsistencia)}',
                        ),
                        trailing: NotaBadge(p?.promedio),
                      ),
                    ),
                  );
                }),
              if (seleccionado != null) ...[
                SectionHeader(
                  title: 'Notas en ${seleccionado.nombre}',
                  trailing: TextButton(
                    onPressed: () => context.abrirCurso(seleccionado),
                    child: const Text('Ver curso'),
                  ),
                ),
                Builder(builder: (context) {
                  final evaluaciones = calificaciones.evaluacionesDe(seleccionado.id);
                  final p = calificaciones.promedioDe(estudiante.id, seleccionado.id);
                  if (evaluaciones.isEmpty) {
                    return Text(
                      'El curso aún no tiene evaluaciones.',
                      style: TextStyle(color: tokens.textSecondary),
                    );
                  }
                  return Card(
                    child: Column(
                      children: [
                        for (final ev in evaluaciones)
                          ListTile(
                            dense: true,
                            title: Text(ev.nombre, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text('${ev.tipo.etiqueta} · peso ${ev.peso}%'),
                            trailing: NotaBadge(ev.notaDe(estudiante.id), ancho: 54),
                          ),
                        const Divider(height: 1),
                        ListTile(
                          title: const Text('Promedio ponderado', style: TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text(
                            p == null || p.promedio == null
                                ? 'Sin notas registradas'
                                : '${p.condicion.etiqueta}'
                                    '${p.parcial ? ' · parcial (${p.pesoEvaluado}% evaluado)' : ''}',
                          ),
                          trailing: NotaBadge(p?.promedio, ancho: 64),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
            if (historial.isNotEmpty) ...[
              const SectionHeader(title: 'Historial de matrículas'),
              Card(
                child: Column(
                  children: [
                    for (final m in historial)
                      ListTile(
                        dense: true,
                        leading: Icon(
                          m.activa ? Icons.check_circle_outline_rounded : Icons.remove_circle_outline_rounded,
                          color: m.activa ? tokens.success : tokens.textSecondary,
                        ),
                        title: Text(academico.cursoPorId(m.cursoId)?.titulo ?? 'Curso'),
                        subtitle: Text('Desde ${formatFechaCorta(m.fecha)}'),
                        trailing: StatusChip(
                          label: m.estado.etiqueta,
                          color: m.activa ? tokens.success : tokens.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
