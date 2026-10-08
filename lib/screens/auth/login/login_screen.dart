import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/validators/validators.dart';
import '../../../providers/auth_provider.dart';
import '../forgot_password/forgot_password_dialog.dart';
import '../register/register_dialog.dart';
import '../widgets/auth_widgets.dart';

/// From this width the login shows a brand panel next to the form.
const double _anchoPanel = 960;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    final authState = context.read<AuthProvider>();
    try {
      await authState.login(
        correo: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Keep the loading state: the router redirect takes over as soon as
      // the Firestore profile finishes loading.
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = e.message;
      });
    }
  }

  void _handleForgotPassword() {
    showForgotPasswordDialog(context, initialEmail: _emailController.text.trim());
  }

  void _handleRegister() => showRegisterDialog(context);

  @override
  Widget build(BuildContext context) {
    final isSessionRestoring = context.watch<AuthProvider>().isLoggedIn;
    if (isSessionRestoring) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return AuthPage(
      builder: (context, ancho) {
        final conPanel = ancho >= _anchoPanel;
        final tarjeta = _LoginCard(
          compacta: ancho < anchoCompacto,
          mostrarMarca: !conPanel,
          formulario: _formulario(context),
        );
        if (!conPanel) {
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: tarjeta,
          );
        }
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(child: _PanelMarca()),
                const SizedBox(width: 40),
                SizedBox(width: 440, child: tarjeta),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _formulario(BuildContext context) {
    final tokens = context.tokens;
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              autofillHints: const [AutofillHints.email],
              decoration: authInputDecoration(
                context,
                label: 'Correo electrónico',
                icon: Icons.mail_outline_rounded,
              ),
              validator: Validators.email,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _handleLogin(),
              decoration: authInputDecoration(
                context,
                label: 'Contraseña',
                icon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Mostrar contraseña' : 'Ocultar contraseña',
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: Validators.password,
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isSubmitting ? null : _handleForgotPassword,
                child: const Text('¿Olvidaste tu contraseña?'),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              child: _error == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 12),
                      child: AuthMessage(_error!),
                    ),
            ),
            const SizedBox(height: 8),
            AuthPrimaryButton(
              label: 'Iniciar sesión',
              loadingLabel: 'Iniciando sesión...',
              icon: Icons.login_rounded,
              loading: _isSubmitting,
              onPressed: _handleLogin,
            ),
            const SizedBox(height: 24),
            Divider(height: 1, color: tokens.border),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('¿No tienes una cuenta?', style: TextStyle(color: tokens.textSecondary)),
                TextButton(
                  onPressed: _isSubmitting ? null : _handleRegister,
                  child: const Text('Crear cuenta'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Header and form of the login, on the shared auth card.
class _LoginCard extends StatelessWidget {
  final bool compacta;
  final bool mostrarMarca;
  final Widget formulario;

  const _LoginCard({
    required this.compacta,
    required this.mostrarMarca,
    required this.formulario,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AuthCard(
      compacta: compacta,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mostrarMarca) ...[
            Center(child: AuthLogo(size: compacta ? 56 : 72)),
            const SizedBox(height: 20),
            Text(
              AppStrings.appName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compacta ? 24 : 26,
                fontWeight: FontWeight.w800,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Bienvenido, inicia sesión para continuar',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: tokens.textSecondary),
            ),
          ] else ...[
            Text(
              'Bienvenido',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: tokens.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Inicia sesión con tu cuenta de docente.',
              style: TextStyle(fontSize: 14, color: tokens.textSecondary),
            ),
          ],
          SizedBox(height: compacta ? 24 : 32),
          formulario,
        ],
      ),
    );
  }
}

/// Desktop / web only: app name and what the app does, on the brand
/// gradient.
class _PanelMarca extends StatelessWidget {
  const _PanelMarca();

  static const _funciones = [
    (Icons.menu_book_rounded, 'Cursos con sesiones y horario automáticos'),
    (Icons.how_to_reg_rounded, 'Matrículas de estudiantes por curso'),
    (Icons.grade_rounded, 'Calificaciones con promedios ponderados'),
    (Icons.fact_check_rounded, 'Asistencia por sesión y control de LDI'),
    (Icons.assessment_rounded, 'Reportes por curso'),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    const blanco = Colors.white;
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: tokens.gradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: tokens.gradientStart.withValues(alpha: context.isDark ? 0.3 : 0.25),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: blanco.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.auto_stories_rounded, color: blanco, size: 32),
          ),
          const SizedBox(height: 28),
          const Text(
            AppStrings.appName,
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: blanco, height: 1.15),
          ),
          const SizedBox(height: 10),
          Text(
            AppStrings.appTagline,
            style: TextStyle(fontSize: 16, height: 1.5, color: blanco.withValues(alpha: 0.88)),
          ),
          const SizedBox(height: 32),
          for (final (icono, texto) in _funciones)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: blanco.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icono, color: blanco, size: 19),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      texto,
                      style: TextStyle(fontSize: 14.5, color: blanco.withValues(alpha: 0.92)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
