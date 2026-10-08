import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:semana5/core/constants/app_strings.dart';
import 'package:semana5/core/theme/app_theme.dart';
import 'package:semana5/screens/auth/change_password/change_password_screen.dart';
import 'package:semana5/screens/auth/forgot_password/forgot_password_dialog.dart';
import 'package:semana5/screens/auth/inactive/inactive_screen.dart';
import 'package:semana5/screens/auth/login/login_screen.dart';
import 'package:semana5/screens/auth/register/register_dialog.dart';
import 'package:semana5/screens/auth/registration_complete/registration_complete_screen.dart';
import 'package:semana5/screens/auth/verify_email/verify_email_screen.dart';
import 'package:semana5/screens/auth/verify_phone/verify_phone_screen.dart';
import 'package:semana5/models/docente.dart';
import 'package:semana5/providers/auth_provider.dart';

Future<void> _pump(
  WidgetTester tester, {
  required Size tamano,
  bool oscuro = false,
  double teclado = 0,
  Widget pantalla = const LoginScreen(),
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: teclado);
  addTearDown(tester.view.reset);
  final auth = AuthProvider.paraPruebas(const Docente(nombre: '', apellidos: '', correo: ''));
  await tester.pumpWidget(
    ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: MaterialApp(
        theme: oscuro
            ? ThemeData(useMaterial3: true, brightness: Brightness.dark, extensions: const [AppTokens.dark])
            : ThemeData(useMaterial3: true, extensions: const [AppTokens.light]),
        home: pantalla,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Visible box of the open dialog (the [Dialog] widget itself fills the
/// screen; its [Material] is the card).
Finder _caja() => find.descendant(of: find.byType(Dialog), matching: find.byType(Material)).first;

/// The dialog's box fits inside the screen.
void _dentroDePantalla(WidgetTester tester, Size tamano) {
  final caja = tester.getRect(_caja());
  expect(caja.left, greaterThanOrEqualTo(0));
  expect(caja.top, greaterThanOrEqualTo(0));
  expect(caja.right, lessThanOrEqualTo(tamano.width));
  expect(caja.bottom, lessThanOrEqualTo(tamano.height));
}

void main() {
  const tamanos = {'360': Size(360, 640), '390': Size(390, 844), 'tablet': Size(820, 1180), 'desktop': Size(1440, 900)};

  for (final oscuro in [false, true]) {
    for (final entrada in tamanos.entries) {
      final modo = oscuro ? 'oscuro' : 'claro';

      testWidgets('login ${entrada.key} ($modo) sin overflow', (tester) async {
        await _pump(tester, tamano: entrada.value, oscuro: oscuro);
        expect(find.text('Iniciar sesión'), findsOneWidget);
        expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
        expect(find.text('Crear cuenta'), findsOneWidget);
        // Brand panel only on wide screens.
        expect(find.text(AppStrings.appTagline), entrada.value.width >= 960 ? findsOneWidget : findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('modal de registro ${entrada.key} ($modo)', (tester) async {
        await _pump(tester, tamano: entrada.value, oscuro: oscuro);
        await tester.ensureVisible(find.text('Crear cuenta'));
        await tester.tap(find.text('Crear cuenta'));
        await tester.pumpAndSettle();

        expect(find.byType(RegisterDialog), findsOneWidget);
        // The login stays mounted behind the dialog.
        expect(find.byType(LoginScreen), findsOneWidget);
        _dentroDePantalla(tester, entrada.value);
        expect(tester.takeException(), isNull);

        await tester.tap(find.byTooltip('Cerrar'));
        await tester.pumpAndSettle();
        expect(find.byType(RegisterDialog), findsNothing);
        expect(find.byType(LoginScreen), findsOneWidget);
      });

      testWidgets('modal de recuperación ${entrada.key} ($modo)', (tester) async {
        await _pump(tester, tamano: entrada.value, oscuro: oscuro);
        await tester.tap(find.text('¿Olvidaste tu contraseña?'));
        await tester.pumpAndSettle();

        expect(find.byType(ForgotPasswordDialog), findsOneWidget);
        _dentroDePantalla(tester, entrada.value);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(find.byType(ForgotPasswordDialog), findsNothing);
      });
    }
  }

  testWidgets('validaciones del login siguen activas', (tester) async {
    await _pump(tester, tamano: const Size(360, 640));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('El correo electrónico es obligatorio'), findsOneWidget);
    expect(find.text('La contraseña es obligatoria'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('registro valida los datos y el correo dentro del modal', (tester) async {
    await _pump(tester, tamano: const Size(360, 640));
    await tester.ensureVisible(find.text('Crear cuenta'));
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(RegisterDialog),
        matching: find.widgetWithText(TextFormField, 'Correo electrónico'),
      ),
      'no-es-un-correo',
    );
    final crear = find.descendant(of: find.byType(RegisterDialog), matching: find.byType(ElevatedButton));
    await tester.ensureVisible(crear);
    await tester.pumpAndSettle();
    await tester.tap(crear);
    await tester.pumpAndSettle();
    expect(find.text('Ingresa un correo electrónico válido'), findsOneWidget);
    expect(find.text('El nombre es obligatorio'), findsOneWidget);
    expect(find.text('Los apellidos es obligatorio'), findsOneWidget);
    expect(find.text('El DNI es obligatorio'), findsOneWidget);
    expect(find.text('El celular es obligatorio'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recuperación usa el correo escrito en el login', (tester) async {
    await _pump(tester, tamano: const Size(390, 844));
    await tester.enterText(find.byType(TextFormField).first, 'docente@colegio.pe');
    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();
    final campo = tester.widget<EditableText>(
      find.descendant(of: find.byType(ForgotPasswordDialog), matching: find.byType(EditableText)),
    );
    expect(campo.controller.text, 'docente@colegio.pe');
  });

  testWidgets('con teclado abierto en 360 dp el modal no se desborda', (tester) async {
    const tamano = Size(360, 640);
    await _pump(tester, tamano: tamano, teclado: 300);
    await tester.ensureVisible(find.text('Crear cuenta'));
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterDialog), findsOneWidget);
    expect(tester.getRect(_caja()).bottom, lessThanOrEqualTo(tamano.height - 300));
    // The action button is reachable by scrolling inside the dialog.
    final boton = find.descendant(of: find.byType(RegisterDialog), matching: find.byType(ElevatedButton));
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final oscuro in [false, true]) {
    for (final entrada in tamanos.entries) {
      final modo = oscuro ? 'oscuro' : 'claro';

      testWidgets('verificar correo ${entrada.key} ($modo) sin overflow', (tester) async {
        await _pump(tester, tamano: entrada.value, oscuro: oscuro, pantalla: const VerifyEmailScreen());
        expect(find.text('Verifica tu correo'), findsOneWidget);
        expect(find.text('Paso 2 de 4 · Verificación'), findsOneWidget);
        expect(find.text('Ya verifiqué mi correo'), findsOneWidget);
        expect(find.text('Reenviar correo'), findsOneWidget);
        expect(find.text('Cancelar y volver al inicio de sesión'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('verificar celular ${entrada.key} ($modo) sin overflow', (tester) async {
        await _pump(tester, tamano: entrada.value, oscuro: oscuro, pantalla: const VerifyPhoneScreen());
        expect(find.text('Verifica tu celular'), findsOneWidget);
        expect(find.text('Paso 3 de 4 · Celular'), findsOneWidget);
        expect(find.text('Enviar código SMS'), findsOneWidget);
        expect(find.text('Cancelar y volver al inicio de sesión'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('crear contraseña ${entrada.key} ($modo) sin overflow', (tester) async {
        await _pump(tester, tamano: entrada.value, oscuro: oscuro, pantalla: const ChangePasswordScreen());
        expect(find.text('Paso 4 de 4 · Contraseña'), findsOneWidget);
        expect(find.text('Nueva contraseña'), findsOneWidget);
        expect(find.text('Confirmar contraseña'), findsOneWidget);
        expect(find.text('Cerrar sesión'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('verificar celular valida el número antes de enviar el SMS', (tester) async {
    await _pump(tester, tamano: const Size(360, 640), pantalla: const VerifyPhoneScreen());
    await tester.enterText(find.widgetWithText(TextFormField, 'Celular (9 dígitos)'), '12345');
    final boton = find.byType(ElevatedButton);
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    await tester.tap(boton);
    await tester.pumpAndSettle();
    expect(find.text('Ingresa un celular válido de 9 dígitos (empieza con 9).'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('crear contraseña mantiene sus validaciones', (tester) async {
    await _pump(tester, tamano: const Size(360, 640), pantalla: const ChangePasswordScreen());
    final boton = find.byType(ElevatedButton);
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    await tester.tap(boton);
    await tester.pumpAndSettle();
    expect(find.text('La contraseña es obligatoria'), findsOneWidget);
    expect(find.text('Confirma tu contraseña'), findsOneWidget);

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'docente2026');
    await tester.enterText(campos.at(1), 'otra2026');
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    await tester.tap(boton);
    await tester.pumpAndSettle();
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la lista de requisitos sigue lo que se escribe', (tester) async {
    await _pump(tester, tamano: const Size(390, 844), pantalla: const ChangePasswordScreen());
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, 'abc');
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget); // letras

    await tester.enterText(find.byType(TextFormField).first, 'docente2026');
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(3));
  });

  testWidgets('crear contraseña con teclado en 360 dp no se desborda', (tester) async {
    await _pump(tester, tamano: const Size(360, 640), teclado: 300, pantalla: const ChangePasswordScreen());
    await tester.ensureVisible(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final oscuro in [false, true]) {
    for (final entrada in tamanos.entries) {
      final modo = oscuro ? 'oscuro' : 'claro';

      testWidgets('registro completo ${entrada.key} ($modo) sin overflow', (tester) async {
        await _pump(tester, tamano: entrada.value, oscuro: oscuro, pantalla: const RegistrationCompleteScreen());
        expect(find.text('¡Cuenta creada!'), findsOneWidget);
        expect(find.text('Contraseña creada'), findsOneWidget);
        expect(find.text('Ir a iniciar sesión'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('cuenta deshabilitada ${entrada.key} ($modo) sin overflow', (tester) async {
        await _pump(tester, tamano: entrada.value, oscuro: oscuro, pantalla: const InactiveScreen());
        expect(find.text('Cuenta deshabilitada'), findsOneWidget);
        expect(find.text('Tu cuenta no está habilitada para usar el sistema.'), findsOneWidget);
        expect(find.text('Cerrar sesión'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
