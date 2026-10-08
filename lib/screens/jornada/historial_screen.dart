import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/logic/horario.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/jornada.dart';
import '../../providers/jornada_provider.dart';
import '../../widgets/academicos.dart';
import '../../widgets/comunes.dart';
import '../../widgets/encabezado.dart';

/// Historial de jornadas agrupado por día, con filtro de fechas (setState).
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  DateTimeRange? _rango;

  Future<void> _elegirRango() async {
    final elegido = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _rango,
      helpText: 'Filtrar por fechas',
      saveText: 'Aplicar',
    );
    if (elegido != null) setState(() => _rango = elegido);
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<JornadaProvider>();
    final rango = _rango;
    final registros = estado.jornadas.where((j) {
      if (rango == null) return true;
      return !j.fecha.isBefore(soloFecha(rango.start)) && !j.fecha.isAfter(soloFecha(rango.end));
    }).toList();
    final total = registros.fold<Duration>(Duration.zero, (s, j) => s + (j.duracion ?? Duration.zero));
    final grupos = agruparPorDia(registros);
    final tokens = context.tokens;

    return Scaffold(
      appBar: EncabezadoSeccion(
        titulo: 'Historial',
        subtitulo: 'Tus jornadas registradas',
        acciones: [
          IconButton(
            onPressed: _elegirRango,
            icon: const Icon(Icons.date_range_rounded),
            tooltip: 'Filtrar por fechas',
          ),
          ...accionesSeccion(),
        ],
      ),
      body: SafeArea(
        top: false,
        child: PageList(
          children: [
            if (rango != null)
              Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  label: Text('${formatFechaCorta(rango.start)} - ${formatFechaCorta(rango.end)}'),
                  onDeleted: () => setState(() => _rango = null),
                  deleteButtonTooltipMessage: 'Quitar filtro',
                ),
              ),
            if (estado.cargando)
              const CargandoView()
            else if (estado.error != null)
              LoadErrorView(message: estado.error!, onRetry: estado.reintentar)
            else if (registros.isEmpty)
              EmptyState(
                icon: Icons.history_rounded,
                title: 'Sin registros',
                message: rango == null ? 'Aún no hay jornadas registradas.' : 'No hay jornadas en ese rango.',
              )
            else ...[
              const SizedBox(height: 8),
              AdaptiveGrid(
                minAncho: 150,
                children: [
                  StatTile(
                    icon: Icons.event_available_rounded,
                    label: 'Jornadas',
                    value: '${registros.length}',
                    color: context.colors.primary,
                  ),
                  StatTile(
                    icon: Icons.timer_rounded,
                    label: 'Horas trabajadas',
                    value: formatDuracion(total),
                    color: context.colors.secondary,
                  ),
                ],
              ),
              for (final entrada in grupos.entries) ...[
                SectionHeader(title: formatFechaLarga(entrada.key, conAnio: true)),
                for (final j in entrada.value)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        j.cursoNombre,
                                        style: TextStyle(fontWeight: FontWeight.w800, color: tokens.textPrimary),
                                      ),
                                      Text(
                                        '${j.horaProgramadaInicio ?? ''} - ${j.horaProgramadaFin ?? ''} · '
                                        'Sesión ${j.sesionNumero}',
                                        style: TextStyle(fontSize: 12.5, color: tokens.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusChip(
                                  label: j.abierta ? 'Sin salida' : formatDuracion(j.duracion),
                                  color: j.abierta ? tokens.warning : tokens.success,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: MarcaTile(
                                    label: 'Entrada',
                                    hora: j.entrada,
                                    resultado: j.resultadoEntrada,
                                    icon: Icons.login_rounded,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: MarcaTile(
                                    label: 'Salida',
                                    hora: j.salida,
                                    resultado: j.resultadoSalida,
                                    icon: Icons.logout_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
