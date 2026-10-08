import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

/// Last step of sign-up: the session is closed so the teacher signs in again
/// with the password they just created.
class RegistrationCompleteScreen extends StatelessWidget {
  const RegistrationCompleteScreen({super.key});

  static const _pasos = ['Datos registrados', 'Correo verificado', 'Celular verificado', 'Contraseña creada'];

  @override
  Widget build(BuildContext context) {
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
              Center(
                child: AuthIconBadge(icon: Icons.check_circle_rounded, color: tokens.success),
              ),
              const SizedBox(height: 16),
              Text(
                '¡Cuenta creada!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: tokens.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Tu contraseña ha sido configurada correctamente. Inicia sesión '
                'con tu correo y tu nueva contraseña.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: tokens.textSecondary, height: 1.45),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: tokens.surfaceMuted, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  children: [
                    for (var i = 0; i < _pasos.length; i++)
                      Padding(
                        padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded, size: 20, color: tokens.success),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(_pasos[i], style: TextStyle(fontSize: 13.5, color: tokens.textPrimary)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'Ir a iniciar sesión',
                loadingLabel: 'Ir a iniciar sesión',
                icon: Icons.login_rounded,
                loading: false,
                onPressed: () => context.read<AuthProvider>().logout(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
