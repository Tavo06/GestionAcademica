import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:semana5/widgets/encabezado.dart';

import 'helpers/datos_prueba.dart';

Future<void> _montar(WidgetTester tester, double ancho, {bool oscuro = false}) async {
  tester.view.physicalSize = Size(ancho, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: temaPrueba(oscuro: oscuro),
    home: Scaffold(
      appBar: EncabezadoSeccion(
        titulo: 'Calificaciones',
        subtitulo: 'Evaluaciones, notas y promedios',
        acciones: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.nightlight_outlined)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.person)),
        ],
      ),
      body: const BannerDestacado(
        insignia: Insignia(texto: '4 créditos'),
        child: Text('Contenido'),
      ),
    ),
  ));
}

void main() {
  for (final oscuro in [false, true]) {
    for (final ancho in [320.0, 800.0, 1440.0]) {
      testWidgets('encabezado ${ancho.toInt()} px (${oscuro ? 'oscuro' : 'claro'})', (tester) async {
        await _montar(tester, ancho, oscuro: oscuro);
        expect(find.text('Calificaciones'), findsOneWidget);
        expect(find.text('Evaluaciones, notas y promedios'), ancho >= 360 ? findsOneWidget : findsNothing);
        expect(find.byIcon(Icons.person), findsOneWidget);
        expect(tester.getRect(find.byIcon(Icons.person)).right, lessThanOrEqualTo(ancho));
        // Círculos decorativos e insignia superpuestos con Stack/Positioned.
        expect(find.descendant(of: find.byType(EncabezadoSeccion), matching: find.byType(Positioned)), findsNWidgets(2));
        expect(find.text('4 créditos'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
