import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/data/catalogo_carreras.dart';
import '../../core/logic/horario.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/curso.dart';
import '../../providers/academico_provider.dart';
import '../../services/academico_service.dart';
import '../../widgets/catalogo_cursos.dart';
import '../../widgets/comunes.dart';
import '../../widgets/dialogos.dart';
import '../../widgets/encabezado.dart';

/// Formulario de curso. Sin [cursoId] crea un curso nuevo (con horario y
/// sesiones); con [cursoId] edita sus datos descriptivos. Al guardar
/// devuelve el [Curso] a la pantalla anterior con `context.pop(curso)`.
/// Con [plantilla] (un curso del catálogo) llega con sus datos rellenados.
class CursoFormScreen extends StatefulWidget {
  final String? cursoId;
  final Curso? curso;
  final PlantillaCurso? plantilla;

  const CursoFormScreen({super.key, this.cursoId, this.curso, this.plantilla});

  @override
  State<CursoFormScreen> createState() => _CursoFormScreenState();
}

class _CursoFormScreenState extends State<CursoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Curso? _original =
      widget.curso ?? (widget.cursoId == null ? null : context.read<AcademicoProvider>().cursoPorId(widget.cursoId!));
  late final _codigoController = TextEditingController(text: _original?.codigo ?? widget.plantilla?.curso.codigo ?? '');
  late final _nombreController = TextEditingController(text: _original?.nombre ?? widget.plantilla?.curso.nombre ?? '');
  late final _descripcionController = TextEditingController(
    text: _original?.descripcion ?? widget.plantilla?.curso.descripcion ?? '',
  );
  late final _sesionesController = TextEditingController(text: '$sesionesPorDefecto');
  late int _creditos = _original?.creditos ?? widget.plantilla?.curso.creditos ?? 3;
  late String? _carrera = _original?.carrera ?? widget.plantilla?.carrera.nombre;

  final Set<int> _dias = {};
  HoraDia? _inicio;
  HoraDia? _fin;
  DateTime _fechaInicio = soloFecha(DateTime.now());
  bool _guardando = false;
  String? _error;

  bool get _editando => widget.cursoId != null;

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _sesionesController.dispose();
    super.dispose();
  }

  int get _totalSesiones => int.tryParse(_sesionesController.text) ?? 0;

  NuevoCurso? get _datos {
    final inicio = _inicio;
    final fin = _fin;
    if (inicio == null || fin == null) return null;
    return NuevoCurso(
      codigo: _codigoController.text,
      nombre: _nombreController.text,
      descripcion: _descripcionController.text,
      carrera: _carrera,
      creditos: _creditos,
      totalSesiones: _totalSesiones,
      diasSemana: _dias.toList()..sort(),
      horaInicio: inicio,
      horaFin: fin,
      fechaInicio: _fechaInicio,
    );
  }

  Future<void> _elegirHora({required bool inicio}) async {
    final actual = inicio ? _inicio : _fin;
    final elegida = await showTimePicker(
      context: context,
      initialTime: actual == null
          ? TimeOfDay(hour: inicio ? 8 : 10, minute: 0)
          : TimeOfDay(hour: actual.hora, minute: actual.minuto),
      helpText: inicio ? 'Hora de inicio' : 'Hora de finalización',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      builder: (context, child) =>
          MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (elegida == null) return;
    setState(() {
      final hora = HoraDia.hm(elegida.hour, elegida.minute);
      if (inicio) {
        _inicio = hora;
      } else {
        _fin = hora;
      }
      _error = null;
    });
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fechaInicio,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Fecha de inicio',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (elegida != null) setState(() => _fechaInicio = soloFecha(elegida));
  }

  /// Rellena el formulario con un curso del catálogo.
  Future<void> _usarCatalogo() async {
    final academico = context.read<AcademicoProvider>();
    final elegido = await showCatalogoCursos(
      context,
      codigosUsados: {for (final c in academico.cursos) c.codigo},
      carreraInicial: _carrera,
    );
    if (elegido == null) return;
    setState(() {
      _codigoController.text = elegido.curso.codigo;
      _nombreController.text = elegido.curso.nombre;
      _descripcionController.text = elegido.curso.descripcion;
      _creditos = elegido.curso.creditos;
      _carrera = elegido.carrera.nombre;
      _error = null;
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final academico = context.read<AcademicoProvider>();

    if (_editando) {
      final original = _original;
      if (original == null) return;
      setState(() {
        _guardando = true;
        _error = null;
      });
      try {
        final editado = await academico.actualizarCurso(
          original.copyWith(
            codigo: _codigoController.text.trim().toUpperCase(),
            nombre: _nombreController.text.trim(),
            descripcion: _descripcionController.text.trim(),
            carrera: _carrera ?? '',
            creditos: _creditos,
          ),
        );
        if (mounted) context.pop(editado);
      } on AcademicoFailure catch (e) {
        if (mounted) {
          setState(() {
            _guardando = false;
            _error = e.message;
          });
        }
      }
      return;
    }

    final datos = _datos;
    final String? error;
    if (_dias.isEmpty) {
      error = 'Selecciona al menos un día de la semana.';
    } else if (datos == null) {
      error = 'Elige la hora de inicio y la de finalización.';
    } else {
      error = validarNuevoCurso(datos);
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final curso = await academico.crearCurso(datos!);
      if (mounted) context.pop(curso);
    } on HorarioNoDisponible catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      await showHorarioNoDisponible(context, e);
    } on AcademicoFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final datos = _datos;
    final fechas =
        _editando || datos == null || _dias.isEmpty || _totalSesiones <= 0 || _totalSesiones > maxSesionesCurso
        ? const <DateTime>[]
        : datos.fechas;

    if (_editando && _original == null) {
      return const Scaffold(
        appBar: EncabezadoSeccion(titulo: 'Editar curso', leading: VolverButton()),
        body: CargandoView(),
      );
    }

    return Scaffold(
      appBar: EncabezadoSeccion(
        titulo: _editando ? 'Editar curso' : 'Nuevo curso',
        subtitulo: _editando ? _original!.nombre : 'Datos, horario y sesiones',
        leading: const VolverButton(),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: PageList(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_editando) ...[
                        const SizedBox(height: 8),
                        _CatalogoBanner(onTap: _guardando ? null : _usarCatalogo, carrera: _carrera),
                      ],
                      const SectionHeader(title: 'Datos del curso'),
                      DropdownButtonFormField<String>(
                        initialValue: _carrera ?? '',
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Carrera',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                        items: [
                          const DropdownMenuItem(value: '', child: Text('Sin carrera')),
                          for (final carrera in catalogoCarreras)
                            DropdownMenuItem(value: carrera.nombre, child: Text(carrera.nombre)),
                          // Una carrera que ya no está en el catálogo se conserva.
                          if (_carrera != null && carreraPorNombre(_carrera) == null)
                            DropdownMenuItem(value: _carrera, child: Text(_carrera!)),
                        ],
                        onChanged: _guardando
                            ? null
                            : (v) => setState(() => _carrera = v == null || v.isEmpty ? null : v),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 140,
                            child: TextFormField(
                              controller: _codigoController,
                              maxLength: 12,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(labelText: 'Código', hintText: 'MAT-101'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Obligatorio' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _nombreController,
                              maxLength: 80,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                labelText: 'Nombre del curso',
                                hintText: 'Matemática I',
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa el nombre del curso.' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _descripcionController,
                        maxLength: 200,
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Créditos',
                        style: TextStyle(fontWeight: FontWeight.w700, color: tokens.textPrimary),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _creditos.toDouble(),
                              min: minCreditos.toDouble(),
                              max: maxCreditos.toDouble(),
                              divisions: maxCreditos - minCreditos,
                              label: '$_creditos',
                              onChanged: _guardando ? null : (v) => setState(() => _creditos = v.round()),
                            ),
                          ),
                          Text(
                            '$_creditos cr.',
                            style: TextStyle(fontWeight: FontWeight.w800, color: tokens.textPrimary),
                          ),
                        ],
                      ),
                      if (_editando) ...[
                        const SectionHeader(title: 'Horario'),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InfoLine(icon: Icons.calendar_today_rounded, text: _original!.diasTexto),
                                InfoLine(icon: Icons.schedule_rounded, text: _original.horario),
                                InfoLine(
                                  icon: Icons.event_note_rounded,
                                  text:
                                      '${_original.totalSesiones} sesiones desde '
                                      '${formatFechaCorta(_original.fechaInicio)}',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'El horario generó las sesiones y no se edita. Para mover una '
                                  'sesión de esta semana usa "Cambiar fecha" en el curso.',
                                  style: TextStyle(fontSize: 12.5, color: tokens.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _sesionesController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Número de sesiones',
                            helperText: 'Entre $minSesionesCurso y $maxSesionesCurso.',
                          ),
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n < minSesionesCurso || n > maxSesionesCurso) {
                              return 'Ingresa un número entre $minSesionesCurso y $maxSesionesCurso.';
                            }
                            return null;
                          },
                        ),
                        const SectionHeader(title: 'Días de clase'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final entrada in diasSemanaNombres.entries)
                              FilterChip(
                                label: Text(entrada.value),
                                selected: _dias.contains(entrada.key),
                                onSelected: _guardando
                                    ? null
                                    : (sel) => setState(() {
                                        sel ? _dias.add(entrada.key) : _dias.remove(entrada.key);
                                        _error = null;
                                      }),
                              ),
                          ],
                        ),
                        const SectionHeader(title: 'Horario y fecha de inicio'),
                        AdaptiveGrid(
                          minAncho: 180,
                          maxColumnas: 3,
                          children: [
                            _Selector(
                              icon: Icons.login_rounded,
                              label: 'Hora de inicio',
                              valor: _inicio?.toString() ?? 'Elegir',
                              onTap: _guardando ? null : () => _elegirHora(inicio: true),
                            ),
                            _Selector(
                              icon: Icons.logout_rounded,
                              label: 'Hora de fin',
                              valor: _fin?.toString() ?? 'Elegir',
                              onTap: _guardando ? null : () => _elegirHora(inicio: false),
                            ),
                            _Selector(
                              icon: Icons.event_rounded,
                              label: 'Fecha de inicio',
                              valor: formatFechaCorta(_fechaInicio),
                              onTap: _guardando ? null : _elegirFecha,
                            ),
                          ],
                        ),
                        if (fechas.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: context.colors.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Se generarán ${fechas.length} sesiones',
                                  style: TextStyle(fontWeight: FontWeight.w800, color: tokens.textPrimary),
                                ),
                                InfoLine(
                                  icon: Icons.first_page_rounded,
                                  text: 'Sesión 1 → ${formatFechaLarga(fechas.first, conAnio: true)}',
                                ),
                                if (fechas.length > 1)
                                  InfoLine(
                                    icon: Icons.last_page_rounded,
                                    text: 'Sesión ${fechas.length} → ${formatFechaLarga(fechas.last, conAnio: true)}',
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: TextStyle(color: tokens.error, fontWeight: FontWeight.w600),
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _guardando ? null : _guardar,
                        icon: _guardando
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.save_rounded),
                        label: Text(_guardando ? 'Guardando...' : (_editando ? 'Guardar cambios' : 'Crear curso')),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Selector extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valor;
  final VoidCallback? onTap;

  const _Selector({required this.icon, required this.label, required this.valor, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Material(
      color: tokens.surfaceMuted,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: context.colors.secondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 12, color: tokens.textSecondary)),
                    Text(
                      valor,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: tokens.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Acceso al catálogo de carreras en un curso nuevo.
class _CatalogoBanner extends StatelessWidget {
  final VoidCallback? onTap;
  final String? carrera;

  const _CatalogoBanner({required this.onTap, this.carrera});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = carreraPorNombre(carrera)?.color ?? context.colors.primary;
    return Material(
      color: color.withValues(alpha: context.isDark ? 0.18 : 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.auto_stories_rounded, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Elegir del catálogo',
                      style: TextStyle(fontWeight: FontWeight.w800, color: tokens.textPrimary),
                    ),
                    Text(
                      '${catalogoCarreras.length} carreras con cursos listos para usar',
                      style: TextStyle(fontSize: 12.5, color: tokens.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
