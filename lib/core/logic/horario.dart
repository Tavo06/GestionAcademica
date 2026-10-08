/// Schedule rules: class times, automatic session dates, overlaps between
/// classes and which sessions can still be edited. Pure Dart, no Firebase.
library;

/// Time of day stored as "HH:mm" in Firestore.
class HoraDia implements Comparable<HoraDia> {
  final int minutos;

  const HoraDia(this.minutos) : assert(minutos >= 0 && minutos < 24 * 60);

  HoraDia.hm(int hora, int minuto) : this(hora * 60 + minuto);

  int get hora => minutos ~/ 60;
  int get minuto => minutos % 60;

  static final _formato = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

  static HoraDia? tryParse(Object? valor) {
    if (valor is! String) return null;
    final m = _formato.firstMatch(valor);
    if (m == null) return null;
    return HoraDia.hm(int.parse(m.group(1)!), int.parse(m.group(2)!));
  }

  DateTime en(DateTime dia) => DateTime(dia.year, dia.month, dia.day, hora, minuto);

  @override
  int compareTo(HoraDia other) => minutos.compareTo(other.minutos);

  bool operator <(HoraDia other) => minutos < other.minutos;

  @override
  bool operator ==(Object other) => other is HoraDia && other.minutos == minutos;

  @override
  int get hashCode => minutos.hashCode;

  @override
  String toString() => '${hora.toString().padLeft(2, '0')}:${minuto.toString().padLeft(2, '0')}';
}

DateTime soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

/// Calendar-safe "add days" (ignores daylight-saving shifts).
DateTime sumarDias(DateTime d, int dias) => DateTime(d.year, d.month, d.day + dias);

const diasSemanaNombres = {
  DateTime.monday: 'Lunes',
  DateTime.tuesday: 'Martes',
  DateTime.wednesday: 'Miércoles',
  DateTime.thursday: 'Jueves',
  DateTime.friday: 'Viernes',
  DateTime.saturday: 'Sábado',
  DateTime.sunday: 'Domingo',
};

/// Real dates of [total] sessions: every selected weekday from [fechaInicio]
/// on (inclusive), in chronological order.
List<DateTime> generarFechasSesiones({
  required DateTime fechaInicio,
  required Iterable<int> diasSemana,
  required int total,
}) {
  final dias = diasSemana.where((d) => d >= 1 && d <= 7).toSet();
  if (dias.isEmpty || total <= 0) return const [];
  final fechas = <DateTime>[];
  var fecha = soloFecha(fechaInicio);
  while (fechas.length < total) {
    if (dias.contains(fecha.weekday)) fechas.add(fecha);
    fecha = sumarDias(fecha, 1);
  }
  return fechas;
}

/// One scheduled block of a teacher: a session of a class on a date.
class BloqueHorario {
  final DateTime fecha;
  final HoraDia inicio;
  final HoraDia fin;
  final String claseNombre;
  final String? sesionId;

  const BloqueHorario({
    required this.fecha,
    required this.inicio,
    required this.fin,
    required this.claseNombre,
    this.sesionId,
  });

  /// Same day and the times overlap. Touching blocks (one ends exactly when
  /// the other starts) do not overlap.
  bool seCruzaCon(BloqueHorario otro) =>
      soloFecha(fecha) == soloFecha(otro.fecha) && inicio < otro.fin && otro.inicio < fin;
}

/// First pair (new block, existing block) that overlaps, or null.
({BloqueHorario nuevo, BloqueHorario existente})? buscarConflicto(
  Iterable<BloqueHorario> nuevos,
  Iterable<BloqueHorario> existentes,
) {
  final porFecha = <DateTime, List<BloqueHorario>>{};
  for (final bloque in existentes) {
    porFecha.putIfAbsent(soloFecha(bloque.fecha), () => []).add(bloque);
  }
  for (final nuevo in nuevos) {
    for (final existente in porFecha[soloFecha(nuevo.fecha)] ?? const <BloqueHorario>[]) {
      if (existente.sesionId != null && existente.sesionId == nuevo.sesionId) continue;
      if (nuevo.seCruzaCon(existente)) return (nuevo: nuevo, existente: existente);
    }
  }
  return null;
}

/// Monday of the week of [dia].
DateTime inicioSemana(DateTime dia) => sumarDias(soloFecha(dia), 1 - dia.weekday);

enum SemanaSesion { anterior, actual, futura }

SemanaSesion semanaDe(DateTime fechaSesion, DateTime hoy) {
  final lunes = inicioSemana(hoy);
  final fecha = soloFecha(fechaSesion);
  if (fecha.isBefore(lunes)) return SemanaSesion.anterior;
  if (!fecha.isBefore(sumarDias(lunes, 7))) return SemanaSesion.futura;
  return SemanaSesion.actual;
}

/// Only sessions of the current week can change their date.
bool puedeEditarFecha(DateTime fechaSesion, DateTime hoy) => semanaDe(fechaSesion, hoy) == SemanaSesion.actual;

/// Attendance is taken in the current week, up to today (future sessions
/// stay pending; past weeks are closed).
bool puedeRegistrarAsistencia(DateTime fechaSesion, DateTime hoy) =>
    semanaDe(fechaSesion, hoy) == SemanaSesion.actual && !soloFecha(fechaSesion).isAfter(soloFecha(hoy));
