import 'package:flutter_test/flutter_test.dart';
import 'package:semana5/core/logic/notas.dart';
import 'package:semana5/core/utils/formatters.dart';
import 'package:semana5/models/evaluacion.dart';
import 'package:semana5/models/resumen_notas.dart';
import 'package:semana5/providers/calificaciones_provider.dart';
import 'package:semana5/services/academico_service.dart';

import 'helpers/datos_prueba.dart';

void main() {
  group('Escala vigesimal', () {
    test('aprueba con 10.50 o más, sin redondeo', () {
      expect(estaAprobado(10.5), isTrue);
      expect(estaAprobado(10.49), isFalse);
      expect(estaAprobado(20), isTrue);
      expect(condicionDe(null), CondicionNota.sinNotas);
      expect(condicionDe(10.5), CondicionNota.aprobado);
      expect(condicionDe(7), CondicionNota.desaprobado);
    });

    test('valida el texto de una nota', () {
      for (final valida in ['', '0', '20', '14.5', '14,75', '10.50']) {
        expect(validarNota(valida), isNull, reason: valida);
      }
      for (final invalida in ['21', '-1', 'a', '14.555', '100']) {
        expect(validarNota(invalida), isNotNull, reason: invalida);
      }
      expect(parseNota('14,5'), 14.5);
      expect(parseNota(''), isNull);
    });

    test('promedio ponderado por el peso de cada evaluación', () {
      expect(promedioPonderado([(nota: 8, peso: 40), (nota: 10, peso: 60)]), closeTo(9.2, 1e-9));
      expect(promedioPonderado([(nota: 18, peso: 40)]), 18);
      expect(promedioPonderado(const []), isNull);
      expect(promedioSimple([10, 11, 12]), 11);
      expect(formatNota(9.2), '9.20');
      expect(formatNota(null), '—');
    });

    test('los pesos de un curso no pasan de 100 %', () {
      expect(validarPeso(60, 40), isNull);
      expect(validarPeso(61, 40), contains('60'));
      expect(validarPeso(10, 100), contains('100'));
      expect(validarPeso(0, 0), isNotNull);
    });
  });

  group('Promedios del curso', () {
    ResumenNotasCurso resumenPii() {
      final d = datosPrueba();
      final pii = d.cursos.firstWhere((c) => c.id == 'pii');
      return calcularResumenNotas(curso: pii, evaluaciones: d.evaluaciones, matriculados: d.estudiantes);
    }

    test('promedio, condición y avance de cada estudiante', () {
      final r = resumenPii();
      final porId = {for (final e in r.estudiantes) e.estudiante.id: e};
      expect(porId['ana']!.promedio, closeTo(9.2, 1e-9));
      expect(porId['ana']!.condicion, CondicionNota.desaprobado);
      expect(porId['pedro']!.promedio, closeTo(11, 1e-9));
      expect(porId['pedro']!.aprobado, isTrue);
      expect(porId['juan']!.promedio, 18);
      expect(porId['juan']!.parcial, isTrue);
      expect(porId['juan']!.pesoEvaluado, 40);
    });

    test('resumen del curso y ranking', () {
      final r = resumenPii();
      expect(r.pesoAsignado, 100);
      expect(r.pesoDisponible, 0);
      expect(r.aprobados, 2);
      expect(r.desaprobados, 1);
      expect(r.promedioGeneral, closeTo((9.2 + 11 + 18) / 3, 1e-9));
      expect(r.notaMasAlta, 18);
      expect(r.ranking.map((e) => e.estudiante.id), ['juan', 'pedro', 'ana']);
    });
  });

  group('CalificacionesProvider', () {
    test('comparte los promedios de los matriculados del AcademicoProvider', () {
      final academico = academicoPrueba();
      final cal = CalificacionesProvider.conDatos(academico, evaluaciones: datosPrueba().evaluaciones);
      addTearDown(cal.dispose);
      expect(cal.promedioDe('pedro', 'pii')!.promedio, closeTo(11, 1e-9));
      // Pedro en BD no tiene evaluaciones.
      expect(cal.promedioDe('pedro', 'bd')!.promedio, isNull);
      expect(cal.promediosDeEstudiante('pedro').map((p) => p.curso.id).toSet(), {'pii', 'bd'});
      expect(cal.totalDesaprobados, 1);
      expect(cal.promedioGeneral, closeTo((9.2 + 11 + 18) / 3, 1e-9));
    });

    test('crea evaluaciones respetando el peso disponible', () async {
      final academico = academicoPrueba();
      final fake = FakeCalificacionesService();
      final cal = CalificacionesProvider.conDatos(academico, service: fake);
      addTearDown(cal.dispose);
      cal.bindTeacher('A');
      await pumpEventQueue();

      final ev = await cal.crearEvaluacion(
        NuevaEvaluacion(
          cursoId: 'bd',
          nombre: 'Proyecto final',
          tipo: TipoEvaluacion.proyecto,
          peso: 70,
          fecha: DateTime(2026, 11, 30),
        ),
      );
      await pumpEventQueue();
      expect(ev.peso, 70);
      expect(cal.pesoAsignado('bd'), 70);
      await expectLater(
        cal.crearEvaluacion(
          NuevaEvaluacion(
            cursoId: 'bd',
            nombre: 'Examen',
            tipo: TipoEvaluacion.examen,
            peso: 40,
            fecha: DateTime(2026, 12, 1),
          ),
        ),
        throwsA(isA<AcademicoFailure>()),
      );
    });

    test('guarda solo notas válidas de matriculados y devuelve el resumen', () async {
      final academico = academicoPrueba();
      final fake = FakeCalificacionesService(datosPrueba().evaluaciones);
      final cal = CalificacionesProvider.conDatos(academico, evaluaciones: datosPrueba().evaluaciones, service: fake);
      addTearDown(cal.dispose);
      cal.bindTeacher('A');
      await pumpEventQueue();

      final r = await cal.guardarNotas('ex1', {'ana': 12.456, 'pedro': 9, 'juan': null, 'intruso': 20});
      await pumpEventQueue();
      expect(fake.evaluaciones.firstWhere((e) => e.id == 'ex1').notas, {'ana': 12.46, 'pedro': 9.0});
      expect(r.calificadas, 2);
      expect(r.aprobadas, 1);
      expect(r.desaprobadas, 1);
      expect(cal.promedioDe('ana', 'pii')!.aprobado, isTrue);

      await expectLater(cal.guardarNotas('ex1', {'ana': 21}), throwsA(isA<AcademicoFailure>()));
    });
  });
}
