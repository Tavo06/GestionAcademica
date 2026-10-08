# Graph Report - semana5  (2026-09-29)

## Corpus Check
- 78 files · ~40,276 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 20 file(s) not represented in the graph (top: .xml 7, (none) 5, .properties 2)

## Summary
- 1331 nodes · 1949 edges · 71 communities (64 shown, 4 thin omitted)
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
- clase.dart
- ../../core/theme/app_theme.dart
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
- State
- clases_screen.dart
- register_dialog.dart
- firebase_options.dart
- workday_history_screen.dart
- estadisticas_screen.dart
- temporary_password.dart
- wWinMain
- workday_service.dart
- AttendanceState
- build
- manifest.json
- asistencia.dart
- validators.dart
- package:flutter/material.dart
- return
- package:cloud_firestore/cloud_firestore.dart
- logic_test.dart
- Control Asistencia (semana5)
- app_strings.dart
- AttendanceFailure
- MainActivity.kt
- app_colors.dart
- settings_screen.dart
- String?
- WorkdayState
- package:go_router/go_router.dart
- AttendanceService
- WorkdayService

## God Nodes (most connected - your core abstractions)
1. `AuthState` - 41 edges
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
  lib/features/auth/presentation/forgot_password/forgot_password_dialog.dart → lib/shared/models/auth_state.dart
- `build` --references--> `AuthState`  [EXTRACTED]
  lib/features/auth/presentation/inactive/inactive_screen.dart → lib/shared/models/auth_state.dart
- `_handleSubmit` --references--> `AuthState`  [EXTRACTED]
  lib/features/auth/presentation/register/register_dialog.dart → lib/shared/models/auth_state.dart

## Import Cycles
- None detected.

## Communities (71 total, 4 thin omitted)

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
Cohesion: 0.07
Nodes (27): addAlumno, _alumnos, _clases, createClase, deleteClase, descripcion, diasSemana, _escribirEnLotes (+19 more)

### Community 4 - "auth_state.dart"
Cohesion: 0.04
Nodes (46): app_user.dart, AppUser get, ../../core/utils/temporary_password.dart, FirebaseAuth, Future, _auth, _authSubscription, canUseTeacherData (+38 more)

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
Cohesion: 0.06
Nodes (34): AppPalette, background, backgroundDark, border, borderDark, error, errorDark, info (+26 more)

### Community 9 - "workday_record.dart"
Cohesion: 0.06
Nodes (33): Duration? get, checkIn, checkOut, claseId, claseNombre, date, dia, duration (+25 more)

### Community 10 - "app_theme.dart"
Cohesion: 0.06
Nodes (32): @immutable, app_palette.dart, AppTokens get, BuildContext, ColorScheme get, ../constants/app_colors.dart, AppTheme, AppThemeContext (+24 more)

### Community 11 - "horario.dart"
Cohesion: 0.06
Nodes (32): int get, claseNombre, compareTo, dias, diasSemanaNombres, en, fecha, fechas (+24 more)

### Community 12 - "asistencia_screen.dart"
Cohesion: 0.07
Nodes (27): alumno, _AlumnoAsistenciaCard, clase, createState, enabled, estadistica, estado, _etiquetaFiltro (+19 more)

### Community 13 - "attendance_forms.dart"
Cohesion: 0.08
Nodes (26): _apellidosController, _AsignarAlumnosDialog, _AsignarAlumnosDialogState, _busqueda, clase, _codigoController, creado, createState (+18 more)

### Community 14 - "clase_form_screen.dart"
Cohesion: 0.08
Nodes (25): ../../attendance/presentation/widgets/attendance_forms.dart, ../../core/services/attendance_service.dart, build, ClaseFormScreen, _ClaseFormScreenState, createState, _descripcionController, _dias (+17 more)

### Community 15 - "workday_screen.dart"
Cohesion: 0.08
Nodes (23): ../../attendance/presentation/widgets/attendance_widgets.dart, ahora, clase, _clock, createState, dispose, _formatReloj, hora (+15 more)

### Community 16 - "main_shell.dart"
Cohesion: 0.08
Nodes (23): int?, anchoRail, _barra, build, createState, _escritorio, icon, _irARama (+15 more)

### Community 17 - "clase_detail_screen.dart"
Cohesion: 0.08
Nodes (25): ../../attendance/presentation/alumno_screen.dart, ../../attendance/presentation/asistencia_screen.dart, _abrirSesion, AlumnoClaseTile, _asignarAlumnos, clase, ClaseDetailScreen, _ClaseDetailScreenState (+17 more)

### Community 18 - "workday_state.dart"
Cohesion: 0.08
Nodes (23): clase.dart, dart:async, bindTeacher, _cargando, deHoy, dispose, _error, _jornadas (+15 more)

### Community 19 - "auth_widgets.dart"
Cohesion: 0.07
Nodes (27): anchoCompacto, AuthDialog, AuthIconBadge, authInputDecoration, AuthLogo, AuthMessage, AuthPage, AuthPrimaryButton (+19 more)

### Community 20 - "AuthState"
Cohesion: 0.13
Nodes (19): build, _handleSubmit, build, _handleLogin, build, createState, _handleCheck, _handleResend (+11 more)

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

### Community 25 - "clase.dart"
Cohesion: 0.10
Nodes (20): Comparable, ../../core/logic/horario.dart, HoraDia, Clase, createdAt, descripcion, diasSemana, diasTexto (+12 more)

### Community 26 - "../../core/theme/app_theme.dart"
Cohesion: 0.18
Nodes (10): ../../core/theme/app_theme.dart, a, accionesPrincipales, AccountMenuButton, b, iniciales, inicialesDocente, ThemeToggleButton (+2 more)

### Community 27 - "alumno_screen.dart"
Cohesion: 0.14
Nodes (14): alumnoId, AlumnosScreen, _AlumnosScreenState, build, _busqueda, claseId, createState, estadistica (+6 more)

### Community 28 - "app_user.dart"
Cohesion: 0.11
Nodes (17): DateTime, apellidos, AppUser, copyWith, correo, dni, estado, fechaIngreso (+9 more)

### Community 29 - "login_test.dart"
Cohesion: 0.10
Nodes (20): EditableText, package:semana5/features/auth/presentation/change_password/change_password_screen.dart, package:semana5/features/auth/presentation/forgot_password/forgot_password_dialog.dart, package:semana5/features/auth/presentation/login/login_screen.dart, package:semana5/features/auth/presentation/register/register_dialog.dart, package:semana5/features/auth/presentation/verify_email/verify_email_screen.dart, package:semana5/shared/models/auth_state.dart, required Size tamano,
  bool (+12 more)

### Community 30 - "app_top_bar.dart"
Cohesion: 0.12
Nodes (15): IconData, actions, _alto, _anchoMinimoSubtitulo, AppTopBar, build, icon, leading (+7 more)

### Community 31 - "StatelessWidget"
Cohesion: 0.11
Nodes (18): _AlumnoLdiCard, _AvisoBloqueo, _Aparicion, AuthCard, AdaptiveGrid, CargandoView, EmptyState, GradientCard (+10 more)

### Community 32 - "profile_screen.dart"
Cohesion: 0.12
Nodes (16): _apellidosController, build, createState, dispose, _dniController, _fechaIngreso, _formKey, _handleSave (+8 more)

### Community 33 - "app.dart"
Cohesion: 0.13
Nodes (14): GoRouter, _attendanceState, _authState, build, createState, dispose, initState, _router (+6 more)

### Community 34 - "forgot_password_dialog.dart"
Cohesion: 0.14
Nodes (14): FormState, build, createState, dispose, _emailController, _error, ForgotPasswordDialog, _ForgotPasswordDialogState (+6 more)

### Community 35 - "puntualidad.dart"
Cohesion: 0.12
Nodes (16): apertura, aperturaEntradaMinutos, diferencia, _diferenciaMinutos, evaluarEntrada, evaluarSalida, minutos, mismoDia (+8 more)

### Community 36 - "navigation_test.dart"
Cohesion: 0.12
Nodes (15): AppBar, package:flutter_test/flutter_test.dart, package:semana5/app/main_shell.dart, package:semana5/core/theme/app_theme.dart, package:semana5/shared/widgets/app_top_bar.dart, main, _menuCompleto, _pump (+7 more)

### Community 37 - "dashboard_screen.dart"
Cohesion: 0.15
Nodes (12): Color, clase, _ClaseHoyCard, color, icon, jornada, label, onTap (+4 more)

### Community 38 - "change_password_screen.dart"
Cohesion: 0.11
Nodes (18): ChangePasswordScreen, _ChangePasswordScreenState, _confirmPasswordController, createState, cumple, dispose, _error, _formKey (+10 more)

### Community 39 - "State"
Cohesion: 0.23
Nodes (12): ControlAsistenciaApp, _ControlAsistenciaAppState, MainShell, _MainShellState, AlumnoScreen, _AlumnoScreenState, AsistenciaScreen, _AsistenciaScreenState (+4 more)

### Community 40 - "clases_screen.dart"
Cohesion: 0.09
Nodes (23): asistencia_screen.dart, ../../classes/presentation/clase_detail_screen.dart, build, _abrir, build, _claseId, claseInicial, createState (+15 more)

### Community 41 - "register_dialog.dart"
Cohesion: 0.15
Nodes (13): ../../../core/validators/validators.dart, build, createState, dispose, _emailController, _error, _formKey, _handleSubmit (+5 more)

### Community 42 - "firebase_options.dart"
Cohesion: 0.25
Nodes (7): android, DefaultFirebaseOptions, web, windows, package:firebase_core/firebase_core.dart, package:flutter/foundation.dart, static const FirebaseOptions

### Community 43 - "workday_history_screen.dart"
Cohesion: 0.15
Nodes (13): ../../core/services/workday_service.dart, DateTimeRange?, Duration, createState, _handleSelectRango, _JornadaHistorialCard, _rango, registro (+5 more)

### Community 44 - "estadisticas_screen.dart"
Cohesion: 0.17
Nodes (12): alumno_screen.dart, ../../core/logic/ldi.dart, _claseId, claseInicial, createState, didUpdateWidget, EstadisticasScreen, _EstadisticasScreenState (+4 more)

### Community 45 - "temporary_password.dart"
Cohesion: 0.17
Nodes (11): dart:math, all, chars, _digits, generateTemporaryPassword, join, _lower, pick (+3 more)

### Community 46 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 47 - "workday_service.dart"
Cohesion: 0.11
Nodes (17): CollectionReference, FirebaseFirestore, agruparPorDia, checkIn, checkOut, _collection, compararJornadas, entrada (+9 more)

### Community 48 - "AttendanceState"
Cohesion: 0.18
Nodes (11): BloqueHorario, build, _handleGuardar, build, _handleGuardar, showCambiarFechaDialog, build, _retirar (+3 more)

### Community 49 - "build"
Cohesion: 0.25
Nodes (8): _eliminar, build, build, Route /clases, Route /estadisticas, Route /historial, Route /jornada, Route /sesiones

### Community 50 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 51 - "asistencia.dart"
Cohesion: 0.20
Nodes (9): bool get, alumnoId, Asistencia, asistio, estado, etiqueta, fromValor, sesionId (+1 more)

### Community 52 - "validators.dart"
Cohesion: 0.22
Nodes (8): confirmPassword, dni, email, newPassword, password, phone, required, Validators

### Community 53 - "package:flutter/material.dart"
Cohesion: 0.16
Nodes (12): app/app.dart, ../../../../core/constants/app_colors.dart, firebase_options.dart, build, InactiveScreen, build, RegistrationCompleteScreen, initializeApp (+4 more)

### Community 54 - "return"
Cohesion: 0.29
Nodes (6): estaEnLdi, faltas, faltasPermitidas, porcentajeFaltas, umbralLdi, return

### Community 55 - "package:cloud_firestore/cloud_firestore.dart"
Cohesion: 0.29
Nodes (6): package:cloud_firestore/cloud_firestore.dart, package:semana5/core/utils/temporary_password.dart, package:semana5/core/validators/validators.dart, package:semana5/shared/models/app_user.dart, package:semana5/shared/models/workday_record.dart, main

### Community 56 - "logic_test.dart"
Cohesion: 0.29
Nodes (6): package:semana5/core/logic/horario.dart, package:semana5/core/logic/ldi.dart, package:semana5/core/logic/puntualidad.dart, package:semana5/shared/models/attendance_stats.dart, _bloque, main

### Community 57 - "Control Asistencia (semana5)"
Cohesion: 0.29
Nodes (6): Autenticación, Configuración de Firebase Console, Control Asistencia (semana5), Firestore, Navegación, Reglas académicas

### Community 58 - "app_strings.dart"
Cohesion: 0.33
Nodes (5): appName, AppStrings, appTagline, appVersion, static const String

### Community 59 - "AttendanceFailure"
Cohesion: 0.40
Nodes (5): Exception, AttendanceFailure, WorkdayFailure, HorarioNoDisponible, AuthFailure

### Community 61 - "app_colors.dart"
Cohesion: 0.14
Nodes (13): AppColors, background, error, primary, primaryDark, primaryLight, secondary, success (+5 more)

### Community 62 - "settings_screen.dart"
Cohesion: 0.27
Nodes (9): ../../../core/constants/app_strings.dart, ../../../core/widgets/back_or_home_button.dart, build, SettingsScreen, ThemeController, build, Route /configuracion, Route /perfil (+1 more)

### Community 67 - "WorkdayState"
Cohesion: 0.33
Nodes (6): ChangeNotifier, _ClasesDeHoy, build, WorkdayScreen, _WorkdayScreenState, WorkdayState

### Community 68 - "package:go_router/go_router.dart"
Cohesion: 0.40
Nodes (4): BackOrHomeButton, build, package:go_router/go_router.dart, Route /home

## Knowledge Gaps
- **835 isolated node(s):** `_authState`, `_attendanceState`, `_workdayState`, `_themeController`, `_router` (+830 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 980 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AuthState` connect `AuthState` to `profile_screen.dart`, `app.dart`, `forgot_password_dialog.dart`, `WorkdayState`, `auth_state.dart`, `dashboard_screen.dart`, `change_password_screen.dart`, `register_dialog.dart`, `build`, `package:flutter/material.dart`, `login_screen.dart`, `../../core/theme/app_theme.dart`, `settings_screen.dart`?**
  _High betweenness centrality (0.030) - this node is a cross-community bridge._
- **Why does `AttendanceState` connect `AttendanceState` to `app.dart`, `attendance_state.dart`, `WorkdayState`, `dashboard_screen.dart`, `State`, `clases_screen.dart`, `asistencia_screen.dart`, `estadisticas_screen.dart`, `attendance_forms.dart`, `clase_form_screen.dart`, `workday_screen.dart`, `clase_detail_screen.dart`, `build`, `alumno_screen.dart`?**
  _High betweenness centrality (0.030) - this node is a cross-community bridge._
- **Why does `Clase` connect `clase.dart` to `dashboard_screen.dart`, `attendance_stats.dart`, `asistencia_screen.dart`, `attendance_forms.dart`, `workday_screen.dart`, `clase_detail_screen.dart`?**
  _High betweenness centrality (0.015) - this node is a cross-community bridge._
- **What connects `_authState`, `_attendanceState`, `_workdayState` to the rest of the system?**
  _835 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `attendance_test.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.027777777777777776 - nodes in this community are weakly interconnected._
- **Should `win32_window.cpp` be split into smaller, more focused modules?**
  _Cohesion score 0.050724637681159424 - nodes in this community are weakly interconnected._
- **Should `attendance_state.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.037037037037037035 - nodes in this community are weakly interconnected._