import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isChecking = false;
  bool _isResending = false;

  /// Result of the last check / resend, shown inside the card.
  String? _message;
  AuthMessageType _messageType = AuthMessageType.info;

  void _showMessage(String message, AuthMessageType type) {
    setState(() {
      _message = message;
      _messageType = type;
    });
  }

  Future<void> _handleCheck() async {
    setState(() {
      _isChecking = true;
      _message = null;
    });
    try {
      final verified = await context.read<AuthProvider>().checkEmailVerified();
      // When verified, the router moves on to "Crear contraseña".
      if (!verified && mounted) {
        _showMessage(
          'Tu correo aún no está verificado. Abre el enlace que te enviamos '
          'y vuelve a intentarlo.',
          AuthMessageType.info,
        );
      }
    } on AuthFailure catch (e) {
      if (mounted) _showMessage(e.message, AuthMessageType.error);
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _handleResend() async {
    setState(() {
      _isResending = true;
      _message = null;
    });
    try {
      await context.read<AuthProvider>().resendVerificationEmail();
      if (mounted) {
        _showMessage('Te enviamos un nuevo correo de verificación.', AuthMessageType.success);
      }
    } on AuthFailure catch (e) {
      if (mounted) _showMessage(e.message, AuthMessageType.error);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthProvider>().email;
    final tokens = context.tokens;

    return AuthPage(
      builder: (context, ancho) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: AuthCard(
          compacta: ancho < anchoCompacto,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: AuthStepChip(paso: 2, texto: 'Verificación')),
              const SizedBox(height: 20),
              const Center(child: AuthIconBadge(icon: Icons.mark_email_unread_outlined)),
              const SizedBox(height: 16),
              Text(
                'Verifica tu correo',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: tokens.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Hemos enviado un correo de verificación a:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: tokens.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: tokens.surfaceMuted, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mail_outline_rounded, size: 20, color: context.colors.primary),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        email,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: tokens.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Revisa tu bandeja de entrada (y la carpeta de spam) y '
                'confirma tu correo. Luego pulsa el botón de abajo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: tokens.textSecondary, height: 1.45),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                child: _message == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: AuthMessage(_message!, type: _messageType),
                      ),
              ),
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'Ya verifiqué mi correo',
                loadingLabel: 'Comprobando...',
                icon: Icons.verified_outlined,
                loading: _isChecking,
                onPressed: _handleCheck,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isResending ? null : _handleResend,
                icon: _isResending
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2))
                    : const Icon(Icons.refresh_rounded, size: 20),
                label: Text(_isResending ? 'Enviando...' : 'Reenviar correo'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.read<AuthProvider>().logout(),
                style: TextButton.styleFrom(foregroundColor: tokens.textSecondary),
                child: const Text('Cancelar y volver al inicio de sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
