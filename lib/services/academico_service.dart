import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/logic/horario.dart';
import '../models/asistencia.dart';
import '../models/curso.dart';
import '../models/estudiante.dart';
import '../models/matricula.dart';
import '../models/sesion.dart';

class AcademicoFailure implements Exception {
  final String message;
  const AcademicoFailure(this.message);

  @override
  String toString() => message;
}

/// Acceso a Firestore de cursos (`cursos`), sus sesiones con asistencia
/// (`sesiones`), los estudiantes (`estudiantes`) y sus matrículas
/// (`matriculas`). Todo documento lleva `docenteId`, que revisan las reglas,
/// y toda consulta filtra por él.
class AcademicoService {
  AcademicoService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Escrituras por lote. Las reglas de cada escritura leen el perfil del
  /// docente; lotes pequeños quedan lejos del límite de lecturas.
  static const _tamanoLote = 8;

  CollectionReference<Map<String, dynamic>> get _cursos => _firestore.collection('cursos');
  CollectionReference<Map<String, dynamic>> get _sesiones => _firestore.collection('sesiones');
  CollectionReference<Map<String, dynamic>> get _estudiantes =>
      _firestore.collection('estudiantes');
  CollectionReference<Map<String, dynamic>> get _matriculas => _firestore.collection('matriculas');
  CollectionReference<Map<String, dynamic>> get _evaluaciones =>
      _firestore.collection('evaluaciones');

  Stream<List<Curso>> watchCursos(String uid) => _cursos
      .where('docenteId', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs.map((d) => Curso.fromDoc(d.id, d.data())).toList());

  Stream<List<Sesion>> watchSesiones(String uid) => _sesiones
      .where('docenteId', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs.map((d) => Sesion.fromDoc(d.id, d.data())).toList());

  Stream<List<Estudiante>> watchEstudiantes(String uid) => _estudiantes
      .where('docenteId', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs.map((d) => Estudiante.fromDoc(d.id, d.data())).toList());

  Stream<List<Matricula>> watchMatriculas(String uid) => _matriculas
      .where('docenteId', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs.map((d) => Matricula.fromDoc(d.id, d.data())).toList());

  Future<void> _escribirEnLotes(List<void Function(WriteBatch batch)> escrituras) async {
    for (var i = 0; i < escrituras.length; i += _tamanoLote) {
      final batch = _firestore.batch();
      for (final escribir in escrituras.skip(i).take(_tamanoLote)) {
        escribir(batch);
      }
      await batch.commit();
    }
  }

  // ---------------------------------------------------------------- Cursos

  /// Crea primero las sesiones y al final el curso, para que un curso nunca
  /// exista sin sus sesiones. Si algo falla, borra las sesiones ya escritas.
  /// Devuelve el id del curso nuevo.
  Future<String> crearCurso(String uid, NuevoCurso datos) async {
    final cursoRef = _cursos.doc();
    final sesionRefs = <DocumentReference<Map<String, dynamic>>>[];
    final fechas = datos.fechas;
    final escrituras = <void Function(WriteBatch)>[];
    for (var i = 0; i < fechas.length; i++) {
      final ref = _sesiones.doc();
      sesionRefs.add(ref);
      escrituras.add((batch) => batch.set(ref, {
            'docenteId': uid,
            'cursoId': cursoRef.id,
            'numero': i + 1,
            'fecha': Timestamp.fromDate(fechas[i]),
            'horaInicio': datos.horaInicio.toString(),
            'horaFin': datos.horaFin.toString(),
            'asistencias': <String, String>{},
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }));
    }
    final descripcion = datos.descripcion?.trim() ?? '';
    try {
      await _escribirEnLotes(escrituras);
      await cursoRef.set({
        'docenteId': uid,
        'codigo': datos.codigo.trim().toUpperCase(),
        'nombre': datos.nombre.trim(),
        'descripcion': descripcion.isEmpty ? null : descripcion,
        'creditos': datos.creditos,
        'totalSesiones': datos.totalSesiones,
        'diasSemana': datos.diasSemana.toSet().toList()..sort(),
        'horaInicio': datos.horaInicio.toString(),
        'horaFin': datos.horaFin.toString(),
        'fechaInicio': Timestamp.fromDate(soloFecha(datos.fechaInicio)),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return cursoRef.id;
    } on FirebaseException {
      try {
        await _escribirEnLotes([for (final ref in sesionRefs) (b) => b.delete(ref)]);
      } on FirebaseException {
        // Las sesiones huérfanas no se muestran: solo se ven las de cursos
        // que existen.
      }
      throw const AcademicoFailure('No se pudo crear el curso. Intenta nuevamente.');
    }
  }

  /// Solo cambian los datos descriptivos; el horario generó las sesiones y
  /// no se edita.
  Future<void> actualizarCurso(Curso curso) async {
    final descripcion = curso.descripcion?.trim() ?? '';
    try {
      await _cursos.doc(curso.id).update({
        'codigo': curso.codigo.trim().toUpperCase(),
        'nombre': curso.nombre.trim(),
        'descripcion': descripcion.isEmpty ? null : descripcion,
        'creditos': curso.creditos,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException {
      throw const AcademicoFailure('No se pudieron guardar los cambios del curso.');
    }
  }

  /// Borra el curso con sus sesiones, matrículas y evaluaciones. Las
  /// jornadas ya registradas se conservan en el historial.
  Future<void> eliminarCurso(
    String cursoId, {
    required Iterable<String> sesionIds,
    required Iterable<String> matriculaIds,
    required Iterable<String> evaluacionIds,
  }) async {
    try {
      await _escribirEnLotes([
        for (final id in sesionIds) (b) => b.delete(_sesiones.doc(id)),
        for (final id in matriculaIds) (b) => b.delete(_matriculas.doc(id)),
        for (final id in evaluacionIds) (b) => b.delete(_evaluaciones.doc(id)),
      ]);
      await _cursos.doc(cursoId).delete();
    } on FirebaseException {
      throw const AcademicoFailure('No se pudo eliminar el curso.');
    }
  }

  // --------------------------------------------------------------- Sesiones

  Future<void> actualizarFechaSesion(String sesionId, DateTime fecha) async {
    try {
      await _sesiones.doc(sesionId).update({
        'fecha': Timestamp.fromDate(soloFecha(fecha)),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException {
      throw const AcademicoFailure('No se pudo cambiar la fecha de la sesión.');
    }
  }

  /// Reemplaza todo el mapa de asistencia de la sesión.
  Future<void> guardarAsistencias(
    String sesionId,
    Map<String, EstadoAsistencia> asistencias,
  ) async {
    try {
      await _sesiones.doc(sesionId).update({
        'asistencias': asistencias.map((id, estado) => MapEntry(id, estado.valor)),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException {
      throw const AcademicoFailure('No se pudo guardar la asistencia.');
    }
  }

  // ------------------------------------------------------------ Estudiantes

  Map<String, dynamic> _datosEstudiante(DatosEstudiante datos) {
    final correo = datos.correo?.trim() ?? '';
    return {
      'codigo': datos.codigo.trim().toUpperCase(),
      'nombres': datos.nombres.trim(),
      'apellidos': datos.apellidos.trim(),
      'correo': correo.isEmpty ? null : correo,
    };
  }

  Future<String> crearEstudiante(String uid, DatosEstudiante datos) async {
    try {
      final ref = await _estudiantes.add({
        'docenteId': uid,
        ..._datosEstudiante(datos),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } on FirebaseException {
      throw const AcademicoFailure('No se pudo registrar al estudiante.');
    }
  }

  Future<void> actualizarEstudiante(String id, DatosEstudiante datos) async {
    try {
      await _estudiantes.doc(id).update({
        ..._datosEstudiante(datos),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException {
      throw const AcademicoFailure('No se pudieron guardar los datos del estudiante.');
    }
  }

  /// Borra al estudiante y sus matrículas.
  Future<void> eliminarEstudiante(String id, Iterable<String> matriculaIds) async {
    try {
      await _escribirEnLotes([
        for (final mid in matriculaIds) (b) => b.delete(_matriculas.doc(mid)),
      ]);
      await _estudiantes.doc(id).delete();
    } on FirebaseException {
      throw const AcademicoFailure('No se pudo eliminar al estudiante.');
    }
  }

  // ------------------------------------------------------------- Matrículas

  Future<void> crearMatricula(String uid, String cursoId, String estudianteId) async {
    try {
      await _matriculas.doc(matriculaId(cursoId, estudianteId)).set({
        'docenteId': uid,
        'cursoId': cursoId,
        'estudianteId': estudianteId,
        'estado': EstadoMatricula.activa.valor,
        'fecha': FieldValue.serverTimestamp(),
      });
    } on FirebaseException {
      throw const AcademicoFailure('No se pudo registrar la matrícula.');
    }
  }

  Future<void> cambiarEstadoMatricula(String id, EstadoMatricula estado) async {
    try {
      await _matriculas.doc(id).update({
        'estado': estado.valor,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException {
      throw const AcademicoFailure('No se pudo actualizar la matrícula.');
    }
  }
}
