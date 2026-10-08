import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/logic/horario.dart';
import 'asistencia.dart';

/// Una sesión de un curso (`sesiones/{id}`), generada automáticamente con su
/// número, fecha y horario. La asistencia de los estudiantes matriculados se
/// guarda en el mismo documento como
/// `{estudianteId: 'presente' | 'tarde' | 'falta'}`.
class Sesion {
  final String id;
  final String docenteId;
  final String cursoId;
  final int numero;
  final DateTime fecha;
  final HoraDia horaInicio;
  final HoraDia horaFin;
  final Map<String, EstadoAsistencia> asistencias;

  const Sesion({
    required this.id,
    required this.docenteId,
    required this.cursoId,
    this.numero = 0,
    required this.fecha,
    this.horaInicio = const HoraDia(0),
    this.horaFin = const HoraDia(0),
    this.asistencias = const {},
  });

  DateTime get inicio => horaInicio.en(fecha);
  DateTime get fin => horaFin.en(fecha);

  String get horario => '$horaInicio - $horaFin';

  /// La asistencia de la sesión como registros [Asistencia].
  List<Asistencia> get registros => [
        for (final entrada in asistencias.entries)
          Asistencia(estudianteId: entrada.key, sesionId: id, estado: entrada.value),
      ];

  EstadoAsistencia? estadoDe(String estudianteId) => asistencias[estudianteId];

  /// Dictada: se tomó asistencia o ya pasó su hora.
  bool realizada(DateTime ahora) => asistencias.isNotEmpty || !fin.isAfter(ahora);

  Sesion copyWith({DateTime? fecha, Map<String, EstadoAsistencia>? asistencias}) => Sesion(
        id: id,
        docenteId: docenteId,
        cursoId: cursoId,
        numero: numero,
        fecha: fecha ?? this.fecha,
        horaInicio: horaInicio,
        horaFin: horaFin,
        asistencias: asistencias ?? this.asistencias,
      );

  factory Sesion.fromDoc(String id, Map<String, dynamic> data) {
    final fecha = data['fecha'];
    final asistencias = <String, EstadoAsistencia>{};
    final crudo = data['asistencias'];
    if (crudo is Map) {
      crudo.forEach((estudianteId, valor) {
        final estado = EstadoAsistencia.fromValor(valor);
        if (estudianteId is String && estado != null) asistencias[estudianteId] = estado;
      });
    }
    return Sesion(
      id: id,
      docenteId: data['docenteId'] as String? ?? '',
      cursoId: data['cursoId'] as String? ?? '',
      numero: (data['numero'] as num?)?.toInt() ?? 0,
      fecha: fecha is Timestamp ? soloFecha(fecha.toDate()) : soloFecha(DateTime.now()),
      horaInicio: HoraDia.tryParse(data['horaInicio']) ?? const HoraDia(0),
      horaFin: HoraDia.tryParse(data['horaFin']) ?? const HoraDia(0),
      asistencias: asistencias,
    );
  }
}

/// Próxima sesión que aún no termina, o null si el curso ya acabó.
Sesion? proximaSesion(Iterable<Sesion> sesiones, DateTime ahora) {
  for (final sesion in sesiones) {
    if (sesion.fin.isAfter(ahora)) return sesion;
  }
  return null;
}
