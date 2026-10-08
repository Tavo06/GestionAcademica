import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/logic/horario.dart';
import '../core/logic/puntualidad.dart';
import '../models/curso.dart';
import '../models/jornada.dart';
import '../models/sesion.dart';
import '../services/jornada_service.dart';

/// Estado global de las jornadas del docente (una por sesión de curso).
/// Lo comparten Inicio, Jornada e Historial.
class JornadaProvider extends ChangeNotifier {
  JornadaProvider({JornadaService? service, DateTime Function()? reloj})
      : _serviceOverride = service,
        _reloj = reloj ?? DateTime.now;

  final JornadaService? _serviceOverride;
  final DateTime Function() _reloj;
  JornadaService? _lazyService;
  JornadaService get _service => _serviceOverride ?? (_lazyService ??= JornadaService());

  StreamSubscription<List<Jornada>>? _sub;
  String? _uid;
  List<Jornada> _jornadas = const [];
  Map<String, Jornada> _porSesion = const {};
  bool _cargando = true;
  String? _error;

  /// El día más reciente primero.
  List<Jornada> get jornadas => _jornadas;

  /// Jornadas por id de sesión.
  Map<String, Jornada> get porSesion => _porSesion;

  bool get cargando => _cargando;
  String? get error => _error;

  List<Jornada> deHoy() {
    final hoy = soloFecha(_reloj());
    return _jornadas.where((j) => j.fecha == hoy).toList();
  }

  void bindTeacher(String? uid) {
    if (uid == _uid) return;
    _subscribe(uid);
  }

  void reintentar() => _subscribe(_uid);

  void _subscribe(String? uid) {
    _sub?.cancel();
    _sub = null;
    _uid = uid;
    _set(const []);
    _error = null;
    _cargando = uid != null;
    notifyListeners();
    if (uid == null) return;
    _sub = _service.watchJornadas(uid).listen((datos) {
      _set(datos);
      _cargando = false;
      _error = null;
      notifyListeners();
    }, onError: (Object e) {
      debugPrint('No se pudieron cargar las jornadas: $e');
      _error = 'No se pudieron cargar tus jornadas.';
      _cargando = false;
      notifyListeners();
    });
  }

  void _set(List<Jornada> datos) {
    _jornadas = List.unmodifiable(List<Jornada>.of(datos)..sort(compararJornadas));
    _porSesion = {for (final j in _jornadas) j.sesionId: j};
  }

  Future<void> marcarEntrada(Curso curso, Sesion sesion) async {
    final uid = _uid;
    if (uid == null) throw const JornadaFailure('Tu sesión no está activa.');
    if (_porSesion.containsKey(sesion.id)) {
      throw const JornadaFailure('Ya registraste tu entrada para esta sesión.');
    }
    final motivo = validarEntrada(inicio: sesion.inicio, fin: sesion.fin, ahora: _reloj());
    if (motivo != null) throw JornadaFailure(motivo);
    await _service.marcarEntrada(uid, curso, sesion);
  }

  Future<void> marcarSalida(Jornada jornada) async {
    if (!jornada.abierta) throw const JornadaFailure('Esta jornada ya tiene su salida.');
    await _service.marcarSalida(jornada.id);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
