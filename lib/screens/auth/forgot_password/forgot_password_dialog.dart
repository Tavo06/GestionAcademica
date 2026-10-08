import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/validators/validators.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

/// Opens the password recovery over the login, prefilled with [initialEmail].
Future<void> showForgotPasswordDialog(BuildContext context, {String initialEmail = ''}) =>
    showAuthDialog<void>(context, (_) => ForgotPasswordDialog(initialEmail: initialEmail));

/// Sends Firebase's own password-reset email; the new password is set on
/// Firebase's hosted page, so no custom codes or mail services are involved.
class ForgotPasswordDialog extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordDialog({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController = TextEditingController(text: widget.initialEmail);

  bool _isSubmitting = false;
  String? _sentTo;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final correo = _emailController.text.trim();
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().sendPasswordResetEmail(correo);
      if (!mounted) return;
      setState(() => _sentTo = correo);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _sentTo = null;
        _error = e.message;
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AuthDialog(
      icon: Icons.key_rounded,
      title: 'Recuperar acceso',
      subtitle: 'Ingresa tu correo y te enviaremos un enlace para crear una '
          'nueva contraseña.',
      closable: !_isSubmitting,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              autofocus: widget.initialEmail.isEmpty,
              autofillHints: const [AutofillHints.email],
              enabled: !_isSubmitting,
              onFieldSubmitted: (_) => _handleSubmit(),
              decoration: authInputDecoration(
                context,
                label: 'Correo electrónico',
                icon: Icons.mail_outline_rounded,
              ),
              validator: Validators.email,
            ),
            if (_sentTo != null) ...[
              const SizedBox(height: 16),
              AuthMessage(
                'Si existe una cuenta con $_sentTo, recibirás un correo con el '
                'enlace. Después vuelve e inicia sesión con tu nueva contraseña.',
                type: AuthMessageType.success,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              AuthMessage(_error!),
            ],
            const SizedBox(height: 24),
            AuthPrimaryButton(
              label: _sentTo == null ? 'Enviar instrucciones' : 'Reenviar correo',
              loadingLabel: 'Enviando...',
              icon: Icons.send_rounded,
              loading: _isSubmitting,
              onPressed: _handleSubmit,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isSubmitting ? null : () => Navigator.of(context).maybePop(),
              style: TextButton.styleFrom(foregroundColor: tokens.textSecondary),
              child: Text(_sentTo == null ? 'Cancelar' : 'Volver al inicio de sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
