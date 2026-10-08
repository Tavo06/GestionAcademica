import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/tema_provider.dart';

/// Barra superior de las secciones: franja con degradado y círculos
/// decorativos superpuestos ([Stack] + [Positioned]), título y subtítulo en
/// blanco, y acciones.
class EncabezadoSeccion extends StatelessWidget implements PreferredSizeWidget {
  final String titulo;
  final String? subtitulo;
  final Widget? leading;
  final List<Widget>? acciones;

  const EncabezadoSeccion({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.leading,
    this.acciones,
  });

  static const double _alto = 76;

  @override
  Size get preferredSize => const Size.fromHeight(_alto);

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final ancho = MediaQuery.sizeOf(context).width;
    final subtitulo = ancho >= 360 ? this.subtitulo : null;
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(gradient: tokens.gradient),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -40,
              child: _Circulo(diametro: 140, color: Colors.white.withValues(alpha: 0.07)),
            ),
            Positioned(
              right: 90,
              bottom: -50,
              child: _Circulo(diametro: 90, color: context.colors.secondary.withValues(alpha: 0.35)),
            ),
            SafeArea(
              bottom: false,
              child: SizedBox(
                height: _alto,
                child: IconTheme(
                  data: const IconThemeData(color: Colors.white),
                  child: Row(
                    children: [
                      if (leading != null) leading! else const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titulo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            if (subtitulo != null)
                              Text(
                                subtitulo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.white.withValues(alpha: 0.82),
                                ),
                              ),
                          ],
                        ),
                      ),
                      ...?acciones,
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Circulo extends StatelessWidget {
  final double diametro;
  final Color color;

  const _Circulo({required this.diametro, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: diametro,
        height: diametro,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

/// Tarjeta destacada (inicio, detalle de curso o estudiante, reporte):
/// degradado, círculo decorativo y una [insignia] opcional que se superpone
/// en la esquina superior derecha, todo con [Stack].
class BannerDestacado extends StatelessWidget {
  final Widget child;
  final Widget? insignia;

  const BannerDestacado({super.key, required this.child, this.insignia});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: tokens.gradient,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                right: -40,
                bottom: -60,
                child: _Circulo(diametro: 180, color: Colors.white.withValues(alpha: 0.06)),
              ),
              Positioned(
                left: -20,
                top: -30,
                child: _Circulo(diametro: 70, color: context.colors.secondary.withValues(alpha: 0.3)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(color: Colors.white),
                  child: IconTheme.merge(
                    data: const IconThemeData(color: Colors.white),
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (insignia != null) Positioned(top: -10, right: 16, child: insignia!),
      ],
    );
  }
}

/// Insignia de color para el [BannerDestacado] ("4 créditos", "Aprobado").
class Insignia extends StatelessWidget {
  final String texto;
  final IconData? icono;
  final Color? color;

  const Insignia({super.key, required this.texto, this.icono, this.color});

  @override
  Widget build(BuildContext context) {
    final fondo = color ?? context.tokens.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 14, color: Colors.black87),
            const SizedBox(width: 4),
          ],
          Text(
            texto,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

/// Número grande en blanco sobre los banners.
class DatoBanner extends StatelessWidget {
  final String valor;
  final String etiqueta;

  const DatoBanner({super.key, required this.valor, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          valor,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
        Text(etiqueta, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85))),
      ],
    );
  }
}

/// Cambia entre modo claro y oscuro al instante.
class TemaToggleButton extends StatelessWidget {
  const TemaToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = context.watch<TemaProvider>();
    return IconButton(
      tooltip: tema.oscuro ? 'Modo claro' : 'Modo oscuro',
      onPressed: () => tema.cambiar(tema.oscuro ? ThemeMode.light : ThemeMode.dark),
      icon: Icon(tema.oscuro ? Icons.wb_sunny_outlined : Icons.nightlight_outlined),
    );
  }
}

/// Avatar del docente con Mi perfil, Ajustes y Cerrar sesión.
class CuentaMenuButton extends StatelessWidget {
  const CuentaMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final docente = context.watch<AuthProvider>().docente;
    return PopupMenuButton<String>(
      tooltip: 'Mi cuenta',
      offset: const Offset(0, 48),
      icon: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: Text(
          docente.iniciales,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ),
      onSelected: (value) {
        switch (value) {
          case 'perfil':
            context.pushNamed(AppRoutes.perfil);
          case 'ajustes':
            context.pushNamed(AppRoutes.ajustes);
          case 'salir':
            context.read<AuthProvider>().logout();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Text(
            docente.nombreCompleto,
            style: TextStyle(fontWeight: FontWeight.w800, color: context.tokens.textPrimary),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'perfil',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.badge_outlined),
            title: Text('Mi perfil'),
          ),
        ),
        const PopupMenuItem(
          value: 'ajustes',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.tune_rounded),
            title: Text('Ajustes'),
          ),
        ),
        PopupMenuItem(
          value: 'salir',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout_rounded, color: context.tokens.error),
            title: const Text('Cerrar sesión'),
          ),
        ),
      ],
    );
  }
}

/// Acciones estándar de las secciones principales.
List<Widget> accionesSeccion() => const [TemaToggleButton(), CuentaMenuButton()];

/// Atrás para pantallas abiertas con `push`, o ir al Inicio cuando no hay
/// a dónde volver (por ejemplo, al recargar la página en web).
class VolverButton extends StatelessWidget {
  const VolverButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      return IconButton(
        tooltip: 'Volver',
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back_rounded),
      );
    }
    return IconButton(
      onPressed: () => context.goNamed(AppRoutes.inicio),
      icon: const Icon(Icons.home_outlined),
      tooltip: 'Ir a Inicio',
    );
  }
}
