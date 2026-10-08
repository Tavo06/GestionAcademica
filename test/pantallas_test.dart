import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:semana5/app/app_routes.dart';
import 'package:semana5/providers/academico_provider.dart';
import 'package:semana5/providers/tema_provider.dart';
import 'package:semana5/widgets/academicos.dart';
import 'package:semana5/widgets/encabezado.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/datos_prueba.dart';

/// Toca [finder] después de llevarlo a la vista.
Future<void> tocar(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await esperar(tester);
}

void main() {
  group('Sin desbordes en 360 dp', () {
    const rutas = [
      '/inicio',
      '/cursos',
      '/estudiantes',
      '/matriculas',
      '/calificaciones',
      '/reportes',
      '/asistencia',
      '/jornada',
      '/historial',
      '/perfil',
      '/ajustes',
      '/curso?id=pii',
      '/curso/nuevo',
      '/curso/editar?id=pii',
      '/estudiante?id=pedro',
      '/matricula?curso=bd',
      '/notas?id=ex1',
      '/reporte?curso=pii',
      '/sesion?id=pii6',
    ];
    for (final oscuro in [false, true]) {
      for (final ruta in rutas) {
        testWidgets('$ruta (${oscuro ? 'oscuro' : 'claro'})', (tester) async {
          await montarApp(tester, ruta: ruta, tamano: const Size(360, 780), oscuro: oscuro);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  testWidgets('inicio comparte cursos, estudiantes, matrículas y promedio', (tester) async {
    await montarApp(tester);
    expect(find.text('Buenas tardes, Gustavo'), findsOneWidget);
    expect(find.text('Promedio general'), findsOneWidget);
    // (9.20 + 11.00 + 18.00) / 3 = 12.73
    expect(find.text('12.73'), findsWidgets);
    // El banner usa Stack para la insignia y los círculos decorativos.
    expect(find.descendant(of: find.byType(BannerDestacado), matching: find.byType(Stack)), findsWidgets);
  });

  testWidgets('listado de cursos: filtro local y detalle recibe el objeto', (tester) async {
    await montarApp(tester, ruta: '/cursos');
    expect(find.byType(CursoCard), findsNWidgets(2));

    await tester.enterText(find.byType(TextField).first, 'base');
    await esperar(tester);
    expect(find.byType(CursoCard), findsOneWidget);
    expect(find.text('1 de 2 cursos'), findsOneWidget);

    await tocar(tester, find.byType(CursoCard));
    expect(find.text('BD-101'), findsWidgets);
    expect(find.text('Base de Datos'), findsWidgets);
    expect(find.text('4 créditos'), findsOneWidget);
  });

  testWidgets('matrícula devuelve el resultado a la pantalla anterior', (tester) async {
    final app = await montarApp(tester, ruta: '/curso?id=bd');
    await tocar(tester, find.textContaining('Matriculados ('));
    await tocar(tester, find.widgetWithText(FloatingActionButton, 'Matricular'));

    // El curso llega preseleccionado.
    expect(find.text('Nueva matrícula'), findsOneWidget);
    expect(find.text('Pedro García'), findsOneWidget);
    expect(find.text('PEDRO · ya matriculado'), findsOneWidget);
    await tocar(tester, find.widgetWithText(CheckboxListTile, 'Ana López'));
    await tocar(tester, find.text('Matricular 1 estudiante'));

    expect(find.text('Nueva matrícula'), findsNothing);
    expect(find.text('1 estudiante matriculado en Base de Datos.'), findsOneWidget);
    expect(app.academico.estaMatriculado('bd', 'ana'), isTrue);
  });

  testWidgets('registro de notas: formulario local, guarda y devuelve el resumen', (tester) async {
    final app = await montarApp(tester, ruta: '/calificaciones');
    expect(find.text('Registro auxiliar'.toUpperCase()), findsOneWidget);
    // Base de Datos aparece primero (orden alfabético); se elige PII.
    await tocar(tester, find.widgetWithText(ChoiceChip, 'PRG-201'));

    final examen = find.ancestor(of: find.text('Examen parcial'), matching: find.byType(Card));
    await tocar(tester, find.descendant(of: examen, matching: find.text('Notas')));
    expect(find.text('Examen parcial'), findsWidgets);

    final campoJuan = find.descendant(
      of: find.ancestor(of: find.text('Juan Pérez'), matching: find.byType(EstudianteTile)),
      matching: find.byType(TextFormField),
    );
    await tester.ensureVisible(campoJuan);
    await tester.enterText(campoJuan, '25');
    await esperar(tester);
    expect(find.text('La nota va de 0 a 20'), findsOneWidget);

    await tester.enterText(campoJuan, '16.5');
    await esperar(tester);
    await tocar(tester, find.text('Guardar notas'));
    expect(find.textContaining('Examen parcial: 3 notas · 1 aprobados'), findsOneWidget);
    expect(app.calificaciones.promedioDe('juan', 'pii')!.promedio, closeTo(18 * 0.4 + 16.5 * 0.6, 1e-9));
  });

  testWidgets('detalle del estudiante muestra promedio por curso', (tester) async {
    await montarApp(tester, ruta: '/estudiante?id=pedro');
    expect(find.text('Pedro García'), findsWidgets);
    expect(find.text('PRG-201 · Programación II'), findsWidgets);
    expect(find.text('BD-101 · Base de Datos'), findsWidgets);
    expect(find.text('11.00'), findsWidgets);
  });

  testWidgets('el detalle muestra el objeto recibido mientras los datos cargan', (tester) async {
    final cargando = AcademicoProvider(service: FakeAcademicoService(), reloj: () => ahoraPrueba);
    final app = await montarApp(tester, ruta: '/inicio', academico: cargando);
    final ana = estudianteDe('ana', 'Ana', 'López');
    final contexto = tester.element(find.byType(Scaffold).first);
    unawaited(GoRouter.of(contexto).pushNamed<void>(
      AppRoutes.estudianteDetalle,
      queryParameters: {'id': ana.id},
      extra: ana,
    ));
    await esperar(tester);
    expect(app.academico.cargando, isTrue);
    expect(find.text('Ana López'), findsWidgets);
  });

  testWidgets('enlaces inválidos muestran una salida clara', (tester) async {
    await montarApp(tester, ruta: '/curso?id=no-existe');
    expect(find.text('Curso no disponible'), findsOneWidget);
    await tocar(tester, find.text('Ir a Cursos'));
    expect(find.byType(CursoCard), findsNWidgets(2));
  });

  testWidgets('el cambio de tema se aplica al instante (TemaProvider)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await montarApp(tester, ruta: '/ajustes');
    final tema = Provider.of<TemaProvider>(tester.element(find.text('Oscuro')), listen: false);
    expect(tema.oscuro, isFalse);
    await tocar(tester, find.text('Oscuro'));
    expect(tema.oscuro, isTrue);
    await tocar(tester, find.text('Claro'));
    expect(tema.oscuro, isFalse);
  });
}

