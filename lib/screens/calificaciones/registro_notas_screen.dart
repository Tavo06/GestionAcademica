import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/app_routes.dart';
import '../../core/logic/notas.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/evaluacion.dart';
import '../../providers/academico_provider.dart';
import '../../providers/calificaciones_provider.dart';
import '../../services/academico_service.dart';
import '../../widgets/academicos.dart';
import '../../widgets/comunes.dart';
import '../../widgets/encabezado.dart';

enum _Filtro { todos, sinNota, desaprobados }

/// Registro de notas de una evaluación. Las notas viven en esta pantalla
/// (formulario local con setState) hasta "Guardar notas", que las guarda con
/// el provider y devuelve [NotasGuardadas] a la pantalla anterior.
class RegistroNotasScreen extends StatefulWidget {
  final String? evaluacionId;
  final Evaluacion? evaluacion;

  const RegistroNotasScreen({super.key, this.evaluacionId, this.evaluacion});

  @override
  State<RegistroNotasScreen> createState() => _RegistroNotasScreenState();
}

class _RegistroNotasScreenState extends State<RegistroNotasScreen> {
  final _formKey = GlobalKey<FormState>();

  /// Un controlador por estudiante, creado al tener la evaluación.
  final Map<String, TextEditingController> _campos = {};
  _Filtro _filtro = _Filtro.todos;
  bool _hayCambios = false;
  bool _guardando = false;

  @override
  void dispose() {
    for (final c in _campos.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _campo(String estudianteId, double? nota) => _campos.putIfAbsent(
        estudianteId,
        () => TextEditingController(text: nota == null ? '' : _texto(nota)),
      );

  /// 15 → "15", 14.5 → "14.5".
  static String _texto(double nota) =>
      nota == nota.roundToDouble() ? nota.toStringAsFixed(0) : nota.toString();

  bool _pasaFiltro(double? nota) => switch (_filtro) {
        _Filtro.todos => true,
        _Filtro.sinNota => nota == null,
        _Filtro.desaprobados => nota != null && !estaAprobado(nota),
      };

  Future<void> _guardar(Evaluacion evaluacion) async {
    if (!_formKey.currentState!.validate()) {
      showMessage(context, 'Revisa las notas marcadas en rojo.', error: true);
      return;
    }
    setState(() => _guardando = true);
    try {
      final notas = {for (final e in _campos.entries) e.key: parseNota(e.value.text)};
      final resultado = await context.read<CalificacionesProvider>().guardarNotas(evaluacion.id, notas);
      if (!mounted) return;
      setState(() => _hayCambios = false);
      context.pop(resultado);
    } on AcademicoFailure catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      showMessage(context, e.message, error: true);
    }
  }

  Future<void> _salirSinGuardar() async {
    final salir = await confirmar(
      context,
      titulo: 'Cambios sin guardar',
      mensaje: 'Si sales ahora se perderán las notas que no guardaste.',
      accion: 'Salir',
    );
    if (salir && mounted) {
      setState(() => _hayCambios = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final calificaciones = context.watch<CalificacionesProvider>();
    final academico = context.watch<AcademicoProvider>();
    final id = widget.evaluacionId ?? widget.evaluacion?.id;
    final evaluacion = (id == null ? null : calificaciones.evaluacionPorId(id)) ??
        (calificaciones.cargando ? widget.evaluacion : null);
    final curso = evaluacion == null ? null : academico.cursoPorId(evaluacion.cursoId);

    if (evaluacion == null || curso == null) {
      return Scaffold(
        appBar: const EncabezadoSeccion(titulo: 'Registro de notas', leading: VolverButton()),
        body: SafeArea(
          child: calificaciones.cargando || academico.cargando
              ? const CargandoView()
              : const UnavailableView(
                  icon: Icons.grade_outlined,
                  title: 'Evaluación no disponible',
                  message: 'La evaluación no existe o fue eliminada.',
                  destino: AppRoutes.calificaciones,
                  destinoTexto: 'Ir a Calificaciones',
                ),
        ),
      );
    }

    final tokens = context.tokens;
    final matriculados = academico.matriculadosEn(curso.id);
    // Valores actuales del formulario (lo escrito, aún sin guardar).
    final actuales = {
      for (final e in matriculados) e.id: parseNota(_campo(e.id, evaluacion.notaDe(e.id)).text),
    };
    final validas = actuales.values.whereType<double>().where(esNotaValida).toList();
    final promedio = promedioSimple(validas);
    final aprobados = validas.where(estaAprobado).length;

    return PopScope(
      canPop: !_hayCambios,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_guardando) _salirSinGuardar();
      },
      child: Scaffold(
        appBar: EncabezadoSeccion(
          titulo: evaluacion.nombre,
          subtitulo: '${curso.titulo} · peso ${evaluacion.peso}%',
          leading: const VolverButton(),
        ),
        bottomNavigationBar: matriculados.isEmpty
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: anchoMaximoContenido),
                      child: ElevatedButton.icon(
                        onPressed: _guardando ? null : () => _guardar(evaluacion),
                        icon: _guardando
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.save_rounded),
                        label: Text(_guardando ? 'Guardando...' : 'Guardar notas'),
                      ),
                    ),
                  ),
                ),
              ),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: PageList(
              children: [
                AdaptiveGrid(
                  minAncho: 140,
                  children: [
                    StatTile(
                      icon: Icons.edit_note_rounded,
                      label: 'Calificados',
                      value: '${validas.length}/${matriculados.length}',
                      color: context.colors.primary,
                    ),
                    StatTile(
                      icon: Icons.functions_rounded,
                      label: 'Promedio',
                      value: formatNota(promedio),
                      color: tokens.info,
                    ),
                    StatTile(
                      icon: Icons.verified_rounded,
                      label: 'Aprobados',
                      value: '$aprobados',
                      color: tokens.success,
                    ),
                    StatTile(
                      icon: Icons.trending_down_rounded,
                      label: 'Desaprobados',
                      value: '${validas.length - aprobados}',
                      color: tokens.error,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Escala de 0 a 20. Aprueba con ${formatNota(notaAprobatoria)} o más. '
                  'Deja vacío para "sin nota".',
                  style: TextStyle(fontSize: 12.5, color: tokens.textSecondary),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final (filtro, texto) in [
                      (_Filtro.todos, 'Todos'),
                      (_Filtro.sinNota, 'Sin nota'),
                      (_Filtro.desaprobados, 'Desaprobados'),
                    ])
                      ChoiceChip(
                        label: Text(texto),
                        selected: _filtro == filtro,
                        onSelected: (_) => setState(() => _filtro = filtro),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (matriculados.isEmpty)
                  EmptyState(
                    icon: Icons.groups_rounded,
                    title: 'Sin matriculados',
                    message: 'Matricula estudiantes en ${curso.nombre} para registrar sus notas.',
                  )
                else
                  for (final e in matriculados)
                    // Los campos ocultos por el filtro siguen en el formulario.
                    Offstage(
                      offstage: !_pasaFiltro(actuales[e.id]),
                      child: EstudianteTile(
                        estudiante: e,
                        color: condicionDe(actuales[e.id]).colorEn(context),
                        trailing: SizedBox(
                          width: 104,
                          child: TextFormField(
                            controller: _campo(e.id, evaluacion.notaDe(e.id)),
                            enabled: !_guardando,
                            textAlign: TextAlign.center,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              hintText: '—',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            validator: validarNota,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            onChanged: (_) => setState(() => _hayCambios = true),
                          ),
                        ),
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
