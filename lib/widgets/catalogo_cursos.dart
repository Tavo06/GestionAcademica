import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../core/data/catalogo_carreras.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/texto.dart';

/// Curso elegido en el catálogo, con su carrera. Se envía al formulario de
/// curso para rellenarlo.
typedef PlantillaCurso = ({CarreraCatalogo carrera, CursoCatalogo curso});

/// Abre el catálogo de carreras y cursos predeterminados. [codigosUsados]
/// marca los cursos que el docente ya creó. Devuelve el curso elegido.
Future<PlantillaCurso?> showCatalogoCursos(
  BuildContext context, {
  Set<String> codigosUsados = const {},
  String? carreraInicial,
}) {
  return showModalBottomSheet<PlantillaCurso>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 760),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scroll) =>
          CatalogoCursos(scroll: scroll, codigosUsados: codigosUsados, carreraInicial: carreraInicial),
    ),
  );
}

/// Catálogo: carreras arriba (deslizables), buscador y los cursos de la
/// carrera elegida agrupados por ciclo. La carrera y la búsqueda son estado
/// local (setState).
class CatalogoCursos extends StatefulWidget {
  final ScrollController? scroll;
  final Set<String> codigosUsados;
  final String? carreraInicial;

  const CatalogoCursos({super.key, this.scroll, this.codigosUsados = const {}, this.carreraInicial});

  @override
  State<CatalogoCursos> createState() => _CatalogoCursosState();
}

class _CatalogoCursosState extends State<CatalogoCursos> {
  late CarreraCatalogo _carrera = carreraPorNombre(widget.carreraInicial) ?? catalogoCarreras.first;
  String _busqueda = '';
  bool _verTodas = false;
  final _carreras = ScrollController();

  @override
  void dispose() {
    _carreras.dispose();
    super.dispose();
  }

  /// Mueve la fila de carreras casi un ancho de pantalla a la izquierda (-1)
  /// o a la derecha (1).
  void _desplazar(int direccion) {
    if (!_carreras.hasClients) return;
    final posicion = _carreras.position;
    final destino = (posicion.pixels + direccion * posicion.viewportDimension * 0.8).clamp(
      posicion.minScrollExtent,
      posicion.maxScrollExtent,
    );
    _carreras.animateTo(destino, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final q = normalizarBusqueda(_busqueda);
    // Con búsqueda se buscan los cursos de todas las carreras.
    final resultados = <PlantillaCurso>[
      for (final carrera in q.isEmpty ? [_carrera] : catalogoCarreras)
        for (final curso in carrera.cursos)
          if (q.isEmpty || normalizarBusqueda('${curso.codigo} ${curso.nombre}').contains(q))
            (carrera: carrera, curso: curso),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Catálogo de cursos',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${catalogoCarreras.length} carreras · elige un curso para crearlo',
                      style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Cerrar',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: TextField(
            onChanged: (v) => setState(() => _busqueda = v),
            decoration: const InputDecoration(
              hintText: 'Buscar curso en todas las carreras',
              prefixIcon: Icon(Icons.search_rounded),
              isDense: true,
            ),
          ),
        ),
        if (q.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'CARRERAS',
                    style: TextStyle(
                      fontSize: 11.5,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w800,
                      color: tokens.textSecondary,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _verTodas = !_verTodas),
                  icon: Icon(_verTodas ? Icons.expand_less_rounded : Icons.expand_more_rounded),
                  label: Text(_verTodas ? 'Ver menos' : 'Ver todas'),
                ),
              ],
            ),
          ),
          if (_verTodas)
            // Todas las carreras desplegadas en filas.
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.4),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final carrera in catalogoCarreras)
                      SizedBox(
                        height: 112,
                        child: _CarreraTile(
                          carrera: carrera,
                          seleccionada: carrera == _carrera,
                          onTap: () => setState(() {
                            _carrera = carrera;
                            _verTodas = false;
                          }),
                        ),
                      ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 112,
              child: Stack(
                children: [
                  // En web el mouse no arrastra listas: se habilita y
                  // además hay flechas a los lados.
                  ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {...PointerDeviceKind.values}),
                    child: ListView.separated(
                      controller: _carreras,
                      padding: const EdgeInsets.symmetric(horizontal: 44),
                      scrollDirection: Axis.horizontal,
                      itemCount: catalogoCarreras.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final carrera = catalogoCarreras[i];
                        return _CarreraTile(
                          carrera: carrera,
                          seleccionada: carrera == _carrera,
                          onTap: () => setState(() => _carrera = carrera),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    left: 4,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _Flecha(icono: Icons.chevron_left_rounded, onTap: () => _desplazar(-1)),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _Flecha(icono: Icons.chevron_right_rounded, onTap: () => _desplazar(1)),
                    ),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 8),
        Expanded(
          child: resultados.isEmpty
              ? Center(
                  child: Text('Ningún curso coincide con "$_busqueda".', style: TextStyle(color: tokens.textSecondary)),
                )
              : ListView.builder(
                  controller: widget.scroll,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: resultados.length,
                  itemBuilder: (context, i) {
                    final item = resultados[i];
                    final anterior = i == 0 ? null : resultados[i - 1];
                    final nuevoGrupo = q.isEmpty
                        ? anterior?.curso.ciclo != item.curso.ciclo
                        : anterior?.carrera != item.carrera;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (nuevoGrupo)
                          Padding(
                            padding: EdgeInsets.only(top: i == 0 ? 4 : 14, bottom: 6),
                            child: Text(
                              q.isEmpty ? 'CICLO ${item.curso.ciclo}' : item.carrera.nombre.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11.5,
                                letterSpacing: 1.1,
                                fontWeight: FontWeight.w800,
                                color: tokens.textSecondary,
                              ),
                            ),
                          ),
                        _CursoCatalogoTile(
                          carrera: item.carrera,
                          curso: item.curso,
                          creado: widget.codigosUsados.contains(item.curso.codigo),
                          onTap: () => Navigator.of(context).pop<PlantillaCurso>(item),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Botón redondo para desplazar la fila de carreras.
class _Flecha extends StatelessWidget {
  final IconData icono;
  final VoidCallback onTap;

  const _Flecha({required this.icono, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      shape: const CircleBorder(),
      elevation: 3,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: onTap,
        icon: Icon(icono, color: context.colors.primary),
      ),
    );
  }
}

class _CarreraTile extends StatelessWidget {
  final CarreraCatalogo carrera;
  final bool seleccionada;
  final VoidCallback onTap;

  const _CarreraTile({required this.carrera, required this.seleccionada, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = carrera.color;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 128,
      decoration: BoxDecoration(
        gradient: seleccionada
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, Color.lerp(color, Colors.black, 0.35)!],
              )
            : null,
        color: seleccionada ? null : tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: seleccionada ? Colors.transparent : color.withValues(alpha: 0.3)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(carrera.icono, color: seleccionada ? Colors.white : color),
                const Spacer(),
                Text(
                  carrera.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: seleccionada ? Colors.white : tokens.textPrimary,
                  ),
                ),
                Text(
                  '${carrera.cursos.length} cursos',
                  style: TextStyle(
                    fontSize: 11,
                    color: seleccionada ? Colors.white.withValues(alpha: 0.8) : tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CursoCatalogoTile extends StatelessWidget {
  final CarreraCatalogo carrera;
  final CursoCatalogo curso;
  final bool creado;
  final VoidCallback onTap;

  const _CursoCatalogoTile({required this.carrera, required this.curso, required this.creado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = carrera.color;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          // Un curso ya creado no se puede volver a crear (código repetido).
          onTap: creado ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 64,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: context.isDark ? 0.25 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        curso.codigo,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
                      ),
                      Text('${curso.creditos} cr.', style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        curso.nombre,
                        style: TextStyle(fontWeight: FontWeight.w800, color: tokens.textPrimary),
                      ),
                      Text(
                        curso.descripcion,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: tokens.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                creado
                    ? Tooltip(
                        message: 'Ya tienes este curso',
                        child: Icon(Icons.check_circle_rounded, color: tokens.success),
                      )
                    : Icon(Icons.add_circle_outline_rounded, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
