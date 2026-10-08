import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/logic/horario.dart';
import '../core/logic/puntualidad.dart';

/// `{uid}_{sesionId}`: una jornada por docente y sesión, así un docente con
/// varios cursos en un día marca entrada y salida en cada uno.
String jornadaDocId(String uid, String sesionId) => '${uid}_$sesionId';

/// Entrada y salida del docente (`jornadas/{id}`) en una sesión de curso.
/// Las horas las pone el servidor, así que no se pueden falsear.
class Jornada {
  final String id;
  final String docenteId;
  final DateTime fecha;
  final DateTime? entrada;
  final DateTime? salida;
  final String cursoId;
  final String sesionId;
  final String cursoNombre;
  final int sesionNumero;
  final HoraDia? horaProgramadaInicio;
  final HoraDia? horaProgramadaFin;

  const Jornada({
    required this.id,
    required this.docenteId,
    required this.fecha,
    this.entrada,
    this.salida,
    required this.cursoId,
    required this.sesionId,
    required this.cursoNombre,
    this.sesionNumero = 0,
    this.horaProgramadaInicio,
    this.horaProgramadaFin,
  });

  bool get abierta => entrada != null && salida == null;

  /// Tiempo trabajado; null hasta que se marca la salida.
  Duration? get duracion => entrada != null && salida != null ? salida!.difference(entrada!) : null;

  ResultadoMarca? get resultadoEntrada => horaProgramadaInicio == null || entrada == null
      ? null
      : evaluarEntrada(horaProgramadaInicio!.en(fecha), entrada!);

  ResultadoMarca? get resultadoSalida =>
      horaProgramadaFin == null || salida == null ? null : evaluarSalida(horaProgramadaFin!.en(fecha), salida!);

  factory Jornada.fromDoc(String id, Map<String, dynamic> data) {
    DateTime? toDate(dynamic value) => value is Timestamp ? value.toDate() : null;
    return Jornada(
      id: id,
      docenteId: data['docenteId'] as String? ?? '',
      fecha: soloFecha(toDate(data['fecha']) ?? DateTime.now()),
      entrada: toDate(data['entrada']),
      salida: toDate(data['salida']),
      cursoId: data['cursoId'] as String? ?? '',
      sesionId: data['sesionId'] as String? ?? '',
      cursoNombre: data['cursoNombre'] as String? ?? 'Curso',
      sesionNumero: (data['sesionNumero'] as num?)?.toInt() ?? 0,
      horaProgramadaInicio: HoraDia.tryParse(data['horaProgramadaInicio']),
      horaProgramadaFin: HoraDia.tryParse(data['horaProgramadaFin']),
    );
  }
}

/// Día más reciente primero; dentro del día, por hora programada.
int compararJornadas(Jornada a, Jornada b) {
  final porFecha = b.fecha.compareTo(a.fecha);
  if (porFecha != 0) return porFecha;
  return _minutoInicio(a).compareTo(_minutoInicio(b));
}

int _minutoInicio(Jornada j) {
  final programada = j.horaProgramadaInicio;
  if (programada != null) return programada.minutos;
  final entrada = j.entrada;
  return entrada == null ? 0 : entrada.hour * 60 + entrada.minute;
}

/// Agrupa las jornadas por día conservando el orden de [jornadas].
Map<DateTime, List<Jornada>> agruparPorDia(Iterable<Jornada> jornadas) {
  final grupos = <DateTime, List<Jornada>>{};
  for (final jornada in jornadas) {
    grupos.putIfAbsent(jornada.fecha, () => []).add(jornada);
  }
  return grupos;
}
