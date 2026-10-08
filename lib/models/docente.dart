import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/texto.dart';

/// Estado interno de la cuenta (`status` en Firestore). Nunca se muestra ni
/// se edita en la app; las reglas solo dejan usar sus datos a docentes
/// `activo`.
enum EstadoCuenta { activo, inactivo }

/// El docente: el único rol del sistema y el usuario que inicia sesión.
/// Su perfil vive en `users/{uid}`; cada curso, estudiante, matrícula y
/// evaluación guarda su `docenteId`.
class Docente {
  final String uid;
  final String nombre;
  final String apellidos;
  final String correo;
  final String dni;
  final String? telefono;
  final EstadoCuenta estado;
  final DateTime? fechaIngreso;
  final DateTime? fechaRegistro;

  const Docente({
    this.uid = '',
    required this.nombre,
    required this.apellidos,
    required this.correo,
    this.dni = '',
    this.telefono,
    this.estado = EstadoCuenta.activo,
    this.fechaIngreso,
    this.fechaRegistro,
  });

  /// Cuentas creadas antes de que el registro pidiera estos datos.
  bool get perfilIncompleto => nombre.isEmpty || apellidos.isEmpty || dni.isEmpty;

  String get nombreCompleto {
    final completo = '$nombre $apellidos'.trim();
    return completo.isEmpty ? correo : completo;
  }

  /// Nombre para saludos.
  String get nombreVisible => nombre.isEmpty ? 'Docente' : nombre;

  /// Iniciales del nombre, o la primera letra del correo si aún no tiene.
  String get iniciales => inicialesDe(
        nombre,
        apellidos,
        respaldo: correo.isEmpty ? '?' : correo[0].toUpperCase(),
      );

  Docente copyWith({
    String? nombre,
    String? apellidos,
    String? correo,
    String? dni,
    String? telefono,
    DateTime? fechaIngreso,
  }) =>
      Docente(
        uid: uid,
        nombre: nombre ?? this.nombre,
        apellidos: apellidos ?? this.apellidos,
        correo: correo ?? this.correo,
        dni: dni ?? this.dni,
        telefono: telefono ?? this.telefono,
        estado: estado,
        fechaIngreso: fechaIngreso ?? this.fechaIngreso,
        fechaRegistro: fechaRegistro,
      );

  static EstadoCuenta estadoDesde(String? valor) =>
      valor == 'inactivo' ? EstadoCuenta.inactivo : EstadoCuenta.activo;

  /// Lee un documento `users/{uid}`.
  factory Docente.fromFirestore(String uid, Map<String, dynamic> data) {
    DateTime? toDate(dynamic value) => value is Timestamp ? value.toDate() : null;
    return Docente(
      uid: uid,
      nombre: data['firstName'] as String? ?? '',
      apellidos: data['lastName'] as String? ?? '',
      correo: data['email'] as String? ?? '',
      dni: data['dni'] as String? ?? '',
      telefono: data['phone'] as String?,
      estado: estadoDesde(data['status'] as String?),
      fechaIngreso: toDate(data['hireDate']),
      fechaRegistro: toDate(data['createdAt']),
    );
  }
}
