import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/matricula.dart';
import '../../providers/academico_provider.dart';
import '../../services/academico_service.dart';
import '../../widgets/comunes.dart';
import '../../widgets/encabezado.dart';

/// Listado de matrículas con filtro por curso y por estado (setState).
class MatriculasScreen extends StatefulWidget {
  const MatriculasScreen({super.key});

  @override
  State<MatriculasScreen> createState() => _MatriculasScreenState();
}

class _MatriculasScreenState extends State<MatriculasScreen> {
  String? _cursoId;
  EstadoMatricula? _estado = EstadoMatricula.activa;

  Future<void> _nueva() async {
    final cursoId = _cursoId;
    final curso = cursoId == null ? null : context.read<AcademicoProvider>().cursoPorId(cursoId);
    final r = await context.abrirMatricula(curso: curso);
    if (r != null && mounted) {
      showMessage(context, '${r.cantidad} ${r.cantidad == 1 ? 'matrícula registrada' : 'matrículas registradas'} en ${r.curso.nombre}.');
    }
  }

  Future<void> _cambiarEstado(Matricula m) async {
    final academico = context.read<AcademicoProvider>();
    try {
      if (m.activa) {
        final ok = await confirmar(
          context,
          titulo: 'Retirar matrícula',
          mensaje: 'El estudiante dejará el curso. Sus notas y asistencia se conservan.',
          accion: 'Retirar',
        );
        if (!ok) return;
        await academico.retirar(m);
        if (mounted) showMessage(context, 'Matrícula retirada.');
      } else {
        await academico.matricular(m.cursoId, {m.estudianteId});
        if (mounted) showMessage(context, 'Matrícula reactivada.');
      }
    } on AcademicoFailure catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EncabezadoSeccion(
        titulo: 'Matrículas',
        subtitulo: 'Estudiantes inscritos en cada curso',
        acciones: accionesSeccion(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nueva,
        icon: const Icon(Icons.how_to_reg_rounded),
        label: const Text('Matricular'),
      ),
      body: SafeArea(
        top: false,
        child: Consumer<AcademicoProvider>(
          builder: (context, academico, _) {
            if (academico.cargando) return const CargandoView();
            if (academico.error != null) {
              return LoadErrorView(message: academico.error!, onRetry: academico.reintentar);
            }
            final tokens = context.tokens;
            final filtradas = academico.matriculas
                .where((m) => (_cursoId == null || m.cursoId == _cursoId) && (_estado == null || m.estado == _estado))
                .toList();
            // Conteo por curso con un Map.
            final porCurso = <String, int>{};
            for (final m in filtradas) {
              porCurso[m.cursoId] = (porCurso[m.cursoId] ?? 0) + 1;
            }

            return PageList(
              bottom: 96,
              children: [
                DropdownButtonFormField<String?>(
                  initialValue: _cursoId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Curso', prefixIcon: Icon(Icons.filter_list_rounded)),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Todos los cursos')),
                    for (final c in academico.cursos)
                      DropdownMenuItem<String?>(value: c.id, child: Text(c.titulo, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (id) => setState(() => _cursoId = id),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final (estado, texto) in [
                      (EstadoMatricula.activa, 'Activas'),
                      (EstadoMatricula.retirada, 'Retiradas'),
                      (null, 'Todas'),
                    ])
                      ChoiceChip(
                        label: Text(texto),
                        selected: _estado == estado,
                        onSelected: (_) => setState(() => _estado = estado),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${filtradas.length} matrículas'
                  '${_cursoId == null && porCurso.isNotEmpty ? ' en ${porCurso.length} cursos' : ''}',
                  style: TextStyle(color: tokens.textSecondary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                if (filtradas.isEmpty)
                  EmptyState(
                    icon: Icons.how_to_reg_rounded,
                    title: 'Sin matrículas',
                    message: 'Matricula estudiantes en tus cursos para tomar asistencia y registrar notas.',
                    action: FilledButton.icon(
                      onPressed: _nueva,
                      icon: const Icon(Icons.how_to_reg_rounded),
                      label: const Text('Matricular'),
                    ),
                  )
                else
                  for (final m in filtradas)
                    Builder(builder: (context) {
                      final estudiante = academico.estudiantePorId(m.estudianteId)!;
                      final curso = academico.cursoPorId(m.cursoId)!;
                      final color = m.activa ? tokens.success : tokens.textSecondary;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: Container(
                            decoration: BoxDecoration(border: Border(left: BorderSide(color: color, width: 4))),
                            child: ListTile(
                              onTap: () => context.abrirEstudiante(estudiante, curso: curso),
                              title: Text(estudiante.nombreVisible, style: const TextStyle(fontWeight: FontWeight.w800)),
                              subtitle: Text('${curso.titulo}\n${m.estado.etiqueta} desde ${formatFechaCorta(m.fecha)}'),
                              isThreeLine: true,
                              trailing: TextButton(
                                onPressed: () => _cambiarEstado(m),
                                child: Text(m.activa ? 'Retirar' : 'Reactivar'),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
              ],
            );
          },
        ),
      ),
    );
  }
}
