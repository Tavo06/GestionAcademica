import 'package:flutter_test/flutter_test.dart';
import 'package:semana5/core/logic/horario.dart';
import 'package:semana5/core/logic/ldi.dart';
import 'package:semana5/core/logic/puntualidad.dart';
import 'package:semana5/core/utils/formatters.dart';

BloqueHorario _bloque(DateTime fecha, String inicio, String fin, [String clase = 'X']) =>
    BloqueHorario(
      fecha: fecha,
      inicio: HoraDia.tryParse(inicio)!,
      fin: HoraDia.tryParse(fin)!,
      claseNombre: clase,
    );

void main() {
  group('LDI: faltas / total de sesiones del curso, desde 30%', () {
    final casos = <(int, int, double, bool)>[
      (16, 4, 25, false),
      (16, 5, 31.25, true),
      (17, 5, 29.41, false),
      (17, 6, 35.29, true),
      (19, 5, 26.32, false),
      (19, 6, 31.58, true),
    ];
    for (final (total, faltas, porcentaje, ldi) in casos) {
      test('$total sesiones + $faltas faltas = $porcentaje% → ${ldi ? 'LDI' : 'no LDI'}', () {
        expect(porcentajeFaltas(faltas, total), closeTo(porcentaje, 0.005));
        expect(estaEnLdi(faltas, total), ldi);
      });
    }

    test('0 y 1 falta no son LDI', () {
      expect(porcentajeFaltas(0, 16), 0);
      expect(estaEnLdi(0, 16), isFalse);
      expect(porcentajeFaltas(1, 16), 6.25);
      expect(estaEnLdi(1, 16), isFalse);
    });

    test('30% exacto ya es LDI (3/10, 6/20)', () {
      expect(porcentajeFaltas(3, 10), closeTo(30, 1e-9));
      expect(estaEnLdi(3, 10), isTrue);
      expect(estaEnLdi(6, 20), isTrue);
      expect(estaEnLdi(2, 10), isFalse);
    });

    test('más de 30% sigue siendo LDI', () {
      expect(estaEnLdi(8, 16), isTrue);
      expect(estaEnLdi(16, 16), isTrue);
    });

    test('sin sesiones no hay LDI ni división por cero', () {
      expect(porcentajeFaltas(3, 0), 0);
      expect(estaEnLdi(3, 0), isFalse);
    });

    test('faltas permitidas antes del LDI', () {
      expect(faltasPermitidas(16), 4);
      expect(faltasPermitidas(17), 5);
      expect(faltasPermitidas(19), 5);
      expect(faltasPermitidas(10), 2);
    });

    test('formato de porcentaje', () {
      expect(formatPorcentaje(31.25), '31.25%');
      expect(formatPorcentaje(25), '25%');
      expect(formatPorcentaje(62.5), '62.5%');
      expect(formatPorcentaje(100 * 5 / 17), '29.41%');
    });
  });

  group('Generación automática de sesiones', () {
    test('16 sesiones, un día semanal, desde la fecha inicial', () {
      final fechas = generarFechasSesiones(
        fechaInicio: DateTime(2026, 10, 5), // lunes
        diasSemana: [DateTime.monday],
        total: 16,
      );
      expect(fechas, hasLength(16));
      expect(fechas.first, DateTime(2026, 10, 5));
      expect(fechas[1], DateTime(2026, 10, 12));
      expect(fechas[2], DateTime(2026, 10, 19));
      expect(fechas.last, DateTime(2027, 1, 18));
      expect(fechas.every((f) => f.weekday == DateTime.monday), isTrue);
    });

    test('varios días en orden cronológico', () {
      final fechas = generarFechasSesiones(
        fechaInicio: DateTime(2026, 10, 5),
        diasSemana: [DateTime.wednesday, DateTime.monday],
        total: 5,
      );
      expect(fechas, [
        DateTime(2026, 10, 5),
        DateTime(2026, 10, 7),
        DateTime(2026, 10, 12),
        DateTime(2026, 10, 14),
        DateTime(2026, 10, 19),
      ]);
      for (var i = 1; i < fechas.length; i++) {
        expect(fechas[i].isAfter(fechas[i - 1]), isTrue);
      }
    });

    test('si la fecha inicial no es un día elegido, empieza el siguiente', () {
      final fechas = generarFechasSesiones(
        fechaInicio: DateTime(2026, 9, 29), // martes
        diasSemana: [DateTime.monday],
        total: 2,
      );
      expect(fechas, [DateTime(2026, 10, 5), DateTime(2026, 10, 12)]);
    });

    test('fechas reales al cruzar meses y el cambio de año', () {
      final fechas = generarFechasSesiones(
        fechaInicio: DateTime(2026, 12, 28),
        diasSemana: [DateTime.monday, DateTime.friday],
        total: 3,
      );
      expect(fechas, [DateTime(2026, 12, 28), DateTime(2027, 1, 1), DateTime(2027, 1, 4)]);
    });

    test('sin días o sin sesiones no genera nada', () {
      expect(generarFechasSesiones(fechaInicio: DateTime(2026), diasSemana: [], total: 16), isEmpty);
      expect(generarFechasSesiones(fechaInicio: DateTime(2026), diasSemana: [1], total: 0), isEmpty);
    });
  });

  group('Conflictos de horario', () {
    final lunes = DateTime(2026, 10, 5);

    test('17:00-20:00 y 18:00-21:00 se cruzan', () {
      expect(_bloque(lunes, '17:00', '20:00').seCruzaCon(_bloque(lunes, '18:00', '21:00')), isTrue);
    });

    test('17:00-20:00 y 20:00-22:00 están permitidos', () {
      expect(_bloque(lunes, '17:00', '20:00').seCruzaCon(_bloque(lunes, '20:00', '22:00')), isFalse);
    });

    test('una clase dentro de otra también se cruza', () {
      expect(_bloque(lunes, '17:00', '20:00').seCruzaCon(_bloque(lunes, '18:00', '19:00')), isTrue);
    });

    test('mismo horario en fechas distintas no se cruza', () {
      final martes = DateTime(2026, 10, 6);
      expect(_bloque(lunes, '17:00', '20:00').seCruzaCon(_bloque(martes, '17:00', '20:00')), isFalse);
    });

    test('buscarConflicto devuelve la clase existente', () {
      final existentes = [
        for (final f in generarFechasSesiones(fechaInicio: lunes, diasSemana: [1], total: 16))
          _bloque(f, '17:00', '20:00', 'Programación II'),
      ];
      final choque = [
        for (final f in generarFechasSesiones(fechaInicio: lunes, diasSemana: [1], total: 16))
          _bloque(f, '18:00', '21:00', 'Base de Datos'),
      ];
      final libre = [
        for (final f in generarFechasSesiones(fechaInicio: lunes, diasSemana: [1], total: 16))
          _bloque(f, '20:00', '22:00', 'Base de Datos'),
      ];
      final conflicto = buscarConflicto(choque, existentes);
      expect(conflicto, isNotNull);
      expect(conflicto!.existente.claseNombre, 'Programación II');
      expect(conflicto.existente.fecha, lunes);
      expect(buscarConflicto(libre, existentes), isNull);
    });
  });

  group('Semanas y bloqueo de edición', () {
    final hoy = DateTime(2026, 10, 14, 18); // miércoles

    test('la semana va de lunes a domingo', () {
      expect(inicioSemana(hoy), DateTime(2026, 10, 12));
      expect(inicioSemana(DateTime(2026, 10, 18)), DateTime(2026, 10, 12));
      expect(inicioSemana(DateTime(2026, 10, 19)), DateTime(2026, 10, 19));
    });

    test('semana anterior cerrada, actual editable, futura programada', () {
      expect(semanaDe(DateTime(2026, 10, 11), hoy), SemanaSesion.anterior);
      expect(semanaDe(DateTime(2026, 10, 12), hoy), SemanaSesion.actual);
      expect(semanaDe(DateTime(2026, 10, 18), hoy), SemanaSesion.actual);
      expect(semanaDe(DateTime(2026, 10, 19), hoy), SemanaSesion.futura);
      expect(puedeEditarFecha(DateTime(2026, 10, 5), hoy), isFalse);
      expect(puedeEditarFecha(DateTime(2026, 10, 16), hoy), isTrue);
      expect(puedeEditarFecha(DateTime(2026, 10, 26), hoy), isFalse);
    });

    test('la asistencia se registra en la semana actual hasta hoy', () {
      expect(puedeRegistrarAsistencia(DateTime(2026, 10, 12), hoy), isTrue);
      expect(puedeRegistrarAsistencia(DateTime(2026, 10, 14), hoy), isTrue);
      expect(puedeRegistrarAsistencia(DateTime(2026, 10, 16), hoy), isFalse);
      expect(puedeRegistrarAsistencia(DateTime(2026, 10, 5), hoy), isFalse);
    });
  });

  group('Puntualidad', () {
    final inicio = DateTime(2026, 10, 12, 17);
    final fin = DateTime(2026, 10, 12, 20);

    test('entrada tarde, puntual y anticipada', () {
      final tarde = evaluarEntrada(inicio, DateTime(2026, 10, 12, 17, 2));
      expect(tarde.tipo, Puntualidad.tarde);
      expect(tarde.minutos, 2);
      expect(tarde.etiqueta, 'Tarde: 2 min');
      expect(tarde.diferencia, '+2 min');

      expect(evaluarEntrada(inicio, DateTime(2026, 10, 12, 16, 58)).tipo, Puntualidad.puntual);
      expect(evaluarEntrada(inicio, inicio).tipo, Puntualidad.puntual);
      expect(evaluarEntrada(inicio, DateTime(2026, 10, 12, 16, 40)).tipo, Puntualidad.anticipada);
    });

    test('salida después del fin es puntual; antes es incidencia', () {
      final salida = evaluarSalida(fin, DateTime(2026, 10, 12, 20, 1));
      expect(salida.tipo, Puntualidad.puntual);
      expect(salida.diferencia, '+1 min');
      expect(evaluarSalida(fin, DateTime(2026, 10, 12, 19, 30)).tipo, Puntualidad.incidencia);
    });

    test('ventana para marcar entrada', () {
      expect(validarEntrada(inicio: inicio, fin: fin, ahora: DateTime(2026, 10, 12, 16, 30)), isNull);
      expect(validarEntrada(inicio: inicio, fin: fin, ahora: DateTime(2026, 10, 12, 15, 30)),
          'Podrás registrar tu entrada desde las 16:00.');
      expect(validarEntrada(inicio: inicio, fin: fin, ahora: DateTime(2026, 10, 12, 20)), isNotNull);
      expect(validarEntrada(inicio: inicio, fin: fin, ahora: DateTime(2026, 10, 13, 17)), isNotNull);
    });
  });
}
