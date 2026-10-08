import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/texto.dart';

/// Un estudiante del docente (`estudiantes/{id}`). Se registra una vez y se
/// matricula en uno o varios cursos (ver `Matricula`).
class Estudiante {
  final String id;
  final String docenteId;
  final String codigo;
  final String nombres;
  final String apellidos;
  final String? correo;
  final DateTime? fechaRegistro;

  const Estudiante({
    required this.id,
    required this.docenteId,
    required this.codigo,
    required this.nombres,
    required this.apellidos,
    this.correo,
    this.fechaRegistro,
  });

  /// "Apellidos, Nombres": para ordenar listas.
  String get nombreCompleto => '$apellidos, $nombres';

  /// "Nombres Apellidos": para títulos.
  String get nombreVisible => '$nombres $apellidos';

  String get iniciales => inicialesDe(nombres, apellidos);

  /// Busca por nombres, apellidos, código o correo, sin importar
  /// mayúsculas ni tildes.
  bool coincide(String consulta) {
    final q = normalizarBusqueda(consulta);
    if (q.isEmpty) return true;
    return normalizarBusqueda('$nombres $apellidos $codigo ${correo ?? ''}').contains(q);
  }

  Estudiante copyWith({String? codigo, String? nombres, String? apellidos, String? correo}) => Estudiante(
    id: id,
    docenteId: docenteId,
    codigo: codigo ?? this.codigo,
    nombres: nombres ?? this.nombres,
    apellidos: apellidos ?? this.apellidos,
    correo: correo ?? this.correo,
    fechaRegistro: fechaRegistro,
  );

  factory Estudiante.fromDoc(String id, Map<String, dynamic> data) {
    final creado = data['createdAt'];
    final correo = (data['correo'] as String?)?.trim();
    return Estudiante(
      id: id,
      docenteId: data['docenteId'] as String? ?? '',
      codigo: data['codigo'] as String? ?? '',
      nombres: data['nombres'] as String? ?? '',
      apellidos: data['apellidos'] as String? ?? '',
      correo: correo == null || correo.isEmpty ? null : correo,
      fechaRegistro: creado is Timestamp ? creado.toDate() : null,
    );
  }
}

/// Datos del formulario de estudiante (crear o editar).
class DatosEstudiante {
  final String codigo;
  final String nombres;
  final String apellidos;
  final String? correo;

  const DatosEstudiante({required this.codigo, required this.nombres, required this.apellidos, this.correo});
}

/// Sugiere el siguiente código libre (`ES-001`, `ES-002`, …).
String sugerirCodigoEstudiante(Iterable<Estudiante> estudiantes) {
  final usados = estudiantes.map((e) => e.codigo).toSet();
  var numero = usados.length;
  String codigo;
  do {
    numero++;
    codigo = 'ES-${numero.toString().padLeft(3, '0')}';
  } while (usados.contains(codigo));
  return codigo;
}
