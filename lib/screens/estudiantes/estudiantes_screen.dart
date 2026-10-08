import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/estudiante.dart';
import '../../providers/academico_provider.dart';
import '../../widgets/academicos.dart';
import '../../widgets/comunes.dart';
import '../../widgets/encabezado.dart';
import 'estudiante_form_dialog.dart';

enum _Filtro { todos, matriculados, sinCursos }

/// Listado de estudiantes con búsqueda y filtro (estado local con
/// setState). Al tocar uno se abre su detalle enviándole el objeto.
class EstudiantesScreen extends StatefulWidget {
  const EstudiantesScreen({super.key});

  @override
  State<EstudiantesScreen> createState() => _EstudiantesScreenState();
}

class _EstudiantesScreenState extends State<EstudiantesScreen> {
  String _busqueda = '';
  _Filtro _filtro = _Filtro.todos;

  Future<void> _nuevo() async {
    final creado = await showEstudianteFormDialog(context);
    if (creado != null && mounted) {
      showMessage(context, '${creado.nombreVisible} registrado.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EncabezadoSeccion(
        titulo: 'Estudiantes',
        subtitulo: 'Registro de tus estudiantes',
        acciones: accionesSeccion(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevo,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Nuevo estudiante'),
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
            final todos = academico.estudiantes;
            if (todos.isEmpty) {
              return PageList(children: [
                EmptyState(
                  icon: Icons.school_rounded,
                  title: 'Sin estudiantes',
                  message: 'Registra a tus estudiantes y luego matricúlalos en tus cursos.',
                  action: FilledButton.icon(
                    onPressed: _nuevo,
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Nuevo estudiante'),
                  ),
                ),
              ]);
            }

            final visibles = <Estudiante>[
              for (final e in todos)
                if (e.coincide(_busqueda))
                  if (switch (_filtro) {
                    _Filtro.todos => true,
                    _Filtro.matriculados => academico.cursosDe(e.id).isNotEmpty,
                    _Filtro.sinCursos => academico.cursosDe(e.id).isEmpty,
                  })
                    e,
            ];

            return PageList(
              bottom: 96,
              children: [
                BuscadorField(
                  hint: 'Buscar por nombre, código o correo',
                  onChanged: (v) => setState(() => _busqueda = v),
                ),
                const SizedBox(height: 12),
                SegmentedButton<_Filtro>(
                  segments: const [
                    ButtonSegment(value: _Filtro.todos, label: Text('Todos')),
                    ButtonSegment(value: _Filtro.matriculados, label: Text('Con cursos')),
                    ButtonSegment(value: _Filtro.sinCursos, label: Text('Sin cursos')),
                  ],
                  selected: {_filtro},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _filtro = s.first),
                ),
                const SizedBox(height: 12),
                Text(
                  '${visibles.length} de ${todos.length} estudiantes',
                  style: TextStyle(color: tokens.textSecondary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                if (visibles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'Ningún estudiante coincide con el filtro.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: tokens.textSecondary),
                    ),
                  ),
                for (final estudiante in visibles)
                  EstudianteTile(
                    estudiante: estudiante,
                    detalle: [
                      estudiante.codigo,
                      if (estudiante.correo != null) estudiante.correo!,
                    ].join(' · '),
                    onTap: () => context.abrirEstudiante(estudiante),
                    extra: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (academico.cursosDe(estudiante.id).isEmpty)
                          StatusChip(label: 'Sin cursos', color: tokens.textSecondary)
                        else
                          for (final curso in academico.cursosDe(estudiante.id))
                            StatusChip(label: curso.codigo, color: context.colors.primary),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
