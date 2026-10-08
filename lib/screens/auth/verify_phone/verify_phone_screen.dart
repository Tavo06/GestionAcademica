import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/validators/validators.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

/// Sign-up step after the email: the teacher receives a 6-digit SMS code and
/// the number is linked to their Firebase account.
class VerifyPhoneScreen extends StatefulWidget {
  const VerifyPhoneScreen({super.key});

  @override
  State<VerifyPhoneScreen> createState() => _VerifyPhoneScreenState();
}

class _VerifyPhoneScreenState extends State<VerifyPhoneScreen> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();

  /// Pre-filled with the number typed at sign-up (stored as +51XXXXXXXXX).
  late final _celularController = TextEditingController(
    text: _digitosNacionales(context.read<AuthProvider>().docente.telefono),
  );
  final _codigoController = TextEditingController();

  bool _codeSent = false;
  bool _isSending = false;
  bool _isConfirming = false;

  String? _message;
  AuthMessageType _messageType = AuthMessageType.info;

  static String _digitosNacionales(String? telefono) {
    final digitos = (telefono ?? '').replaceAll(RegExp(r'\D'), '');
    return digitos.length == 11 && digitos.startsWith('51') ? digitos.substring(2) : digitos;
  }

  String get _telefonoE164 => AuthProvider.celularE164(_celularController.text);

  @override
  void dispose() {
    _celularController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  void _showMessage(String? message, [AuthMessageType type = AuthMessageType.info]) {
    setState(() {
      _message = message;
      _messageType = type;
    });
  }

  Future<void> _handleSend() async {
    if (!_phoneFormKey.currentState!.validate()) return;

    setState(() {
      _isSending = true;
      _message = null;
    });
    try {
      await context.read<AuthProvider>().sendPhoneCode(_telefonoE164);
      // If Android verified the number by itself the router already moved on.
      if (!mounted) return;
      setState(() => _codeSent = true);
      _showMessage('Te enviamos un código por SMS al $_telefonoE164.', AuthMessageType.success);
    } on AuthFailure catch (e) {
      if (mounted) _showMessage(e.message, AuthMessageType.error);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _handleConfirm() async {
    if (!_codeFormKey.currentState!.validate()) return;

    setState(() {
      _isConfirming = true;
      _message = null;
    });
    try {
      // When linked, the router moves on to "Crear contraseña".
      await context.read<AuthProvider>().confirmPhoneCode(_codigoController.text);
    } on AuthFailure catch (e) {
      if (mounted) _showMessage(e.message, AuthMessageType.error);
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  void _handleChangeNumber() {
    _codigoController.clear();
    setState(() {
      _codeSent = false;
      _message = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final busy = _isSending || _isConfirming;

    return AuthPage(
      builder: (context, ancho) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: AuthCard(
          compacta: ancho < anchoCompacto,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: AuthStepChip(paso: 3, texto: 'Celular')),
              const SizedBox(height: 20),
              const Center(child: AuthIconBadge(icon: Icons.sms_outlined)),
              const SizedBox(height: 16),
              Text(
                'Verifica tu celular',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: tokens.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _codeSent
                    ? 'Ingresa el código de 6 dígitos que enviamos a tu celular.'
                    : 'Te enviaremos un código por SMS para confirmar que este '
                        'número es tuyo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: tokens.textSecondary, height: 1.45),
              ),
              const SizedBox(height: 20),
              Form(
                key: _phoneFormKey,
                child: TextFormField(
                  controller: _celularController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  enabled: !_codeSent && !busy,
                  onFieldSubmitted: (_) => _handleSend(),
                  decoration: authCelularDecoration(context),
                  validator: Validators.celular,
                ),
              ),
              if (_codeSent) ...[
                const SizedBox(height: 14),
                Form(
                  key: _codeFormKey,
                  child: TextFormField(
                    controller: _codigoController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    autofocus: true,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    enabled: !busy,
                    onFieldSubmitted: (_) => _handleConfirm(),
                    decoration: authInputDecoration(
                      context,
                      label: 'Código SMS',
                      icon: Icons.pin_outlined,
                    ),
                    validator: Validators.smsCode,
                  ),
                ),
              ],
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                child: _message == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: AuthMessage(_message!, type: _messageType),
                      ),
              ),
              const SizedBox(height: 24),
              if (!_codeSent)
                AuthPrimaryButton(
                  label: 'Enviar código SMS',
                  loadingLabel: 'Enviando...',
                  icon: Icons.send_rounded,
                  loading: _isSending,
                  onPressed: _handleSend,
                )
              else ...[
                AuthPrimaryButton(
                  label: 'Verificar código',
                  loadingLabel: 'Verificando...',
                  icon: Icons.verified_outlined,
                  loading: _isConfirming,
                  onPressed: _handleConfirm,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: busy ? null : _handleSend,
                  icon: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 20),
                  label: Text(_isSending ? 'Enviando...' : 'Reenviar código'),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: busy ? null : _handleChangeNumber,
                  child: const Text('Cambiar número'),
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.read<AuthProvider>().logout(),
                style: TextButton.styleFrom(foregroundColor: tokens.textSecondary),
                child: const Text('Cancelar y volver al inicio de sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
