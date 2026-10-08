import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/curso.dart';
import '../../providers/academico_provider.dart';
import '../../services/academico_service.dart';
import '../../widgets/comunes.dart';
import '../../widgets/encabezado.dart';

/// Nueva matrícula: se elige el curso y se marcan los estudiantes (un
/// [Set] guarda la selección y evita duplicados). Recibe el curso y/o el
/// estudiante ya elegidos y, al confirmar, devuelve el [ResultadoMatricula]
/// con `context.pop(resultado)`.
class MatriculaScreen extends StatefulWidget {
  final String? cursoId;
  final String? estudianteId;

  const MatriculaScreen({super.key, this.cursoId, this.estudianteId});

  @override
  State<MatriculaScreen> createState() => _MatriculaScreenState();
}

class _MatriculaScreenState extends State<MatriculaScreen> {
  late String? _cursoId = widget.cursoId;
  late final Set<String> _seleccion = {?widget.estudianteId};
  String _busqueda = '';
  bool _guardando = false;
  String? _error;

  Future<void> _confirmar(Curso curso) async {
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final resultado = await context.read<AcademicoProvider>().matricular(curso.id, _seleccion);
      if (mounted) context.pop(resultado);
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
    final academico = context.watch<AcademicoProvider>();
    final tokens = context.tokens;
    final curso = _cursoId == null ? null : academico.cursoPorId(_cursoId!);

    Widget cuerpo;
    if (academico.cargando) {
      cuerpo = const CargandoView();
    } else if (academico.cursos.isEmpty || academico.estudiantes.isEmpty) {
      cuerpo = EmptyState(
        icon: Icons.how_to_reg_rounded,
        title: academico.cursos.isEmpty ? 'Primero crea un curso' : 'Primero registra estudiantes',
        message: 'Para matricular necesitas al menos un curso y un estudiante.',
        action: OutlinedButton(
          onPressed: () => context.goNamed(academico.cursos.isEmpty ? AppRoutes.cursos : AppRoutes.estudiantes),
          child: Text(academico.cursos.isEmpty ? 'Ir a Cursos' : 'Ir a Estudiantes'),
        ),
      );
    } else {
      final visibles = academico.estudiantes.where((e) => e.coincide(_busqueda)).toList();
      final nuevos = curso == null ? 0 : _seleccion.where((id) => !academico.estaMatriculado(curso.id, id)).length;
      cuerpo = Column(
        children: [
          Expanded(
            child: PageList(
              children: [
                const SectionHeader(title: '1. Curso'),
                DropdownButtonFormField<String>(
                  key: ValueKey(_cursoId),
                  initialValue: curso?.id,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Curso', prefixIcon: Icon(Icons.menu_book_outlined)),
                  items: [
                    for (final c in academico.cursos)
                      DropdownMenuItem(
                        value: c.id,
                        child: Text(c.titulo, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: _guardando ? null : (id) => setState(() => _cursoId = id),
                ),
                if (curso != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${academico.matriculadosEn(curso.id).length} matriculados · '
                    '${curso.diasTexto} · ${curso.horario}',
                    style: TextStyle(fontSize: 12.5, color: tokens.textSecondary),
                  ),
                ],
                const SectionHeader(title: '2. Estudiantes'),
                BuscadorField(hint: 'Buscar estudiante', onChanged: (v) => setState(() => _busqueda = v)),
                const SizedBox(height: 8),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (final e in visibles)
                        Builder(
                          builder: (context) {
                            final yaEsta = curso != null && academico.estaMatriculado(curso.id, e.id);
                            return CheckboxListTile(
                              value: yaEsta || _seleccion.contains(e.id),
                              onChanged: yaEsta || _guardando
                                  ? null
                                  : (v) => setState(() => v == true ? _seleccion.add(e.id) : _seleccion.remove(e.id)),
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(e.nombreVisible),
                              subtitle: Text(yaEsta ? '${e.codigo} · ya matriculado' : e.codigo),
                            );
                          },
                        ),
                      if (visibles.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Ningún estudiante coincide con la búsqueda.',
                            style: TextStyle(color: tokens.textSecondary),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(color: tokens.error, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: context.colors.surface,
                border: Border(top: BorderSide(color: tokens.border)),
              ),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: anchoMaximoContenido),
                  child: ElevatedButton.icon(
                    onPressed: curso == null || nuevos == 0 || _guardando ? null : () => _confirmar(curso),
                    icon: _guardando
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.how_to_reg_rounded),
                    label: Text(
                      curso == null
                          ? 'Elige un curso'
                          : nuevos == 0
                          ? 'Marca al menos un estudiante'
                          : 'Matricular $nuevos ${nuevos == 1 ? 'estudiante' : 'estudiantes'}',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: const EncabezadoSeccion(
        titulo: 'Nueva matrícula',
        subtitulo: 'Elige el curso y los estudiantes',
        leading: VolverButton(),
      ),
      body: SafeArea(top: false, child: cuerpo),
    );
  }
}
