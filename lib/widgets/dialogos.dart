import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/logic/horario.dart';
import '../core/theme/app_theme.dart';
import '../models/sesion.dart';
import '../providers/academico_provider.dart';
import '../services/academico_service.dart';
import 'comunes.dart';

/// Mueve una sesión de esta semana a otro día de la misma semana.
/// Devuelve true si la fecha cambió.
Future<bool> showCambiarFechaDialog(BuildContext context, Sesion sesion) async {
  final academico = context.read<AcademicoProvider>();
  final lunes = inicioSemana(academico.hoy);
  final seleccionada = await showDatePicker(
    context: context,
    initialDate: sesion.fecha,
    firstDate: lunes,
    lastDate: sumarDias(lunes, 6),
    helpText: 'Nueva fecha (semana actual)',
    cancelText: 'Cancelar',
    confirmText: 'Guardar',
  );
  if (seleccionada == null || soloFecha(seleccionada) == sesion.fecha) return false;
  try {
    await academico.cambiarFechaSesion(sesion, seleccionada);
    return true;
  } on HorarioNoDisponible catch (e) {
    if (context.mounted) await showHorarioNoDisponible(context, e);
  } on AcademicoFailure catch (e) {
    if (context.mounted) showMessage(context, e.message, error: true);
  }
  return false;
}

Future<void> showHorarioNoDisponible(BuildContext context, HorarioNoDisponible e) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(Icons.event_busy_rounded, color: context.tokens.error, size: 36),
      title: const Text('Horario no disponible'),
      content: Text(e.message, textAlign: TextAlign.center),
      actions: [FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Entendido'))],
    ),
  );
}

/// Confirmación tras guardar asistencia y aviso de quienes llegaron al LDI.
Future<void> mostrarResultadoAsistencia(BuildContext context, AsistenciaGuardada r) async {
  showMessage(
    context,
    'Asistencia guardada · Presentes: ${r.resumen.presentes} · '
    'Tardanzas: ${r.resumen.tardes} · Faltas: ${r.resumen.faltas}',
  );
  if (r.nuevosLdi.isEmpty) return;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(Icons.block_rounded, color: context.tokens.error, size: 36),
      title: const Text('LDI - Exceso de inasistencia'),
      content: Text(
        '${r.nuevosLdi.map((e) => e.nombreVisible).join(', ')} '
        '${r.nuevosLdi.length == 1 ? 'alcanzó' : 'alcanzaron'} el 30% o más de '
        'inasistencias en este curso. Desde la próxima sesión ya no se registrará '
        'su asistencia.',
        textAlign: TextAlign.center,
      ),
      actions: [FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Entendido'))],
    ),
  );
}
