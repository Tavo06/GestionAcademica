import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:semana5/core/utils/temporary_password.dart';
import 'package:semana5/core/validators/validators.dart';
import 'package:semana5/core/utils/formatters.dart';
import 'package:semana5/models/docente.dart';
import 'package:semana5/models/jornada.dart';

void main() {
  test('email validator rejects malformed addresses', () {
    expect(Validators.email(''), isNotNull);
    expect(Validators.email('no-es-un-correo'), isNotNull);
    expect(Validators.email('usuario@dominio'), isNotNull);
    expect(Validators.email('usuario@dominio.com'), isNull);
  });

  test('password validator requires at least 6 characters', () {
    expect(Validators.password('123'), isNotNull);
    expect(Validators.password('123456'), isNull);
  });

  test('new password requires 8+ characters with letters and numbers', () {
    expect(Validators.newPassword(''), isNotNull);
    expect(Validators.newPassword('abc12'), isNotNull);
    expect(Validators.newPassword('abcdefgh'), isNotNull);
    expect(Validators.newPassword('12345678'), isNotNull);
    expect(Validators.newPassword('docente2026'), isNull);
  });

  test('confirm password must match', () {
    expect(Validators.confirmPassword('', 'docente2026'), isNotNull);
    expect(Validators.confirmPassword('otra2026', 'docente2026'), isNotNull);
    expect(Validators.confirmPassword('docente2026', 'docente2026'), isNull);
  });

  test('temporary password is long, mixed and unique', () {
    final a = generateTemporaryPassword();
    final b = generateTemporaryPassword();
    expect(a.length, 32);
    expect(a, isNot(b));
    expect(RegExp(r'[a-z]').hasMatch(a), isTrue);
    expect(RegExp(r'[A-Z]').hasMatch(a), isTrue);
    expect(RegExp(r'\d').hasMatch(a), isTrue);
    expect(RegExp(r'[!@#%*\-_=+?]').hasMatch(a), isTrue);
  });

  test('teacher profile parses data and name fallbacks', () {
    final nuevo = Docente.fromFirestore('u1', {
      'firstName': '',
      'lastName': '',
      'dni': '',
      'email': 'nuevo@x.com',
      'role': 'docente',
      'status': 'activo',
    });
    expect(nuevo.perfilIncompleto, isTrue);
    expect(nuevo.nombreCompleto, 'nuevo@x.com');
    expect(nuevo.nombreVisible, 'Docente');
    expect(nuevo.estado, EstadoCuenta.activo);

    final completo = Docente.fromFirestore('u2', {
      'firstName': 'Ana',
      'lastName': 'Pérez',
      'dni': '12345678',
      'phone': '987654321',
      'email': 'ana@x.com',
      'hireDate': Timestamp.fromDate(DateTime(2024, 3, 1)),
      'createdAt': Timestamp.fromDate(DateTime(2026, 9, 28)),
      'status': 'inactivo',
    });
    expect(completo.perfilIncompleto, isFalse);
    expect(completo.nombreCompleto, 'Ana Pérez');
    expect(completo.fechaIngreso, DateTime(2024, 3, 1));
    expect(completo.fechaRegistro, DateTime(2026, 9, 28));
    expect(completo.estado, EstadoCuenta.inactivo);
  });

  test('jornada: id, duración y formatos', () {
    expect(jornadaDocId('abc', 'ses1'), 'abc_ses1');
    final cerrada = Jornada.fromDoc('abc_ses1', {
      'docenteId': 'abc',
      'fecha': Timestamp.fromDate(DateTime(2026, 9, 28)),
      'entrada': Timestamp.fromDate(DateTime(2026, 9, 28, 8, 5)),
      'salida': Timestamp.fromDate(DateTime(2026, 9, 28, 16, 50)),
      'cursoId': 'c1',
      'sesionId': 'ses1',
      'cursoNombre': 'Matemática',
      'horaProgramadaInicio': '08:00',
      'horaProgramadaFin': '17:00',
    });
    expect(cerrada.abierta, isFalse);
    expect(cerrada.duracion, const Duration(hours: 8, minutes: 45));
    expect(cerrada.resultadoEntrada!.minutos, 5);
    expect(cerrada.resultadoSalida!.minutos, -10);
    expect(formatHora(cerrada.entrada), '08:05');
    expect(formatDuracion(cerrada.duracion), '8h 45min');
    expect(formatFechaCorta(cerrada.fecha), '28/09/2026');
  });
}
