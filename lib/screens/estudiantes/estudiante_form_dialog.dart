import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/validators/validators.dart';
import '../../models/estudiante.dart';
import '../../providers/academico_provider.dart';
import '../../services/academico_service.dart';

/// Formulario de estudiante en un diálogo. Sin [estudiante] lo crea; con
/// [estudiante] edita sus datos. Devuelve el [Estudiante] guardado, o null.
Future<Estudiante?> showEstudianteFormDialog(BuildContext context, {Estudiante? estudiante}) =>
    showDialog<Estudiante>(
      context: context,
      builder: (_) => _EstudianteFormDialog(estudiante: estudiante),
    );

class _EstudianteFormDialog extends StatefulWidget {
  final Estudiante? estudiante;

  const _EstudianteFormDialog({this.estudiante});

  @override
  State<_EstudianteFormDialog> createState() => _EstudianteFormDialogState();
}

class _EstudianteFormDialogState extends State<_EstudianteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _codigoController = TextEditingController(
    text: widget.estudiante?.codigo ??
        sugerirCodigoEstudiante(context.read<AcademicoProvider>().estudiantes),
  );
  late final _nombresController = TextEditingController(text: widget.estudiante?.nombres);
  late final _apellidosController = TextEditingController(text: widget.estudiante?.apellidos);
  late final _correoController = TextEditingController(text: widget.estudiante?.correo);
  bool _guardando = false;
  String? _error;

  bool get _editando => widget.estudiante != null;

  @override
  void dispose() {
    _codigoController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    final datos = DatosEstudiante(
      codigo: _codigoController.text,
      nombres: _nombresController.text,
      apellidos: _apellidosController.text,
      correo: _correoController.text,
    );
    final academico = context.read<AcademicoProvider>();
    try {
      final Estudiante guardado;
      if (_editando) {
        await academico.actualizarEstudiante(widget.estudiante!.id, datos);
        guardado = widget.estudiante!.copyWith(
          codigo: datos.codigo.trim().toUpperCase(),
          nombres: datos.nombres.trim(),
          apellidos: datos.apellidos.trim(),
          correo: datos.correo?.trim(),
        );
      } else {
        guardado = await academico.crearEstudiante(datos);
      }
      if (mounted) Navigator.of(context).pop(guardado);
    } on AcademicoFailure catch (e) {
      if (mounted) {
        setState(() {
          _guardando = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AlertDialog(
      title: Text(_editando ? 'Editar estudiante' : 'Nuevo estudiante'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _codigoController,
                  maxLength: 20,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Código', prefixIcon: Icon(Icons.tag_rounded)),
                  validator: (v) => Validators.required(v, field: 'El código'),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _nombresController,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nombres'),
                  validator: (v) => Validators.required(v, field: 'El nombre'),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _apellidosController,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Apellidos'),
                  validator: (v) => Validators.required(v, field: 'Los apellidos'),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Correo (opcional)'),
                  validator: (v) => v == null || v.trim().isEmpty ? null : Validators.email(v),
                ),
                if (!_editando) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Después podrás matricularlo en tus cursos.',
                    style: TextStyle(fontSize: 12.5, color: tokens.textSecondary),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: TextStyle(color: tokens.error)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
