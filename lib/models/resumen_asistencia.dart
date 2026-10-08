import '../core/logic/ldi.dart' as ldi;
import 'asistencia.dart';
import 'curso.dart';
import 'estudiante.dart';
import 'sesion.dart';

/// Conteo de presentes, tardanzas y faltas. El "% de asistencia" cuenta
/// presentes + tardanzas sobre los registros tomados; no es el % del LDI.
class ResumenAsistencia {
  final int presentes;
  final int tardes;
  final int faltas;

  const ResumenAsistencia({this.presentes = 0, this.tardes = 0, this.faltas = 0});

  int get total => presentes + tardes + faltas;

  double get porcentajeAsistencia => total == 0 ? 0 : (presentes + tardes) * 100 / total;

  factory ResumenAsistencia.contar(Iterable<EstadoAsistencia> estados) {
    var presentes = 0;
    var tardes = 0;
    var faltas = 0;
    for (final estado in estados) {
      switch (estado) {
        case EstadoAsistencia.presente:
          presentes++;
        case EstadoAsistencia.tarde:
          tardes++;
        case EstadoAsistencia.falta:
          faltas++;
      }
    }
    return ResumenAsistencia(presentes: presentes, tardes: tardes, faltas: faltas);
  }
}

/// La asistencia de un estudiante en UN curso. Las faltas de otros cursos
/// nunca cuentan aquí.
class AsistenciaEstudiante {
  final Estudiante estudiante;
  final Curso curso;
  final ResumenAsistencia resumen;

  const AsistenciaEstudiante({required this.estudiante, required this.curso, required this.resumen});

  int get faltas => resumen.faltas;

  /// Faltas sobre el total de sesiones del curso (regla del LDI).
  double get porcentajeFaltas => ldi.porcentajeFaltas(faltas, curso.totalSesiones);

  bool get enLdi => ldi.estaEnLdi(faltas, curso.totalSesiones);

  double get porcentajeAsistencia => resumen.porcentajeAsistencia;

  /// "Faltas: 3/16".
  String get faltasTexto => 'Faltas: $faltas/${curso.totalSesiones}';
}

/// Todo lo que se muestra de la asistencia de un curso.
class ResumenCurso {
  final Curso curso;

  /// Ordenadas por número.
  final List<Sesion> sesiones;
  final List<AsistenciaEstudiante> estudiantes;
  final int realizadas;
  final ResumenAsistencia resumen;

  const ResumenCurso({
    required this.curso,
    required this.sesiones,
    required this.estudiantes,
    required this.realizadas,
    required this.resumen,
  });

  int get pendientes => (curso.totalSesiones - realizadas).clamp(0, curso.totalSesiones);

  /// Avance del curso (sesiones dictadas), independiente de las faltas.
  double get progreso => curso.totalSesiones == 0 ? 0 : realizadas / curso.totalSesiones;

  int get enLdi => estudiantes.where((e) => e.enLdi).length;
  int get regulares => estudiantes.length - enLdi;
  int get totalFaltas => resumen.faltas;
  double get promedioAsistencia => resumen.porcentajeAsistencia;
}

/// Asistencia de [curso] con sus propias sesiones y sus [matriculados].
ResumenCurso calcularResumenCurso({
  required Curso curso,
  required Iterable<Sesion> sesiones,
  required Iterable<Estudiante> matriculados,
  required DateTime ahora,
}) {
  final propias = sesiones.where((s) => s.cursoId == curso.id).toList()..sort((a, b) => a.numero.compareTo(b.numero));
  final inscritos = matriculados.toList()..sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));

  final estadosPorEstudiante = <String, List<EstadoAsistencia>>{
    for (final estudiante in inscritos) estudiante.id: <EstadoAsistencia>[],
  };
  var realizadas = 0;
  for (final sesion in propias) {
    if (sesion.realizada(ahora)) realizadas++;
    for (final registro in sesion.registros) {
      estadosPorEstudiante[registro.estudianteId]?.add(registro.estado);
    }
  }

  return ResumenCurso(
    curso: curso,
    sesiones: propias,
    estudiantes: [
      for (final estudiante in inscritos)
        AsistenciaEstudiante(
          estudiante: estudiante,
          curso: curso,
          resumen: ResumenAsistencia.contar(estadosPorEstudiante[estudiante.id]!),
        ),
    ],
    realizadas: realizadas.clamp(0, curso.totalSesiones),
    resumen: ResumenAsistencia.contar(estadosPorEstudiante.values.expand((e) => e)),
  );
}

/// Un estudiante queda bloqueado en [sesion] cuando las faltas de las
/// sesiones ANTERIORES del mismo curso ya alcanzan el LDI. La falta que lo
/// alcanza sí se registra; el bloqueo empieza después.
bool bloqueadoPorLdi({
  required String estudianteId,
  required Sesion sesion,
  required Iterable<Sesion> sesionesCurso,
  required int totalSesiones,
}) {
  var faltas = 0;
  for (final anterior in sesionesCurso) {
    if (anterior.cursoId == sesion.cursoId &&
        anterior.numero < sesion.numero &&
        anterior.estadoDe(estudianteId) == EstadoAsistencia.falta) {
      faltas++;
    }
  }
  return ldi.estaEnLdi(faltas, totalSesiones);
}

/// Estudiantes en LDI, mayor % de faltas primero.
List<AsistenciaEstudiante> estudiantesEnLdi(Iterable<AsistenciaEstudiante> lista) =>
    lista.where((e) => e.enLdi).toList()..sort((a, b) => b.porcentajeFaltas.compareTo(a.porcentajeFaltas));
