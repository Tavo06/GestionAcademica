import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_routes.dart';
import '../../core/logic/ldi.dart';
import '../../core/logic/notas.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/curso.dart';
import '../../models/resumen_asistencia.dart';
import '../../models/resumen_notas.dart';
import '../../providers/academico_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/calificaciones_provider.dart';
import '../../widgets/academicos.dart';
import '../../widgets/comunes.dart';
import '../../widgets/encabezado.dart';

/// Rangos de la distribución de notas (vigesimal).
const _rangos = [
  (desde: 0.0, hasta: 10.5, etiqueta: '0 – 10.49'),
  (desde: 10.5, hasta: 14.0, etiqueta: '10.50 – 13.99'),
  (desde: 14.0, hasta: 17.0, etiqueta: '14 – 16.99'),
  (desde: 17.0, hasta: 20.01, etiqueta: '17 – 20'),
];

/// Reporte de un curso: docente, rendimiento (promedios, ranking y
/// distribución), asistencia y estudiantes en LDI. Recibe el [curso] como
/// objeto desde la pantalla anterior.
class ReporteScreen extends StatelessWidget {
  final String? cursoId;
  final Curso? curso;

  const ReporteScreen({super.key, this.cursoId, this.curso});

  @override
  Widget build(BuildContext context) {
    final academico = context.watch<AcademicoProvider>();
    final calificaciones = context.watch<CalificacionesProvider>();
    final docente = context.watch<AuthProvider>().docente;
    final id = cursoId ?? curso?.id;
    final actual = (id == null ? null : academico.cursoPorId(id)) ?? (academico.cargando ? curso : null);

    if (actual == null) {
      return Scaffold(
        appBar: const EncabezadoSeccion(titulo: 'Reporte', leading: VolverButton()),
        body: SafeArea(
          child: academico.cargando
              ? const CargandoView()
              : const UnavailableView(
                  icon: Icons.assessment_outlined,
                  title: 'Reporte no disponible',
                  message: 'El curso no existe o fue eliminado.',
                  destino: AppRoutes.reportes,
                  destinoTexto: 'Ir a Reportes',
                ),
        ),
      );
    }

    final tokens = context.tokens;
    final notas = calificaciones.resumenDe(actual);
    final asistencia = academico.resumenDe(actual);
    final enLdi = estudiantesEnLdi(asistencia.estudiantes);
    final asistenciaPorId = {for (final a in asistencia.estudiantes) a.estudiante.id: a};

    return Scaffold(
      appBar: EncabezadoSeccion(
        titulo: 'Reporte · ${actual.codigo}',
        subtitulo: actual.nombre,
        leading: const VolverButton(),
      ),
      body: SafeArea(
        top: false,
        child: PageList(
          children: [
            BannerDestacado(
              insignia: Insignia(texto: condicionDe(notas.promedioGeneral).etiqueta, icono: Icons.insights_rounded),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    actual.titulo,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  InfoLine(icon: Icons.person_rounded, text: 'Docente: ${docente.nombreCompleto}', color: Colors.white),
                  InfoLine(
                    icon: Icons.schedule_rounded,
                    text: '${actual.diasTexto} · ${actual.horario} · ${actual.creditos} créditos',
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 28,
                    runSpacing: 12,
                    children: [
                      DatoBanner(valor: '${notas.estudiantes.length}', etiqueta: 'Matriculados'),
                      DatoBanner(valor: formatNota(notas.promedioGeneral), etiqueta: 'Promedio'),
                      DatoBanner(valor: '${notas.aprobados}', etiqueta: 'Aprobados'),
                      DatoBanner(valor: formatPorcentaje(asistencia.promedioAsistencia), etiqueta: 'Asistencia'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const SectionHeader(title: 'Distribución de promedios'),
            _Distribucion(resumen: notas),
            const SectionHeader(title: 'Avance'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ProgressLine(
                      value: asistencia.progreso,
                      label: 'Sesiones dictadas',
                      detalle: '${asistencia.realizadas}/${actual.totalSesiones}',
                    ),
                    const SizedBox(height: 12),
                    ProgressLine(
                      value: notas.pesoAsignado / pesoTotal,
                      label: 'Evaluaciones programadas (peso)',
                      detalle: '${notas.pesoAsignado}%',
                      color: context.colors.secondary,
                    ),
                  ],
                ),
              ),
            ),
            SectionHeader(title: 'Ranking', subtitle: 'Promedio ponderado; aprueba con ${formatNota(notaAprobatoria)}'),
            if (notas.estudiantes.isEmpty)
              Text('No hay estudiantes matriculados.', style: TextStyle(color: tokens.textSecondary))
            else
              for (final (i, p) in notas.ranking.indexed)
                EstudianteTile(
                  estudiante: p.estudiante,
                  detalle: [
                    p.estudiante.codigo,
                    if (asistenciaPorId[p.estudiante.id] case final a?)
                      'asistencia ${formatPorcentaje(a.porcentajeAsistencia)}',
                  ].join(' · '),
                  color: p.condicion.colorEn(context),
                  onTap: () => context.abrirEstudiante(p.estudiante, curso: actual),
                  extra: CondicionChip(p.condicion),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (i < 3 && p.promedio != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(Icons.emoji_events_rounded, color: tokens.accent),
                        ),
                      NotaBadge(p.promedio),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
            SectionHeader(title: 'Estudiantes en LDI', subtitle: '$umbralLdi% o más de faltas'),
            if (enLdi.isEmpty)
              Card(
                child: ListTile(
                  leading: Icon(Icons.verified_rounded, color: tokens.success),
                  title: const Text('Ningún estudiante alcanzó el LDI.'),
                ),
              )
            else
              for (final AsistenciaEstudiante e in enLdi)
                EstudianteTile(
                  estudiante: e.estudiante,
                  detalle: e.faltasTexto,
                  color: tokens.error,
                  trailing: StatusChip(label: formatPorcentaje(e.porcentajeFaltas), color: tokens.error),
                ),
          ],
        ),
      ),
    );
  }
}

/// Barras horizontales con cuántos estudiantes caen en cada rango.
class _Distribucion extends StatelessWidget {
  final ResumenNotasCurso resumen;

  const _Distribucion({required this.resumen});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final promedios = [for (final p in resumen.conNotas) p.promedio!];
    final conteo = <String, int>{
      for (final r in _rangos) r.etiqueta: promedios.where((n) => n >= r.desde && n < r.hasta).length,
    };
    final maximo = conteo.values.fold(0, (a, b) => a > b ? a : b);
    if (promedios.isEmpty) {
      return Text('Aún no hay promedios.', style: TextStyle(color: tokens.textSecondary));
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final r in _rangos)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    SizedBox(
                      width: 104,
                      child: Text(r.etiqueta, style: TextStyle(fontSize: 12.5, color: tokens.textSecondary)),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final cantidad = conteo[r.etiqueta]!;
                          final color = r.desde < notaAprobatoria ? tokens.error : tokens.success;
                          return Stack(
                            children: [
                              Container(
                                height: 22,
                                decoration: BoxDecoration(
                                  color: tokens.surfaceMuted,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              Container(
                                height: 22,
                                width: maximo == 0 ? 0 : constraints.maxWidth * cantidad / maximo,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '$cantidad',
                                      style: TextStyle(fontWeight: FontWeight.w800, color: tokens.textPrimary),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
