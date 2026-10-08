import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/validators/validators.dart';
import '../../providers/academico_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/comunes.dart';
import '../../widgets/encabezado.dart';

/// Perfil del docente (la entidad Docente del sistema): edita sus datos;
/// el correo y el celular verificados son de solo lectura.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _docente = context.read<AuthProvider>().docente;
  late final _nombreController = TextEditingController(text: _docente.nombre);
  late final _apellidosController = TextEditingController(text: _docente.apellidos);
  late final _dniController = TextEditingController(text: _docente.dni);
  late DateTime? _fechaIngreso = _docente.fechaIngreso;
  bool _guardando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _dniController.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fechaIngreso ?? DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
      helpText: 'Fecha de ingreso',
    );
    if (elegida != null) setState(() => _fechaIngreso = elegida);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await context.read<AuthProvider>().updateProfile(
            nombre: _nombreController.text,
            apellidos: _apellidosController.text,
            dni: _dniController.text,
            fechaIngreso: _fechaIngreso,
          );
      if (mounted) showMessage(context, 'Perfil actualizado.');
    } on AuthFailure catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final docente = context.watch<AuthProvider>().docente;
    final academico = context.watch<AcademicoProvider>();
    final tokens = context.tokens;

    return Scaffold(
      appBar: const EncabezadoSeccion(titulo: 'Mi perfil', subtitulo: 'Datos del docente', leading: VolverButton()),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: PageList(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BannerDestacado(
                        insignia: const Insignia(texto: 'Docente', icono: Icons.school_rounded),
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                docente.iniciales,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    docente.nombreCompleto,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  Text(docente.correo),
                                  if (docente.fechaRegistro != null)
                                    Text(
                                      'Registrado el ${formatFechaCorta(docente.fechaRegistro!)}',
                                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                                    ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 24,
                                    children: [
                                      DatoBanner(valor: '${academico.cursos.length}', etiqueta: 'Cursos'),
                                      DatoBanner(valor: '${academico.estudiantes.length}', etiqueta: 'Estudiantes'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (docente.perfilIncompleto) ...[
                        const SizedBox(height: 16),
                        Card(
                          color: tokens.warning.withValues(alpha: 0.14),
                          child: ListTile(
                            leading: Icon(Icons.info_outline_rounded, color: tokens.warning),
                            title: const Text('Completa tus datos para terminar tu perfil.'),
                          ),
                        ),
                      ],
                      const SectionHeader(title: 'Cuenta'),
                      TextFormField(
                        initialValue: docente.correo,
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          helperText: 'Es tu usuario de acceso y no se puede cambiar.',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: docente.telefono ?? '',
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'Celular',
                          helperText: 'Verificado por SMS. No se puede cambiar aquí.',
                          prefixIcon: Icon(Icons.smartphone_rounded),
                        ),
                      ),
                      const SectionHeader(title: 'Datos personales'),
                      TextFormField(
                        controller: _nombreController,
                        textCapitalization: TextCapitalization.words,
                        inputFormatters: [LengthLimitingTextInputFormatter(80)],
                        decoration: const InputDecoration(labelText: 'Nombres', prefixIcon: Icon(Icons.person_outline_rounded)),
                        validator: (v) => Validators.required(v, field: 'El nombre'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _apellidosController,
                        textCapitalization: TextCapitalization.words,
                        inputFormatters: [LengthLimitingTextInputFormatter(80)],
                        decoration: const InputDecoration(labelText: 'Apellidos', prefixIcon: Icon(Icons.badge_outlined)),
                        validator: (v) => Validators.required(v, field: 'Los apellidos'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _dniController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                        decoration: const InputDecoration(labelText: 'DNI', prefixIcon: Icon(Icons.credit_card_rounded)),
                        validator: Validators.dni,
                      ),
                      const SizedBox(height: 12),
                      Material(
                        color: tokens.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                        child: ListTile(
                          leading: const Icon(Icons.event_outlined),
                          title: const Text('Fecha de ingreso (opcional)'),
                          subtitle: Text(_fechaIngreso == null ? 'Seleccionar' : formatFechaCorta(_fechaIngreso!)),
                          onTap: _elegirFecha,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _guardando ? null : _guardar,
                        icon: _guardando
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.save_rounded),
                        label: const Text('Guardar cambios'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
