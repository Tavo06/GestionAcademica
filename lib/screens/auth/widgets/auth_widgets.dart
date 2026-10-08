import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Width below which auth screens use tighter spacing (small phones).
const double anchoCompacto = 400;

/// Page of the auth flow (login, verify email, create password): soft
/// tinted background, centered scrollable content and a quick fade-in.
/// [builder] receives the available width to adapt the layout.
class AuthPage extends StatelessWidget {
  final Widget Function(BuildContext context, double ancho) builder;

  const AuthPage({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fondo = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.6],
            colors: [
              Color.alphaBlend(colors.primary.withValues(alpha: context.isDark ? 0.12 : 0.07), fondo),
              fondo,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final ancho = constraints.maxWidth;
              final compacto = ancho < anchoCompacto;
              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: compacto ? 16 : 24,
                    vertical: compacto ? 12 : 24,
                  ),
                  child: _Aparicion(child: builder(context, ancho)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Raised surface of the auth screens: rounded, thin border, soft shadow.
class AuthCard extends StatelessWidget {
  final bool compacta;
  final Widget child;

  const AuthCard({super.key, required this.compacta, required this.child});

  @override
  Widget build(BuildContext context) {
    final lateral = compacta ? 20.0 : 32.0;
    return Container(
      padding: EdgeInsets.fromLTRB(lateral, compacta ? 24 : 36, lateral, compacta ? 12 : 20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.tokens.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.35 : 0.06),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Quick fade and slide-up when an auth page first appears.
class _Aparicion extends StatelessWidget {
  final Widget child;

  const _Aparicion({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, valor, child) => Opacity(
        opacity: valor,
        child: Transform.translate(offset: Offset(0, 16 * (1 - valor)), child: child),
      ),
    );
  }
}

/// Opens an auth form (sign-up, password recovery) floating over the login:
/// the login stays visible behind a dimmed barrier, and the route never
/// changes.
Future<T?> showAuthDialog<T>(BuildContext context, WidgetBuilder builder) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: context.isDark ? 0.6 : 0.45),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, _, _) => builder(context),
    transitionBuilder: (context, animation, _, child) {
      final curva = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curva,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curva),
          child: child,
        ),
      );
    },
  );
}

/// Frame shared by the auth dialogs: close button, icon, title, subtitle and
/// a scrollable body so small phones and the keyboard never cut the form.
class AuthDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  /// False while a request is running, so the dialog can't be closed.
  final bool closable;

  const AuthDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.closable = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final ancho = MediaQuery.sizeOf(context).width;
    final lateral = ancho < 400 ? 20.0 : 28.0;

    return PopScope(
      canPop: closable,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        clipBehavior: Clip.antiAlias,
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: context.isDark ? 0.5 : 0.2),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(lateral, 12, lateral, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: 'Cerrar',
                    onPressed: closable ? () => Navigator.of(context).maybePop() : null,
                    icon: const Icon(Icons.close_rounded),
                    color: tokens.textSecondary,
                  ),
                ),
                Center(child: AuthIconBadge(icon: icon)),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.45, color: tokens.textSecondary),
                ),
                const SizedBox(height: 24),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Round tinted icon used at the top of the auth dialogs.
class AuthIconBadge extends StatelessWidget {
  final IconData icon;

  /// Defaults to the theme's primary color.
  final Color? color;

  const AuthIconBadge({super.key, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final primary = color ?? context.colors.primary;
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: context.isDark ? 0.18 : 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: primary, size: 30),
    );
  }
}

/// "Paso 2 de 4 · Verificación": where the teacher is in the sign-up
/// (1 datos, 2 correo, 3 celular, 4 contraseña).
class AuthStepChip extends StatelessWidget {
  static const totalPasos = 4;

  final int paso;
  final String texto;

  const AuthStepChip({super.key, required this.paso, required this.texto});

  @override
  Widget build(BuildContext context) {
    final primary = context.colors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: context.isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Paso $paso de $totalPasos · $texto',
        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: primary),
      ),
    );
  }
}

/// Gradient app mark of the login (theme colors, light and dark).
class AuthLogo extends StatelessWidget {
  final double size;

  const AuthLogo({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: tokens.gradient,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: tokens.gradientStart.withValues(alpha: context.isDark ? 0.45 : 0.3),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(Icons.auto_stories_rounded, color: Colors.white, size: size * 0.5),
    );
  }
}

/// Input style of the auth forms: rounded, tinted fill, icon and focus
/// border from the app theme.
InputDecoration authInputDecoration(
  BuildContext context, {
  required String label,
  required IconData icon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: context.tokens.surfaceMuted,
    errorMaxLines: 3,
  );
}

/// Peruvian mobile input: the "+51" is always shown before the field, so the
/// teacher only types the 9 digits.
InputDecoration authCelularDecoration(BuildContext context, {String? helperText}) {
  final tokens = context.tokens;
  return authInputDecoration(context, label: 'Celular (9 dígitos)', icon: Icons.smartphone_rounded)
      .copyWith(
    hintText: '9XXXXXXXX',
    helperText: helperText,
    prefixIcon: Padding(
      padding: const EdgeInsets.only(left: 12, right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.smartphone_rounded, color: tokens.textSecondary),
          const SizedBox(width: 8),
          Text(
            '+51',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: tokens.textPrimary),
          ),
        ],
      ),
    ),
  );
}

enum AuthMessageType { error, success, info }

/// Inline result of an auth request (Firebase error, confirmation or hint).
class AuthMessage extends StatelessWidget {
  final String message;
  final AuthMessageType type;

  const AuthMessage(this.message, {super.key, this.type = AuthMessageType.error});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final (color, icono) = switch (type) {
      AuthMessageType.error => (tokens.error, Icons.error_outline_rounded),
      AuthMessageType.success => (tokens.success, Icons.check_circle_outline_rounded),
      AuthMessageType.info => (tokens.info, Icons.info_outline_rounded),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: tokens.textPrimary, fontSize: 13.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Main action of the auth forms. While [loading] it stays colored, shows a
/// spinner with [loadingLabel] and ignores taps (no double submits).
class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final String loadingLabel;
  final IconData icon;
  final bool loading;
  final VoidCallback onPressed;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.loadingLabel,
    required this.icon,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 2,
        shadowColor: colors.primary.withValues(alpha: 0.4),
        disabledBackgroundColor: colors.primary.withValues(alpha: 0.75),
        disabledForegroundColor: colors.onPrimary,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: Row(
          key: ValueKey(loading),
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: colors.onPrimary),
              )
            else
              Icon(icon, size: 20),
            const SizedBox(width: 10),
            Flexible(
              child: Text(loading ? loadingLabel : label, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
