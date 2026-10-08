import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/logic/horario.dart';
import '../core/utils/formatters.dart';
import '../models/asistencia.dart';
import '../models/curso.dart';
import '../models/estudiante.dart';
import '../models/matricula.dart';
import '../models/resumen_asistencia.dart';
import '../models/sesion.dart';
import '../services/academico_service.dart';

/// El horario de un curso nuevo o de una sesión movida se cruza con otro.
class HorarioNoDisponible extends AcademicoFailure {
  final BloqueHorario existente;

  HorarioNoDisponible(this.existente)
    : super(
        'Ya tienes un curso programado el '
        '${diasSemanaNombres[existente.fecha.weekday]!.toLowerCase()} '
        '${formatFechaCorta(existente.fecha)} de ${existente.inicio} a '
        '${existente.fin} (${existente.claseNombre}).',
      );
}

/// Resultado de guardar la asistencia de una sesión.
class AsistenciaGuardada {
  final ResumenAsistencia resumen;

  /// Estudiantes que con esta falta alcanzaron el LDI.
  final List<Estudiante> nuevosLdi;

  const AsistenciaGuardada({required this.resumen, this.nuevosLdi = const []});
}

/// Resultado de matricular varios estudiantes en un curso; la pantalla de
/// matrícula lo devuelve a la anterior.
class ResultadoMatricula {
  final Curso curso;
  final List<Matricula> matriculas;

  const ResultadoMatricula({required this.curso, required this.matriculas});

  int get cantidad => matriculas.length;
}

/// Estado global académico del docente: cursos, sesiones, estudiantes y
/// matrículas, con la asistencia y el LDI calculados. Las pantallas lo
/// escuchan con `Consumer` / `watch`, así un cambio en un curso se ve en
/// todas las pantallas que lo muestran.
class AcademicoProvider extends ChangeNotifier {
  AcademicoProvider({AcademicoService? service, DateTime Function()? reloj})
    : _serviceOverride = service,
      _reloj = reloj ?? DateTime.now;

  /// Estado precargado sin Firestore, para las pruebas de widgets.
  @visibleForTesting
  AcademicoProvider.conDatos({
    List<Curso> cursos = const [],
    List<Estudiante> estudiantes = const [],
    List<Sesion> sesiones = const [],
    List<Matricula> matriculas = const [],
    DateTime Function()? reloj,
    AcademicoService? service,
  }) : _serviceOverride = service,
       _reloj = reloj ?? DateTime.now,
       _uid = 'test' {
    _cursosCrudos = cursos;
    _estudiantesCrudos = estudiantes;
    _sesionesCrudas = sesiones;
    _matriculasCrudas = matriculas;
    _reindexar();
    _cargando = false;
  }

  final AcademicoService? _serviceOverride;
  final DateTime Function() _reloj;
  AcademicoService? _lazyService;
  AcademicoService get _service => _serviceOverride ?? (_lazyService ??= AcademicoService());

  final List<StreamSubscription<Object?>> _subs = [];

  String? _uid;
  List<Curso> _cursosCrudos = const [];
  List<Estudiante> _estudiantesCrudos = const [];
  List<Sesion> _sesionesCrudas = const [];
  List<Matricula> _matriculasCrudas = const [];

  List<Curso> _cursos = const [];
  List<Estudiante> _estudiantes = const [];
  List<Matricula> _matriculas = const [];
  Map<String, Curso> _cursosPorId = const {};
  Map<String, Estudiante> _estudiantesPorId = const {};
  Map<String, Sesion> _sesionesPorId = const {};
  Map<String, List<Sesion>> _sesionesPorCurso = const {};
  Map<String, Matricula> _matriculasPorId = const {};

  /// Ids de estudiantes con matrícula ACTIVA en cada curso.
  Map<String, Set<String>> _activosPorCurso = const {};

  final Set<String> _listos = {};
  bool _cargando = true;
  String? _error;

  DateTime get ahora => _reloj();
  DateTime get hoy => soloFecha(ahora);

  bool get cargando => _cargando;
  String? get error => _error;

  /// Ordenados por nombre.
  List<Curso> get cursos => _cursos;

  /// Todos los estudiantes del docente, por apellido.
  List<Estudiante> get estudiantes => _estudiantes;

  /// Todas las matrículas (activas y retiradas), la más reciente primero.
  List<Matricula> get matriculas => _matriculas;

  int get matriculasActivas => _matriculas.where((m) => m.activa).length;

  Curso? cursoPorId(String id) => _cursosPorId[id];
  Estudiante? estudiantePorId(String id) => _estudiantesPorId[id];

  /// Solo sesiones de cursos que existen.
  Sesion? sesionPorId(String id) => _sesionesPorId[id];

  /// Sesiones de un curso, por número.
  List<Sesion> sesionesDe(String cursoId) => _sesionesPorCurso[cursoId] ?? const [];

  Matricula? matriculaDe(String cursoId, String estudianteId) => _matriculasPorId[matriculaId(cursoId, estudianteId)];

  bool estaMatriculado(String cursoId, String estudianteId) =>
      _activosPorCurso[cursoId]?.contains(estudianteId) ?? false;

  /// Estudiantes con matrícula activa en el curso, por apellido.
  List<Estudiante> matriculadosEn(String cursoId) {
    final ids = _activosPorCurso[cursoId] ?? const <String>{};
    return _estudiantes.where((e) => ids.contains(e.id)).toList();
  }

  /// Cursos donde el estudiante tiene matrícula activa.
  List<Curso> cursosDe(String estudianteId) => _cursos.where((c) => estaMatriculado(c.id, estudianteId)).toList();

  /// Matrículas (activas y retiradas) de un estudiante.
  List<Matricula> matriculasDeEstudiante(String estudianteId) =>
      _matriculas.where((m) => m.estudianteId == estudianteId).toList();

  ResumenCurso resumenDe(Curso curso) => calcularResumenCurso(
    curso: curso,
    sesiones: sesionesDe(curso.id),
    matriculados: matriculadosEn(curso.id),
    ahora: ahora,
  );

  List<ResumenCurso> get resumenes => [for (final curso in _cursos) resumenDe(curso)];

  AsistenciaEstudiante? asistenciaDe(String estudianteId, String cursoId) {
    final curso = _cursosPorId[cursoId];
    if (curso == null) return null;
    for (final e in resumenDe(curso).estudiantes) {
      if (e.estudiante.id == estudianteId) return e;
    }
    return null;
  }

  /// Cursos que aún tienen sesiones por dictar.
  List<Curso> get cursosEnCurso => _cursos.where((c) => resumenDe(c).pendientes > 0).toList();

  /// Las sesiones de hoy de todos los cursos, por hora de inicio.
  List<({Curso curso, Sesion sesion})> get sesionesDeHoy {
    final hoy = this.hoy;
    return [
      for (final curso in _cursos)
        for (final sesion in sesionesDe(curso.id))
          if (sesion.fecha == hoy) (curso: curso, sesion: sesion),
    ]..sort((a, b) => a.sesion.horaInicio.compareTo(b.sesion.horaInicio));
  }

  /// Estudiantes distintos en LDI en al menos un curso (un Set evita
  /// contarlos dos veces).
  int get totalEnLdi {
    final ids = <String>{};
    for (final resumen in resumenes) {
      for (final e in resumen.estudiantes) {
        if (e.enLdi) ids.add(e.estudiante.id);
      }
    }
    return ids.length;
  }

  bool bloqueado(String estudianteId, Sesion sesion) {
    final curso = _cursosPorId[sesion.cursoId];
    if (curso == null) return false;
    return bloqueadoPorLdi(
      estudianteId: estudianteId,
      sesion: sesion,
      sesionesCurso: sesionesDe(curso.id),
      totalSesiones: curso.totalSesiones,
    );
  }

  // ---------------------------------------------------------- Suscripción

  /// La app lo llama cuando cambia la sesión: escucha los datos del docente
  /// activo, o limpia todo al cerrar sesión.
  void bindTeacher(String? uid) {
    if (uid == _uid) return;
    _subscribe(uid);
  }

  /// Vuelve a escuchar tras un error (un listener de Firestore fallido se
  /// detiene).
  void reintentar() => _subscribe(_uid);

  void _cancelar() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
  }

  void _subscribe(String? uid) {
    _cancelar();
    _uid = uid;
    _cursosCrudos = const [];
    _estudiantesCrudos = const [];
    _sesionesCrudas = const [];
    _matriculasCrudas = const [];
    _reindexar();
    _listos.clear();
    _error = null;
    _cargando = uid != null;
    notifyListeners();
    if (uid == null) return;

    _subs.addAll([
      _service.watchCursos(uid).listen((datos) {
        _cursosCrudos = datos;
        _onDatos('cursos');
      }, onError: _onError),
      _service.watchEstudiantes(uid).listen((datos) {
        _estudiantesCrudos = datos;
        _onDatos('estudiantes');
      }, onError: _onError),
      _service.watchSesiones(uid).listen((datos) {
        _sesionesCrudas = datos;
        _onDatos('sesiones');
      }, onError: _onError),
      _service.watchMatriculas(uid).listen((datos) {
        _matriculasCrudas = datos;
        _onDatos('matriculas');
      }, onError: _onError),
    ]);
  }

  void _reindexar() {
    _cursos = List.unmodifiable(
      List.of(_cursosCrudos)..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase())),
    );
    _cursosPorId = {for (final c in _cursos) c.id: c};
    _estudiantes = List.unmodifiable(
      List.of(_estudiantesCrudos)..sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto)),
    );
    _estudiantesPorId = {for (final e in _estudiantes) e.id: e};

    final porCurso = <String, List<Sesion>>{};
    final porId = <String, Sesion>{};
    for (final sesion in _sesionesCrudas) {
      if (!_cursosPorId.containsKey(sesion.cursoId)) continue;
      porCurso.putIfAbsent(sesion.cursoId, () => []).add(sesion);
      porId[sesion.id] = sesion;
    }
    for (final lista in porCurso.values) {
      lista.sort((a, b) => a.numero.compareTo(b.numero));
    }
    _sesionesPorCurso = porCurso;
    _sesionesPorId = porId;

    // Solo matrículas de cursos y estudiantes que existen.
    final validas =
        _matriculasCrudas
            .where((m) => _cursosPorId.containsKey(m.cursoId) && _estudiantesPorId.containsKey(m.estudianteId))
            .toList()
          ..sort((a, b) => b.fecha.compareTo(a.fecha));
    _matriculas = List.unmodifiable(validas);
    _matriculasPorId = {for (final m in validas) m.id: m};
    final activos = <String, Set<String>>{};
    for (final m in validas) {
      if (m.activa) activos.putIfAbsent(m.cursoId, () => <String>{}).add(m.estudianteId);
    }
    _activosPorCurso = activos;
  }

  void _onDatos(String coleccion) {
    _listos.add(coleccion);
    _reindexar();
    _error = null;
    _cargando = _listos.length < 4;
    notifyListeners();
  }

  void _onError(Object error) {
    debugPrint('No se pudo cargar la información académica: $error');
    _error = 'No se pudo cargar tu información. Revisa tu conexión e intenta nuevamente.';
    _cargando = false;
    notifyListeners();
  }

  String get _uidActivo {
    final uid = _uid;
    if (uid == null) throw const AcademicoFailure('Tu sesión no está activa.');
    return uid;
  }

  // ---------------------------------------------------------------- Cursos

  Iterable<BloqueHorario> _bloquesExistentes() sync* {
    for (final curso in _cursos) {
      for (final sesion in sesionesDe(curso.id)) {
        yield BloqueHorario(
          fecha: sesion.fecha,
          inicio: sesion.horaInicio,
          fin: sesion.horaFin,
          claseNombre: curso.nombre,
          sesionId: sesion.id,
        );
      }
    }
  }

  String? _codigoCursoRepetido(String codigo, {String? excepto}) {
    final buscado = codigo.trim().toUpperCase();
    for (final curso in _cursos) {
      if (curso.id != excepto && curso.codigo.toUpperCase() == buscado) {
        return 'El código $buscado ya pertenece a ${curso.nombre}.';
      }
    }
    return null;
  }

  /// Valida y crea un curso con sus sesiones. Lanza [HorarioNoDisponible]
  /// si alguna sesión se cruza con otro curso. Devuelve el curso creado.
  Future<Curso> crearCurso(NuevoCurso datos) async {
    final error = validarNuevoCurso(datos) ?? _codigoCursoRepetido(datos.codigo);
    if (error != null) throw AcademicoFailure(error);
    final nuevos = [
      for (final fecha in datos.fechas)
        BloqueHorario(fecha: fecha, inicio: datos.horaInicio, fin: datos.horaFin, claseNombre: datos.nombre),
    ];
    final conflicto = buscarConflicto(nuevos, _bloquesExistentes());
    if (conflicto != null) throw HorarioNoDisponible(conflicto.existente);
    final uid = _uidActivo;
    final id = await _service.crearCurso(uid, datos);
    return Curso(
      id: id,
      docenteId: uid,
      codigo: datos.codigo.trim().toUpperCase(),
      nombre: datos.nombre.trim(),
      descripcion: datos.descripcion,
      carrera: datos.carrera,
      creditos: datos.creditos,
      totalSesiones: datos.totalSesiones,
      diasSemana: datos.diasSemana,
      horaInicio: datos.horaInicio,
      horaFin: datos.horaFin,
      fechaInicio: soloFecha(datos.fechaInicio),
    );
  }

  Future<Curso> actualizarCurso(Curso curso) async {
    if (curso.nombre.trim().isEmpty || curso.codigo.trim().isEmpty) {
      throw const AcademicoFailure('Completa el código y el nombre del curso.');
    }
    final repetido = _codigoCursoRepetido(curso.codigo, excepto: curso.id);
    if (repetido != null) throw AcademicoFailure(repetido);
    await _service.actualizarCurso(curso);
    return curso;
  }

  /// Borra el curso con sus sesiones, matrículas y las [evaluacionIds] (las
  /// conoce el provider de calificaciones).
  Future<void> eliminarCurso(String cursoId, {Iterable<String> evaluacionIds = const []}) => _service.eliminarCurso(
    cursoId,
    sesionIds: sesionesDe(cursoId).map((s) => s.id),
    matriculaIds: _matriculas.where((m) => m.cursoId == cursoId).map((m) => m.id),
    evaluacionIds: evaluacionIds,
  );

  /// Solo se mueven sesiones de la semana actual, a otro día de la misma
  /// semana, conservando el orden de las sesiones y sin cruces.
  Future<void> cambiarFechaSesion(Sesion sesion, DateTime nuevaFecha) async {
    final hoy = this.hoy;
    final fecha = soloFecha(nuevaFecha);
    if (!puedeEditarFecha(sesion.fecha, hoy)) {
      throw const AcademicoFailure('Solo puedes cambiar la fecha de sesiones de esta semana.');
    }
    if (!puedeEditarFecha(fecha, hoy)) {
      throw const AcademicoFailure('La nueva fecha debe estar dentro de la semana actual.');
    }
    final curso = _cursosPorId[sesion.cursoId];
    if (curso == null) throw const AcademicoFailure('El curso ya no existe.');
    for (final otra in sesionesDe(curso.id)) {
      final antes = otra.numero < sesion.numero && !otra.fecha.isBefore(fecha);
      final despues = otra.numero > sesion.numero && !otra.fecha.isAfter(fecha);
      if (antes || despues) {
        throw AcademicoFailure(
          'La sesión ${sesion.numero} debe quedar después de la anterior y antes de la '
          'siguiente (sesión ${otra.numero}: ${formatFechaCorta(otra.fecha)}).',
        );
      }
    }
    final conflicto = buscarConflicto([
      BloqueHorario(
        fecha: fecha,
        inicio: sesion.horaInicio,
        fin: sesion.horaFin,
        claseNombre: curso.nombre,
        sesionId: sesion.id,
      ),
    ], _bloquesExistentes());
    if (conflicto != null) throw HorarioNoDisponible(conflicto.existente);
    await _service.actualizarFechaSesion(sesion.id, fecha);
  }

  // ----------------------------------------------------------- Estudiantes

  void _validarEstudiante(DatosEstudiante datos, {String? excepto}) {
    if (datos.nombres.trim().isEmpty || datos.apellidos.trim().isEmpty || datos.codigo.trim().isEmpty) {
      throw const AcademicoFailure('Completa código, nombres y apellidos.');
    }
    final codigo = datos.codigo.trim().toUpperCase();
    for (final e in _estudiantes) {
      if (e.id != excepto && e.codigo.toUpperCase() == codigo) {
        throw AcademicoFailure('El código $codigo ya pertenece a ${e.nombreVisible}.');
      }
    }
  }

  /// Registra un estudiante (sin cursos) y lo devuelve.
  Future<Estudiante> crearEstudiante(DatosEstudiante datos) async {
    _validarEstudiante(datos);
    final uid = _uidActivo;
    final id = await _service.crearEstudiante(uid, datos);
    return Estudiante(
      id: id,
      docenteId: uid,
      codigo: datos.codigo.trim().toUpperCase(),
      nombres: datos.nombres.trim(),
      apellidos: datos.apellidos.trim(),
      correo: datos.correo,
    );
  }

  Future<void> actualizarEstudiante(String id, DatosEstudiante datos) async {
    _validarEstudiante(datos, excepto: id);
    await _service.actualizarEstudiante(id, datos);
  }

  Future<void> eliminarEstudiante(String id) =>
      _service.eliminarEstudiante(id, _matriculas.where((m) => m.estudianteId == id).map((m) => m.id));

  // ------------------------------------------------------------ Matrículas

  /// Matricula a los [estudianteIds] en el curso: crea las matrículas nuevas
  /// y reactiva las retiradas. Los ya matriculados se ignoran (el Set evita
  /// duplicados).
  Future<ResultadoMatricula> matricular(String cursoId, Set<String> estudianteIds) async {
    final curso = _cursosPorId[cursoId];
    if (curso == null) throw const AcademicoFailure('El curso ya no existe.');
    final uid = _uidActivo;
    final pendientes = estudianteIds.where((id) => !estaMatriculado(cursoId, id)).toSet();
    if (pendientes.isEmpty) {
      throw const AcademicoFailure('Los estudiantes elegidos ya están matriculados en este curso.');
    }
    final resultado = <Matricula>[];
    await Future.wait([
      for (final estudianteId in pendientes)
        () async {
          final previa = matriculaDe(cursoId, estudianteId);
          if (previa != null) {
            await _service.cambiarEstadoMatricula(previa.id, EstadoMatricula.activa);
            resultado.add(previa.copyWith(estado: EstadoMatricula.activa));
          } else {
            await _service.crearMatricula(uid, cursoId, estudianteId);
            resultado.add(
              Matricula(
                id: matriculaId(cursoId, estudianteId),
                docenteId: uid,
                cursoId: cursoId,
                estudianteId: estudianteId,
                fecha: ahora,
              ),
            );
          }
        }(),
    ]);
    return ResultadoMatricula(curso: curso, matriculas: resultado);
  }

  /// El estudiante deja el curso; la matrícula queda como "retirada".
  Future<void> retirar(Matricula matricula) => _service.cambiarEstadoMatricula(matricula.id, EstadoMatricula.retirada);

  // ------------------------------------------------------------ Asistencia

  /// Guarda la asistencia de una sesión de la semana actual. Solo se
  /// escriben los matriculados no bloqueados por LDI; los bloqueados
  /// conservan lo que ya tenía la sesión.
  Future<AsistenciaGuardada> guardarAsistencia(String sesionId, Map<String, EstadoAsistencia> seleccion) async {
    final sesion = _sesionesPorId[sesionId];
    final curso = sesion == null ? null : _cursosPorId[sesion.cursoId];
    if (sesion == null || curso == null) throw const AcademicoFailure('La sesión ya no existe.');
    if (!puedeRegistrarAsistencia(sesion.fecha, hoy)) {
      throw const AcademicoFailure('Esta sesión no admite registro de asistencia.');
    }
    final matriculados = matriculadosEn(curso.id);
    final asistencias = <String, EstadoAsistencia>{};
    for (final estudiante in matriculados) {
      final anterior = sesion.estadoDe(estudiante.id);
      final nuevo = bloqueado(estudiante.id, sesion) ? anterior : seleccion[estudiante.id];
      if (nuevo != null) asistencias[estudiante.id] = nuevo;
    }

    final antes = {
      for (final e in resumenDe(curso).estudiantes)
        if (e.enLdi) e.estudiante.id,
    };
    await _service.guardarAsistencias(sesion.id, asistencias);

    final despues = calcularResumenCurso(
      curso: curso,
      sesiones: [for (final s in sesionesDe(curso.id)) s.id == sesion.id ? s.copyWith(asistencias: asistencias) : s],
      matriculados: matriculados,
      ahora: ahora,
    );
    return AsistenciaGuardada(
      resumen: ResumenAsistencia.contar(asistencias.values),
      nuevosLdi: [
        for (final e in despues.estudiantes)
          if (e.enLdi && !antes.contains(e.estudiante.id)) e.estudiante,
      ],
    );
  }

  @override
  void dispose() {
    _cancelar();
    super.dispose();
  }
}

/// Validación del formulario de curso nuevo; null si es válido.
String? validarNuevoCurso(NuevoCurso datos) {
  if (datos.codigo.trim().isEmpty) return 'Ingresa el código del curso.';
  if (datos.nombre.trim().isEmpty) return 'Ingresa el nombre del curso.';
  if (datos.creditos < minCreditos || datos.creditos > maxCreditos) {
    return 'Los créditos van de $minCreditos a $maxCreditos.';
  }
  if (datos.totalSesiones < minSesionesCurso || datos.totalSesiones > maxSesionesCurso) {
    return 'El número de sesiones debe estar entre $minSesionesCurso y $maxSesionesCurso.';
  }
  if (datos.diasSemana.isEmpty) return 'Selecciona al menos un día de la semana.';
  if (!(datos.horaInicio < datos.horaFin)) {
    return 'La hora de finalización debe ser posterior a la hora de inicio.';
  }
  return null;
}
