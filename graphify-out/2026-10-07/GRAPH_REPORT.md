# Graph Report - semana5  (2026-10-07)

## Corpus Check
- 78 files · ~42,079 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 20 file(s) not represented in the graph (top: .xml 7, (none) 5, .properties 2)

## Summary
- 1362 nodes · 2003 edges · 69 communities (63 shown, 3 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 14 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- attendance_test.dart
- win32_window.cpp
- attendance_state.dart
- attendance_service.dart
- auth_state.dart
- attendance_stats.dart
- router.dart
- ui.dart
- app_palette.dart
- workday_record.dart
- app_theme.dart
- horario.dart
- asistencia_screen.dart
- attendance_forms.dart
- clase_form_screen.dart
- workday_screen.dart
- main_shell.dart
- clase_detail_screen.dart
- workday_state.dart
- auth_widgets.dart
- AuthState
- attendance_widgets.dart
- login_screen.dart
- alumno.dart
- sesion.dart
- verify_phone_screen.dart
- account_menu.dart
- alumno_screen.dart
- app_user.dart
- login_test.dart
- app_top_bar.dart
- StatelessWidget
- profile_screen.dart
- app.dart
- forgot_password_dialog.dart
- puntualidad.dart
- navigation_test.dart
- dashboard_screen.dart
- change_password_screen.dart
- HoraDia
- clases_screen.dart
- register_dialog.dart
- firebase_options.dart
- workday_history_screen.dart
- estadisticas_screen.dart
- temporary_password.dart
- wWinMain
- clase.dart
- AttendanceState
- build
- manifest.json
- asistencia.dart
- validators.dart
- ../../core/theme/app_theme.dart
- return
- package:cloud_firestore/cloud_firestore.dart
- logic_test.dart
- Control Asistencia (semana5)
- app_strings.dart
- AttendanceFailure
- MainActivity.kt
- theme_controller.dart
- String?
- package:go_router/go_router.dart
- package:flutter/material.dart
- top_bar_test.dart

## God Nodes (most connected - your core abstractions)
1. `AuthState` - 46 edges
2. `AttendanceState` - 30 edges
3. `Win32Window` - 21 edges
4. `WorkdayState` - 12 edges
5. `MessageHandler` - 12 edges
6. `build` - 10 edges
7. `FlutterWindow` - 10 edges
8. `Create` - 10 edges
9. `WndProc` - 10 edges
10. `ThemeController` - 9 edges

## Surprising Connections (you probably didn't know these)
- `_FakeAttendanceService` --implements--> `AttendanceService`  [EXTRACTED]
  test/attendance_test.dart → lib/core/services/attendance_service.dart
- `_FakeWorkdayService` --implements--> `WorkdayService`  [EXTRACTED]
  test/attendance_test.dart → lib/core/services/workday_service.dart
- `_handleSubmit` --references--> `AuthState`  [EXTRACTED]
  lib/features/auth/presentation/change_password/change_password_screen.dart → lib/shared/models/auth_state.dart
- `build` --references--> `AuthState`  [EXTRACTED]
  lib/features/auth/presentation/change_password/change_password_screen.dart → lib/shared/models/auth_state.dart
- `_handleSubmit` --references--> `AuthState`  [EXTRACTED]
  lib/features/auth/presentation/forgot_password/forgot_password_dialog.dart → lib/shared/models/auth_state.dart

## Import Cycles
- None detected.

## Communities (69 total, 3 thin omitted)

### Community 0 - "attendance_test.dart"
Cohesion: 0.03
Nodes (71): package:semana5/core/services/attendance_service.dart, package:semana5/core/services/workday_service.dart, package:semana5/features/attendance/presentation/alumno_screen.dart, package:semana5/features/attendance/presentation/asistencia_screen.dart, package:semana5/features/attendance/presentation/estadisticas_screen.dart, package:semana5/features/attendance/presentation/sesiones_screen.dart, package:semana5/features/classes/presentation/clase_detail_screen.dart, package:semana5/features/classes/presentation/clase_form_screen.dart (+63 more)

### Community 1 - "win32_window.cpp"
Cohesion: 0.05
Nodes (58): FlutterViewController, PluginRegistry, RECT, unique_ptr, RegisterPlugins(), DartProject, HWND, LPARAM (+50 more)

### Community 2 - "attendance_state.dart"
Cohesion: 0.04
Nodes (53): attendance_stats.dart, AttendanceService get, ahora, alumnoPorId, _alumnos, _alumnosCrudos, alumnosDe, _alumnosPorId (+45 more)

### Community 3 - "attendance_service.dart"
Cohesion: 0.04
Nodes (47): CollectionReference, FirebaseFirestore, addAlumno, _alumnos, AttendanceService, _clases, createClase, deleteClase (+39 more)

### Community 4 - "auth_state.dart"
Cohesion: 0.03
Nodes (60): app_user.dart, AppUser get, ConfirmationResult?, ../../core/utils/temporary_password.dart, FirebaseAuth, Future, _auth, _authSubscription (+52 more)

### Community 5 - "attendance_stats.dart"
Cohesion: 0.05
Nodes (40): alumno.dart, double get, alumno, alumnos, alumnosEnLdi, bloqueadoPorLdi, calcularResumenClase, clase (+32 more)

### Community 6 - "router.dart"
Cohesion: 0.08
Nodes (23): ../features/attendance/presentation/alumno_screen.dart, ../features/attendance/presentation/asistencia_screen.dart, ../features/attendance/presentation/estadisticas_screen.dart, ../features/attendance/presentation/sesiones_screen.dart, ../features/auth/presentation/change_password/change_password_screen.dart, ../features/auth/presentation/inactive/inactive_screen.dart, ../features/auth/presentation/login/login_screen.dart, ../features/auth/presentation/registration_complete/registration_complete_screen.dart (+15 more)

### Community 7 - "ui.dart"
Cohesion: 0.06
Nodes (35): EdgeInsetsGeometry, accion, action, anchoMaximoContenido, bottom, build, child, children (+27 more)

### Community 8 - "app_palette.dart"
Cohesion: 0.08
Nodes (25): AppPalette, background, backgroundDark, border, borderDark, error, errorDark, info (+17 more)

### Community 9 - "workday_record.dart"
Cohesion: 0.06
Nodes (33): Duration? get, checkIn, checkOut, claseId, claseNombre, date, dia, duration (+25 more)

### Community 10 - "app_theme.dart"
Cohesion: 0.06
Nodes (31): @immutable, app_palette.dart, AppTokens get, BuildContext, ColorScheme get, AppTheme, AppThemeContext, AppTokens (+23 more)

### Community 11 - "horario.dart"
Cohesion: 0.06
Nodes (32): int get, claseNombre, compareTo, dias, diasSemanaNombres, en, fecha, fechas (+24 more)

### Community 12 - "asistencia_screen.dart"
Cohesion: 0.07
Nodes (29): alumno, AsistenciaScreen, _AsistenciaScreenState, _AvisoBloqueo, clase, createState, enabled, estadistica (+21 more)

### Community 13 - "attendance_forms.dart"
Cohesion: 0.08
Nodes (26): _apellidosController, _AsignarAlumnosDialog, _AsignarAlumnosDialogState, _busqueda, clase, _codigoController, creado, createState (+18 more)

### Community 14 - "clase_form_screen.dart"
Cohesion: 0.08
Nodes (25): ../../attendance/presentation/widgets/attendance_forms.dart, ../../core/services/attendance_service.dart, build, ClaseFormScreen, _ClaseFormScreenState, createState, _descripcionController, _dias (+17 more)

### Community 15 - "workday_screen.dart"
Cohesion: 0.08
Nodes (24): ahora, clase, _clock, createState, dispose, _formatReloj, hora, icon (+16 more)

### Community 16 - "main_shell.dart"
Cohesion: 0.06
Nodes (39): int?, ControlAsistenciaApp, _ControlAsistenciaAppState, anchoRail, _barra, build, createState, _escritorio (+31 more)

### Community 17 - "clase_detail_screen.dart"
Cohesion: 0.08
Nodes (24): ../../attendance/presentation/alumno_screen.dart, ../../attendance/presentation/asistencia_screen.dart, ../../attendance/presentation/widgets/attendance_widgets.dart, _abrirSesion, AlumnoClaseTile, _asignarAlumnos, clase, _ClaseHeader (+16 more)

### Community 18 - "workday_state.dart"
Cohesion: 0.08
Nodes (23): clase.dart, dart:async, bindTeacher, _cargando, deHoy, dispose, _error, _jornadas (+15 more)

### Community 19 - "auth_widgets.dart"
Cohesion: 0.07
Nodes (28): anchoCompacto, authCelularDecoration, AuthDialog, AuthIconBadge, authInputDecoration, AuthMessage, AuthPrimaryButton, AuthStepChip (+20 more)

### Community 20 - "AuthState"
Cohesion: 0.15
Nodes (16): build, _handleLogin, build, createState, _handleCheck, _handleResend, _isChecking, _isResending (+8 more)

### Community 21 - "attendance_widgets.dart"
Cohesion: 0.10
Nodes (21): ../../core/logic/puntualidad.dart, build, colorEn, compacta, enLdi, estado, EstadoAsistenciaUi, EstadoChip (+13 more)

### Community 22 - "login_screen.dart"
Cohesion: 0.10
Nodes (21): ../forgot_password/forgot_password_dialog.dart, _anchoPanel, compacta, createState, dispose, _emailController, _error, _formKey (+13 more)

### Community 23 - "alumno.dart"
Cohesion: 0.09
Nodes (21): Alumno, apellidos, buffer, claseIds, codigo, coincide, _conTilde, docenteId (+13 more)

### Community 24 - "sesion.dart"
Cohesion: 0.10
Nodes (20): asistencia.dart, DateTime get, asistencias, claseId, copyWith, docenteId, estadoDe, fecha (+12 more)

### Community 25 - "verify_phone_screen.dart"
Cohesion: 0.11
Nodes (19): build, _celularController, _codeFormKey, _codeSent, _codigoController, createState, _digitosNacionales, dispose (+11 more)

### Community 26 - "account_menu.dart"
Cohesion: 0.14
Nodes (16): ChangeNotifier, build, SettingsScreen, ThemeController, a, accionesPrincipales, AccountMenuButton, b (+8 more)

### Community 27 - "alumno_screen.dart"
Cohesion: 0.09
Nodes (22): asistencia_screen.dart, ../../classes/presentation/clase_detail_screen.dart, alumnoId, build, _busqueda, claseId, createState, estadistica (+14 more)

### Community 28 - "app_user.dart"
Cohesion: 0.12
Nodes (16): apellidos, AppUser, copyWith, correo, dni, estado, fechaIngreso, fechaRegistro (+8 more)

### Community 29 - "login_test.dart"
Cohesion: 0.09
Nodes (22): EditableText, package:semana5/features/auth/presentation/change_password/change_password_screen.dart, package:semana5/features/auth/presentation/forgot_password/forgot_password_dialog.dart, package:semana5/features/auth/presentation/inactive/inactive_screen.dart, package:semana5/features/auth/presentation/login/login_screen.dart, package:semana5/features/auth/presentation/register/register_dialog.dart, package:semana5/features/auth/presentation/registration_complete/registration_complete_screen.dart, package:semana5/features/auth/presentation/verify_email/verify_email_screen.dart (+14 more)

### Community 30 - "app_top_bar.dart"
Cohesion: 0.12
Nodes (16): IconData, actions, _alto, _anchoMinimoSubtitulo, AppTopBar, build, icon, leading (+8 more)

### Community 31 - "StatelessWidget"
Cohesion: 0.10
Nodes (20): _AlumnoAsistenciaCard, _AlumnoLdiCard, _Aparicion, AuthCard, AuthLogo, AuthPage, AdaptiveGrid, CargandoView (+12 more)

### Community 32 - "profile_screen.dart"
Cohesion: 0.13
Nodes (15): FormState, _apellidosController, build, createState, dispose, _dniController, _fechaIngreso, _formKey (+7 more)

### Community 33 - "app.dart"
Cohesion: 0.12
Nodes (16): ../../../core/constants/app_strings.dart, GoRouter, _attendanceState, _authState, build, createState, dispose, initState (+8 more)

### Community 34 - "forgot_password_dialog.dart"
Cohesion: 0.14
Nodes (14): ../../../core/validators/validators.dart, build, createState, dispose, _emailController, _error, ForgotPasswordDialog, _ForgotPasswordDialogState (+6 more)

### Community 35 - "puntualidad.dart"
Cohesion: 0.12
Nodes (16): apertura, aperturaEntradaMinutos, diferencia, _diferenciaMinutos, evaluarEntrada, evaluarSalida, minutos, mismoDia (+8 more)

### Community 36 - "navigation_test.dart"
Cohesion: 0.22
Nodes (8): package:semana5/app/main_shell.dart, main, _menuCompleto, _pump, pumpAndSettle, pumpWidget, _ramas, router

### Community 37 - "dashboard_screen.dart"
Cohesion: 0.12
Nodes (15): Color, clase, _ClaseHoyCard, _ClasesDeHoy, color, DashboardScreen, icon, jornada (+7 more)

### Community 38 - "change_password_screen.dart"
Cohesion: 0.10
Nodes (20): build, ChangePasswordScreen, _ChangePasswordScreenState, _confirmPasswordController, createState, cumple, dispose, _error (+12 more)

### Community 40 - "clases_screen.dart"
Cohesion: 0.17
Nodes (11): DateTime, ahora, ClaseCard, ClasesScreen, null, proximaSesion, resumen, rutaClase (+3 more)

### Community 41 - "register_dialog.dart"
Cohesion: 0.12
Nodes (17): _apellidosController, build, _celularController, createState, dispose, _dniController, _emailController, _error (+9 more)

### Community 42 - "firebase_options.dart"
Cohesion: 0.25
Nodes (7): android, DefaultFirebaseOptions, web, windows, package:firebase_core/firebase_core.dart, package:flutter/foundation.dart, static const FirebaseOptions

### Community 43 - "workday_history_screen.dart"
Cohesion: 0.18
Nodes (13): ../../core/services/workday_service.dart, DateTimeRange?, Duration, build, createState, _handleSelectRango, _JornadaHistorialCard, _rango (+5 more)

### Community 44 - "estadisticas_screen.dart"
Cohesion: 0.17
Nodes (11): alumno_screen.dart, ../../core/logic/ldi.dart, _claseId, claseInicial, createState, didUpdateWidget, filas, _masFaltasPrimero (+3 more)

### Community 45 - "temporary_password.dart"
Cohesion: 0.17
Nodes (11): dart:math, all, chars, _digits, generateTemporaryPassword, join, _lower, pick (+3 more)

### Community 46 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 47 - "clase.dart"
Cohesion: 0.11
Nodes (18): ../../core/logic/horario.dart, Clase, createdAt, descripcion, diasSemana, diasTexto, docenteId, fechaInicio (+10 more)

### Community 48 - "AttendanceState"
Cohesion: 0.18
Nodes (11): BloqueHorario, build, _handleGuardar, build, _handleGuardar, showCambiarFechaDialog, build, _retirar (+3 more)

### Community 49 - "build"
Cohesion: 0.17
Nodes (12): build, build, _eliminar, build, build, build, Route /clases, Route /estadisticas (+4 more)

### Community 50 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 51 - "asistencia.dart"
Cohesion: 0.20
Nodes (9): bool get, alumnoId, Asistencia, asistio, estado, etiqueta, fromValor, sesionId (+1 more)

### Community 52 - "validators.dart"
Cohesion: 0.18
Nodes (10): celular, confirmPassword, dni, email, newPassword, password, phone, required (+2 more)

### Community 53 - "../../core/theme/app_theme.dart"
Cohesion: 0.22
Nodes (10): ../../core/theme/app_theme.dart, ../../../core/widgets/back_or_home_button.dart, build, InactiveScreen, build, _pasos, RegistrationCompleteScreen, package:provider/provider.dart (+2 more)

### Community 54 - "return"
Cohesion: 0.29
Nodes (6): estaEnLdi, faltas, faltasPermitidas, porcentajeFaltas, umbralLdi, return

### Community 55 - "package:cloud_firestore/cloud_firestore.dart"
Cohesion: 0.29
Nodes (6): package:cloud_firestore/cloud_firestore.dart, package:semana5/core/utils/temporary_password.dart, package:semana5/core/validators/validators.dart, package:semana5/shared/models/app_user.dart, package:semana5/shared/models/workday_record.dart, main

### Community 56 - "logic_test.dart"
Cohesion: 0.25
Nodes (7): package:flutter_test/flutter_test.dart, package:semana5/core/logic/horario.dart, package:semana5/core/logic/ldi.dart, package:semana5/core/logic/puntualidad.dart, package:semana5/shared/models/attendance_stats.dart, _bloque, main

### Community 57 - "Control Asistencia (semana5)"
Cohesion: 0.29
Nodes (6): Autenticación, Configuración de Firebase Console, Control Asistencia (semana5), Firestore, Navegación, Reglas académicas

### Community 58 - "app_strings.dart"
Cohesion: 0.33
Nodes (5): appName, AppStrings, appTagline, appVersion, static const String

### Community 59 - "AttendanceFailure"
Cohesion: 0.40
Nodes (5): Exception, AttendanceFailure, WorkdayFailure, HorarioNoDisponible, AuthFailure

### Community 61 - "theme_controller.dart"
Cohesion: 0.20
Nodes (9): cambiar, cargar, _clave, _modo, oscuro, package:shared_preferences/shared_preferences.dart, static const, ThemeMode (+1 more)

### Community 67 - "package:go_router/go_router.dart"
Cohesion: 0.40
Nodes (4): BackOrHomeButton, build, package:go_router/go_router.dart, Route /home

### Community 68 - "package:flutter/material.dart"
Cohesion: 0.33
Nodes (5): app/app.dart, firebase_options.dart, initializeApp, main, package:flutter/material.dart

### Community 70 - "top_bar_test.dart"
Cohesion: 0.29
Nodes (6): AppBar, package:semana5/core/theme/app_theme.dart, package:semana5/shared/widgets/app_top_bar.dart, main, _pump, pumpWidget

## Knowledge Gaps
- **859 isolated node(s):** `_authState`, `_attendanceState`, `_workdayState`, `_themeController`, `_router` (+854 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1007 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AuthState` connect `AuthState` to `profile_screen.dart`, `app.dart`, `forgot_password_dialog.dart`, `auth_state.dart`, `dashboard_screen.dart`, `change_password_screen.dart`, `register_dialog.dart`, `build`, `../../core/theme/app_theme.dart`, `login_screen.dart`, `verify_phone_screen.dart`, `account_menu.dart`?**
  _High betweenness centrality (0.052) - this node is a cross-community bridge._
- **Why does `AttendanceState` connect `AttendanceState` to `app.dart`, `attendance_state.dart`, `dashboard_screen.dart`, `clases_screen.dart`, `asistencia_screen.dart`, `attendance_forms.dart`, `estadisticas_screen.dart`, `clase_form_screen.dart`, `main_shell.dart`, `clase_detail_screen.dart`, `build`, `workday_screen.dart`, `account_menu.dart`, `alumno_screen.dart`?**
  _High betweenness centrality (0.021) - this node is a cross-community bridge._
- **Why does `HoraDia` connect `HoraDia` to `attendance_service.dart`, `workday_record.dart`, `horario.dart`, `clase_form_screen.dart`, `clase.dart`, `sesion.dart`?**
  _High betweenness centrality (0.015) - this node is a cross-community bridge._
- **What connects `_authState`, `_attendanceState`, `_workdayState` to the rest of the system?**
  _859 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `attendance_test.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.027777777777777776 - nodes in this community are weakly interconnected._
- **Should `win32_window.cpp` be split into smaller, more focused modules?**
  _Cohesion score 0.050724637681159424 - nodes in this community are weakly interconnected._
- **Should `attendance_state.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.037037037037037035 - nodes in this community are weakly interconnected._