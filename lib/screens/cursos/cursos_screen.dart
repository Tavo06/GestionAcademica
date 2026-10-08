import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/texto.dart';
import '../../models/curso.dart';
import '../../providers/academico_provider.dart';
import '../../providers/calificaciones_provider.dart';
import '../../widgets/academicos.dart';
import '../../widgets/comunes.dart';
import '../../widgets/encabezado.dart';

enum _Orden { nombre, codigo, matriculados }

enum _Estado { todos, enDictado, finalizados }

/// Listado de cursos con búsqueda, filtro por estado y orden (estado local
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

  Future<void> _nuevo() async {
    final creado = await context.crearCurso();
    if (creado != null && mounted) {
      showMessage(context, 'Curso ${creado.codigo} creado con ${creado.totalSesiones} sesiones.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EncabezadoSeccion(
        titulo: 'Cursos',
        subtitulo: 'Tus cursos, horarios y sesiones',
        acciones: accionesSeccion(),
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
              return PageList(children: [
                EmptyState(
                  icon: Icons.menu_book_rounded,
                  title: 'Aún no tienes cursos',
                  message: 'Crea tu primer curso: sus sesiones se generan solas según '
                      'los días y el horario que elijas.',
                  action: FilledButton.icon(
                    onPressed: _nuevo,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Nuevo curso'),
                  ),
                ),
              ]);
            }

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
              if (coincide && pasaEstado) visibles.add(curso);
            }
            visibles.sort((a, b) => switch (_orden) {
                  _Orden.nombre => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
                  _Orden.codigo => a.codigo.compareTo(b.codigo),
                  _Orden.matriculados => academico
                      .matriculadosEn(b.id)
                      .length
                      .compareTo(academico.matriculadosEn(a.id).length),
                });

            return PageList(
              bottom: 96,
              children: [
                BuscadorField(
                  hint: 'Buscar por código o nombre',
                  onChanged: (v) => setState(() => _busqueda = v),
                ),
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
