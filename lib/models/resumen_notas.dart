import '../core/logic/notas.dart';
import 'curso.dart';
import 'estudiante.dart';
import 'evaluacion.dart';

/// Las notas de un estudiante en UN curso y su promedio ponderado.
class PromedioEstudiante {
  final Estudiante estudiante;
  final Curso curso;

  /// Nota por id de evaluación (solo las evaluaciones calificadas).
  final Map<String, double> notas;

  /// Promedio ponderado de las evaluaciones con nota; null sin notas.
  final double? promedio;

  /// Suma de los pesos (%) de las evaluaciones que ya tienen nota.
  final int pesoEvaluado;

  const PromedioEstudiante({
    required this.estudiante,
    required this.curso,
    required this.notas,
    required this.promedio,
    required this.pesoEvaluado,
  });

  CondicionNota get condicion => condicionDe(promedio);
  bool get aprobado => condicion == CondicionNota.aprobado;

  /// El promedio aún no cubre el 100 % de las evaluaciones.
  bool get parcial => pesoEvaluado < pesoTotal;
}

/// Promedios de un curso: uno por estudiante matriculado y el resumen.
class ResumenNotasCurso {
  final Curso curso;

  /// Ordenadas por fecha.
  final List<Evaluacion> evaluaciones;

  /// Ordenados por nombre.
  final List<PromedioEstudiante> estudiantes;

  const ResumenNotasCurso({required this.curso, required this.evaluaciones, required this.estudiantes});

  int get pesoAsignado => evaluaciones.fold(0, (suma, e) => suma + e.peso);
  int get pesoDisponible => (pesoTotal - pesoAsignado).clamp(0, pesoTotal);

  Iterable<PromedioEstudiante> get conNotas => estudiantes.where((e) => e.promedio != null);

  int get aprobados => estudiantes.where((e) => e.condicion == CondicionNota.aprobado).length;
  int get desaprobados => estudiantes.where((e) => e.condicion == CondicionNota.desaprobado).length;
  int get sinNotas => estudiantes.where((e) => e.condicion == CondicionNota.sinNotas).length;

  /// Promedio de los promedios de los estudiantes con notas.
  double? get promedioGeneral => promedioSimple(conNotas.map((e) => e.promedio!));

  double? get notaMasAlta {
    double? maximo;
    for (final e in conNotas) {
      if (maximo == null || e.promedio! > maximo) maximo = e.promedio;
    }
    return maximo;
  }

  /// Ranking: mayor promedio primero; los que no tienen notas al final.
  List<PromedioEstudiante> get ranking => List.of(estudiantes)
    ..sort((a, b) {
      final pa = a.promedio;
      final pb = b.promedio;
      if (pa == null && pb == null) {
        return a.estudiante.nombreCompleto.compareTo(b.estudiante.nombreCompleto);
      }
      if (pa == null) return 1;
      if (pb == null) return -1;
      return pb.compareTo(pa);
    });
}

/// Calcula el promedio ponderado de cada [matriculados] en [curso].
ResumenNotasCurso calcularResumenNotas({
  required Curso curso,
  required Iterable<Evaluacion> evaluaciones,
  required Iterable<Estudiante> matriculados,
}) {
  final propias = evaluaciones.where((e) => e.cursoId == curso.id).toList()
    ..sort((a, b) {
      final porFecha = a.fecha.compareTo(b.fecha);
      return porFecha != 0 ? porFecha : a.nombre.compareTo(b.nombre);
    });
  final inscritos = matriculados.toList()..sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));

  return ResumenNotasCurso(
    curso: curso,
    evaluaciones: propias,
    estudiantes: [for (final estudiante in inscritos) _promedioDe(estudiante, curso, propias)],
  );
}

PromedioEstudiante _promedioDe(Estudiante estudiante, Curso curso, List<Evaluacion> evaluaciones) {
  final notas = <String, double>{};
  final ponderadas = <({double nota, int peso})>[];
  var pesoEvaluado = 0;
  for (final evaluacion in evaluaciones) {
    final nota = evaluacion.notaDe(estudiante.id);
    if (nota == null) continue;
    notas[evaluacion.id] = nota;
    ponderadas.add((nota: nota, peso: evaluacion.peso));
    pesoEvaluado += evaluacion.peso;
  }
  return PromedioEstudiante(
    estudiante: estudiante,
    curso: curso,
    notas: notas,
    promedio: promedioPonderado(ponderadas),
    pesoEvaluado: pesoEvaluado,
  );
}
