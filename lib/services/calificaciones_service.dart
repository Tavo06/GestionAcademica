import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/logic/horario.dart';
import '../models/evaluacion.dart';
import 'academico_service.dart';

/// Evaluaciones y notas (`evaluaciones`). Cada evaluación guarda sus notas
/// en el mapa `notas` ({estudianteId: nota}).
class CalificacionesService {
  CalificacionesService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _evaluaciones =>
      _firestore.collection('evaluaciones');

  Stream<List<Evaluacion>> watchEvaluaciones(String uid) => _evaluaciones
      .where('docenteId', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs.map((d) => Evaluacion.fromDoc(d.id, d.data())).toList());

  Future<String> crearEvaluacion(String uid, NuevaEvaluacion datos) async {
    try {
      final ref = await _evaluaciones.add({
        'docenteId': uid,
        'cursoId': datos.cursoId,
        'nombre': datos.nombre.trim(),
        'tipo': datos.tipo.valor,
        'peso': datos.peso,
        'fecha': Timestamp.fromDate(soloFecha(datos.fecha)),
        'notas': <String, double>{},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } on FirebaseException {
      throw const AcademicoFailure('No se pudo crear la evaluación.');
    }
  }

  Future<void> eliminarEvaluacion(String id) async {
    try {
      await _evaluaciones.doc(id).delete();
    } on FirebaseException {
      throw const AcademicoFailure('No se pudo eliminar la evaluación.');
    }
  }

  /// Reemplaza todas las notas de la evaluación.
  Future<void> guardarNotas(String evaluacionId, Map<String, double> notas) async {
    try {
      await _evaluaciones.doc(evaluacionId).update({
        'notas': notas,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException {
      throw const AcademicoFailure('No se pudieron guardar las notas.');
    }
  }
}
