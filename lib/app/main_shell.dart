import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/tema_provider.dart';
import 'app_routes.dart';

/// Desde este ancho el menú lateral reemplaza a la barra inferior.
const double anchoMenuLateral = 900;

/// Desde este ancho el menú lateral muestra los textos.
const double anchoMenuExtendido = 1200;

/// Una sección del menú: una rama del shell ([rama]) o una pantalla que se
/// abre encima ([ruta]).
class _Seccion {
  final IconData icono;
  final IconData iconoActivo;
  final String texto;
  final int? rama;
  final String? ruta;

  const _Seccion(this.icono, this.iconoActivo, this.texto, {this.rama, this.ruta});
}

// Los índices de rama siguen el orden de las ramas en router.dart.
const _academico = [
  _Seccion(Icons.space_dashboard_outlined, Icons.space_dashboard_rounded, 'Inicio', rama: 0),
  _Seccion(Icons.menu_book_outlined, Icons.menu_book_rounded, 'Cursos', rama: 1),
  _Seccion(Icons.school_outlined, Icons.school_rounded, 'Estudiantes', rama: 2),
  _Seccion(Icons.how_to_reg_outlined, Icons.how_to_reg_rounded, 'Matrículas', rama: 3),
  _Seccion(Icons.grade_outlined, Icons.grade_rounded, 'Calificaciones', rama: 4),
  _Seccion(Icons.assessment_outlined, Icons.assessment_rounded, 'Reportes', rama: 5),
];
const _docencia = [
  _Seccion(Icons.fact_check_outlined, Icons.fact_check_rounded, 'Asistencia', rama: 6),
  _Seccion(Icons.punch_clock_outlined, Icons.punch_clock_rounded, 'Jornada', rama: 7),
  _Seccion(Icons.history_outlined, Icons.history_rounded, 'Historial', rama: 8),
];
const _cuenta = [
  _Seccion(Icons.badge_outlined, Icons.badge_rounded, 'Mi perfil', ruta: AppRoutes.perfil),
  _Seccion(Icons.tune_outlined, Icons.tune_rounded, 'Ajustes', ruta: AppRoutes.ajustes),
];

/// Barra inferior del teléfono: secciones de uso diario + "Más".
const _barra = [
  _Seccion(Icons.space_dashboard_outlined, Icons.space_dashboard_rounded, 'Inicio', rama: 0),
  _Seccion(Icons.menu_book_outlined, Icons.menu_book_rounded, 'Cursos', rama: 1),
  _Seccion(Icons.school_outlined, Icons.school_rounded, 'Estudiantes', rama: 2),
  _Seccion(Icons.grade_outlined, Icons.grade_rounded, 'Notas', rama: 4),
];

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  void _ir(BuildContext context, _Seccion seccion) {
    final rama = seccion.rama;
    if (rama != null) {
      navigationShell.goBranch(rama, initialLocation: rama == navigationShell.currentIndex);
    } else {
      context.pushNamed(seccion.ruta!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    if (ancho >= anchoMenuLateral) {
      return Scaffold(
        body: Row(
          children: [
            _MenuLateral(
              extendido: ancho >= anchoMenuExtendido,
              actual: navigationShell.currentIndex,
              onSeleccion: (s) => _ir(context, s),
            ),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }
    final enBarra = _barra.indexWhere((s) => s.rama == navigationShell.currentIndex);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        // Las secciones que solo están en "Más" encienden "Más".
        selectedIndex: enBarra < 0 ? _barra.length : enBarra,
        onDestinationSelected: (i) {
          if (i == _barra.length) {
            _mostrarMas(context);
          } else {
            _ir(context, _barra[i]);
          }
        },
        destinations: [
          for (final s in _barra)
            NavigationDestination(icon: Icon(s.icono), selectedIcon: Icon(s.iconoActivo), label: s.texto),
          const NavigationDestination(
            icon: Icon(Icons.apps_rounded),
            selectedIcon: Icon(Icons.apps_rounded),
            label: 'Más',
          ),
        ],
      ),
    );
  }

  /// Hoja inferior con todas las secciones en cuadrícula.
  void _mostrarMas(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (hoja) {
        final tokens = hoja.tokens;
        Widget grupo(String titulo, List<_Seccion> secciones) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                  child: Text(
                    titulo.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w800,
                      color: tokens.textSecondary,
                    ),
                  ),
                ),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.15,
                  children: [
                    for (final s in secciones)
                      _BotonSeccion(
                        seccion: s,
                        activa: s.rama != null && s.rama == navigationShell.currentIndex,
                        onTap: () {
                          Navigator.of(hoja).pop();
                          _ir(context, s);
                        },
                      ),
                  ],
                ),
              ],
            );
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                grupo('Académico', _academico),
                grupo('Docencia', _docencia),
                grupo('Cuenta', _cuenta),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BotonSeccion extends StatelessWidget {
  final _Seccion seccion;
  final bool activa;
  final VoidCallback onTap;

  const _BotonSeccion({required this.seccion, required this.activa, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = activa ? context.colors.secondary : context.colors.primary;
    return Material(
      color: activa ? color.withValues(alpha: 0.14) : tokens.surfaceMuted,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(activa ? seccion.iconoActivo : seccion.icono, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              seccion.texto,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: tokens.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Menú lateral oscuro de escritorio y web: marca, grupos de secciones y
/// el pie con el docente, el tema y cerrar sesión.
class _MenuLateral extends StatelessWidget {
  final bool extendido;
  final int actual;
  final ValueChanged<_Seccion> onSeleccion;

  const _MenuLateral({required this.extendido, required this.actual, required this.onSeleccion});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final docente = context.watch<AuthProvider>().docente;
    final tema = context.watch<TemaProvider>();
    const claro = Colors.white;
    final tenue = claro.withValues(alpha: 0.6);

    Widget titulo(String texto) => extendido
        ? Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
            child: Text(
              texto.toUpperCase(),
              style: TextStyle(fontSize: 11, letterSpacing: 1.3, fontWeight: FontWeight.w800, color: tenue),
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 22),
            child: Divider(color: claro.withValues(alpha: 0.15), height: 1),
          );

    return Container(
      width: extendido ? 256 : 84,
      color: tokens.sidebar,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(extendido ? 20 : 0, 20, extendido ? 20 : 0, 8),
              child: Row(
                mainAxisAlignment: extendido ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: context.colors.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_stories_rounded, color: Colors.white),
                  ),
                  if (extendido) ...[
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        AppStrings.appName,
                        style: TextStyle(color: claro, fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  titulo('Académico'),
                  for (final s in _academico) _ItemMenu(s, extendido, s.rama == actual, onSeleccion),
                  titulo('Docencia'),
                  for (final s in _docencia) _ItemMenu(s, extendido, s.rama == actual, onSeleccion),
                  titulo('Cuenta'),
                  for (final s in _cuenta) _ItemMenu(s, extendido, false, onSeleccion),
                ],
              ),
            ),
            Divider(color: claro.withValues(alpha: 0.15), height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: extendido
                  ? Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: claro.withValues(alpha: 0.15),
                          child: Text(
                            docente.iniciales,
                            style: const TextStyle(color: claro, fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            docente.nombreCompleto,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: claro, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                        _BotonPie(
                          icono: tema.oscuro ? Icons.wb_sunny_outlined : Icons.nightlight_outlined,
                          tooltip: tema.oscuro ? 'Modo claro' : 'Modo oscuro',
                          onTap: () => tema.cambiar(tema.oscuro ? ThemeMode.light : ThemeMode.dark),
                        ),
                        _BotonPie(
                          icono: Icons.logout_rounded,
                          tooltip: 'Cerrar sesión',
                          onTap: () => context.read<AuthProvider>().logout(),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _BotonPie(
                          icono: tema.oscuro ? Icons.wb_sunny_outlined : Icons.nightlight_outlined,
                          tooltip: tema.oscuro ? 'Modo claro' : 'Modo oscuro',
                          onTap: () => tema.cambiar(tema.oscuro ? ThemeMode.light : ThemeMode.dark),
                        ),
                        _BotonPie(
                          icono: Icons.logout_rounded,
                          tooltip: 'Cerrar sesión',
                          onTap: () => context.read<AuthProvider>().logout(),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  final _Seccion seccion;
  final bool extendido;
  final bool activo;
  final ValueChanged<_Seccion> onSeleccion;

  const _ItemMenu(this.seccion, this.extendido, this.activo, this.onSeleccion);

  @override
  Widget build(BuildContext context) {
    const claro = Colors.white;
    final acento = context.colors.secondary;
    final icono = Icon(
      activo ? seccion.iconoActivo : seccion.icono,
      color: activo ? claro : claro.withValues(alpha: 0.72),
      size: 22,
    );
    final contenido = Container(
      height: 44,
      padding: EdgeInsets.symmetric(horizontal: extendido ? 14 : 0),
      decoration: BoxDecoration(
        color: activo ? acento.withValues(alpha: 0.9) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: extendido
          ? Row(
              children: [
                icono,
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    seccion.texto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: activo ? claro : claro.withValues(alpha: 0.85),
                      fontWeight: activo ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            )
          : Center(child: icono),
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: extendido ? 12 : 14, vertical: 2),
      child: Tooltip(
        message: extendido ? '' : seccion.texto,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onSeleccion(seccion),
            child: Semantics(label: seccion.texto, selected: activo, button: true, child: contenido),
          ),
        ),
      ),
    );
  }
}

class _BotonPie extends StatelessWidget {
  final IconData icono;
  final String tooltip;
  final VoidCallback onTap;

  const _BotonPie({required this.icono, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icono, color: Colors.white.withValues(alpha: 0.8)),
      );
}
