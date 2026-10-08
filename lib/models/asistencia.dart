/// Valores posibles de asistencia de un estudiante en una sesión. Se
/// guardan en Firestore como [valor] dentro de `sesiones/{id}.asistencias`.
enum EstadoAsistencia {
  presente('presente', 'Presente'),
  tarde('tarde', 'Tarde'),
  falta('falta', 'Falta');

  const EstadoAsistencia(this.valor, this.etiqueta);

  final String valor;
  final String etiqueta;

  /// Presente o tarde: el estudiante asistió.
  bool get asistio => this != EstadoAsistencia.falta;

  /// Los valores desconocidos (por ejemplo, editados a mano) se ignoran.
  static EstadoAsistencia? fromValor(Object? valor) {
    for (final estado in values) {
      if (estado.valor == valor) return estado;
    }
    return null;
  }
}

/// La asistencia de un estudiante en una sesión.
class Asistencia {
  final String estudianteId;
  final String sesionId;
  final EstadoAsistencia estado;

  const Asistencia({required this.estudianteId, required this.sesionId, required this.estado});
}
