import '../core/logic/notas.dart';

/// La nota (0 a 20) de un estudiante en una evaluación.
class Calificacion {
  final String evaluacionId;
  final String estudianteId;
  final double nota;

  const Calificacion({
    required this.evaluacionId,
    required this.estudianteId,
    required this.nota,
  });

  bool get aprobada => estaAprobado(nota);
}
