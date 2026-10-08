import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/datos_prueba.dart';

void main() {
  for (final oscuro in [false, true]) {
    testWidgets('móvil 360 dp: barra inferior + hoja "Más" (${oscuro ? 'oscuro' : 'claro'})', (tester) async {
      await montarApp(tester, tamano: const Size(360, 780), oscuro: oscuro);
      expect(find.byType(NavigationBar), findsOneWidget);
      for (final texto in ['Inicio', 'Cursos', 'Estudiantes', 'Notas', 'Más']) {
        expect(find.descendant(of: find.byType(NavigationBar), matching: find.text(texto)), findsOneWidget);
      }

      await tester.tap(find.text('Más'));
      await esperar(tester);
      for (final texto in [
        'ACADÉMICO',
        'DOCENCIA',
        'CUENTA',
        'Matrículas',
        'Reportes',
        'Asistencia',
        'Jornada',
        'Historial',
        'Mi perfil',
        'Ajustes',
      ]) {
        expect(find.text(texto), findsWidgets, reason: texto);
      }
      await tester.tap(find.text('Matrículas').last);
      await esperar(tester);
      expect(find.text('Estudiantes inscritos en cada curso'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('escritorio: menú lateral con grupos y todas las secciones', (tester) async {
    await montarApp(tester, tamano: const Size(1300, 900));
    expect(find.byType(NavigationBar), findsNothing);
    for (final texto in [
      'Inicio',
      'Cursos',
      'Estudiantes',
      'Matrículas',
      'Calificaciones',
      'Reportes',
      'Asistencia',
      'Jornada',
      'Historial',
      'Mi perfil',
      'Ajustes',
    ]) {
      expect(find.text(texto), findsWidgets, reason: texto);
    }
    await tester.tap(find.text('Calificaciones').first);
    await esperar(tester);
    expect(find.text('Evaluaciones, notas y promedios'), findsOneWidget);
    await tester.tap(find.text('Ajustes').first);
    await esperar(tester);
    expect(find.text('Apariencia y cuenta'), findsOneWidget);
  });

  testWidgets('escritorio angosto: menú de íconos sin desbordes', (tester) async {
    await montarApp(tester, tamano: const Size(960, 520));
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byTooltip('Reportes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
