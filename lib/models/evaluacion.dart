import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/logic/horario.dart';
import 'calificacion.dart';

enum TipoEvaluacion {
  practica('practica', 'Práctica'),
  examen('examen', 'Examen'),
  trabajo('trabajo', 'Trabajo'),
  proyecto('proyecto', 'Proyecto'),
  participacion('participacion', 'Participación');

  const TipoEvaluacion(this.valor, this.etiqueta);

  final String valor;
  final String etiqueta;

  static TipoEvaluacion fromValor(Object? valor) {
    for (final tipo in values) {
      if (tipo.valor == valor) return tipo;
    }
    return TipoEvaluacion.practica;
  }
}

/// Una evaluación de un curso (`evaluaciones/{id}`) con su peso en el
/// promedio. Las notas de los estudiantes se guardan en el mismo documento
/// como `{estudianteId: nota}` (0 a 20).
class Evaluacion {
  final String id;
  final String docenteId;
  final String cursoId;
  final String nombre;
  final TipoEvaluacion tipo;

  /// Porcentaje del promedio (1 a 100). Los pesos de un curso suman ≤ 100.
  final int peso;
  final DateTime fecha;
  final Map<String, double> notas;

  const Evaluacion({
    required this.id,
    required this.docenteId,
    required this.cursoId,
    required this.nombre,
    required this.tipo,
    required this.peso,
    required this.fecha,
    this.notas = const {},
  });

  double? notaDe(String estudianteId) => notas[estudianteId];

  /// Las notas como registros [Calificacion].
  List<Calificacion> get calificaciones => [
        for (final entrada in notas.entries)
          Calificacion(evaluacionId: id, estudianteId: entrada.key, nota: entrada.value),
      ];

  Evaluacion copyWith({Map<String, double>? notas}) => Evaluacion(
        id: id,
        docenteId: docenteId,
        cursoId: cursoId,
        nombre: nombre,
        tipo: tipo,
        peso: peso,
        fecha: fecha,
        notas: notas ?? this.notas,
      );

  factory Evaluacion.fromDoc(String id, Map<String, dynamic> data) {
    final fecha = data['fecha'];
    final notas = <String, double>{};
    final crudo = data['notas'];
    if (crudo is Map) {
      crudo.forEach((estudianteId, valor) {
        if (estudianteId is String && valor is num) notas[estudianteId] = valor.toDouble();
      });
    }
    return Evaluacion(
      id: id,
      docenteId: data['docenteId'] as String? ?? '',
      cursoId: data['cursoId'] as String? ?? '',
      nombre: data['nombre'] as String? ?? '',
      tipo: TipoEvaluacion.fromValor(data['tipo']),
      peso: (data['peso'] as num?)?.toInt() ?? 0,
      fecha: fecha is Timestamp ? soloFecha(fecha.toDate()) : soloFecha(DateTime.now()),
      notas: notas,
    );
  }
}

/// Datos del formulario para crear una evaluación.
class NuevaEvaluacion {
  final String cursoId;
  final String nombre;
  final TipoEvaluacion tipo;
  final int peso;
  final DateTime fecha;

  const NuevaEvaluacion({
    required this.cursoId,
    required this.nombre,
    required this.tipo,
    required this.peso,
    required this.fecha,
  });
}
