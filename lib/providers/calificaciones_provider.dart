import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/logic/notas.dart';
import '../models/curso.dart';
import '../models/evaluacion.dart';
import '../models/resumen_notas.dart';
import '../services/academico_service.dart';
import '../services/calificaciones_service.dart';
import 'academico_provider.dart';

/// Lo que devuelve la pantalla de registro de notas al guardar.
class NotasGuardadas {
  final Evaluacion evaluacion;
  final int calificadas;
  final int aprobadas;
  final double? promedio;

  const NotasGuardadas({
    required this.evaluacion,
    required this.calificadas,
    required this.aprobadas,
    required this.promedio,
  });

  int get desaprobadas => calificadas - aprobadas;
}

/// Estado global de evaluaciones, notas y promedios. Usa los matriculados
/// del [AcademicoProvider] y se actualiza cuando este cambia, así los
/// promedios del inicio, del curso, del estudiante y del reporte siempre
/// coinciden.
class CalificacionesProvider extends ChangeNotifier {
  CalificacionesProvider(this._academico, {CalificacionesService? service}) : _serviceOverride = service {
    _academico.addListener(_onAcademico);
  }

  /// Estado precargado sin Firestore, para las pruebas de widgets.
  @visibleForTesting
  CalificacionesProvider.conDatos(
    this._academico, {
    List<Evaluacion> evaluaciones = const [],
    CalificacionesService? service,
  }) : _serviceOverride = service,
       _uid = 'test' {
    _setEvaluaciones(evaluaciones);
    _cargando = false;
    _academico.addListener(_onAcademico);
  }

  final AcademicoProvider _academico;
  final CalificacionesService? _serviceOverride;
  CalificacionesService? _lazyService;
  CalificacionesService get _service => _serviceOverride ?? (_lazyService ??= CalificacionesService());

  StreamSubscription<List<Evaluacion>>? _sub;
  String? _uid;
  List<Evaluacion> _evaluaciones = const [];
  Map<String, Evaluacion> _porId = const {};
  bool _cargando = true;
  String? _error;

  bool get cargando => _cargando;
  String? get error => _error;

  List<Evaluacion> get evaluaciones => _evaluaciones;

  Evaluacion? evaluacionPorId(String id) => _porId[id];

  /// Evaluaciones de un curso, por fecha.
  List<Evaluacion> evaluacionesDe(String cursoId) => _evaluaciones.where((e) => e.cursoId == cursoId).toList();

  /// Pesos (%) ya asignados en el curso.
  int pesoAsignado(String cursoId) => evaluacionesDe(cursoId).fold(0, (s, e) => s + e.peso);

  ResumenNotasCurso resumenDe(Curso curso) => calcularResumenNotas(
    curso: curso,
    evaluaciones: evaluacionesDe(curso.id),
    matriculados: _academico.matriculadosEn(curso.id),
  );

  PromedioEstudiante? promedioDe(String estudianteId, String cursoId) {
    final curso = _academico.cursoPorId(cursoId);
    if (curso == null) return null;
    for (final p in resumenDe(curso).estudiantes) {
      if (p.estudiante.id == estudianteId) return p;
    }
    return null;
  }

  /// Promedio del estudiante en cada curso donde está matriculado.
  List<PromedioEstudiante> promediosDeEstudiante(String estudianteId) => [
    for (final curso in _academico.cursosDe(estudianteId)) ?promedioDe(estudianteId, curso.id),
  ];

  /// Promedio de los promedios generales de los cursos con notas.
  double? get promedioGeneral =>
      promedioSimple([for (final curso in _academico.cursos) ?resumenDe(curso).promedioGeneral]);

  /// Estudiantes distintos desaprobados en al menos un curso.
  int get totalDesaprobados {
    final ids = <String>{};
    for (final curso in _academico.cursos) {
      for (final p in resumenDe(curso).estudiantes) {
        if (p.condicion == CondicionNota.desaprobado) ids.add(p.estudiante.id);
      }
    }
    return ids.length;
  }

  void _onAcademico() => notifyListeners();

  // ---------------------------------------------------------- Suscripción

  void bindTeacher(String? uid) {
    if (uid == _uid) return;
    _subscribe(uid);
  }

  void reintentar() => _subscribe(_uid);

  void _subscribe(String? uid) {
    _sub?.cancel();
    _sub = null;
    _uid = uid;
    _setEvaluaciones(const []);
    _error = null;
    _cargando = uid != null;
    notifyListeners();
    if (uid == null) return;
    _sub = _service
        .watchEvaluaciones(uid)
        .listen(
          (datos) {
            _setEvaluaciones(datos);
            _cargando = false;
            _error = null;
            notifyListeners();
          },
          onError: (Object e) {
            debugPrint('No se pudieron cargar las evaluaciones: $e');
            _error = 'No se pudieron cargar las calificaciones.';
            _cargando = false;
            notifyListeners();
          },
        );
  }

  void _setEvaluaciones(List<Evaluacion> datos) {
    _evaluaciones = List.unmodifiable(
      List.of(datos)..sort((a, b) {
        final porFecha = a.fecha.compareTo(b.fecha);
        return porFecha != 0 ? porFecha : a.nombre.compareTo(b.nombre);
      }),
    );
    _porId = {for (final e in _evaluaciones) e.id: e};
  }

  String get _uidActivo {
    final uid = _uid;
    if (uid == null) throw const AcademicoFailure('Tu sesión no está activa.');
    return uid;
  }

  // -------------------------------------------------------------- Acciones

  Future<Evaluacion> crearEvaluacion(NuevaEvaluacion datos) async {
    if (datos.nombre.trim().isEmpty) {
      throw const AcademicoFailure('Ingresa el nombre de la evaluación.');
    }
    if (_academico.cursoPorId(datos.cursoId) == null) {
      throw const AcademicoFailure('El curso ya no existe.');
    }
    final errorPeso = validarPeso(datos.peso, pesoAsignado(datos.cursoId));
    if (errorPeso != null) throw AcademicoFailure(errorPeso);
    final uid = _uidActivo;
    final id = await _service.crearEvaluacion(uid, datos);
    return Evaluacion(
      id: id,
      docenteId: uid,
      cursoId: datos.cursoId,
      nombre: datos.nombre.trim(),
      tipo: datos.tipo,
      peso: datos.peso,
      fecha: datos.fecha,
    );
  }

  Future<void> eliminarEvaluacion(Evaluacion evaluacion) => _service.eliminarEvaluacion(evaluacion.id);

  /// Guarda las notas de una evaluación. Solo se guardan notas válidas de
  /// estudiantes matriculados; null deja al estudiante sin nota.
  Future<NotasGuardadas> guardarNotas(String evaluacionId, Map<String, double?> notas) async {
    final evaluacion = _porId[evaluacionId];
    if (evaluacion == null) throw const AcademicoFailure('La evaluación ya no existe.');
    final matriculados = {for (final e in _academico.matriculadosEn(evaluacion.cursoId)) e.id};
    final limpias = <String, double>{};
    notas.forEach((estudianteId, nota) {
      if (nota == null || !matriculados.contains(estudianteId)) return;
      if (!esNotaValida(nota)) {
        throw AcademicoFailure('La nota $nota está fuera del rango 0 - 20.');
      }
      limpias[estudianteId] = (nota * 100).round() / 100;
    });
    await _service.guardarNotas(evaluacion.id, limpias);
    final valores = limpias.values;
    return NotasGuardadas(
      evaluacion: evaluacion.copyWith(notas: limpias),
      calificadas: limpias.length,
      aprobadas: valores.where(estaAprobado).length,
      promedio: promedioSimple(valores),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _academico.removeListener(_onAcademico);
    super.dispose();
  }
}
