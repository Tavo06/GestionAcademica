/// Reglas de calificación del sistema: escala vigesimal (0 a 20), se
/// aprueba con 10.50 o más (sin redondeo) y el promedio es ponderado por el
/// peso (%) de cada evaluación. Dart puro, sin Firebase.
library;

const double notaMinima = 0;
const double notaMaxima = 20;
const double notaAprobatoria = 10.5;

/// Los pesos de las evaluaciones de un curso suman como máximo 100 %.
const int pesoTotal = 100;

enum CondicionNota {
  aprobado('Aprobado'),
  desaprobado('Desaprobado'),
  sinNotas('Sin notas');

  const CondicionNota(this.etiqueta);
  final String etiqueta;
}

bool esNotaValida(double nota) => nota >= notaMinima && nota <= notaMaxima;

bool estaAprobado(double promedio) => promedio >= notaAprobatoria;

CondicionNota condicionDe(double? promedio) {
  if (promedio == null) return CondicionNota.sinNotas;
  return estaAprobado(promedio) ? CondicionNota.aprobado : CondicionNota.desaprobado;
}

/// "14,5" o "14.5" → 14.5. Null si el texto no es un número.
double? parseNota(String texto) {
  final limpio = texto.trim().replaceAll(',', '.');
  if (limpio.isEmpty) return null;
  return double.tryParse(limpio);
}

/// Validación de un campo de nota: vacío (sin nota) o un número de 0 a 20
/// con hasta dos decimales.
String? validarNota(String? texto) {
  final valor = texto?.trim() ?? '';
  if (valor.isEmpty) return null;
  if (!RegExp(r'^\d{1,2}([.,]\d{1,2})?$').hasMatch(valor)) {
    return 'Usa un número con hasta 2 decimales';
  }
  final nota = parseNota(valor)!;
  if (!esNotaValida(nota)) return 'La nota va de 0 a 20';
  return null;
}

/// Promedio ponderado Σ(nota × peso) / Σ(peso) de las evaluaciones que
/// tienen nota. Null si ninguna tiene nota.
double? promedioPonderado(Iterable<({double nota, int peso})> notas) {
  var suma = 0.0;
  var pesos = 0;
  for (final n in notas) {
    if (n.peso <= 0) continue;
    suma += n.nota * n.peso;
    pesos += n.peso;
  }
  if (pesos == 0) return null;
  return suma / pesos;
}

/// Promedio simple (para el promedio general de un curso).
double? promedioSimple(Iterable<double> valores) {
  var suma = 0.0;
  var cantidad = 0;
  for (final v in valores) {
    suma += v;
    cantidad++;
  }
  return cantidad == 0 ? null : suma / cantidad;
}

/// Mensaje de error si el nuevo [peso] no cabe junto a los [pesosUsados]
/// por las demás evaluaciones del curso; null si es válido.
String? validarPeso(int peso, int pesosUsados) {
  if (peso < 1 || peso > pesoTotal) return 'El peso va de 1 a $pesoTotal %.';
  final disponible = pesoTotal - pesosUsados;
  if (peso > disponible) {
    return disponible <= 0
        ? 'Las evaluaciones de este curso ya suman $pesoTotal %.'
        : 'Solo quedan $disponible % disponibles en este curso.';
  }
  return null;
}
