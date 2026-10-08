class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo electrónico es obligatorio';
    }
    final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un correo electrónico válido';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  /// Stricter rule for a password the user is creating (not for login).
  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    if (!RegExp(r'[A-Za-zÁÉÍÓÚáéíóúÑñ]').hasMatch(value) ||
        !RegExp(r'\d').hasMatch(value)) {
      return 'La contraseña debe incluir letras y números';
    }
    return null;
  }

  static String? required(String? value, {String field = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field es obligatorio';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (value != original) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  static String? dni(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El DNI es obligatorio';
    }
    if (!RegExp(r'^\d{8}$').hasMatch(value.trim())) {
      return 'El DNI debe tener 8 dígitos.';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
      return 'El teléfono solo debe contener números.';
    }
    return null;
  }

  /// Peruvian mobile number without the +51 prefix: 9 digits starting with 9.
  static String? celular(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El celular es obligatorio';
    }
    if (!RegExp(r'^9\d{8}$').hasMatch(value.trim())) {
      return 'Ingresa un celular válido de 9 dígitos (empieza con 9).';
    }
    return null;
  }

  static String? smsCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa el código que recibiste por SMS';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'El código tiene 6 dígitos.';
    }
    return null;
  }
}
