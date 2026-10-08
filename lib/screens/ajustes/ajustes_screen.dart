import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/app_routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/logic/ldi.dart';
import '../../core/logic/notas.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tema_provider.dart';
import '../../widgets/comunes.dart';
import '../../widgets/encabezado.dart';

/// Apariencia (modo claro / oscuro en vivo), cuenta y reglas del sistema.
class AjustesScreen extends StatelessWidget {
  const AjustesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = context.watch<TemaProvider>();
    final tokens = context.tokens;

    Widget bloque(String titulo, List<Widget> hijos) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: titulo),
            Card(clipBehavior: Clip.antiAlias, child: Column(children: hijos)),
          ],
        );

    return Scaffold(
      appBar: const EncabezadoSeccion(titulo: 'Ajustes', subtitulo: 'Apariencia y cuenta', leading: VolverButton()),
      body: SafeArea(
        top: false,
        child: PageList(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    bloque('Apariencia', [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            for (final (modo, icono, texto) in [
                              (ThemeMode.light, Icons.wb_sunny_rounded, 'Claro'),
                              (ThemeMode.dark, Icons.nightlight_round, 'Oscuro'),
                            ])
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: _OpcionTema(
                                    icono: icono,
                                    texto: texto,
                                    activa: tema.modo == modo,
                                    oscura: modo == ThemeMode.dark,
                                    onTap: () => tema.cambiar(modo),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ]),
                    bloque('Cuenta', [
                      ListTile(
                        leading: Icon(Icons.badge_outlined, color: context.colors.primary),
                        title: const Text('Mi perfil'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.pushNamed(AppRoutes.perfil),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.logout_rounded, color: tokens.error),
                        title: Text('Cerrar sesión', style: TextStyle(color: tokens.error)),
                        onTap: () async {
                          final ok = await confirmar(
                            context,
                            titulo: 'Cerrar sesión',
                            mensaje: '¿Quieres cerrar tu sesión en este dispositivo?',
                            accion: 'Cerrar sesión',
                          );
                          if (ok && context.mounted) await context.read<AuthProvider>().logout();
                        },
                      ),
                    ]),
                    bloque('Reglas del sistema', [
                      ListTile(
                        leading: Icon(Icons.grade_outlined, color: context.colors.primary),
                        title: const Text('Escala de notas'),
                        subtitle: Text(
                          'Vigesimal de ${notaMinima.toInt()} a ${notaMaxima.toInt()}. Aprueba con '
                          '${formatNota(notaAprobatoria)} o más. Promedio ponderado por el peso de cada evaluación.',
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.block_outlined, color: context.colors.primary),
                        title: const Text('Límite de inasistencias (LDI)'),
                        subtitle: Text('$umbralLdi% de faltas sobre el total de sesiones del curso.'),
                      ),
                    ]),
                    bloque('Información', [
                      ListTile(
                        leading: Icon(Icons.info_outline_rounded, color: context.colors.primary),
                        title: const Text('Versión'),
                        trailing: Text(
                          AppStrings.appVersion,
                          style: TextStyle(color: tokens.textSecondary, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.auto_stories_outlined, color: context.colors.primary),
                        title: const Text('Acerca de'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => showAboutDialog(
                          context: context,
                          applicationName: AppStrings.appFullName,
                          applicationVersion: AppStrings.appVersion,
                          children: const [Text(AppStrings.appTagline)],
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Muestra en miniatura cómo se ve cada modo (Container + Stack).
class _OpcionTema extends StatelessWidget {
  final IconData icono;
  final String texto;
  final bool activa;
  final bool oscura;
  final VoidCallback onTap;

  const _OpcionTema({
    required this.icono,
    required this.texto,
    required this.activa,
    required this.oscura,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fondo = oscura ? const Color(0xFF162120) : const Color(0xFFF6F4EF);
    final barra = oscura ? const Color(0xFF115E59) : const Color(0xFF0F766E);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 84,
                decoration: BoxDecoration(
                  color: fondo,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: activa ? context.colors.secondary : context.tokens.border,
                    width: activa ? 2.5 : 1,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 22,
                  decoration: BoxDecoration(
                    color: barra,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                ),
              ),
              Positioned(left: 12, bottom: 14, child: Icon(icono, color: oscura ? Colors.white70 : Colors.black54)),
              if (activa)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Icon(Icons.check_circle_rounded, color: context.colors.secondary),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(texto, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
