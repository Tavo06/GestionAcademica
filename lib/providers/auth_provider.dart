import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/utils/temporary_password.dart';
import '../models/docente.dart';

class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);
}

/// Session + profile state backed by Firebase Authentication and the
/// Firestore `users/{uid}` profile document.
class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    // Verification and password-reset emails are sent in Spanish.
    _auth.setLanguageCode('es');
    // Debug builds use the test phone numbers configured in Firebase
    // Console (no real SMS on the Spark plan), which don't need Play
    // Integrity / reCAPTCHA. Release builds keep app verification on.
    if (kDebugMode) {
      _auth.setSettings(appVerificationDisabledForTesting: true);
    }
    _authSubscription = _auth.authStateChanges().listen(_onAuthChanged);
  }

  /// Signed-out state with a fixed profile and no Firebase access, so
  /// widget tests can render screens that show the teacher's name.
  @visibleForTesting
  AuthProvider.paraPruebas(Docente perfil) : _profile = perfil;

  late final FirebaseAuth _auth = FirebaseAuth.instance;
  late final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSubscription;

  User? _firebaseUser;
  Docente? _profile;
  bool _mustChangePassword = false;
  bool _isLoadingProfile = false;
  bool _registrationComplete = false;
  Future<void>? _profileLoad;
  String? _profileLoadUid;

  /// Throwaway password from [registerTeacher], kept only in memory so the
  /// user can be re-authenticated before [createPassword]. Lost if the app is
  /// closed; [createPassword] then falls back to a Firebase reset email.
  String? _tempPassword;

  /// Set by [login]. Temporary passwords are never shown to anyone, so a
  /// successful email+password sign-in proves the user already set their
  /// own password (in the app or through Firebase's reset link).
  bool _signedInWithPassword = false;

  /// Personal data typed in the sign-up dialog, written into the new
  /// profile by [_newTeacherProfile]. Only set while [registerTeacher] runs.
  Map<String, dynamic>? _pendingRegistration;

  /// Phone verification in progress: [_verificationId] and [_resendToken]
  /// on Android/iOS, [_webConfirmation] on web.
  String? _verificationId;
  int? _resendToken;
  ConfirmationResult? _webConfirmation;

  bool get isLoggedIn => _firebaseUser != null;
  bool get isLoadingProfile => _isLoadingProfile;
  bool get mustChangePassword => _mustChangePassword;
  bool get emailVerified => _firebaseUser?.emailVerified ?? false;

  /// True once a mobile number has been linked to the Firebase account
  /// with an SMS code.
  bool get phoneVerified => _firebaseUser?.phoneNumber?.isNotEmpty ?? false;
  bool get registrationComplete => _registrationComplete;
  String? get uid => _firebaseUser?.uid;
  String get email => _firebaseUser?.email ?? '';

  /// Same conditions the Firestore rules require (`isActiveTeacher`) to read
  /// or write the teacher's students and sessions.
  bool get canUseTeacherData =>
      isLoggedIn &&
      !_isLoadingProfile &&
      emailVerified &&
      !_mustChangePassword &&
      _profile?.estado == EstadoCuenta.activo;

  Docente get docente =>
      _profile ??
      Docente(
        uid: _firebaseUser?.uid ?? '',
        nombre: '',
        apellidos: '',
        correo: _firebaseUser?.email ?? '',
      );

  Future<void> _onAuthChanged(User? user) async {
    _firebaseUser = user;
    if (user == null) {
      _profile = null;
      _mustChangePassword = false;
      _registrationComplete = false;
      _tempPassword = null;
      _verificationId = null;
      _resendToken = null;
      _webConfirmation = null;
      notifyListeners();
      return;
    }
    await _loadProfile(user);
  }

  /// Single-flight: the auth listener and [registerTeacher] may both ask for
  /// the same user's profile, and only one of them may create it.
  Future<void> _loadProfile(User user) {
    if (_profileLoad != null && _profileLoadUid == user.uid) return _profileLoad!;
    _profileLoadUid = user.uid;
    return _profileLoad = _doLoadProfile(user).whenComplete(() {
      _profileLoad = null;
      _profileLoadUid = null;
    });
  }

  Future<void> _doLoadProfile(User user) async {
    _isLoadingProfile = true;
    notifyListeners();
    try {
      final ref = _firestore.collection('users').doc(user.uid);
      var data = (await ref.get()).data();
      if (data == null) {
        // New self-registered account (or one whose profile write failed
        // earlier): every public registration is a teacher. Rules reject
        // any other role/status here.
        try {
          await ref.set(_newTeacherProfile(user));
        } on FirebaseException catch (e) {
          debugPrint('No se pudo crear el perfil: ${e.code}');
        }
        data = (await ref.get()).data();
      }
      if (data != null) {
        final profile = Docente.fromFirestore(user.uid, data);
        _profile = profile.correo.isEmpty
            ? profile.copyWith(correo: user.email ?? '')
            : profile;
        _mustChangePassword = data['mustChangePassword'] as bool? ?? false;
        if (_mustChangePassword && _signedInWithPassword) {
          try {
            await ref.update({'mustChangePassword': false});
            _mustChangePassword = false;
          } on FirebaseException catch (e) {
            debugPrint('No se pudo actualizar mustChangePassword: ${e.code}');
          }
        }
      } else {
        _profile = null;
        _mustChangePassword = true;
      }
    } on FirebaseException catch (e) {
      debugPrint('No se pudo cargar el perfil: ${e.code}');
      _profile = null;
    } finally {
      _signedInWithPassword = false;
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> _newTeacherProfile(User user) => {
        'firstName': _pendingRegistration?['firstName'] ?? '',
        'lastName': _pendingRegistration?['lastName'] ?? '',
        'dni': _pendingRegistration?['dni'] ?? '',
        // Number typed at sign-up; replaced by the SMS-verified one in
        // [_onPhoneLinked].
        'phone': _pendingRegistration?['phone'],
        'email': user.email ?? '',
        'role': 'docente',
        'status': 'activo',
        'hireDate': null,
        'mustChangePassword': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

  Future<void> login({required String correo, required String password}) async {
    _signedInWithPassword = true;
    try {
      await _auth.signInWithEmailAndPassword(
        email: correo.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      _signedInWithPassword = false;
      throw AuthFailure(_mapLoginError(e));
    }
  }

  /// Public teacher sign-up: creates the Firebase Auth account with an
  /// in-memory throwaway password and sends the official verification email.
  /// The `docente` profile, with the personal data typed here, is created by
  /// [_loadProfile]. [celular] is the 9-digit Peruvian mobile, verified by
  /// SMS in the next steps.
  Future<void> registerTeacher({
    required String correo,
    required String nombre,
    required String apellidos,
    required String dni,
    required String celular,
  }) async {
    final tempPassword = generateTemporaryPassword();
    _tempPassword = tempPassword;
    // Set before creating the account: the auth listener may create the
    // profile before this method gets to it.
    _pendingRegistration = {
      'firstName': nombre.trim(),
      'lastName': apellidos.trim(),
      'dni': dni.trim(),
      'phone': celularE164(celular),
    };
    final UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: correo.trim(),
        password: tempPassword,
      );
    } on FirebaseAuthException catch (e) {
      _tempPassword = null;
      _pendingRegistration = null;
      throw AuthFailure(_mapRegisterError(e));
    }

    final user = credential.user!;
    try {
      await _loadProfile(user);
    } finally {
      _pendingRegistration = null;
    }
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      // The account exists already; the verification screen offers "Reenviar".
      debugPrint('No se pudo enviar la verificación: ${e.code}');
    }
  }

  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapVerificationError(e));
    }
  }

  /// Reloads the Firebase user (the cached `emailVerified` flag does not
  /// update by itself) and returns whether the email is now verified.
  Future<bool> checkEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await user.reload();
      final refreshed = _auth.currentUser;
      if (refreshed != null && refreshed.emailVerified) {
        // Refresh the ID token so `email_verified` is current for rules.
        await refreshed.getIdToken(true);
      }
      _firebaseUser = refreshed;
      notifyListeners();
      return refreshed?.emailVerified ?? false;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapVerificationError(e));
    }
  }

  /// "987654321" → "+51987654321".
  static String celularE164(String celular) => '+51${celular.trim()}';

  /// Sends the SMS code to [telefonoE164]. Completes when the code was sent
  /// (or, on Android, when the number was verified automatically).
  Future<void> sendPhoneCode(String telefonoE164) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (kIsWeb) {
      try {
        // Uses an invisible reCAPTCHA created by the plugin.
        _webConfirmation = await user.linkWithPhoneNumber(telefonoE164);
      } on FirebaseAuthException catch (e) {
        throw AuthFailure(_mapPhoneError(e));
      }
      return;
    }

    // Firebase phone auth only exists on Android, iOS and web.
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      throw const AuthFailure(
        'La verificación por SMS solo funciona en el celular (Android) o en '
        'el navegador. Abre la app en tu celular para continuar.',
      );
    }

    final sent = Completer<void>();
    await _auth.verifyPhoneNumber(
      phoneNumber: telefonoE164,
      forceResendingToken: _resendToken,
      timeout: const Duration(seconds: 60),
      // Android may read the SMS by itself: link right away.
      verificationCompleted: (credential) async {
        try {
          await _linkPhone(credential);
        } on AuthFailure catch (e) {
          debugPrint('Verificación automática fallida: ${e.message}');
        }
        if (!sent.isCompleted) sent.complete();
      },
      verificationFailed: (e) {
        if (!sent.isCompleted) sent.completeError(AuthFailure(_mapPhoneError(e)));
      },
      codeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        if (!sent.isCompleted) sent.complete();
      },
      codeAutoRetrievalTimeout: (verificationId) => _verificationId = verificationId,
    );
    return sent.future;
  }

  /// Checks the 6-digit [codigo] and links the number to the account.
  Future<void> confirmPhoneCode(String codigo) async {
    if (kIsWeb) {
      final confirmation = _webConfirmation;
      if (confirmation == null) throw const AuthFailure(_sendCodeFirst);
      try {
        await confirmation.confirm(codigo.trim());
      } on FirebaseAuthException catch (e) {
        throw AuthFailure(_mapPhoneError(e));
      }
      await _onPhoneLinked();
      return;
    }

    final verificationId = _verificationId;
    if (verificationId == null) throw const AuthFailure(_sendCodeFirst);
    await _linkPhone(PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: codigo.trim(),
    ));
  }

  Future<void> _linkPhone(PhoneAuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      // Auto-verification and the typed code can both try to link.
      if (e.code != 'provider-already-linked') throw AuthFailure(_mapPhoneError(e));
    }
    await _onPhoneLinked();
  }

  /// Refreshes the user so [phoneVerified] and the token's `phone_number`
  /// claim are current, then stores the verified number in the profile.
  Future<void> _onPhoneLinked() async {
    final current = _auth.currentUser;
    if (current == null) return;
    await current.reload();
    final user = _auth.currentUser!;
    await user.getIdToken(true);
    _firebaseUser = user;
    _verificationId = null;
    _resendToken = null;
    _webConfirmation = null;

    final telefono = user.phoneNumber;
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'phone': telefono,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _profile = _profile?.copyWith(telefono: telefono);
    } on FirebaseException catch (e) {
      debugPrint('No se pudo guardar el teléfono verificado: ${e.code}');
    }
    notifyListeners();
  }

  /// Sets the user's definitive password. Firebase requires a recent sign-in
  /// for `updatePassword`; if the session is too old it re-authenticates
  /// with the in-memory temporary password, and if that was lost (app
  /// closed) it sends the official reset email instead.
  Future<void> createPassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      try {
        await user.updatePassword(newPassword);
      } on FirebaseAuthException catch (e) {
        if (e.code != 'requires-recent-login') rethrow;
        final tempPassword = _tempPassword;
        if (tempPassword == null) {
          await _auth.sendPasswordResetEmail(email: user.email!);
          throw AuthFailure(
            'Por seguridad, te enviamos un correo a ${user.email} con un '
            'enlace para crear tu contraseña. Después cierra sesión e '
            'inicia sesión con tu nueva contraseña.',
          );
        }
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: user.email!, password: tempPassword),
        );
        await user.updatePassword(newPassword);
      }
      _tempPassword = null;
      await _firestore.collection('users').doc(user.uid).update({
        'mustChangePassword': false,
      });
      _mustChangePassword = false;
      _registrationComplete = true;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapPasswordError(e));
    } on FirebaseException {
      throw const AuthFailure(
        'Tu contraseña se guardó, pero no se pudo actualizar tu perfil. '
        'Intenta nuevamente.',
      );
    }
  }

  /// The teacher edits their own profile. Email, phone (verified by SMS),
  /// role, status and dates set by the system can't be changed here
  /// (enforced by the rules too).
  Future<void> updateProfile({
    required String nombre,
    required String apellidos,
    required String dni,
    DateTime? fechaIngreso,
  }) async {
    final user = _firebaseUser;
    final profile = _profile;
    if (user == null || profile == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'firstName': nombre.trim(),
        'lastName': apellidos.trim(),
        'dni': dni.trim(),
        'hireDate': fechaIngreso != null ? Timestamp.fromDate(fechaIngreso) : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw AuthFailure(
        e.code == 'unavailable'
            ? _networkError
            : 'No se pudieron guardar los cambios del perfil.',
      );
    }
    _profile = Docente(
      uid: profile.uid,
      nombre: nombre.trim(),
      apellidos: apellidos.trim(),
      correo: profile.correo,
      dni: dni.trim(),
      telefono: profile.telefono,
      estado: profile.estado,
      fechaIngreso: fechaIngreso,
      fechaRegistro: profile.fechaRegistro,
    );
    notifyListeners();
  }

  Future<void> sendPasswordResetEmail(String correo) async {
    try {
      await _auth.sendPasswordResetEmail(email: correo.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapResetError(e));
    }
  }

  Future<void> logout() => _auth.signOut();

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  static const _networkError =
      'Sin conexión a internet. Verifica tu conexión e intenta nuevamente.';
  static const _tooManyRequests =
      'Demasiados intentos. Intenta nuevamente más tarde.';
  static const _sendCodeFirst =
      'Primero solicita el código SMS a tu celular.';

  /// In debug builds the Firebase code is appended, so configuration
  /// problems (provider disabled, test number missing...) can be told apart.
  String _mapPhoneError(FirebaseAuthException e) {
    debugPrint('Phone auth error: ${e.code} ${e.message}');
    final mensaje = _phoneErrorMessage(e);
    return kDebugMode ? '$mensaje\n[${e.code}] ${e.message ?? ''}' : mensaje;
  }

  String _phoneErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'El número de celular no es válido.';
      case 'invalid-verification-code':
        return 'El código es incorrecto. Revisa el SMS e inténtalo de nuevo.';
      case 'session-expired':
      case 'code-expired':
      case 'invalid-verification-id':
        return 'El código expiró. Solicita uno nuevo.';
      case 'credential-already-in-use':
      case 'account-exists-with-different-credential':
        return 'Este celular ya está asociado a otra cuenta.';
      case 'quota-exceeded':
      case 'too-many-requests':
        return 'Se enviaron demasiados SMS. Espera unos minutos e intenta nuevamente.';
      case 'operation-not-allowed':
      case 'app-not-authorized':
      case 'missing-client-identifier':
      case 'captcha-check-failed':
        return 'La verificación por SMS no está disponible en este momento.';
      case 'network-request-failed':
        return _networkError;
      default:
        return 'No se pudo verificar tu celular. Intenta nuevamente.';
    }
  }

  String _mapLoginError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'invalid-email':
        return 'Ingresa un correo electrónico válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return _tooManyRequests;
      case 'network-request-failed':
        return _networkError;
      default:
        return 'No se pudo iniciar sesión. Intenta nuevamente.';
    }
  }

  String _mapRegisterError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo. Si no terminaste tu '
            'registro, usa "¿Olvidaste tu contraseña?" para crear tu contraseña.';
      case 'invalid-email':
        return 'Ingresa un correo electrónico válido.';
      case 'operation-not-allowed':
        return 'El registro con correo no está habilitado en este momento.';
      case 'too-many-requests':
        return _tooManyRequests;
      case 'network-request-failed':
        return _networkError;
      default:
        return 'No se pudo crear la cuenta. Intenta nuevamente.';
    }
  }

  String _mapVerificationError(FirebaseAuthException e) {
    switch (e.code) {
      case 'too-many-requests':
        return 'Ya enviamos varios correos. Espera unos minutos antes de reenviar.';
      case 'network-request-failed':
        return _networkError;
      case 'user-not-found':
      case 'user-disabled':
      case 'user-token-expired':
        return 'Tu sesión ya no es válida. Vuelve a registrarte o inicia sesión.';
      default:
        return 'No se pudo comprobar tu correo. Intenta nuevamente.';
    }
  }

  String _mapPasswordError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
      case 'password-does-not-meet-requirements':
        return 'La contraseña es demasiado débil.';
      case 'requires-recent-login':
      case 'invalid-credential':
      case 'user-mismatch':
        return 'Por seguridad, cierra sesión y usa "¿Olvidaste tu contraseña?" '
            'para crear tu contraseña.';
      case 'too-many-requests':
        return _tooManyRequests;
      case 'network-request-failed':
        return _networkError;
      default:
        return 'No se pudo guardar la contraseña.';
    }
  }

  String _mapResetError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo electrónico.';
      case 'invalid-email':
        return 'Ingresa un correo electrónico válido.';
      case 'too-many-requests':
        return _tooManyRequests;
      case 'network-request-failed':
        return _networkError;
      default:
        return 'No se pudo enviar el correo de recuperación.';
    }
  }
}
