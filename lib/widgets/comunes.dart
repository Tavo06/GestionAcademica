import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';

/// Ancho máximo del contenido en tablet, escritorio y web.
const double anchoMaximoContenido = 1040;

/// Cuerpo desplazable de una página: márgenes de 16 en teléfono, centrado y
/// con ancho limitado en pantallas grandes.
class PageList extends StatelessWidget {
  final List<Widget> children;
  final double top;
  final double bottom;

  const PageList({super.key, required this.children, this.top = 16, this.bottom = 32});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final lateral = math.max(16.0, (constraints.maxWidth - anchoMaximoContenido) / 2);
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(lateral, top, lateral, bottom),
          children: children,
        );
      },
    );
  }
}

/// Celdas de igual alto en tantas columnas como quepan (cada una de al
/// menos [minAncho], como máximo [maxColumnas]).
class AdaptiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minAncho;
  final int maxColumnas;
  final double espacio;

  const AdaptiveGrid({super.key, required this.children, this.minAncho = 150, this.maxColumnas = 4, this.espacio = 12});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnas = math.max(
          1,
          math.min(maxColumnas, ((constraints.maxWidth + espacio) / (minAncho + espacio)).floor()),
        );
        final filas = <Widget>[];
        for (var i = 0; i < children.length; i += columnas) {
          filas.add(
            Padding(
              padding: EdgeInsets.only(bottom: i + columnas < children.length ? espacio : 0),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var j = 0; j < columnas; j++) ...[
                      if (j > 0) SizedBox(width: espacio),
                      Expanded(child: i + j < children.length ? children[i + j] : const SizedBox()),
                    ],
                  ],
                ),
              ),
            ),
          );
        }
        return Column(children: filas);
      },
    );
  }
}

/// Título de sección: barra de acento, texto en versalitas y acción opcional.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: subtitle == null ? 18 : 34,
            decoration: BoxDecoration(color: context.colors.secondary, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: tokens.textPrimary,
                  ),
                ),
                if (subtitle != null) Text(subtitle!, style: TextStyle(fontSize: 12.5, color: tokens.textSecondary)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Indicador numérico: número grande, etiqueta y un ícono en esquina.
class StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700, color: tokens.textPrimary),
                    ),
                    Text(label, style: TextStyle(fontSize: 12.5, color: tokens.textSecondary, height: 1.2)),
                  ],
                ),
              ),
              Icon(icon, color: color.withValues(alpha: 0.85), size: 26),
            ],
          ),
        ),
      ),
    );
  }
}

/// Etiqueta de color (estado, LDI, condición, puntualidad).
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusChip({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 4)],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra de progreso con etiqueta ("Sesiones dictadas · 10 / 16").
class ProgressLine extends StatelessWidget {
  final double value;
  final String label;
  final String detalle;
  final Color? color;

  const ProgressLine({super.key, required this.value, required this.label, required this.detalle, this.color});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final tono = color ?? context.colors.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 12.5, color: tokens.textSecondary)),
            ),
            Text(
              detalle,
              style: TextStyle(fontWeight: FontWeight.w800, color: tokens.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1).toDouble(),
            minHeight: 6,
            color: tono,
            backgroundColor: tono.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }
}

/// Avatar cuadrado redondeado con iniciales.
class InitialsAvatar extends StatelessWidget {
  final String text;
  final Color? color;
  final double size;

  const InitialsAvatar({super.key, required this.text, this.color, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final tono = color ?? context.colors.primary;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tono.withValues(alpha: context.isDark ? 0.24 : 0.14),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Text(
        text.isEmpty ? '?' : text,
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: size * 0.36, color: tono),
      ),
    );
  }
}

/// Línea ícono + texto usada en tarjetas ("Lunes, Miércoles", "08:00 - 10:00").
class InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const InfoLine({super.key, required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final tono = color ?? context.tokens.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: tono),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, color: tono)),
          ),
        ],
      ),
    );
  }
}

/// Estado vacío con ilustración (círculos superpuestos con [Stack]).
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 112,
            height: 96,
            child: Stack(
              children: [
                Positioned(
                  right: 0,
                  top: 0,
                  child: CircleAvatar(radius: 30, backgroundColor: colors.secondary.withValues(alpha: 0.18)),
                ),
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(icon, size: 38, color: colors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700, color: tokens.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: tokens.textSecondary, height: 1.4),
          ),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}

/// Carga fallida con opción de reintentar.
class LoadErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const LoadErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: 'Error al cargar',
      message: message,
      action: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Reintentar'),
      ),
    );
  }
}

/// Algo que no se puede mostrar (fue eliminado o el enlace no tiene un id
/// válido), con una salida clara.
class UnavailableView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String destino;
  final String destinoTexto;

  const UnavailableView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.destino,
    required this.destinoTexto,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: EmptyState(
        icon: icon,
        title: title,
        message: message,
        action: OutlinedButton.icon(
          onPressed: () => context.goNamed(destino),
          icon: const Icon(Icons.arrow_forward_rounded),
          label: Text(destinoTexto),
        ),
      ),
    );
  }
}

class CargandoView extends StatelessWidget {
  const CargandoView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 64),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Campo de búsqueda usado en los listados (filtro local con setState).
class BuscadorField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const BuscadorField({super.key, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(hintText: hint, prefixIcon: const Icon(Icons.search_rounded)),
      onChanged: onChanged,
    );
  }
}

void showMessage(BuildContext context, String mensaje, {bool error = false}) {
  final tokens = context.tokens;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: error ? tokens.error : null,
        content: Row(
          children: [
            Icon(error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(mensaje, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
}

Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  String accion = 'Eliminar',
  bool destructiva = true,
}) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: destructiva ? FilledButton.styleFrom(backgroundColor: context.tokens.error) : null,
          child: Text(accion),
        ),
      ],
    ),
  );
  return confirmado ?? false;
}
