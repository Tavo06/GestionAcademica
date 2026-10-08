# Graph Report - semana5  (2026-10-08)

## Corpus Check
- 101 files · ~62,739 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 21 file(s) not represented in the graph (top: .xml 7, (none) 6, .properties 2)

## Summary
- 1837 nodes · 2832 edges · 90 communities (81 shown, 6 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 14 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `a8ff496a`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- academico_provider.dart
- FlutterWindow
- datos_prueba.dart
- ../models/curso.dart
- auth_provider.dart
- resumen_notas.dart
- router.dart
- comunes.dart
- app_palette.dart
- jornada.dart
- app_theme.dart
- horario.dart
- app_routes.dart
- AcademicoProvider
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
- cursos_screen.dart
- matriculas_screen.dart
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
- calendario.dart
- matricula.dart
- perfil_screen.dart
- historial_screen.dart
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
- ../providers/academico_provider.dart
- ../core/theme/app_theme.dart
- estudiante_detalle_screen.dart
- catalogo_cursos.dart
- win32_window.cpp
- catalogo_carreras.dart
- AcademicoService
- calificaciones_test.dart
- State
- estudiantes_screen.dart
- Win32Window
- MessageHandler
- RegisterPlugins
- Point
- Size
- _CursoFormScreenState
- _HistorialScreenState

## God Nodes (most connected - your core abstractions)
1. `AcademicoProvider` - 55 edges
2. `AuthProvider` - 52 edges
3. `CalificacionesProvider` - 23 edges
4. `Win32Window` - 21 edges
5. `Curso` - 16 edges
6. `TemaProvider` - 14 edges
7. `JornadaProvider` - 12 edges
8. `MessageHandler` - 12 edges
9. `build` - 10 edges
10. `FlutterWindow` - 10 edges

## Surprising Connections (you probably didn't know these)
- `main` --references--> `TemaProvider`  [EXTRACTED]
  test/pantallas_test.dart → lib/providers/tema_provider.dart
- `_desdeCatalogo` --references--> `AcademicoProvider`  [EXTRACTED]
  lib/screens/cursos/cursos_screen.dart → lib/providers/academico_provider.dart
- `_guardar` --references--> `AcademicoProvider`  [EXTRACTED]
  lib/screens/estudiantes/estudiante_form_dialog.dart → lib/providers/academico_provider.dart
- `_cambiarEstado` --references--> `AcademicoProvider`  [EXTRACTED]
  lib/screens/matriculas/matriculas_screen.dart → lib/providers/academico_provider.dart
- `_nueva` --references--> `AcademicoProvider`  [EXTRACTED]
  lib/screens/matriculas/matriculas_screen.dart → lib/providers/academico_provider.dart

## Import Cycles
- None detected.

## Communities (90 total, 6 thin omitted)

### Community 0 - "academico_provider.dart"
Cohesion: 0.03
Nodes (67): AcademicoService get, _activosPorCurso, actualizarCurso, actualizarEstudiante, ahora, asistenciaDe, bindTeacher, bloqueado (+59 more)

### Community 1 - "FlutterWindow"
Cohesion: 0.12
Nodes (16): FlutterViewController, unique_ptr, DartProject, HWND, LPARAM, LRESULT, UINT, WPARAM (+8 more)

### Community 2 - "datos_prueba.dart"
Cohesion: 0.03
Nodes (64): package:semana5/app/router.dart, package:semana5/models/asistencia.dart, package:semana5/services/calificaciones_service.dart, aca, academicoPrueba, actualizarCurso, actualizarEstudiante, actualizarFechaSesion (+56 more)

### Community 3 - "../models/curso.dart"
Cohesion: 0.15
Nodes (12): FirebaseFirestore, _firestore, _jornadas, JornadaService, marcarEntrada, marcarSalida, message, toString (+4 more)

### Community 4 - "auth_provider.dart"
Cohesion: 0.03
Nodes (59): ConfirmationResult?, ../core/utils/temporary_password.dart, Docente get, FirebaseAuth, Future, _auth, _authSubscription, canUseTeacherData (+51 more)

### Community 5 - "resumen_notas.dart"
Cohesion: 0.06
Nodes (30): CondicionNota get, curso.dart, double? get, estudiante.dart, evaluacion.dart, Iterable, aprobado, aprobados (+22 more)

### Community 6 - "router.dart"
Cohesion: 0.06
Nodes (32): PreseleccionMatricula, buildRouter, _ruta, _rutasPublicas, _rutasRegistro, main_shell.dart, ../models/docente.dart, ../screens/ajustes/ajustes_screen.dart (+24 more)

### Community 7 - "comunes.dart"
Cohesion: 0.06
Nodes (35): accion, action, anchoMaximoContenido, bottom, build, children, color, confirmado (+27 more)

### Community 8 - "app_palette.dart"
Cohesion: 0.05
Nodes (38): accent, accentDark, AppPalette, background, backgroundDark, border, borderDark, error (+30 more)

### Community 9 - "jornada.dart"
Cohesion: 0.07
Nodes (26): Duration? get, abierta, agruparPorDia, compararJornadas, cursoId, cursoNombre, docenteId, duracion (+18 more)

### Community 10 - "app_theme.dart"
Cohesion: 0.06
Nodes (34): @immutable, app_palette.dart, AppTokens get, BuildContext, ColorScheme get, NavegacionAcademica, accent, AppTheme (+26 more)

### Community 11 - "horario.dart"
Cohesion: 0.06
Nodes (31): claseNombre, compareTo, dias, diasSemanaNombres, en, fecha, fechas, fin (+23 more)

### Community 12 - "app_routes.dart"
Cohesion: 0.05
Nodes (40): abrirCurso, abrirEstudiante, abrirMatricula, abrirRegistroNotas, abrirReporte, abrirTomaAsistencia, ajustes, AppPaths (+32 more)

### Community 13 - "AcademicoProvider"
Cohesion: 0.11
Nodes (20): BloqueHorario, AcademicoProvider, build, _guardar, build, _retirar, _guardar, _usarCatalogo (+12 more)

### Community 14 - "calificaciones_provider.dart"
Cohesion: 0.04
Nodes (44): academico_provider.dart, CalificacionesService get, android, DefaultFirebaseOptions, web, windows, _academico, aprobadas (+36 more)

### Community 15 - "jornada_screen.dart"
Cohesion: 0.06
Nodes (40): ChangeNotifier, double?, Duration, Curso, Sesion, JornadaProvider, asistencia, build (+32 more)

### Community 16 - "main_shell.dart"
Cohesion: 0.07
Nodes (29): app_routes.dart, int?, _academico, activa, activo, actual, anchoMenuExtendido, anchoMenuLateral (+21 more)

### Community 17 - "academicos.dart"
Cohesion: 0.06
Nodes (38): IconData get, CondicionNota, ResultadoMarca, EstadoAsistencia, ahora, ancho, build, color (+30 more)

### Community 18 - "resumen_asistencia.dart"
Cohesion: 0.06
Nodes (30): AsistenciaEstudiante, bloqueadoPorLdi, calcularResumenCurso, contar, curso, enLdi, estadosPorEstudiante, estaEnLdi (+22 more)

### Community 19 - "auth_widgets.dart"
Cohesion: 0.06
Nodes (33): anchoCompacto, _Aparicion, AuthCard, authCelularDecoration, AuthDialog, AuthIconBadge, authInputDecoration, AuthLogo (+25 more)

### Community 20 - "curso_form_screen.dart"
Cohesion: 0.06
Nodes (30): build, _carrera, _CatalogoBanner, _codigoController, createState, _creditos, curso, cursoId (+22 more)

### Community 21 - "toma_asistencia_screen.dart"
Cohesion: 0.07
Nodes (27): _AvisoBloqueo, _Cabecera, createState, curso, enabled, estado, estudiante, _etiquetas (+19 more)

### Community 22 - "login_screen.dart"
Cohesion: 0.10
Nodes (20): dart:ui, ../forgot_password/forgot_password_dialog.dart, _anchoPanel, compacta, createState, dispose, _emailController, _error (+12 more)

### Community 23 - "academico_service.dart"
Cohesion: 0.07
Nodes (26): actualizarCurso, actualizarEstudiante, actualizarFechaSesion, cambiarEstadoMatricula, crearCurso, crearEstudiante, crearMatricula, _cursos (+18 more)

### Community 24 - "sesion.dart"
Cohesion: 0.09
Nodes (22): asistencia.dart, Comparable, DateTime get, HoraDia, asistencias, copyWith, cursoId, docenteId (+14 more)

### Community 25 - "cursos_screen.dart"
Cohesion: 0.12
Nodes (18): ../core/utils/formatters.dart, ../core/utils/texto.dart, build, _busqueda, _carrera, createState, CursosScreen, _CursosScreenState (+10 more)

### Community 26 - "matriculas_screen.dart"
Cohesion: 0.18
Nodes (11): EstadoMatricula, build, _cambiarEstado, createState, _cursoId, _estado, MatriculasScreen, _MatriculasScreenState (+3 more)

### Community 27 - "curso_detalle_screen.dart"
Cohesion: 0.08
Nodes (29): ../calificaciones/evaluacion_form_dialog.dart, ResumenCurso, ResumenNotasCurso, CalificacionesProvider, _eliminar, _guardar, _abrirSesion, _Cabecera (+21 more)

### Community 28 - "registro_notas_screen.dart"
Cohesion: 0.11
Nodes (18): Evaluacion, build, _campo, _campos, createState, dispose, evaluacion, evaluacionId (+10 more)

### Community 29 - "login_test.dart"
Cohesion: 0.08
Nodes (25): EditableText, package:semana5/core/constants/app_strings.dart, package:semana5/core/theme/app_theme.dart, package:semana5/providers/auth_provider.dart, package:semana5/screens/auth/change_password/change_password_screen.dart, package:semana5/screens/auth/forgot_password/forgot_password_dialog.dart, package:semana5/screens/auth/inactive/inactive_screen.dart, package:semana5/screens/auth/login/login_screen.dart (+17 more)

### Community 30 - "encabezado.dart"
Cohesion: 0.08
Nodes (24): acciones, accionesSeccion, _alto, BannerDestacado, child, _Circulo, color, CuentaMenuButton (+16 more)

### Community 31 - "StatelessWidget"
Cohesion: 0.11
Nodes (19): CursoCard, EstadoChip, EstudianteTile, SesionEstadoChip, SesionTile, AdaptiveGrid, BuscadorField, CargandoView (+11 more)

### Community 32 - "forgot_password_dialog.dart"
Cohesion: 0.13
Nodes (15): ../../core/validators/validators.dart, FormState, build, createState, dispose, _emailController, _error, ForgotPasswordDialog (+7 more)

### Community 33 - "app.dart"
Cohesion: 0.11
Nodes (19): ../../../core/constants/app_strings.dart, GoRouter, _academico, _auth, build, _calificaciones, createState, dispose (+11 more)

### Community 34 - "curso.dart"
Cohesion: 0.08
Nodes (25): carrera, codigo, copyWith, createdAt, creditos, descripcion, diasSemana, diasTexto (+17 more)

### Community 35 - "puntualidad.dart"
Cohesion: 0.13
Nodes (14): apertura, aperturaEntradaMinutos, diferencia, _diferenciaMinutos, evaluarEntrada, evaluarSalida, minutos, mismoDia (+6 more)

### Community 36 - "pantallas_test.dart"
Cohesion: 0.11
Nodes (18): dart:async, helpers/datos_prueba.dart, package:flutter_test/flutter_test.dart, package:semana5/app/app_routes.dart, package:semana5/providers/academico_provider.dart, package:semana5/providers/tema_provider.dart, package:semana5/widgets/academicos.dart, package:semana5/widgets/encabezado.dart (+10 more)

### Community 37 - "ajustes_screen.dart"
Cohesion: 0.11
Nodes (20): ../../core/logic/ldi.dart, IconData?, build, _MenuLateral, TemaProvider, activa, AjustesScreen, build (+12 more)

### Community 38 - "notas.dart"
Cohesion: 0.09
Nodes (22): cantidad, condicionDe, disponible, esNotaValida, estaAprobado, etiqueta, limpio, nota (+14 more)

### Community 39 - "calendario.dart"
Cohesion: 0.05
Nodes (39): DateTimeRange?, DateTimeRange? inicial,
  Map, _atajo, build, CalendarioMensual, _CalendarioMensualState, createState, _Cuadricula (+31 more)

### Community 40 - "matricula.dart"
Cohesion: 0.12
Nodes (15): DateTime?, activa, copyWith, cursoId, docenteId, estado, estudianteId, etiqueta (+7 more)

### Community 41 - "perfil_screen.dart"
Cohesion: 0.12
Nodes (15): ../auth/register/register_dialog.dart, _apellidosController, build, createState, dispose, _dniController, _docente, _elegirFecha (+7 more)

### Community 42 - "historial_screen.dart"
Cohesion: 0.06
Nodes (34): _agenda, _AgendaDelDia, ahora, color, _colorDe, createState, curso, _dia (+26 more)

### Community 43 - "jornada_provider.dart"
Cohesion: 0.09
Nodes (21): ../core/logic/puntualidad.dart, JornadaService get, bindTeacher, _cargando, deHoy, dispose, _error, _jornadas (+13 more)

### Community 44 - "verify_phone_screen.dart"
Cohesion: 0.12
Nodes (15): _celularController, _codeFormKey, _codeSent, _codigoController, createState, _digitosNacionales, dispose, _handleChangeNumber (+7 more)

### Community 45 - "temporary_password.dart"
Cohesion: 0.17
Nodes (11): dart:math, all, chars, _digits, generateTemporaryPassword, join, _lower, pick (+3 more)

### Community 46 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 47 - "../core/logic/horario.dart"
Cohesion: 0.18
Nodes (10): academico_service.dart, CollectionReference, ../core/logic/horario.dart, crearEvaluacion, eliminarEvaluacion, _evaluaciones, _firestore, guardarNotas (+2 more)

### Community 48 - "evaluacion.dart"
Cohesion: 0.11
Nodes (18): calificacion.dart, calificaciones, copyWith, cursoId, docenteId, etiqueta, fecha, fromDoc (+10 more)

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
Cohesion: 0.11
Nodes (17): celular, confirmPassword, dni, edad, edadEn, edadMaxima, edadMinima, email (+9 more)

### Community 53 - "AuthProvider"
Cohesion: 0.13
Nodes (19): AuthProvider, build, _handleLogin, _handleSubmit, build, createState, _handleCheck, _handleResend (+11 more)

### Community 54 - "return"
Cohesion: 0.29
Nodes (6): estaEnLdi, faltas, faltasPermitidas, porcentajeFaltas, umbralLdi, return

### Community 55 - "docente.dart"
Cohesion: 0.10
Nodes (20): int get, apellidos, copyWith, correo, dni, Docente, edad, estado (+12 more)

### Community 56 - "package:cloud_firestore/cloud_firestore.dart"
Cohesion: 0.14
Nodes (12): package:cloud_firestore/cloud_firestore.dart, package:semana5/core/data/catalogo_carreras.dart, package:semana5/core/utils/temporary_password.dart, package:semana5/core/validators/validators.dart, package:semana5/models/curso.dart, package:semana5/models/docente.dart, package:semana5/models/jornada.dart, package:semana5/widgets/calendario.dart (+4 more)

### Community 57 - "Sistema de Gestión Académica Multiplataforma"
Cohesion: 0.25
Nodes (7): Estructura del proyecto, Firebase Console, Firestore, Pruebas, Reglas académicas, Requisitos del enunciado → dónde se cumplen, Sistema de Gestión Académica Multiplataforma

### Community 58 - "app_strings.dart"
Cohesion: 0.29
Nodes (6): appFullName, appName, AppStrings, appTagline, appVersion, static const String

### Community 59 - "academico_test.dart"
Cohesion: 0.14
Nodes (15): Exception, HorarioNoDisponible, AuthFailure, AcademicoFailure, JornadaFailure, package:semana5/models/estudiante.dart, package:semana5/models/matricula.dart, package:semana5/models/sesion.dart (+7 more)

### Community 61 - "estudiante.dart"
Cohesion: 0.11
Nodes (17): apellidos, codigo, coincide, copyWith, correo, DatosEstudiante, docenteId, fechaRegistro (+9 more)

### Community 62 - "calificaciones_screen.dart"
Cohesion: 0.11
Nodes (19): evaluacion_form_dialog.dart, _abreviar, build, CalificacionesScreen, _CalificacionesScreenState, createState, curso, _cursoId (+11 more)

### Community 67 - "evaluacion_form_dialog.dart"
Cohesion: 0.11
Nodes (18): TipoEvaluacion, build, creada, createState, curso, dispose, _elegirFecha, _error (+10 more)

### Community 68 - "package:flutter/material.dart"
Cohesion: 0.33
Nodes (5): app/app.dart, firebase_options.dart, initializeApp, main, package:flutter/material.dart

### Community 69 - "formatters.dart"
Cohesion: 0.12
Nodes (16): dia, formatDuracion, formatFechaCorta, formatFechaLarga, formatHora, formatNota, formatPorcentaje, hora (+8 more)

### Community 70 - "register_dialog.dart"
Cohesion: 0.10
Nodes (20): _apellidosController, build, _celularController, createState, dispose, _dniController, _elegir, _emailController (+12 more)

### Community 71 - "estudiante_form_dialog.dart"
Cohesion: 0.11
Nodes (18): Estudiante, _apellidosController, build, _codigoController, _correoController, createState, dispose, _editando (+10 more)

### Community 72 - "texto.dart"
Cohesion: 0.20
Nodes (9): buffer, _conTilde, inicialesDe, normalizarBusqueda, _sinTilde, texto, toString, x (+1 more)

### Community 73 - "../providers/academico_provider.dart"
Cohesion: 0.12
Nodes (16): comunes.dart, _abrir, build, createState, _cursoId, academico, false, lunes (+8 more)

### Community 74 - "../core/theme/app_theme.dart"
Cohesion: 0.24
Nodes (9): ../core/theme/app_theme.dart, build, InactiveScreen, build, _pasos, RegistrationCompleteScreen, package:provider/provider.dart, ../providers/auth_provider.dart (+1 more)

### Community 75 - "estudiante_detalle_screen.dart"
Cohesion: 0.11
Nodes (18): ../core/logic/notas.dart, estudiante_form_dialog.dart, aprobada, Calificacion, estudianteId, evaluacionId, nota, build (+10 more)

### Community 76 - "catalogo_cursos.dart"
Cohesion: 0.09
Nodes (22): ../core/data/catalogo_carreras.dart, CursoCatalogo, build, _busqueda, _carrera, carreraInicial, _CarreraTile, CatalogoCursos (+14 more)

### Community 77 - "win32_window.cpp"
Cohesion: 0.18
Nodes (14): wchar_t, Scale(), Create, Destroy, SetQuitOnClose, Show, UpdateTheme, Win32Window::Win32Window() (+6 more)

### Community 78 - "catalogo_carreras.dart"
Cohesion: 0.12
Nodes (16): Color, CarreraCatalogo, carreraPorNombre, catalogoCarreras, ciclo, codigo, color, creditos (+8 more)

### Community 80 - "calificaciones_test.dart"
Cohesion: 0.14
Nodes (12): package:semana5/core/logic/horario.dart, package:semana5/core/logic/ldi.dart, package:semana5/core/logic/notas.dart, package:semana5/core/logic/puntualidad.dart, package:semana5/core/utils/formatters.dart, package:semana5/models/evaluacion.dart, package:semana5/models/resumen_notas.dart, package:semana5/providers/calificaciones_provider.dart (+4 more)

### Community 81 - "State"
Cohesion: 0.23
Nodes (12): AsistenciaScreen, _AsistenciaScreenState, LoginScreen, _LoginScreenState, RegisterDialog, _RegisterDialogState, VerifyPhoneScreen, _VerifyPhoneScreenState (+4 more)

### Community 82 - "estudiantes_screen.dart"
Cohesion: 0.22
Nodes (9): ../app/app_routes.dart, _Filtro, build, _busqueda, createState, EstudiantesScreen, _EstudiantesScreenState, _Filtro (+1 more)

### Community 83 - "Win32Window"
Cohesion: 0.27
Nodes (10): RECT, OnCreate, HWND, Win32Window, child_content_, GetClientArea, OnCreate, quit_on_close_ (+2 more)

### Community 84 - "MessageHandler"
Cohesion: 0.36
Nodes (10): HWND, LPARAM, LRESULT, UINT, WPARAM, EnableFullDpiSupportIfAvailable(), GetHandle, GetThisFromHandle (+2 more)

### Community 86 - "Point"
Cohesion: 0.50
Nodes (3): Point, x, y

### Community 87 - "Size"
Cohesion: 0.50
Nodes (3): Size, height, width

## Knowledge Gaps
- **1227 isolated node(s):** `_auth`, `_academico`, `_calificaciones`, `_jornada`, `_tema` (+1222 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1371 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AuthProvider` connect `AuthProvider` to `forgot_password_dialog.dart`, `app.dart`, `auth_provider.dart`, `ajustes_screen.dart`, `register_dialog.dart`, `perfil_screen.dart`, `../core/theme/app_theme.dart`, `verify_phone_screen.dart`, `jornada_screen.dart`, `main_shell.dart`, `change_password_screen.dart`, `State`, `login_screen.dart`, `curso_detalle_screen.dart`, `encabezado.dart`?**
  _High betweenness centrality (0.042) - this node is a cross-community bridge._
- **Why does `AcademicoProvider` connect `AcademicoProvider` to `academico_provider.dart`, `calificaciones_provider.dart`, `jornada_screen.dart`, `curso_form_screen.dart`, `toma_asistencia_screen.dart`, `cursos_screen.dart`, `matriculas_screen.dart`, `curso_detalle_screen.dart`, `registro_notas_screen.dart`, `app.dart`, `perfil_screen.dart`, `historial_screen.dart`, `estudiante_form_dialog.dart`, `../providers/academico_provider.dart`, `estudiante_detalle_screen.dart`, `State`, `estudiantes_screen.dart`, `_CursoFormScreenState`, `_HistorialScreenState`?**
  _High betweenness centrality (0.029) - this node is a cross-community bridge._
- **Why does `Curso` connect `jornada_screen.dart` to `academico_provider.dart`, `curso.dart`, `evaluacion_form_dialog.dart`, `resumen_notas.dart`, `router.dart`, `historial_screen.dart`, `app_routes.dart`, `academicos.dart`, `resumen_asistencia.dart`, `curso_form_screen.dart`, `toma_asistencia_screen.dart`, `curso_detalle_screen.dart`, `calificaciones_screen.dart`?**
  _High betweenness centrality (0.028) - this node is a cross-community bridge._
- **What connects `_auth`, `_academico`, `_calificaciones` to the rest of the system?**
  _1227 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `academico_provider.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.029411764705882353 - nodes in this community are weakly interconnected._
- **Should `FlutterWindow` be split into smaller, more focused modules?**
  _Cohesion score 0.11695906432748537 - nodes in this community are weakly interconnected._
- **Should `datos_prueba.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03076923076923077 - nodes in this community are weakly interconnected._