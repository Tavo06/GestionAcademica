/// LDI ("límite de inasistencias"): a student reaches it with 30% or more
/// absences over the TOTAL sessions configured for the course, not only over
/// the sessions already taught. Used by attendance, students, statistics and
/// the dashboard so every screen agrees.
library;

const int umbralLdi = 30;

double porcentajeFaltas(int faltas, int totalSesiones) {
  if (totalSesiones <= 0) return 0;
  return faltas / totalSesiones * 100;
}

/// Compared with integers so 30% exactly counts even with rounding errors.
bool estaEnLdi(int faltas, int totalSesiones) {
  if (totalSesiones <= 0) return false;
  return faltas * 100 >= umbralLdi * totalSesiones;
}

/// Absences a course allows before LDI (e.g. 4 of 16, 5 of 17).
int faltasPermitidas(int totalSesiones) {
  var faltas = 0;
  while (!estaEnLdi(faltas + 1, totalSesiones) && faltas < totalSesiones) {
    faltas++;
  }
  return faltas;
}
