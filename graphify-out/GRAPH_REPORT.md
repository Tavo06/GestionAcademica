# Graph Report - semana5  (2026-10-07)

## Corpus Check
- 97 files · ~51,402 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 20 file(s) not represented in the graph (top: .xml 7, (none) 5, .properties 2)

## Summary
- 1698 nodes · 2615 edges · 80 communities (70 shown, 7 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 14 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- academico_provider.dart
- win32_window.cpp
- datos_prueba.dart
- inicio_screen.dart
- auth_provider.dart
- resumen_notas.dart
- router.dart
- comunes.dart
- app_palette.dart
- jornada.dart
- app_theme.dart
- horario.dart
- app_routes.dart
- matricula_screen.dart
- calificaciones_provider.dart
- jornada_screen.dart
- main_shell.dart
- academicos.dart
- resumen_asistencia.dart
- auth_widgets.dart
- curso_form_screen.dart
- toma_asistencia_screen.dart
- login_screen.dart
- academico_service.dart
- sesion.dart
- estudiante_detalle_screen.dart
- AcademicoProvider
- curso_detalle_screen.dart
- registro_notas_screen.dart
- login_test.dart
- encabezado.dart
- StatelessWidget
- forgot_password_dialog.dart
- app.dart
- curso.dart
- puntualidad.dart
- pantallas_test.dart
- ajustes_screen.dart
- notas.dart
- HoraDia
- matricula.dart
- perfil_screen.dart
- firebase_options.dart
- jornada_provider.dart
- verify_phone_screen.dart
- temporary_password.dart
- wWinMain
- ../core/logic/horario.dart
- evaluacion.dart
- change_password_screen.dart
- manifest.json
- bool get
- validators.dart
- AuthProvider
- return
- docente.dart
- package:cloud_firestore/cloud_firestore.dart
- Sistema de Gestión Académica Multiplataforma
- app_strings.dart
- academico_test.dart
- MainActivity.kt
- estudiante.dart
- calificaciones_screen.dart
- String?
- evaluacion_form_dialog.dart
- package:flutter/material.dart
- formatters.dart
- register_dialog.dart
- estudiante_form_dialog.dart
- texto.dart
- ../../widgets/encabezado.dart
- reporte_screen.dart
- ../core/logic/notas.dart
- CondicionNota
- ResultadoMarca
- EstadoAsistencia
- AcademicoService

## God Nodes (most connected - your core abstractions)
1. `AuthProvider` - 52 edges
2. `AcademicoProvider` - 48 edges
3. `CalificacionesProvider` - 23 edges
4. `Win32Window` - 21 edges
5. `Curso` - 15 edges
6. `TemaProvider` - 14 edges
7. `JornadaProvider` - 12 edges
8. `MessageHandler` - 12 edges
9. `build` - 10 edges
10. `FlutterWindow` - 10 edges

## Surprising Connections (you probably didn't know these)
- `main` --references--> `TemaProvider`  [EXTRACTED]
  test/pantallas_test.dart → lib/providers/tema_provider.dart
- `build` --references--> `AcademicoProvider`  [EXTRACTED]
  lib/screens/asistencia/toma_asistencia_screen.dart → lib/providers/academico_provider.dart
- `_guardar` --references--> `AcademicoProvider`  [EXTRACTED]
  lib/screens/asistencia/toma_asistencia_screen.dart → lib/providers/academico_provider.dart
- `_retirar` --references--> `AcademicoProvider`  [EXTRACTED]
  lib/screens/cursos/curso_detalle_screen.dart → lib/providers/academico_provider.dart
- `_guardar` --references--> `AcademicoProvider`  [EXTRACTED]
  lib/screens/cursos/curso_form_screen.dart → lib/providers/academico_provider.dart

## Import Cycles
- None detected.

## Communities (80 total, 7 thin omitted)

### Community 0 - "academico_provider.dart"
Cohesion: 0.03
Nodes (67): AcademicoService get, _activosPorCurso, actualizarCurso, actualizarEstudiante, ahora, asistenciaDe, bindTeacher, bloqueado (+59 more)

### Community 1 - "win32_window.cpp"
Cohesion: 0.05
Nodes (58): FlutterViewController, PluginRegistry, RECT, unique_ptr, RegisterPlugins(), DartProject, HWND, LPARAM (+50 more)

### Community 2 - "datos_prueba.dart"
Cohesion: 0.03
Nodes (65): package:semana5/app/router.dart, package:semana5/models/asistencia.dart, package:semana5/services/calificaciones_service.dart, aca, academicoPrueba, actualizarCurso, actualizarEstudiante, actualizarFechaSesion (+57 more)

### Community 3 - "inicio_screen.dart"
Cohesion: 0.07
Nodes (27): CollectionReference, double?, Curso, asistencia, build, curso, InicioScreen, matriculados (+19 more)

### Community 4 - "auth_provider.dart"
Cohesion: 0.03
Nodes (59): ConfirmationResult?, ../core/utils/temporary_password.dart, Docente get, FirebaseAuth, Future, _auth, _authSubscription, canUseTeacherData (+51 more)

### Community 5 - "resumen_notas.dart"
Cohesion: 0.06
Nodes (30): CondicionNota get, curso.dart, double? get, estudiante.dart, evaluacion.dart, Iterable, aprobado, aprobados (+22 more)

### Community 6 - "router.dart"
Cohesion: 0.06
Nodes (33): PreseleccionMatricula, buildRouter, inicial, _ruta, _rutasPublicas, _rutasRegistro, sinRedireccion, main_shell.dart (+25 more)

### Community 7 - "comunes.dart"
Cohesion: 0.06
Nodes (35): accion, action, anchoMaximoContenido, bottom, build, children, color, confirmado (+27 more)

### Community 8 - "app_palette.dart"
Cohesion: 0.05
Nodes (38): accent, accentDark, AppPalette, background, backgroundDark, border, borderDark, error (+30 more)

### Community 9 - "jornada.dart"
Cohesion: 0.07
Nodes (27): ../core/logic/puntualidad.dart, Duration? get, abierta, agruparPorDia, compararJornadas, cursoId, cursoNombre, docenteId (+19 more)

### Community 10 - "app_theme.dart"
Cohesion: 0.06
Nodes (35): @immutable, app_palette.dart, AppTokens get, BuildContext, Color, ColorScheme get, NavegacionAcademica, accent (+27 more)

### Community 11 - "horario.dart"
Cohesion: 0.06
Nodes (33): int get, BloqueHorario, claseNombre, compareTo, dias, diasSemanaNombres, en, fecha (+25 more)

### Community 12 - "app_routes.dart"
Cohesion: 0.05
Nodes (40): abrirCurso, abrirEstudiante, abrirMatricula, abrirRegistroNotas, abrirReporte, abrirTomaAsistencia, ajustes, AppPaths (+32 more)

### Community 13 - "matricula_screen.dart"
Cohesion: 0.17
Nodes (12): build, _busqueda, _confirmar, createState, cursoId, _error, estudianteId, _guardando (+4 more)

### Community 14 - "calificaciones_provider.dart"
Cohesion: 0.06
Nodes (35): academico_provider.dart, CalificacionesService get, _academico, aprobadas, bindTeacher, calificadas, _cargando, crearEvaluacion (+27 more)

### Community 15 - "jornada_screen.dart"
Cohesion: 0.08
Nodes (30): DateTimeRange?, Duration, JornadaProvider, _ClaseHoy, build, createState, _elegirRango, HistorialScreen (+22 more)

### Community 16 - "main_shell.dart"
Cohesion: 0.07
Nodes (29): app_routes.dart, int?, _academico, activa, activo, actual, anchoMenuExtendido, anchoMenuLateral (+21 more)

### Community 17 - "academicos.dart"
Cohesion: 0.06
Nodes (30): IconData get, ahora, ancho, build, color, colorEn, condicion, CondicionChip (+22 more)

### Community 18 - "resumen_asistencia.dart"
Cohesion: 0.06
Nodes (30): AsistenciaEstudiante, bloqueadoPorLdi, calcularResumenCurso, contar, curso, enLdi, estadosPorEstudiante, estaEnLdi (+22 more)

### Community 19 - "auth_widgets.dart"
Cohesion: 0.06
Nodes (32): anchoCompacto, _Aparicion, AuthCard, authCelularDecoration, AuthDialog, AuthIconBadge, authInputDecoration, AuthLogo (+24 more)

### Community 20 - "curso_form_screen.dart"
Cohesion: 0.07
Nodes (28): build, _codigoController, createState, _creditos, curso, cursoId, _descripcionController, _dias (+20 more)

### Community 21 - "toma_asistencia_screen.dart"
Cohesion: 0.07
Nodes (27): _AvisoBloqueo, build, _Cabecera, createState, curso, enabled, estado, estudiante (+19 more)

### Community 22 - "login_screen.dart"
Cohesion: 0.09
Nodes (23): ../forgot_password/forgot_password_dialog.dart, _anchoPanel, build, compacta, createState, dispose, _emailController, _error (+15 more)

### Community 23 - "academico_service.dart"
Cohesion: 0.07
Nodes (26): actualizarCurso, actualizarEstudiante, actualizarFechaSesion, cambiarEstadoMatricula, crearCurso, crearEstudiante, crearMatricula, _cursos (+18 more)

### Community 24 - "sesion.dart"
Cohesion: 0.09
Nodes (21): asistencia.dart, DateTime get, asistencias, copyWith, cursoId, docenteId, estadoDe, fecha (+13 more)

### Community 25 - "estudiante_detalle_screen.dart"
Cohesion: 0.10
Nodes (23): ../app/app_routes.dart, ../core/utils/formatters.dart, build, _busqueda, createState, CursosScreen, _CursosScreenState, _Estado (+15 more)

### Community 26 - "AcademicoProvider"
Cohesion: 0.10
Nodes (37): ChangeNotifier, AcademicoProvider, CalificacionesProvider, TomaAsistenciaScreen, _TomaAsistenciaScreenState, CalificacionesScreen, _CalificacionesScreenState, _EvaluacionFormDialog (+29 more)

### Community 27 - "curso_detalle_screen.dart"
Cohesion: 0.08
Nodes (24): ../calificaciones/evaluacion_form_dialog.dart, comunes.dart, ResumenCurso, ResumenNotasCurso, _abrirSesion, _Cabecera, createState, curso (+16 more)

### Community 28 - "registro_notas_screen.dart"
Cohesion: 0.08
Nodes (24): estudiante_form_dialog.dart, _Filtro, _campo, _campos, createState, dispose, evaluacion, evaluacionId (+16 more)

### Community 29 - "login_test.dart"
Cohesion: 0.08
Nodes (25): EditableText, package:semana5/core/constants/app_strings.dart, package:semana5/core/theme/app_theme.dart, package:semana5/providers/auth_provider.dart, package:semana5/screens/auth/change_password/change_password_screen.dart, package:semana5/screens/auth/forgot_password/forgot_password_dialog.dart, package:semana5/screens/auth/inactive/inactive_screen.dart, package:semana5/screens/auth/login/login_screen.dart (+17 more)

### Community 30 - "encabezado.dart"
Cohesion: 0.08
Nodes (24): acciones, accionesSeccion, _alto, BannerDestacado, child, _Circulo, color, CuentaMenuButton (+16 more)

### Community 31 - "StatelessWidget"
Cohesion: 0.10
Nodes (21): CursoCard, EstadoChip, EstudianteTile, MarcaTile, ResumenLine, SesionEstadoChip, SesionTile, AdaptiveGrid (+13 more)

### Community 32 - "forgot_password_dialog.dart"
Cohesion: 0.13
Nodes (15): ../../core/validators/validators.dart, FormState, build, createState, dispose, _emailController, _error, ForgotPasswordDialog (+7 more)

### Community 33 - "app.dart"
Cohesion: 0.12
Nodes (17): ../../../core/constants/app_strings.dart, GoRouter, _academico, _auth, build, _calificaciones, createState, dispose (+9 more)

### Community 34 - "curso.dart"
Cohesion: 0.08
Nodes (24): codigo, copyWith, createdAt, creditos, descripcion, diasSemana, diasTexto, docenteId (+16 more)

### Community 35 - "puntualidad.dart"
Cohesion: 0.13
Nodes (14): apertura, aperturaEntradaMinutos, diferencia, _diferenciaMinutos, evaluarEntrada, evaluarSalida, minutos, mismoDia (+6 more)

### Community 36 - "pantallas_test.dart"
Cohesion: 0.10
Nodes (19): dart:async, helpers/datos_prueba.dart, package:flutter_test/flutter_test.dart, package:go_router/go_router.dart, package:semana5/app/app_routes.dart, package:semana5/providers/academico_provider.dart, package:semana5/providers/tema_provider.dart, package:semana5/widgets/academicos.dart (+11 more)

### Community 37 - "ajustes_screen.dart"
Cohesion: 0.10
Nodes (21): ../../core/logic/ldi.dart, IconData?, build, _MenuLateral, TemaProvider, activa, AjustesScreen, build (+13 more)

### Community 38 - "notas.dart"
Cohesion: 0.09
Nodes (22): cantidad, condicionDe, disponible, esNotaValida, estaAprobado, etiqueta, limpio, nota (+14 more)

### Community 40 - "matricula.dart"
Cohesion: 0.12
Nodes (16): DateTime, activa, copyWith, cursoId, docenteId, estado, EstadoMatricula, estudianteId (+8 more)

### Community 41 - "perfil_screen.dart"
Cohesion: 0.13
Nodes (15): _apellidosController, build, createState, dispose, _dniController, _docente, _elegirFecha, _fechaIngreso (+7 more)

### Community 42 - "firebase_options.dart"
Cohesion: 0.25
Nodes (7): android, DefaultFirebaseOptions, web, windows, package:firebase_core/firebase_core.dart, package:flutter/foundation.dart, static const FirebaseOptions

### Community 43 - "jornada_provider.dart"
Cohesion: 0.09
Nodes (21): JornadaService get, bindTeacher, _cargando, deHoy, dispose, _error, _jornadas, _lazyService (+13 more)

### Community 44 - "verify_phone_screen.dart"
Cohesion: 0.10
Nodes (21): build, _celularController, _codeFormKey, _codeSent, _codigoController, createState, _digitosNacionales, dispose (+13 more)

### Community 45 - "temporary_password.dart"
Cohesion: 0.17
Nodes (11): dart:math, all, chars, _digits, generateTemporaryPassword, join, _lower, pick (+3 more)

### Community 46 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 47 - "../core/logic/horario.dart"
Cohesion: 0.15
Nodes (12): academico_service.dart, ../core/logic/horario.dart, FirebaseFirestore, CalificacionesService, crearEvaluacion, eliminarEvaluacion, _evaluaciones, _firestore (+4 more)

### Community 48 - "evaluacion.dart"
Cohesion: 0.10
Nodes (20): calificacion.dart, calificaciones, copyWith, cursoId, docenteId, etiqueta, Evaluacion, fecha (+12 more)

### Community 49 - "change_password_screen.dart"
Cohesion: 0.10
Nodes (20): build, ChangePasswordScreen, _ChangePasswordScreenState, _confirmPasswordController, createState, cumple, dispose, _error (+12 more)

### Community 50 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 51 - "bool get"
Cohesion: 0.20
Nodes (9): bool get, Asistencia, asistio, estado, estudianteId, etiqueta, fromValor, sesionId (+1 more)

### Community 52 - "validators.dart"
Cohesion: 0.18
Nodes (10): celular, confirmPassword, dni, email, newPassword, password, phone, required (+2 more)

### Community 53 - "AuthProvider"
Cohesion: 0.15
Nodes (20): ../core/theme/app_theme.dart, AuthProvider, build, InactiveScreen, build, _pasos, RegistrationCompleteScreen, build (+12 more)

### Community 54 - "return"
Cohesion: 0.29
Nodes (6): estaEnLdi, faltas, faltasPermitidas, porcentajeFaltas, umbralLdi, return

### Community 55 - "docente.dart"
Cohesion: 0.11
Nodes (18): ../../core/utils/texto.dart, apellidos, copyWith, correo, dni, Docente, estado, EstadoCuenta (+10 more)

### Community 56 - "package:cloud_firestore/cloud_firestore.dart"
Cohesion: 0.14
Nodes (12): package:cloud_firestore/cloud_firestore.dart, package:semana5/core/logic/horario.dart, package:semana5/core/logic/ldi.dart, package:semana5/core/logic/puntualidad.dart, package:semana5/core/utils/formatters.dart, package:semana5/core/utils/temporary_password.dart, package:semana5/core/validators/validators.dart, package:semana5/models/docente.dart (+4 more)

### Community 57 - "Sistema de Gestión Académica Multiplataforma"
Cohesion: 0.25
Nodes (7): Estructura del proyecto, Firebase Console, Firestore, Pruebas, Reglas académicas, Requisitos del enunciado → dónde se cumplen, Sistema de Gestión Académica Multiplataforma

### Community 58 - "app_strings.dart"
Cohesion: 0.29
Nodes (6): appFullName, appName, AppStrings, appTagline, appVersion, static const String

### Community 59 - "academico_test.dart"
Cohesion: 0.09
Nodes (22): Exception, HorarioNoDisponible, AuthFailure, AcademicoFailure, JornadaFailure, package:semana5/core/logic/notas.dart, package:semana5/models/curso.dart, package:semana5/models/estudiante.dart (+14 more)

### Community 61 - "estudiante.dart"
Cohesion: 0.11
Nodes (18): apellidos, codigo, coincide, copyWith, correo, DatosEstudiante, docenteId, Estudiante (+10 more)

### Community 62 - "calificaciones_screen.dart"
Cohesion: 0.11
Nodes (17): evaluacion_form_dialog.dart, _abreviar, build, createState, curso, _cursoId, _eliminar, evaluacion (+9 more)

### Community 67 - "evaluacion_form_dialog.dart"
Cohesion: 0.11
Nodes (17): TipoEvaluacion, build, creada, createState, curso, dispose, _elegirFecha, _error (+9 more)

### Community 68 - "package:flutter/material.dart"
Cohesion: 0.33
Nodes (5): app/app.dart, firebase_options.dart, initializeApp, main, package:flutter/material.dart

### Community 69 - "formatters.dart"
Cohesion: 0.12
Nodes (16): dia, formatDuracion, formatFechaCorta, formatFechaLarga, formatHora, formatNota, formatPorcentaje, hora (+8 more)

### Community 70 - "register_dialog.dart"
Cohesion: 0.12
Nodes (16): _apellidosController, build, _celularController, createState, dispose, _dniController, _emailController, _error (+8 more)

### Community 71 - "estudiante_form_dialog.dart"
Cohesion: 0.12
Nodes (15): _apellidosController, build, _codigoController, _correoController, createState, dispose, _editando, _error (+7 more)

### Community 72 - "texto.dart"
Cohesion: 0.20
Nodes (9): buffer, _conTilde, inicialesDe, normalizarBusqueda, _sinTilde, texto, toString, x (+1 more)

### Community 73 - "../../widgets/encabezado.dart"
Cohesion: 0.25
Nodes (8): _abrir, AsistenciaScreen, _AsistenciaScreenState, build, createState, _cursoId, ../../widgets/dialogos.dart, ../../widgets/encabezado.dart

### Community 74 - "reporte_screen.dart"
Cohesion: 0.22
Nodes (8): curso, cursoId, _Distribucion, _rangos, resumen, ../models/resumen_asistencia.dart, ../../models/resumen_notas.dart, ../providers/auth_provider.dart

### Community 75 - "../core/logic/notas.dart"
Cohesion: 0.29
Nodes (6): ../core/logic/notas.dart, aprobada, Calificacion, estudianteId, evaluacionId, nota

## Knowledge Gaps
- **1129 isolated node(s):** `_auth`, `_academico`, `_calificaciones`, `_jornada`, `_tema` (+1124 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1266 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AuthProvider` connect `AuthProvider` to `forgot_password_dialog.dart`, `app.dart`, `inicio_screen.dart`, `auth_provider.dart`, `ajustes_screen.dart`, `register_dialog.dart`, `perfil_screen.dart`, `reporte_screen.dart`, `verify_phone_screen.dart`, `main_shell.dart`, `change_password_screen.dart`, `login_screen.dart`, `AcademicoProvider`, `encabezado.dart`?**
  _High betweenness centrality (0.036) - this node is a cross-community bridge._
- **Why does `Curso` connect `inicio_screen.dart` to `academico_provider.dart`, `curso.dart`, `evaluacion_form_dialog.dart`, `resumen_notas.dart`, `router.dart`, `reporte_screen.dart`, `app_routes.dart`, `jornada_screen.dart`, `academicos.dart`, `resumen_asistencia.dart`, `curso_form_screen.dart`, `toma_asistencia_screen.dart`, `curso_detalle_screen.dart`, `calificaciones_screen.dart`?**
  _High betweenness centrality (0.031) - this node is a cross-community bridge._
- **Why does `AcademicoProvider` connect `AcademicoProvider` to `academico_provider.dart`, `app.dart`, `estudiante_form_dialog.dart`, `../../widgets/encabezado.dart`, `perfil_screen.dart`, `horario.dart`, `reporte_screen.dart`, `matricula_screen.dart`, `calificaciones_provider.dart`, `jornada_screen.dart`, `curso_form_screen.dart`, `toma_asistencia_screen.dart`, `estudiante_detalle_screen.dart`, `curso_detalle_screen.dart`, `registro_notas_screen.dart`?**
  _High betweenness centrality (0.031) - this node is a cross-community bridge._
- **What connects `_auth`, `_academico`, `_calificaciones` to the rest of the system?**
  _1129 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `academico_provider.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.029411764705882353 - nodes in this community are weakly interconnected._
- **Should `win32_window.cpp` be split into smaller, more focused modules?**
  _Cohesion score 0.050724637681159424 - nodes in this community are weakly interconnected._
- **Should `datos_prueba.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.030303030303030304 - nodes in this community are weakly interconnected._