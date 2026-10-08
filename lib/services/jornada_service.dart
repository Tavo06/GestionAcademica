import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/logic/horario.dart';
import '../models/curso.dart';
import '../models/jornada.dart';
import '../models/sesion.dart';

class JornadaFailure implements Exception {
  final String message;
  const JornadaFailure(this.message);

  @override
  String toString() => message;
}

/// Reloj de jornadas del docente (`jornadas`): un registro por sesión de
/// curso (`{uid}_{sesionId}`). Las horas vienen del servidor
/// (`serverTimestamp`), así que no se pueden falsear cambiando la hora del
/// teléfono; las reglas también lo exigen.
class JornadaService {
  JornadaService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _jornadas => _firestore.collection('jornadas');

  Future<void> marcarEntrada(String uid, Curso curso, Sesion sesion) async {
    final ref = _jornadas.doc(jornadaDocId(uid, sesion.id));
    try {
      if ((await ref.get()).exists) {
        throw const JornadaFailure('Ya registraste tu entrada para esta sesión.');
      }
      await ref.set({
        'docenteId': uid,
        'cursoId': curso.id,
        'sesionId': sesion.id,
        'cursoNombre': curso.nombre,
        'sesionNumero': sesion.numero,
        'fecha': Timestamp.fromDate(soloFecha(sesion.fecha)),
        'horaProgramadaInicio': sesion.horaInicio.toString(),
        'horaProgramadaFin': sesion.horaFin.toString(),
        'entrada': FieldValue.serverTimestamp(),
        'salida': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException {
      throw const JornadaFailure('No se pudo registrar la entrada.');
    }
  }

  Future<void> marcarSalida(String jornadaId) async {
    final ref = _jornadas.doc(jornadaId);
    try {
      final data = (await ref.get()).data();
      if (data == null || data['entrada'] == null) {
        throw const JornadaFailure('Debes registrar tu entrada antes de la salida.');
      }
      if (data['salida'] != null) {
        throw const JornadaFailure('Ya registraste tu salida para esta sesión.');
      }
      await ref.update({
        'salida': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException {
      throw const JornadaFailure('No se pudo registrar la salida.');
    }
  }

  /// Todas las jornadas del docente, la más reciente primero. Se ordenan en
  /// memoria para que la consulta use solo el índice automático.
  Stream<List<Jornada>> watchJornadas(String uid) => _jornadas
      .where('docenteId', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs.map((d) => Jornada.fromDoc(d.id, d.data())).toList()
        ..sort(compararJornadas));
}
