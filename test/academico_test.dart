import 'package:flutter_test/flutter_test.dart';
import 'package:semana5/core/logic/horario.dart';
import 'package:semana5/core/logic/puntualidad.dart';
import 'package:semana5/models/curso.dart';
import 'package:semana5/models/estudiante.dart';
import 'package:semana5/models/jornada.dart';
import 'package:semana5/models/matricula.dart';
import 'package:semana5/models/sesion.dart';
import 'package:semana5/providers/academico_provider.dart';
import 'package:semana5/providers/jornada_provider.dart';
import 'package:semana5/services/academico_service.dart';
import 'package:semana5/services/jornada_service.dart';

import 'helpers/datos_prueba.dart';

NuevoCurso nuevoCurso(String codigo, String inicio, String fin, {List<int> dias = const [DateTime.monday]}) =>
    NuevoCurso(
      codigo: codigo,
      nombre: 'Redes',
      creditos: 3,
      totalSesiones: 16,
      diasSemana: dias,
      horaInicio: HoraDia.tryParse(inicio)!,
      horaFin: HoraDia.tryParse(fin)!,
      fechaInicio: DateTime(2026, 10, 19),
    );

Future<(AcademicoProvider, FakeAcademicoService)> conectado(Datos d) async {
  final fake = FakeAcademicoService.desde(d);
  final academico = AcademicoProvider(service: fake, reloj: () => ahoraPrueba)..bindTeacher('A');
  addTearDown(academico.dispose);
  await pumpEventQueue();
  return (academico, fake);
}

void main() {
  group('Asistencia por curso', () {
    test('sesiones, matriculados y faltas no se mezclan entre cursos', () {
      final academico = academicoPrueba();
      final pii = academico.resumenDe(academico.cursoPorId('pii')!);
      final bd = academico.resumenDe(academico.cursoPorId('bd')!);

      expect(pii.sesiones.every((s) => s.cursoId == 'pii'), isTrue);
      expect(pii.sesiones.map((s) => s.numero), List.generate(16, (i) => i + 1));
      expect(bd.estudiantes.map((e) => e.estudiante.id), ['pedro']);

      expect(academico.asistenciaDe('pedro', 'pii')!.faltas, 4);
      expect(academico.asistenciaDe('pedro', 'pii')!.porcentajeFaltas, 25);
      expect(academico.asistenciaDe('pedro', 'bd')!.faltas, 1);
      expect(academico.asistenciaDe('ana', 'bd'), isNull);
    });

    test('el LDI usa el total de sesiones del curso', () {
      final academico = academicoPrueba();
      final pii = academico.resumenDe(academico.cursoPorId('pii')!);
      final ana = academico.asistenciaDe('ana', 'pii')!;
      expect(ana.porcentajeFaltas, 31.25);
      expect(ana.enLdi, isTrue);
      expect(pii.realizadas, 5);
      expect(pii.pendientes, 11);
      expect(pii.enLdi, 1);
      expect(academico.totalEnLdi, 1);
    });

    test('el bloqueo por LDI empieza después de la falta que lo alcanza', () {
      final academico = academicoPrueba();
      expect(academico.bloqueado('ana', academico.sesionPorId('pii5')!), isFalse);
      expect(academico.bloqueado('ana', academico.sesionPorId('pii6')!), isTrue);
      expect(academico.bloqueado('pedro', academico.sesionPorId('pii6')!), isFalse);
    });

    test('sesiones de hoy de todos los cursos, por hora', () {
      final hoy = academicoPrueba().sesionesDeHoy;
      expect(hoy.map((e) => e.curso.nombre), ['Programación II', 'Base de Datos']);
      expect(hoy.map((e) => e.sesion.numero), [6, 6]);
    });

    test('la falta que alcanza el LDI se registra y avisa', () async {
      final (academico, fake) = await conectado(datosPrueba());
      final r = await academico.guardarAsistencia('pii6', {'ana': p, 'pedro': f, 'juan': p});
      // Ana está bloqueada: su marca se ignora.
      expect(fake.sesion('pii6').asistencias, {'pedro': f, 'juan': p});
      expect(r.nuevosLdi.map((e) => e.id), ['pedro']);
      await pumpEventQueue();
      expect(academico.bloqueado('pedro', academico.sesionPorId('pii7')!), isTrue);
      expect(academico.asistenciaDe('pedro', 'bd')!.enLdi, isFalse);
    });

    test('semanas cerradas y sesiones futuras no admiten asistencia', () {
      final academico = academicoPrueba(service: FakeAcademicoService());
      expect(() => academico.guardarAsistencia('pii5', {'juan': p}), throwsA(isA<AcademicoFailure>()));
      expect(() => academico.guardarAsistencia('pii7', {'juan': p}), throwsA(isA<AcademicoFailure>()));
    });

    test('un retirado ya no aparece en la asistencia ni puede marcarse', () async {
      final d = datosPrueba();
      final (academico, fake) = await conectado((
        cursos: d.cursos,
        estudiantes: d.estudiantes,
        sesiones: d.sesiones,
        matriculas: [
          ...d.matriculas.where((m) => m.estudianteId != 'juan'),
          matriculaDe('pii', 'juan', estado: EstadoMatricula.retirada),
        ],
        evaluaciones: d.evaluaciones,
      ));
      expect(academico.matriculadosEn('pii').map((e) => e.id), isNot(contains('juan')));
      await academico.guardarAsistencia('pii6', {'juan': p, 'pedro': p});
      expect(fake.sesion('pii6').asistencias.keys, ['pedro']);
    });
  });

  group('Cursos', () {
    test('no se crea un curso que se cruce con otro; devuelve el curso creado', () async {
      final fake = FakeAcademicoService();
      final academico = academicoPrueba(service: fake);
      await expectLater(
        academico.crearCurso(nuevoCurso('RED-1', '18:00', '21:00')),
        throwsA(isA<HorarioNoDisponible>().having((e) => e.message, 'mensaje', contains('Programación II'))),
      );
      final curso = await academico.crearCurso(nuevoCurso('red-1', '20:00', '21:00'));
      expect(curso.codigo, 'RED-1');
      expect(curso.nombre, 'Redes');
      expect(fake.sesiones.where((s) => s.cursoId == curso.id), hasLength(16));
    });

    test('valida datos y no repite el código', () async {
      final academico = academicoPrueba(service: FakeAcademicoService());
      await expectLater(
        academico.crearCurso(nuevoCurso('PRG-201', '08:00', '10:00')),
        throwsA(isA<AcademicoFailure>().having((e) => e.message, 'mensaje', contains('Programación II'))),
      );
      expect(validarNuevoCurso(nuevoCurso('X', '08:00', '10:00', dias: const [])), isNotNull);
      expect(validarNuevoCurso(nuevoCurso('X', '10:00', '08:00')), isNotNull);
      expect(validarNuevoCurso(nuevoCurso('', '08:00', '10:00')), isNotNull);
    });

    test('editar cambia los datos descriptivos', () async {
      final (academico, fake) = await conectado(datosPrueba());
      final editado = await academico.actualizarCurso(
        academico.cursoPorId('bd')!.copyWith(nombre: 'Bases de Datos I', creditos: 5),
      );
      await pumpEventQueue();
      expect(editado.nombre, 'Bases de Datos I');
      expect(fake.cursos.firstWhere((c) => c.id == 'bd').creditos, 5);
      expect(academico.cursoPorId('bd')!.nombre, 'Bases de Datos I');
    });

    test('eliminar borra sus sesiones y matrículas', () async {
      final (academico, fake) = await conectado(datosPrueba());
      await academico.eliminarCurso('bd');
      await pumpEventQueue();
      expect(fake.cursos.map((c) => c.id), ['pii']);
      expect(fake.sesiones.any((s) => s.cursoId == 'bd'), isFalse);
      expect(fake.matriculas.any((m) => m.cursoId == 'bd'), isFalse);
      expect(academico.cursosDe('pedro').map((c) => c.id), ['pii']);
    });

    test('solo se mueve la fecha dentro de la semana actual y sin cruces', () async {
      final d = datosPrueba();
      final taller = cursoDe(
        'taller',
        'TAL',
        'Taller',
        '17:30',
        '18:30',
        total: 1,
        dias: const [DateTime.tuesday],
        desde: DateTime(2026, 10, 13),
      );
      final fake = FakeAcademicoService();
      final academico = AcademicoProvider.conDatos(
        cursos: [...d.cursos, taller],
        estudiantes: d.estudiantes,
        sesiones: [...d.sesiones, ...sesionesDe(taller)],
        matriculas: d.matriculas,
        reloj: () => ahoraPrueba,
        service: fake,
      );
      final s6 = academico.sesionPorId('pii6')!;
      await expectLater(
        academico.cambiarFechaSesion(academico.sesionPorId('pii5')!, DateTime(2026, 10, 6)),
        throwsA(isA<AcademicoFailure>()),
      );
      await expectLater(academico.cambiarFechaSesion(s6, DateTime(2026, 10, 13)), throwsA(isA<HorarioNoDisponible>()));
      await academico.cambiarFechaSesion(s6, DateTime(2026, 10, 14));
      expect(fake.fechasMovidas, {'pii6': DateTime(2026, 10, 14)});
    });
  });

  group('Estudiantes y matrículas', () {
    test('el estudiante se registra sin cursos y el código no se repite', () async {
      final (academico, fake) = await conectado(datosPrueba());
      final nuevo = await academico.crearEstudiante(
        const DatosEstudiante(codigo: 'es-100', nombres: 'Lucía', apellidos: 'Díaz', correo: 'lucia@mail.com'),
      );
      await pumpEventQueue();
      expect(nuevo.codigo, 'ES-100');
      expect(academico.cursosDe(nuevo.id), isEmpty);
      await expectLater(
        academico.crearEstudiante(const DatosEstudiante(codigo: 'ES-100', nombres: 'Otra', apellidos: 'X')),
        throwsA(isA<AcademicoFailure>()),
      );
      expect(fake.estudiantes, hasLength(4));
    });

    test('matricular usa un Set: no duplica y reactiva retiradas', () async {
      final (academico, fake) = await conectado(datosPrueba());
      // Ana y Juan a BD (Pedro ya estaba y se ignora).
      final r = await academico.matricular('bd', {'ana', 'juan', 'pedro'});
      await pumpEventQueue();
      expect(r.curso.id, 'bd');
      expect(r.matriculas.map((m) => m.estudianteId).toSet(), {'ana', 'juan'});
      expect(academico.matriculadosEn('bd').map((e) => e.id).toSet(), {'ana', 'juan', 'pedro'});
      expect(fake.matriculas.where((m) => m.cursoId == 'bd'), hasLength(3));

      await expectLater(academico.matricular('bd', {'ana'}), throwsA(isA<AcademicoFailure>()));

      await academico.retirar(academico.matriculaDe('bd', 'ana')!);
      await pumpEventQueue();
      expect(academico.estaMatriculado('bd', 'ana'), isFalse);
      expect(academico.matriculaDe('bd', 'ana')!.estado, EstadoMatricula.retirada);

      await academico.matricular('bd', {'ana'});
      await pumpEventQueue();
      expect(academico.estaMatriculado('bd', 'ana'), isTrue);
      expect(fake.matriculas.where((m) => m.cursoId == 'bd'), hasLength(3));
    });

    test('eliminar un estudiante borra sus matrículas', () async {
      final (academico, fake) = await conectado(datosPrueba());
      await academico.eliminarEstudiante('pedro');
      await pumpEventQueue();
      expect(academico.estudiantePorId('pedro'), isNull);
      expect(fake.matriculas.any((m) => m.estudianteId == 'pedro'), isFalse);
      expect(academico.matriculadosEn('bd'), isEmpty);
    });

    test('sugerencia de código libre', () {
      expect(sugerirCodigoEstudiante(const []), 'ES-001');
      expect(sugerirCodigoEstudiante(datosPrueba().estudiantes), 'ES-004');
    });
  });

  group('Estado global', () {
    test('al cambiar de docente no quedan datos del anterior', () async {
      final d = datosPrueba();
      final fake = FakeAcademicoService(
        cursos: [
          ...d.cursos,
          cursoDe('otro', 'B-1', 'Curso de B', '08:00', '10:00', docenteId: 'B'),
        ],
        estudiantes: [
          ...d.estudiantes,
          estudianteDe('b1', 'Beto', 'Bravo', docenteId: 'B'),
        ],
        sesiones: d.sesiones,
        matriculas: [
          ...d.matriculas,
          matriculaDe('otro', 'b1', docenteId: 'B'),
        ],
      );
      final academico = AcademicoProvider(service: fake, reloj: () => ahoraPrueba);
      addTearDown(academico.dispose);

      academico.bindTeacher('A');
      await pumpEventQueue();
      expect(academico.cursos.map((c) => c.id), ['bd', 'pii']);
      expect(academico.cargando, isFalse);

      academico.bindTeacher(null);
      expect(academico.cursos, isEmpty);
      expect(academico.estudiantes, isEmpty);

      academico.bindTeacher('B');
      await pumpEventQueue();
      expect(academico.cursos.map((c) => c.nombre), ['Curso de B']);
      expect(academico.matriculadosEn('otro').map((e) => e.id), ['b1']);
      expect(academico.sesionPorId('pii6'), isNull);
    });
  });

  group('Jornadas', () {
    test('una entrada y una salida por sesión, con puntualidad', () async {
      var ahora = DateTime(2026, 10, 12, 17, 2);
      final academico = academicoPrueba();
      final jornadas = JornadaProvider(service: FakeJornadaService(() => ahora), reloj: () => ahora)..bindTeacher('A');
      addTearDown(jornadas.dispose);
      await pumpEventQueue();

      final pii = academico.cursoPorId('pii')!;
      final bd = academico.cursoPorId('bd')!;
      final Sesion s6 = academico.sesionPorId('pii6')!;
      await jornadas.marcarEntrada(pii, s6);
      await pumpEventQueue();
      await expectLater(jornadas.marcarEntrada(pii, s6), throwsA(isA<JornadaFailure>()));
      await expectLater(jornadas.marcarEntrada(bd, academico.sesionPorId('bd6')!), throwsA(isA<JornadaFailure>()));

      ahora = DateTime(2026, 10, 12, 20, 1);
      await jornadas.marcarSalida(jornadas.porSesion['pii6']!);
      await pumpEventQueue();

      final Jornada j = jornadas.porSesion['pii6']!;
      expect(j.cursoNombre, 'Programación II');
      expect(j.resultadoEntrada!.tipo, Puntualidad.tarde);
      expect(j.resultadoEntrada!.minutos, 2);
      expect(j.resultadoSalida!.diferencia, '+1 min');
      expect(j.duracion, const Duration(hours: 2, minutes: 59));
      expect(agruparPorDia(jornadas.deHoy()).keys, [DateTime(2026, 10, 12)]);
    });
  });
}
