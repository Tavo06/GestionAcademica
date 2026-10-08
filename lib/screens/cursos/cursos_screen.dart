import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/texto.dart';
import '../../models/curso.dart';
import '../../providers/academico_provider.dart';
import '../../providers/calificaciones_provider.dart';
import '../../widgets/academicos.dart';
import '../../widgets/catalogo_cursos.dart';
import '../../widgets/comunes.dart';
import '../../widgets/encabezado.dart';

enum _Orden { nombre, codigo, matriculados }

enum _Estado { todos, enDictado, finalizados }

/// Listado de cursos con búsqueda, filtro por carrera y estado, y orden (estado local
/// con setState). Al tocar un curso se abre su detalle enviándole el objeto.
class CursosScreen extends StatefulWidget {
  const CursosScreen({super.key});

  @override
  State<CursosScreen> createState() => _CursosScreenState();
}

class _CursosScreenState extends State<CursosScreen> {
  String _busqueda = '';
  _Estado _estado = _Estado.todos;
  _Orden _orden = _Orden.nombre;

  /// Carrera elegida en el filtro; null muestra todas.
  String? _carrera;

  Future<void> _nuevo({PlantillaCurso? plantilla}) async {
    final creado = await context.crearCurso(plantilla: plantilla);
    if (creado != null && mounted) {
      showMessage(context, 'Curso ${creado.codigo} creado con ${creado.totalSesiones} sesiones.');
    }
  }

  /// Elige un curso del catálogo y abre el formulario con sus datos.
  Future<void> _desdeCatalogo() async {
    final academico = context.read<AcademicoProvider>();
    final elegido = await showCatalogoCursos(
      context,
      codigosUsados: {for (final c in academico.cursos) c.codigo},
      carreraInicial: _carrera,
    );
    if (elegido != null && mounted) await _nuevo(plantilla: elegido);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EncabezadoSeccion(
        titulo: 'Cursos',
        subtitulo: 'Tus cursos, horarios y sesiones',
        acciones: [
          IconButton(
            onPressed: _desdeCatalogo,
            icon: const Icon(Icons.auto_stories_rounded),
            tooltip: 'Catálogo de carreras',
          ),
          ...accionesSeccion(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevo,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo curso'),
      ),
      body: SafeArea(
        top: false,
        child: Consumer2<AcademicoProvider, CalificacionesProvider>(
          builder: (context, academico, calificaciones, _) {
            if (academico.cargando) return const CargandoView();
            if (academico.error != null) {
              return LoadErrorView(message: academico.error!, onRetry: academico.reintentar);
            }
            if (academico.cursos.isEmpty) {
              return PageList(
                children: [
                  EmptyState(
                    icon: Icons.menu_book_rounded,
                    title: 'Aún no tienes cursos',
                    message:
                        'Crea tu primer curso: sus sesiones se generan solas según '
                        'los días y el horario que elijas.',
                    action: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: _desdeCatalogo,
                          icon: const Icon(Icons.auto_stories_rounded),
                          label: const Text('Elegir del catálogo'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _nuevo,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Curso propio'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            // Set: cada carrera una sola vez, para el filtro.
            final carreras = <String>{for (final curso in academico.cursos) ?curso.carrera}.toList()..sort();
            final carrera = carreras.contains(_carrera) ? _carrera : null;
            final q = normalizarBusqueda(_busqueda);
            final visibles = <Curso>[];
            for (final curso in academico.cursos) {
              final coincide = q.isEmpty || normalizarBusqueda('${curso.codigo} ${curso.nombre}').contains(q);
              final pendientes = academico.resumenDe(curso).pendientes;
              final pasaEstado = switch (_estado) {
                _Estado.todos => true,
                _Estado.enDictado => pendientes > 0,
                _Estado.finalizados => pendientes == 0,
              };
              final pasaCarrera = carrera == null || curso.carrera == carrera;
              if (coincide && pasaEstado && pasaCarrera) visibles.add(curso);
            }
            visibles.sort(
              (a, b) => switch (_orden) {
                _Orden.nombre => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
                _Orden.codigo => a.codigo.compareTo(b.codigo),
                _Orden.matriculados =>
                  academico.matriculadosEn(b.id).length.compareTo(academico.matriculadosEn(a.id).length),
              },
            );

            return PageList(
              bottom: 96,
              children: [
                BuscadorField(hint: 'Buscar por código o nombre', onChanged: (v) => setState(() => _busqueda = v)),
                if (carreras.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            avatar: const Icon(Icons.school_rounded, size: 18),
                            label: const Text('Todas las carreras'),
                            selected: carrera == null,
                            onSelected: (_) => setState(() => _carrera = null),
                          ),
                        ),
                        for (final nombre in carreras)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(nombre),
                              selected: carrera == nombre,
                              onSelected: (_) => setState(() => _carrera = nombre),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final (estado, texto) in [
                              (_Estado.todos, 'Todos'),
                              (_Estado.enDictado, 'En dictado'),
                              (_Estado.finalizados, 'Finalizados'),
                            ])
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(texto),
                                  selected: _estado == estado,
                                  onSelected: (_) => setState(() => _estado = estado),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuButton<_Orden>(
                      tooltip: 'Ordenar',
                      icon: const Icon(Icons.sort_rounded),
                      initialValue: _orden,
                      onSelected: (o) => setState(() => _orden = o),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: _Orden.nombre, child: Text('Por nombre')),
                        PopupMenuItem(value: _Orden.codigo, child: Text('Por código')),
                        PopupMenuItem(value: _Orden.matriculados, child: Text('Más matriculados')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${visibles.length} de ${academico.cursos.length} cursos',
                  style: TextStyle(color: context.tokens.textSecondary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                if (visibles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'Ningún curso coincide con el filtro.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.tokens.textSecondary),
                    ),
                  )
                else
                  AdaptiveGrid(
                    minAncho: 360,
                    maxColumnas: 2,
                    children: [
                      for (final curso in visibles)
                        CursoCard(
                          curso: curso,
                          resumen: academico.resumenDe(curso),
                          ahora: academico.ahora,
                          promedio: calificaciones.resumenDe(curso).promedioGeneral,
                          onTap: () => context.abrirCurso(curso),
                        ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
