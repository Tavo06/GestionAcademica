import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

/// Shown to a teacher whose internal `status` is `inactivo` (only changeable
/// from Firebase Console); the Firestore rules block their data as well.
class InactiveScreen extends StatelessWidget {
  const InactiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final email = context.watch<AuthProvider>().email;
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
                child: AuthIconBadge(icon: Icons.block_rounded, color: tokens.error),
              ),
              const SizedBox(height: 16),
              Text(
                'Cuenta deshabilitada',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: tokens.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Tu cuenta no está habilitada para usar el sistema.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: tokens.textSecondary, height: 1.45),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: tokens.surfaceMuted, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_outline_rounded, size: 20, color: tokens.textSecondary),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          email,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: tokens.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'Cerrar sesión',
                loadingLabel: 'Cerrar sesión',
                icon: Icons.logout_rounded,
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
