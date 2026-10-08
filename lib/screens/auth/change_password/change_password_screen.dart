import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/validators/validators.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Refresh the requirement checklist while typing.
    _newPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().createPassword(
            _newPasswordController.text,
          );
      // Keep the loading state: the router shows /registration-complete
      // as soon as the password is saved.
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = e.message;
      });
    }
  }

  Widget _toggle(bool oculta, VoidCallback onPressed) => IconButton(
        tooltip: oculta ? 'Mostrar contraseña' : 'Ocultar contraseña',
        icon: Icon(oculta ? Icons.visibility_outlined : Icons.visibility_off_outlined),
        onPressed: onPressed,
      );

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final password = _newPasswordController.text;

    return AuthPage(
      builder: (context, ancho) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: AuthCard(
          compacta: ancho < anchoCompacto,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: AuthStepChip(paso: 4, texto: 'Contraseña')),
                const SizedBox(height: 20),
                const Center(child: AuthIconBadge(icon: Icons.lock_outline_rounded)),
                const SizedBox(height: 16),
                Text(
                  'Crear contraseña',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: tokens.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu correo fue verificado. Crea la contraseña con la que '
                  'iniciarás sesión.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: tokens.textSecondary, height: 1.45),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNew,
                  enabled: !_isSubmitting,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: authInputDecoration(
                    context,
                    label: 'Nueva contraseña',
                    icon: Icons.lock_outline_rounded,
                    suffixIcon: _toggle(_obscureNew, () => setState(() => _obscureNew = !_obscureNew)),
                  ),
                  validator: Validators.newPassword,
                ),
                const SizedBox(height: 12),
                _Requisitos(password: password),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  enabled: !_isSubmitting,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  onFieldSubmitted: (_) => _handleSubmit(),
                  decoration: authInputDecoration(
                    context,
                    label: 'Confirmar contraseña',
                    icon: Icons.lock_reset_rounded,
                    suffixIcon: _toggle(
                      _obscureConfirm,
                      () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (value) => Validators.confirmPassword(
                    value,
                    _newPasswordController.text,
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  child: _error == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: AuthMessage(_error!),
                        ),
                ),
                const SizedBox(height: 24),
                AuthPrimaryButton(
                  label: 'Crear contraseña',
                  loadingLabel: 'Guardando...',
                  icon: Icons.check_rounded,
                  loading: _isSubmitting,
                  onPressed: _handleSubmit,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isSubmitting ? null : () => context.read<AuthProvider>().logout(),
                  style: TextButton.styleFrom(foregroundColor: tokens.textSecondary),
                  child: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Live checklist of the rules in [Validators.newPassword] (display only:
/// the validator still decides).
class _Requisitos extends StatelessWidget {
  final String password;

  const _Requisitos({required this.password});

  @override
  Widget build(BuildContext context) {
    final requisitos = [
      ('Mínimo 8 caracteres', password.length >= 8),
      ('Incluye letras', RegExp(r'[A-Za-zÁÉÍÓÚáéíóúÑñ]').hasMatch(password)),
      ('Incluye números', RegExp(r'\d').hasMatch(password)),
    ];
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        for (final (texto, cumple) in requisitos) _Requisito(texto: texto, cumple: cumple),
      ],
    );
  }
}

class _Requisito extends StatelessWidget {
  final String texto;
  final bool cumple;

  const _Requisito({required this.texto, required this.cumple});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = cumple ? tokens.success : tokens.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: Icon(
            cumple ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            key: ValueKey(cumple),
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(texto, style: TextStyle(fontSize: 12.5, color: color)),
      ],
    );
  }
}
