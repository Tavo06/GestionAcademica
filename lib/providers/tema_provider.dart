import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modo claro / oscuro elegido por el docente, recordado en este dispositivo.
/// Cambia en vivo toda la app (MaterialApp escucha este provider).
class TemaProvider extends ChangeNotifier {
  static const _clave = 'modo_tema';

  ThemeMode _modo = ThemeMode.light;

  ThemeMode get modo => _modo;
  bool get oscuro => _modo == ThemeMode.dark;

  Future<void> cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final guardado = prefs.getString(_clave);
      if (guardado == 'oscuro' && _modo != ThemeMode.dark) {
        _modo = ThemeMode.dark;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('No se pudo leer el tema guardado: $e');
    }
  }

  Future<void> cambiar(ThemeMode modo) async {
    if (modo == _modo) return;
    _modo = modo;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_clave, modo == ThemeMode.dark ? 'oscuro' : 'claro');
    } catch (e) {
      debugPrint('No se pudo guardar el tema: $e');
    }
  }
}
