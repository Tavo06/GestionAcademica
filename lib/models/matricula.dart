import 'package:cloud_firestore/cloud_firestore.dart';

enum EstadoMatricula {
  activa('activa', 'Activa'),
  retirada('retirada', 'Retirada');

  const EstadoMatricula(this.valor, this.etiqueta);

  final String valor;
  final String etiqueta;

  static EstadoMatricula fromValor(Object? valor) =>
      valor == 'retirada' ? EstadoMatricula.retirada : EstadoMatricula.activa;
}

/// Id fijo `{cursoId}_{estudianteId}`: un estudiante tiene como máximo una
/// matrícula por curso (las reglas de Firestore también lo exigen).
String matriculaId(String cursoId, String estudianteId) => '${cursoId}_$estudianteId';

/// La inscripción de un estudiante en un curso (`matriculas/{id}`). Al
/// retirarse no se borra: queda como `retirada` con su historial.
class Matricula {
  final String id;
  final String docenteId;
  final String cursoId;
  final String estudianteId;
  final DateTime fecha;
  final EstadoMatricula estado;

  const Matricula({
    required this.id,
    required this.docenteId,
    required this.cursoId,
    required this.estudianteId,
    required this.fecha,
    this.estado = EstadoMatricula.activa,
  });

  bool get activa => estado == EstadoMatricula.activa;

  Matricula copyWith({EstadoMatricula? estado}) => Matricula(
    id: id,
    docenteId: docenteId,
    cursoId: cursoId,
    estudianteId: estudianteId,
    fecha: fecha,
    estado: estado ?? this.estado,
  );

  factory Matricula.fromDoc(String id, Map<String, dynamic> data) {
    final fecha = data['fecha'];
    return Matricula(
      id: id,
      docenteId: data['docenteId'] as String? ?? '',
      cursoId: data['cursoId'] as String? ?? '',
      estudianteId: data['estudianteId'] as String? ?? '',
      // Recién creada, la hora del servidor aún no llega al listener.
      fecha: fecha is Timestamp ? fecha.toDate() : DateTime.now(),
      estado: EstadoMatricula.fromValor(data['estado']),
    );
  }
}
