import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/logic/horario.dart';

/// Un curso que dicta el docente (`cursos/{id}`). Sus sesiones se generan
/// al crearlo y viven en `sesiones` con este `cursoId`.
class Curso {
  final String id;
  final String docenteId;
  final String codigo;
  final String nombre;
  final String? descripcion;

  /// Carrera a la que pertenece (opcional; normalmente una del catálogo).
  final String? carrera;
  final int creditos;
  final int totalSesiones;

  /// `DateTime.monday` (1) … `DateTime.sunday` (7), ordenados.
  final List<int> diasSemana;
  final HoraDia horaInicio;
  final HoraDia horaFin;
  final DateTime fechaInicio;
  final DateTime? createdAt;

  const Curso({
    required this.id,
    required this.docenteId,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    this.carrera,
    this.creditos = 3,
    required this.totalSesiones,
    required this.diasSemana,
    required this.horaInicio,
    required this.horaFin,
    required this.fechaInicio,
    this.createdAt,
  });

  String get horario => '$horaInicio - $horaFin';

  String get diasTexto => diasSemana.map((d) => diasSemanaNombres[d]!).join(', ');

  /// "MAT-101 · Matemática I".
  String get titulo => codigo.isEmpty ? nombre : '$codigo · $nombre';

  /// [carrera] vacía quita la carrera del curso.
  Curso copyWith({String? codigo, String? nombre, String? descripcion, String? carrera, int? creditos}) => Curso(
    id: id,
    docenteId: docenteId,
    codigo: codigo ?? this.codigo,
    nombre: nombre ?? this.nombre,
    descripcion: descripcion ?? this.descripcion,
    carrera: carrera == null ? this.carrera : (carrera.isEmpty ? null : carrera),
    creditos: creditos ?? this.creditos,
    totalSesiones: totalSesiones,
    diasSemana: diasSemana,
    horaInicio: horaInicio,
    horaFin: horaFin,
    fechaInicio: fechaInicio,
    createdAt: createdAt,
  );

  factory Curso.fromDoc(String id, Map<String, dynamic> data) {
    DateTime? toDate(dynamic value) => value is Timestamp ? value.toDate() : null;
    final dias = (data['diasSemana'] as List?)?.whereType<int>().toList() ?? <int>[];
    dias.sort();
    final descripcion = (data['descripcion'] as String?)?.trim();
    final carrera = (data['carrera'] as String?)?.trim();
    return Curso(
      id: id,
      docenteId: data['docenteId'] as String? ?? '',
      codigo: data['codigo'] as String? ?? '',
      nombre: data['nombre'] as String? ?? '',
      descripcion: descripcion == null || descripcion.isEmpty ? null : descripcion,
      carrera: carrera == null || carrera.isEmpty ? null : carrera,
      creditos: (data['creditos'] as num?)?.toInt() ?? 0,
      totalSesiones: (data['totalSesiones'] as num?)?.toInt() ?? 0,
      diasSemana: dias,
      horaInicio: HoraDia.tryParse(data['horaInicio']) ?? const HoraDia(0),
      horaFin: HoraDia.tryParse(data['horaFin']) ?? const HoraDia(0),
      fechaInicio: toDate(data['fechaInicio']) ?? DateTime.now(),
      createdAt: toDate(data['createdAt']),
    );
  }
}

/// Datos del formulario para crear un curso y sus sesiones.
class NuevoCurso {
  final String codigo;
  final String nombre;
  final String? descripcion;
  final String? carrera;
  final int creditos;
  final int totalSesiones;
  final List<int> diasSemana;
  final HoraDia horaInicio;
  final HoraDia horaFin;
  final DateTime fechaInicio;

  const NuevoCurso({
    required this.codigo,
    required this.nombre,
    this.descripcion,
    this.carrera,
    required this.creditos,
    required this.totalSesiones,
    required this.diasSemana,
    required this.horaInicio,
    required this.horaFin,
    required this.fechaInicio,
  });

  List<DateTime> get fechas =>
      generarFechasSesiones(fechaInicio: fechaInicio, diasSemana: diasSemana, total: totalSesiones);
}

/// Límites compartidos por el formulario y las reglas de Firestore.
const int minSesionesCurso = 1;
const int maxSesionesCurso = 60;
const int sesionesPorDefecto = 16;
const int minCreditos = 1;
const int maxCreditos = 10;
