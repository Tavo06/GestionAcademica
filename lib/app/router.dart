import 'package:go_router/go_router.dart';

import '../models/curso.dart';
import '../models/docente.dart';
import '../models/estudiante.dart';
import '../models/evaluacion.dart';
import '../models/sesion.dart';
import '../providers/auth_provider.dart';
import '../screens/ajustes/ajustes_screen.dart';
import '../screens/asistencia/asistencia_screen.dart';
import '../screens/asistencia/toma_asistencia_screen.dart';
import '../screens/auth/change_password/change_password_screen.dart';
import '../screens/auth/inactive/inactive_screen.dart';
import '../screens/auth/login/login_screen.dart';
import '../screens/auth/registration_complete/registration_complete_screen.dart';
import '../screens/auth/verify_email/verify_email_screen.dart';
import '../screens/auth/verify_phone/verify_phone_screen.dart';
import '../screens/calificaciones/calificaciones_screen.dart';
import '../screens/calificaciones/registro_notas_screen.dart';
import '../screens/cursos/curso_detalle_screen.dart';
import '../screens/cursos/curso_form_screen.dart';
import '../screens/cursos/cursos_screen.dart';
import '../screens/estudiantes/estudiante_detalle_screen.dart';
import '../screens/estudiantes/estudiantes_screen.dart';
import '../screens/inicio/inicio_screen.dart';
import '../screens/jornada/historial_screen.dart';
import '../screens/jornada/jornada_screen.dart';
import '../screens/matriculas/matricula_screen.dart';
import '../screens/matriculas/matriculas_screen.dart';
import '../screens/perfil/perfil_screen.dart';
import '../screens/reportes/reporte_screen.dart';
import '../screens/reportes/reportes_screen.dart';
import '../widgets/catalogo_cursos.dart';
import 'app_routes.dart';
import 'main_shell.dart';

/// Se llega sin sesión. El registro y la recuperación de contraseña son
/// diálogos sobre el login, no rutas.
const _rutasPublicas = [AppPaths.login];

/// Pasos del registro; nunca son destino cuando el registro ya terminó.
const _rutasRegistro = [
  AppPaths.verificarCorreo,
  AppPaths.verificarCelular,
  AppPaths.crearContrasena,
  AppPaths.registroCompleto,
];

/// `extra` del tipo esperado, o null (por ejemplo al recargar en web).
T? _extra<T>(GoRouterState state) => state.extra is T ? state.extra as T : null;

GoRoute _ruta(String name, String path, GoRouterWidgetBuilder builder) =>
    GoRoute(name: name, path: path, builder: builder);

/// [inicial] y [sinRedireccion] solo los usan las pruebas, para abrir una
/// pantalla sin una sesión real de Firebase.
GoRouter buildRouter(AuthProvider auth, {String inicial = AppPaths.login, bool sinRedireccion = false}) {
  return GoRouter(
    initialLocation: inicial,
    refreshListenable: auth,
    redirect: (context, state) {
      if (sinRedireccion) return null;
      final location = state.matchedLocation;

      if (!auth.isLoggedIn) {
        return _rutasPublicas.contains(location) ? null : AppPaths.login;
      }

      // Sesión restaurada pero el perfil aún carga: esperar antes de decidir.
      if (auth.isLoadingProfile) return null;

      // Contraseña recién creada: pantalla de éxito, que cierra la sesión.
      if (auth.registrationComplete) {
        return location == AppPaths.registroCompleto ? null : AppPaths.registroCompleto;
      }
      if (!auth.emailVerified) {
        return location == AppPaths.verificarCorreo ? null : AppPaths.verificarCorreo;
      }
      // Toda cuenta necesita un celular confirmado por SMS.
      if (!auth.phoneVerified) {
        return location == AppPaths.verificarCelular ? null : AppPaths.verificarCelular;
      }
      if (auth.mustChangePassword) {
        return location == AppPaths.crearContrasena ? null : AppPaths.crearContrasena;
      }

      // `status` interno (solo se cambia desde Firebase Console).
      if (auth.docente.estado == EstadoCuenta.inactivo) {
        return location == AppPaths.cuentaInactiva ? null : AppPaths.cuentaInactiva;
      }
      if (location == AppPaths.cuentaInactiva) return AppPaths.inicio;

      if (_rutasPublicas.contains(location) || _rutasRegistro.contains(location)) {
        return AppPaths.inicio;
      }
      return null;
    },
    routes: [
      _ruta(AppRoutes.login, AppPaths.login, (_, _) => const LoginScreen()),
      _ruta(AppRoutes.verificarCorreo, AppPaths.verificarCorreo, (_, _) => const VerifyEmailScreen()),
      _ruta(AppRoutes.verificarCelular, AppPaths.verificarCelular, (_, _) => const VerifyPhoneScreen()),
      _ruta(AppRoutes.crearContrasena, AppPaths.crearContrasena, (_, _) => const ChangePasswordScreen()),
      _ruta(AppRoutes.registroCompleto, AppPaths.registroCompleto, (_, _) => const RegistrationCompleteScreen()),
      _ruta(AppRoutes.cuentaInactiva, AppPaths.cuentaInactiva, (_, _) => const InactiveScreen()),

      // Pantallas que se abren encima del menú. Reciben el objeto en
      // `extra` y su id en la URL.
      _ruta(
        AppRoutes.cursoNuevo,
        AppPaths.cursoNuevo,
        (_, state) => CursoFormScreen(plantilla: _extra<PlantillaCurso>(state)),
      ),
      _ruta(
        AppRoutes.cursoEditar,
        AppPaths.cursoEditar,
        (_, state) => CursoFormScreen(cursoId: state.uri.queryParameters['id'], curso: _extra<Curso>(state)),
      ),
      _ruta(
        AppRoutes.cursoDetalle,
        AppPaths.cursoDetalle,
        (_, state) => CursoDetalleScreen(cursoId: state.uri.queryParameters['id'], curso: _extra<Curso>(state)),
      ),
      _ruta(
        AppRoutes.estudianteDetalle,
        AppPaths.estudianteDetalle,
        (_, state) => EstudianteDetalleScreen(
          estudianteId: state.uri.queryParameters['id'],
          estudiante: _extra<Estudiante>(state),
          cursoId: state.uri.queryParameters['curso'],
        ),
      ),
      _ruta(AppRoutes.matricula, AppPaths.matricula, (_, state) {
        final pre = _extra<PreseleccionMatricula>(state);
        return MatriculaScreen(
          cursoId: pre?.curso?.id ?? state.uri.queryParameters['curso'],
          estudianteId: pre?.estudiante?.id ?? state.uri.queryParameters['estudiante'],
        );
      }),
      _ruta(
        AppRoutes.registroNotas,
        AppPaths.registroNotas,
        (_, state) =>
            RegistroNotasScreen(evaluacionId: state.uri.queryParameters['id'], evaluacion: _extra<Evaluacion>(state)),
      ),
      _ruta(
        AppRoutes.reporte,
        AppPaths.reporte,
        (_, state) => ReporteScreen(cursoId: state.uri.queryParameters['curso'], curso: _extra<Curso>(state)),
      ),
      _ruta(
        AppRoutes.tomaAsistencia,
        AppPaths.tomaAsistencia,
        (_, state) => TomaAsistenciaScreen(sesionId: state.uri.queryParameters['id'], sesion: _extra<Sesion>(state)),
      ),
      _ruta(AppRoutes.perfil, AppPaths.perfil, (_, _) => const PerfilScreen()),
      _ruta(AppRoutes.ajustes, AppPaths.ajustes, (_, _) => const AjustesScreen()),

      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        // El orden debe coincidir con las secciones de main_shell.dart.
        branches: [
          for (final (nombre, path, pantalla) in [
            (AppRoutes.inicio, AppPaths.inicio, const InicioScreen()),
            (AppRoutes.cursos, AppPaths.cursos, const CursosScreen()),
            (AppRoutes.estudiantes, AppPaths.estudiantes, const EstudiantesScreen()),
            (AppRoutes.matriculas, AppPaths.matriculas, const MatriculasScreen()),
            (AppRoutes.calificaciones, AppPaths.calificaciones, const CalificacionesScreen()),
            (AppRoutes.reportes, AppPaths.reportes, const ReportesScreen()),
            (AppRoutes.asistencia, AppPaths.asistencia, const AsistenciaScreen()),
            (AppRoutes.jornada, AppPaths.jornada, const JornadaScreen()),
            (AppRoutes.historial, AppPaths.historial, const HistorialScreen()),
          ])
            StatefulShellBranch(routes: [_ruta(nombre, path, (_, _) => pantalla)]),
        ],
      ),
    ],
  );
}
