import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:semana5/core/data/catalogo_carreras.dart';
import 'package:semana5/core/validators/validators.dart';
import 'package:semana5/models/curso.dart';
import 'package:semana5/widgets/calendario.dart';
import 'package:semana5/widgets/catalogo_cursos.dart';

import 'helpers/datos_prueba.dart';

void main() {
  group('Fecha de nacimiento', () {
    final hoy = DateTime(2026, 10, 8);

    test('edad exacta según si ya cumplió años', () {
      expect(edadEn(DateTime(2000, 10, 8), hoy), 26);
      expect(edadEn(DateTime(2000, 10, 9), hoy), 25);
      expect(edadEn(DateTime(2000, 1, 1), hoy), 26);
    });

    test('obligatoria y mayor de edad', () {
      expect(Validators.fechaNacimiento(null, hoy: hoy), isNotNull);
      expect(Validators.fechaNacimiento(DateTime(2010, 1, 1), hoy: hoy), contains('18'));
      expect(Validators.fechaNacimiento(DateTime(2008, 10, 8), hoy: hoy), isNull);
      expect(Validators.fechaNacimiento(DateTime(1900, 1, 1), hoy: hoy), isNotNull);
      expect(Validators.fechaNacimiento(DateTime(1985, 5, 20), hoy: hoy), isNull);
    });
  });

  group('Catálogo de carreras', () {
    test('10 carreras con 10 cursos cada una', () {
      expect(catalogoCarreras, hasLength(10));
      for (final carrera in catalogoCarreras) {
        expect(carrera.cursos, hasLength(10), reason: carrera.nombre);
      }
    });

    test('códigos únicos y datos dentro de los límites del curso', () {
      final codigos = <String>{};
      for (final carrera in catalogoCarreras) {
        expect(carrera.nombre.length, lessThanOrEqualTo(80));
        for (final curso in carrera.cursos) {
          expect(codigos.add(curso.codigo), isTrue, reason: 'código repetido ${curso.codigo}');
          expect(curso.codigo.length, lessThanOrEqualTo(12));
          expect(curso.nombre.length, lessThanOrEqualTo(80));
          expect(curso.descripcion.length, lessThanOrEqualTo(200));
          expect(curso.creditos, inInclusiveRange(minCreditos, maxCreditos));
        }
      }
      expect(codigos, hasLength(100));
    });

    test('carreraPorNombre', () {
      expect(carreraPorNombre('Derecho')?.sigla, 'DER');
      expect(carreraPorNombre('Astronomía'), isNull);
      expect(carreraPorNombre(null), isNull);
    });

    testWidgets('elegir un curso devuelve la plantilla y marca los ya creados', (tester) async {
      PlantillaCurso? elegido;
      await tester.pumpWidget(MaterialApp(
        theme: temaPrueba(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async => elegido = await showCatalogoCursos(context, codigosUsados: {'SIS-101'}),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Catálogo de cursos'), findsOneWidget);
      expect(find.byTooltip('Ya tienes este curso'), findsOneWidget);

      // Un curso ya creado no se puede elegir.
      await tester.tap(find.text('Introducción a la Programación'));
      await tester.pumpAndSettle();
      expect(elegido, isNull);

      await tester.tap(find.text('Derecho'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Introducción al Derecho'));
      await tester.pumpAndSettle();
      expect(elegido?.carrera.nombre, 'Derecho');
      expect(elegido?.curso.codigo, 'DER-101');
    });

    testWidgets('el formulario llega rellenado con la plantilla', (tester) async {
      final app = await montarApp(tester, ruta: '/cursos', tamano: const Size(1300, 900));
      final derecho = carreraPorNombre('Derecho')!;
      app.router.pushNamed('curso-nuevo', extra: (carrera: derecho, curso: derecho.cursos.first));
      await esperar(tester);
      expect(find.widgetWithText(TextFormField, 'DER-101'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Introducción al Derecho'), findsOneWidget);
      expect(find.text('Derecho'), findsWidgets);
    });
  });

  group('Agenda de jornadas', () {
    testWidgets('calendario: marca el rango y cambia de mes', (tester) async {
      DateTime? tocado;
      await tester.pumpWidget(MaterialApp(
        theme: temaPrueba(),
        home: Scaffold(
          body: CalendarioMensual(
            hoy: DateTime(2026, 10, 12),
            mesInicial: DateTime(2026, 10),
            rango: DateTimeRange(start: DateTime(2026, 10, 5), end: DateTime(2026, 10, 9)),
            marcadores: {
              DateTime(2026, 10, 7): [Colors.green, Colors.red],
            },
            onDiaTocado: (d) => tocado = d,
          ),
        ),
      ));
      expect(find.text('Octubre 2026'), findsOneWidget);
      await tester.tap(find.text('20'));
      expect(tocado, DateTime(2026, 10, 20));

      await tester.tap(find.byTooltip('Mes siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('Noviembre 2026'), findsOneWidget);
      expect(find.text('Hoy'), findsOneWidget);
      await tester.tap(find.text('Hoy'));
      await tester.pumpAndSettle();
      expect(find.text('Octubre 2026'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final ancho in [360.0, 1300.0]) {
      testWidgets('historial: agenda y lista (${ancho.toInt()} px)', (tester) async {
        await montarApp(tester, ruta: '/historial', tamano: Size(ancho, 900));
        expect(find.text('Octubre 2026'), findsOneWidget);
        expect(find.textContaining('HOY · LUNES 12 DE OCTUBRE'), findsOneWidget);
        expect(find.text('Sin registro'), findsWidgets);

        await tester.tap(find.text('Lista'));
        await esperar(tester);
        expect(find.text('Filtrar por fechas'), findsWidgets);
        await tester.tap(find.widgetWithText(ActionChip, 'Filtrar por fechas'));
        await esperar(tester);
        await tester.tap(find.text('Este mes'));
        await tester.pump();
        await tester.tap(find.text('Aplicar'));
        await esperar(tester);
        // "Este mes" depende de la fecha del dispositivo: basta con ver el filtro.
        expect(find.byType(InputChip), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
