/// Utilidades de texto para búsquedas e iniciales.
library;

const _conTilde = 'áéíóúüñ';
const _sinTilde = 'aeiouun';

/// Minúsculas, sin tildes y sin espacios alrededor.
String normalizarBusqueda(String texto) {
  final buffer = StringBuffer();
  for (final c in texto.trim().toLowerCase().split('')) {
    final i = _conTilde.indexOf(c);
    buffer.write(i >= 0 ? _sinTilde[i] : c);
  }
  return buffer.toString();
}

/// Primeras letras de dos palabras ("María", "Pérez" → "MP").
String inicialesDe(String a, String b, {String respaldo = '?'}) {
  final x = a.trim().isEmpty ? '' : a.trim()[0];
  final y = b.trim().isEmpty ? '' : b.trim()[0];
  final texto = '$x$y'.toUpperCase();
  return texto.isEmpty ? respaldo : texto;
}
