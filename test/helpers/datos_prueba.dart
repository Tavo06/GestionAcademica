import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:semana5/app/router.dart' show buildRouter;
import 'package:semana5/core/logic/horario.dart';
import 'package:semana5/core/theme/app_theme.dart';
import 'package:semana5/models/asistencia.dart';
import 'package:semana5/models/curso.dart';
import 'package:semana5/models/docente.dart';
import 'package:semana5/models/estudiante.dart';
import 'package:semana5/models/evaluacion.dart';
import 'package:semana5/models/jornada.dart';
import 'package:semana5/models/matricula.dart';
import 'package:semana5/models/sesion.dart';
import 'package:semana5/providers/academico_provider.dart';
import 'package:semana5/providers/auth_provider.dart';
import 'package:semana5/providers/calificaciones_provider.dart';
import 'package:semana5/providers/jornada_provider.dart';
import 'package:semana5/providers/tema_provider.dart';
import 'package:semana5/services/academico_service.dart';
import 'package:semana5/services/calificaciones_service.dart';
import 'package:semana5/services/jornada_service.dart';


const p = EstadoAsistencia.presente;
const f = EstadoAsistencia.falta;

/// Lunes 12/10/2026, 18:00. Semana actual: 12/10 - 18/10.
final ahoraPrueba = DateTime(2026, 10, 12, 18);

Curso cursoDe(
  String id,
  String codigo,
  String nombre,
  String inicio,
  String fin, {
  String docenteId = 'A',
  int total = 16,
  List<int> dias = const [DateTime.monday],
  DateTime? desde,
}) =>
    Curso(
      id: id,
      docenteId: docenteId,
      codigo: codigo,
      nombre: nombre,
      creditos: 4,
      totalSesiones: total,
      diasSemana: dias,
      horaInicio: HoraDia.tryParse(inicio)!,
      horaFin: HoraDia.tryParse(fin)!,
      fechaInicio: desde ?? DateTime(2026, 9, 7),
    );

/// Sesiones de [curso] en sus fechas reales; [marcas] por número de sesión.
List<Sesion> sesionesDe(Curso curso, [Map<int, Map<String, EstadoAsistencia>> marcas = const {}]) {
  final fechas = generarFechasSesiones(
    fechaInicio: curso.fechaInicio,
    diasSemana: curso.diasSemana,
    total: curso.totalSesiones,
  );
  return [
    for (var i = 0; i < fechas.length; i++)
      Sesion(
        id: '${curso.id}${i + 1}',
        docenteId: curso.docenteId,
        cursoId: curso.id,
        numero: i + 1,
        fecha: fechas[i],
        horaInicio: curso.horaInicio,
        horaFin: curso.horaFin,
        asistencias: marcas[i + 1] ?? const {},
      ),
  ];
}

Estudiante estudianteDe(String id, String nombres, String apellidos, {String docenteId = 'A'}) => Estudiante(
      id: id,
      docenteId: docenteId,
      codigo: id.toUpperCase(),
      nombres: nombres,
      apellidos: apellidos,
    );

Matricula matriculaDe(String cursoId, String estudianteId,
        {String docenteId = 'A', EstadoMatricula estado = EstadoMatricula.activa}) =>
    Matricula(
      id: matriculaId(cursoId, estudianteId),
      docenteId: docenteId,
      cursoId: cursoId,
      estudianteId: estudianteId,
      fecha: DateTime(2026, 9, 1),
      estado: estado,
    );

/// Programación II (lunes 17-20) y Base de Datos (lunes 21-23).
/// Ana: 5 faltas en PII (LDI). Pedro: 4 en PII (25%) y 1 en BD.
typedef Datos = ({
  List<Curso> cursos,
  List<Estudiante> estudiantes,
  List<Sesion> sesiones,
  List<Matricula> matriculas,
  List<Evaluacion> evaluaciones,
});

Datos datosPrueba() {
  final pii = cursoDe('pii', 'PRG-201', 'Programación II', '17:00', '20:00');
  final bd = cursoDe('bd', 'BD-101', 'Base de Datos', '21:00', '23:00');
  return (
    cursos: [pii, bd],
    estudiantes: [
      estudianteDe('ana', 'Ana', 'López'),
      estudianteDe('pedro', 'Pedro', 'García'),
      estudianteDe('juan', 'Juan', 'Pérez'),
    ],
    sesiones: [
      ...sesionesDe(pii, {
        1: {'ana': f, 'pedro': f, 'juan': p},
        2: {'ana': f, 'pedro': f, 'juan': p},
        3: {'ana': f, 'pedro': f, 'juan': p},
        4: {'ana': f, 'pedro': f, 'juan': p},
        5: {'ana': f, 'pedro': p, 'juan': p},
      }),
      ...sesionesDe(bd, {
        1: {'pedro': f},
        2: {'pedro': p},
      }),
    ],
    matriculas: [
      matriculaDe('pii', 'ana'),
      matriculaDe('pii', 'pedro'),
      matriculaDe('pii', 'juan'),
      matriculaDe('bd', 'pedro'),
    ],
    // PII: práctica 40% y examen 60%.
    evaluaciones: [
      Evaluacion(
        id: 'pc1',
        docenteId: 'A',
        cursoId: 'pii',
        nombre: 'Práctica 1',
        tipo: TipoEvaluacion.practica,
        peso: 40,
        fecha: DateTime(2026, 9, 21),
        notas: const {'ana': 8, 'pedro': 14, 'juan': 18},
      ),
      Evaluacion(
        id: 'ex1',
        docenteId: 'A',
        cursoId: 'pii',
        nombre: 'Examen parcial',
        tipo: TipoEvaluacion.examen,
        peso: 60,
        fecha: DateTime(2026, 10, 5),
        notas: const {'ana': 10, 'pedro': 9},
      ),
    ],
  );
}

AcademicoProvider academicoPrueba({AcademicoService? service, Datos? datos}) {
  final d = datos ?? datosPrueba();
  return AcademicoProvider.conDatos(
    cursos: d.cursos,
    estudiantes: d.estudiantes,
    sesiones: d.sesiones,
    matriculas: d.matriculas,
    reloj: () => ahoraPrueba,
    service: service,
  );
}

/// Firestore en memoria que filtra por `docenteId` como las consultas reales.
class FakeAcademicoService implements AcademicoService {
  FakeAcademicoService({
    List<Curso> cursos = const [],
    List<Estudiante> estudiantes = const [],
    List<Sesion> sesiones = const [],
    List<Matricula> matriculas = const [],
  })  : cursos = List.of(cursos),
        estudiantes = List.of(estudiantes),
        sesiones = List.of(sesiones),
        matriculas = List.of(matriculas);

  factory FakeAcademicoService.desde(Datos d) => FakeAcademicoService(
        cursos: d.cursos,
        estudiantes: d.estudiantes,
        sesiones: d.sesiones,
        matriculas: d.matriculas,
      );

  final List<Curso> cursos;
  final List<Estudiante> estudiantes;
  final List<Sesion> sesiones;
  final List<Matricula> matriculas;
  final Map<String, DateTime> fechasMovidas = {};
  final _cambios = StreamController<void>.broadcast();
  var _id = 0;

  Sesion sesion(String id) => sesiones.firstWhere((s) => s.id == id);

  Stream<List<T>> _watch<T>(List<T> Function() leer) async* {
    yield leer();
    await for (final _ in _cambios.stream) {
      yield leer();
    }
  }

  void _avisar() => _cambios.add(null);

  @override
  Stream<List<Curso>> watchCursos(String uid) => _watch(() => cursos.where((c) => c.docenteId == uid).toList());

  @override
  Stream<List<Estudiante>> watchEstudiantes(String uid) =>
      _watch(() => estudiantes.where((e) => e.docenteId == uid).toList());

  @override
  Stream<List<Sesion>> watchSesiones(String uid) =>
      _watch(() => sesiones.where((s) => s.docenteId == uid).toList());

  @override
  Stream<List<Matricula>> watchMatriculas(String uid) =>
      _watch(() => matriculas.where((m) => m.docenteId == uid).toList());

  @override
  Future<String> crearCurso(String uid, NuevoCurso datos) async {
    final curso = Curso(
      id: 'nuevo${_id++}',
      docenteId: uid,
      codigo: datos.codigo.toUpperCase(),
      nombre: datos.nombre,
      creditos: datos.creditos,
      totalSesiones: datos.totalSesiones,
      diasSemana: datos.diasSemana,
      horaInicio: datos.horaInicio,
      horaFin: datos.horaFin,
      fechaInicio: datos.fechaInicio,
    );
    cursos.add(curso);
    sesiones.addAll(sesionesDe(curso));
    _avisar();
    return curso.id;
  }

  @override
  Future<void> actualizarCurso(Curso curso) async {
    cursos[cursos.indexWhere((c) => c.id == curso.id)] = curso;
    _avisar();
  }

  @override
  Future<void> eliminarCurso(
    String cursoId, {
    required Iterable<String> sesionIds,
    required Iterable<String> matriculaIds,
    required Iterable<String> evaluacionIds,
  }) async {
    cursos.removeWhere((c) => c.id == cursoId);
    sesiones.removeWhere((s) => s.cursoId == cursoId);
    matriculas.removeWhere((m) => matriculaIds.contains(m.id));
    _avisar();
  }

  @override
  Future<void> actualizarFechaSesion(String sesionId, DateTime fecha) async {
    fechasMovidas[sesionId] = fecha;
  }

  @override
  Future<void> guardarAsistencias(String sesionId, Map<String, EstadoAsistencia> asistencias) async {
    final i = sesiones.indexWhere((s) => s.id == sesionId);
    sesiones[i] = sesiones[i].copyWith(asistencias: Map.of(asistencias));
    _avisar();
  }

  @override
  Future<String> crearEstudiante(String uid, DatosEstudiante datos) async {
    final e = Estudiante(
      id: 'es${_id++}',
      docenteId: uid,
      codigo: datos.codigo.toUpperCase(),
      nombres: datos.nombres,
      apellidos: datos.apellidos,
      correo: datos.correo,
    );
    estudiantes.add(e);
    _avisar();
    return e.id;
  }

  @override
  Future<void> actualizarEstudiante(String id, DatosEstudiante datos) async {
    final i = estudiantes.indexWhere((e) => e.id == id);
    estudiantes[i] = estudiantes[i].copyWith(
      codigo: datos.codigo.toUpperCase(),
      nombres: datos.nombres,
      apellidos: datos.apellidos,
      correo: datos.correo,
    );
    _avisar();
  }

  @override
  Future<void> eliminarEstudiante(String id, Iterable<String> matriculaIds) async {
    estudiantes.removeWhere((e) => e.id == id);
    matriculas.removeWhere((m) => matriculaIds.contains(m.id));
    _avisar();
  }

  @override
  Future<void> crearMatricula(String uid, String cursoId, String estudianteId) async {
    final id = matriculaId(cursoId, estudianteId);
    if (matriculas.any((m) => m.id == id)) throw const AcademicoFailure('ya existe');
    matriculas.add(Matricula(
      id: id,
      docenteId: uid,
      cursoId: cursoId,
      estudianteId: estudianteId,
      fecha: ahoraPrueba,
    ));
    _avisar();
  }

  @override
  Future<void> cambiarEstadoMatricula(String id, EstadoMatricula estado) async {
    final i = matriculas.indexWhere((m) => m.id == id);
    matriculas[i] = matriculas[i].copyWith(estado: estado);
    _avisar();
  }
}

class FakeCalificacionesService implements CalificacionesService {
  FakeCalificacionesService([List<Evaluacion> evaluaciones = const []]) : evaluaciones = List.of(evaluaciones);

  final List<Evaluacion> evaluaciones;
  final _cambios = StreamController<void>.broadcast();
  var _id = 0;

  @override
  Stream<List<Evaluacion>> watchEvaluaciones(String uid) async* {
    List<Evaluacion> leer() => evaluaciones.where((e) => e.docenteId == uid).toList();
    yield leer();
    await for (final _ in _cambios.stream) {
      yield leer();
    }
  }

  @override
  Future<String> crearEvaluacion(String uid, NuevaEvaluacion datos) async {
    final ev = Evaluacion(
      id: 'ev${_id++}',
      docenteId: uid,
      cursoId: datos.cursoId,
      nombre: datos.nombre,
      tipo: datos.tipo,
      peso: datos.peso,
      fecha: datos.fecha,
    );
    evaluaciones.add(ev);
    _cambios.add(null);
    return ev.id;
  }

  @override
  Future<void> eliminarEvaluacion(String id) async {
    evaluaciones.removeWhere((e) => e.id == id);
    _cambios.add(null);
  }

  @override
  Future<void> guardarNotas(String evaluacionId, Map<String, double> notas) async {
    final i = evaluaciones.indexWhere((e) => e.id == evaluacionId);
    evaluaciones[i] = evaluaciones[i].copyWith(notas: Map.of(notas));
    _cambios.add(null);
  }
}

class FakeJornadaService implements JornadaService {
  FakeJornadaService(this.reloj);

  final DateTime Function() reloj;
  final List<Jornada> registros = [];
  final _cambios = StreamController<void>.broadcast();

  @override
  Future<void> marcarEntrada(String uid, Curso curso, Sesion sesion) async {
    registros.add(Jornada(
      id: jornadaDocId(uid, sesion.id),
      docenteId: uid,
      fecha: sesion.fecha,
      entrada: reloj(),
      cursoId: curso.id,
      sesionId: sesion.id,
      cursoNombre: curso.nombre,
      sesionNumero: sesion.numero,
      horaProgramadaInicio: sesion.horaInicio,
      horaProgramadaFin: sesion.horaFin,
    ));
    _cambios.add(null);
  }

  @override
  Future<void> marcarSalida(String jornadaId) async {
    final i = registros.indexWhere((r) => r.id == jornadaId);
    final r = registros[i];
    registros[i] = Jornada.fromDoc(r.id, {
      'docenteId': r.docenteId,
      'fecha': Timestamp.fromDate(r.fecha),
      'entrada': Timestamp.fromDate(r.entrada!),
      'salida': Timestamp.fromDate(reloj()),
      'cursoId': r.cursoId,
      'sesionId': r.sesionId,
      'cursoNombre': r.cursoNombre,
      'sesionNumero': r.sesionNumero,
      'horaProgramadaInicio': r.horaProgramadaInicio.toString(),
      'horaProgramadaFin': r.horaProgramadaFin.toString(),
    });
    _cambios.add(null);
  }

  @override
  Stream<List<Jornada>> watchJornadas(String uid) async* {
    List<Jornada> leer() => registros.where((r) => r.docenteId == uid).toList();
    yield leer();
    await for (final _ in _cambios.stream) {
      yield leer();
    }
  }
}

const docentePrueba = Docente(
  uid: 'A',
  nombre: 'Gustavo',
  apellidos: 'Ramos',
  correo: 'gustavo@colegio.edu',
  dni: '12345678',
  telefono: '+51983024889',
);

ThemeData temaPrueba({bool oscuro = false}) => oscuro
    ? ThemeData(useMaterial3: true, brightness: Brightness.dark, extensions: const [AppTokens.dark])
    : ThemeData(useMaterial3: true, extensions: const [AppTokens.light]);

Future<void> esperar(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

/// Monta la app real (router con rutas nombradas, shell y providers) con
/// datos en memoria, abierta en [ruta].
Future<({AcademicoProvider academico, CalificacionesProvider calificaciones, GoRouter router})> montarApp(
  WidgetTester tester, {
  String ruta = '/inicio',
  Size tamano = const Size(1000, 2200),
  bool oscuro = false,
  AcademicoProvider? academico,
  CalificacionesProvider? calificaciones,
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final auth = AuthProvider.paraPruebas(docentePrueba);
  // Providers conectados a Firestore en memoria: lo que se guarda vuelve
  // por los streams, igual que con Firebase.
  final aca = academico ??
      (AcademicoProvider(service: FakeAcademicoService.desde(datosPrueba()), reloj: () => ahoraPrueba)
        ..bindTeacher('A'));
  final cal = calificaciones ??
      (CalificacionesProvider(aca, service: FakeCalificacionesService(datosPrueba().evaluaciones))
        ..bindTeacher('A'));
  final jornadas = JornadaProvider(service: FakeJornadaService(() => ahoraPrueba), reloj: () => ahoraPrueba)
    ..bindTeacher('A');
  final router = buildRouter(auth, inicial: ruta, sinRedireccion: true);
  addTearDown(router.dispose);
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider.value(value: aca),
      ChangeNotifierProvider.value(value: cal),
      ChangeNotifierProvider.value(value: jornadas),
      ChangeNotifierProvider(create: (_) => TemaProvider()),
    ],
    child: MaterialApp.router(theme: temaPrueba(oscuro: oscuro), routerConfig: router),
  ));
  await esperar(tester);
  return (academico: aca, calificaciones: cal, router: router);
}
