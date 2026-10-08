import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../models/curso.dart';
import '../models/estudiante.dart';
import '../models/evaluacion.dart';
import '../models/sesion.dart';
import '../providers/academico_provider.dart';
import '../providers/calificaciones_provider.dart';
import '../widgets/catalogo_cursos.dart';

/// Rutas nombradas de la app. Se navega por NOMBRE
/// (`context.pushNamed(AppRoutes.cursoDetalle, ...)`), nunca escribiendo la
/// dirección a mano.
abstract final class AppRoutes {
  // Acceso y registro
  static const login = 'login';
  static const verificarCorreo = 'verificar-correo';
  static const verificarCelular = 'verificar-celular';
  static const crearContrasena = 'crear-contrasena';
  static const registroCompleto = 'registro-completo';
  static const cuentaInactiva = 'cuenta-inactiva';

  // Secciones del menú (ramas del shell)
  static const inicio = 'inicio';
  static const cursos = 'cursos'; // listado
  static const estudiantes = 'estudiantes';
  static const matriculas = 'matriculas';
  static const calificaciones = 'calificaciones';
  static const reportes = 'reportes';
  static const asistencia = 'asistencia';
  static const jornada = 'jornada';
  static const historial = 'historial';

  // Pantallas que se abren encima
  static const cursoDetalle = 'curso-detalle'; // detalle
  static const cursoNuevo = 'curso-nuevo';
  static const cursoEditar = 'curso-editar';
  static const estudianteDetalle = 'estudiante-detalle';
  static const matricula = 'matricula'; // nueva matrícula
  static const registroNotas = 'registro-notas';
  static const reporte = 'reporte'; // reporte de un curso
  static const tomaAsistencia = 'toma-asistencia';
  static const perfil = 'perfil';
  static const ajustes = 'ajustes';
}

/// Direcciones (paths) de cada ruta; solo las usa el router.
abstract final class AppPaths {
  static const login = '/login';
  static const verificarCorreo = '/verificar-correo';
  static const verificarCelular = '/verificar-celular';
  static const crearContrasena = '/crear-contrasena';
  static const registroCompleto = '/registro-completo';
  static const cuentaInactiva = '/cuenta-inactiva';

  static const inicio = '/inicio';
  static const cursos = '/cursos';
  static const estudiantes = '/estudiantes';
  static const matriculas = '/matriculas';
  static const calificaciones = '/calificaciones';
  static const reportes = '/reportes';
  static const asistencia = '/asistencia';
  static const jornada = '/jornada';
  static const historial = '/historial';

  static const cursoDetalle = '/curso';
  static const cursoNuevo = '/curso/nuevo';
  static const cursoEditar = '/curso/editar';
  static const estudianteDetalle = '/estudiante';
  static const matricula = '/matricula';
  static const registroNotas = '/notas';
  static const reporte = '/reporte';
  static const tomaAsistencia = '/sesion';
  static const perfil = '/perfil';
  static const ajustes = '/ajustes';
}

/// Lo que se envía a la pantalla de matrícula: el curso y/o el estudiante
/// ya elegidos (los dos son opcionales).
class PreseleccionMatricula {
  final Curso? curso;
  final Estudiante? estudiante;

  const PreseleccionMatricula({this.curso, this.estudiante});
}

/// Navegación con objetos: cada pantalla recibe el OBJETO completo en
/// `extra` (se muestra al instante) y su id en la URL (así funciona también
/// al recargar la página en web). Las que devuelven un resultado lo
/// entregan con `context.pop(resultado)`.
extension NavegacionAcademica on BuildContext {
  Future<void> abrirCurso(Curso curso) =>
      pushNamed(AppRoutes.cursoDetalle, queryParameters: {'id': curso.id}, extra: curso);

  /// Devuelve el [Curso] creado, o null si se canceló. Con [plantilla]
  /// (un curso del catálogo) el formulario llega rellenado.
  Future<Curso?> crearCurso({PlantillaCurso? plantilla}) => pushNamed<Curso>(AppRoutes.cursoNuevo, extra: plantilla);

  /// Devuelve el [Curso] con los cambios guardados, o null.
  Future<Curso?> editarCurso(Curso curso) =>
      pushNamed<Curso>(AppRoutes.cursoEditar, queryParameters: {'id': curso.id}, extra: curso);

  Future<void> abrirEstudiante(Estudiante estudiante, {Curso? curso}) => pushNamed(
    AppRoutes.estudianteDetalle,
    queryParameters: {'id': estudiante.id, 'curso': ?curso?.id},
    extra: estudiante,
  );

  /// Devuelve el [ResultadoMatricula] con las matrículas creadas, o null.
  Future<ResultadoMatricula?> abrirMatricula({Curso? curso, Estudiante? estudiante}) => pushNamed<ResultadoMatricula>(
    AppRoutes.matricula,
    queryParameters: {'curso': ?curso?.id, 'estudiante': ?estudiante?.id},
    extra: PreseleccionMatricula(curso: curso, estudiante: estudiante),
  );

  /// Devuelve las [NotasGuardadas], o null si se salió sin guardar.
  Future<NotasGuardadas?> abrirRegistroNotas(Evaluacion evaluacion) =>
      pushNamed<NotasGuardadas>(AppRoutes.registroNotas, queryParameters: {'id': evaluacion.id}, extra: evaluacion);

  Future<void> abrirReporte(Curso curso) =>
      pushNamed(AppRoutes.reporte, queryParameters: {'curso': curso.id}, extra: curso);

  /// Devuelve la [AsistenciaGuardada], o null si se salió sin guardar.
  Future<AsistenciaGuardada?> abrirTomaAsistencia(Sesion sesion) =>
      pushNamed<AsistenciaGuardada>(AppRoutes.tomaAsistencia, queryParameters: {'id': sesion.id}, extra: sesion);
}
