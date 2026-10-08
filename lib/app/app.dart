import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../providers/academico_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/calificaciones_provider.dart';
import '../providers/jornada_provider.dart';
import '../providers/tema_provider.dart';
import 'router.dart';

/// Raíz de la app: crea los providers (ChangeNotifier) y los comparte con
/// todas las pantallas mediante [MultiProvider].
class SistemaAcademicoApp extends StatefulWidget {
  const SistemaAcademicoApp({super.key});

  @override
  State<SistemaAcademicoApp> createState() => _SistemaAcademicoAppState();
}

class _SistemaAcademicoAppState extends State<SistemaAcademicoApp> {
  late final AuthProvider _auth;
  late final AcademicoProvider _academico;
  late final CalificacionesProvider _calificaciones;
  late final JornadaProvider _jornada;
  late final TemaProvider _tema;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _auth = AuthProvider();
    _academico = AcademicoProvider();
    _calificaciones = CalificacionesProvider(_academico);
    _jornada = JornadaProvider();
    _tema = TemaProvider()..cargar();
    _auth.addListener(_sincronizarDocente);
    _router = buildRouter(_auth);
  }

  /// Los datos académicos solo se cargan para un docente activo y
  /// verificado (lo mismo que exigen las reglas de Firestore) y se borran al
  /// cerrar sesión, así otra cuenta nunca ve los datos anteriores.
  void _sincronizarDocente() {
    final uid = _auth.canUseTeacherData ? _auth.uid : null;
    _academico.bindTeacher(uid);
    _calificaciones.bindTeacher(uid);
    _jornada.bindTeacher(uid);
  }

  @override
  void dispose() {
    _auth.removeListener(_sincronizarDocente);
    _calificaciones.dispose();
    _academico.dispose();
    _jornada.dispose();
    _auth.dispose();
    _tema.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _academico),
        ChangeNotifierProvider.value(value: _calificaciones),
        ChangeNotifierProvider.value(value: _jornada),
        ChangeNotifierProvider.value(value: _tema),
      ],
      child: Consumer<TemaProvider>(
        builder: (context, tema, _) => MaterialApp.router(
          title: AppStrings.appFullName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: tema.modo,
          // Textos del framework (calendarios, diálogos) en español.
          locale: const Locale('es'),
          supportedLocales: const [Locale('es')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: _router,
        ),
      ),
    );
  }
}
