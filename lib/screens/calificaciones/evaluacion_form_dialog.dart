import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/logic/horario.dart';
import '../../core/logic/notas.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/curso.dart';
import '../../models/evaluacion.dart';
import '../../providers/calificaciones_provider.dart';
import '../../services/academico_service.dart';
import '../../widgets/comunes.dart';

/// Crea una evaluación del [curso]. Devuelve la [Evaluacion] creada, o null.
Future<Evaluacion?> showEvaluacionFormDialog(BuildContext context, Curso curso) async {
  final creada = await showDialog<Evaluacion>(
    context: context,
    builder: (_) => _EvaluacionFormDialog(curso: curso),
  );
  if (creada != null && context.mounted) {
    showMessage(context, 'Evaluación "${creada.nombre}" creada (${creada.peso}%).');
  }
  return creada;
}

class _EvaluacionFormDialog extends StatefulWidget {
  final Curso curso;

  const _EvaluacionFormDialog({required this.curso});

  @override
  State<_EvaluacionFormDialog> createState() => _EvaluacionFormDialogState();
}

class _EvaluacionFormDialogState extends State<_EvaluacionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  late final int _usado = context.read<CalificacionesProvider>().pesoAsignado(widget.curso.id);
  late final _pesoController = TextEditingController(
    text: '${(pesoTotal - _usado).clamp(0, 20)}',
  );
  TipoEvaluacion _tipo = TipoEvaluacion.practica;
  DateTime _fecha = soloFecha(DateTime.now());
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _nombreController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Fecha de la evaluación',
    );
    if (elegida != null) setState(() => _fecha = soloFecha(elegida));
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final creada = await context.read<CalificacionesProvider>().crearEvaluacion(NuevaEvaluacion(
            cursoId: widget.curso.id,
            nombre: _nombreController.text,
            tipo: _tipo,
            peso: int.parse(_pesoController.text),
            fecha: _fecha,
          ));
      if (mounted) Navigator.of(context).pop(creada);
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
    final disponible = pesoTotal - _usado;
    return AlertDialog(
      title: Text('Nueva evaluación · ${widget.curso.codigo}'),
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
                  controller: _nombreController,
                  maxLength: 60,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Nombre', hintText: 'Práctica calificada 1'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa el nombre.' : null,
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<TipoEvaluacion>(
                  initialValue: _tipo,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: [
                    for (final t in TipoEvaluacion.values) DropdownMenuItem(value: t, child: Text(t.etiqueta)),
                  ],
                  onChanged: (t) => setState(() => _tipo = t ?? _tipo),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pesoController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                  decoration: InputDecoration(
                    labelText: 'Peso en el promedio (%)',
                    helperText: 'Disponible: $disponible % de $pesoTotal %',
                    suffixText: '%',
                  ),
                  validator: (v) => validarPeso(int.tryParse(v ?? '') ?? 0, _usado),
                ),
                const SizedBox(height: 12),
                Material(
                  color: tokens.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                  child: ListTile(
                    leading: const Icon(Icons.event_rounded),
                    title: const Text('Fecha'),
                    subtitle: Text(formatFechaLarga(_fecha, conAnio: true)),
                    onTap: _guardando ? null : _elegirFecha,
                  ),
                ),
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
          onPressed: _guardando || disponible <= 0 ? null : _guardar,
          child: _guardando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Crear'),
        ),
      ],
    );
  }
}
