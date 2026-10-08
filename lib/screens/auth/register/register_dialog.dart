import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/validators/validators.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

/// Opens the public sign-up over the login.
Future<void> showRegisterDialog(BuildContext context) => showAuthDialog<void>(context, (_) => const RegisterDialog());

/// Public sign-up: teachers only. The teacher's personal data is collected
/// here; the role is always `docente` and is assigned by
/// [AuthProvider.registerTeacher], never chosen here.
class RegisterDialog extends StatefulWidget {
  const RegisterDialog({super.key});

  @override
  State<RegisterDialog> createState() => _RegisterDialogState();
}

class _RegisterDialogState extends State<RegisterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _dniController = TextEditingController();
  final _celularController = TextEditingController();
  final _emailController = TextEditingController();
  DateTime? _fechaNacimiento;

  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _dniController.dispose();
    _celularController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().registerTeacher(
        correo: _emailController.text,
        nombre: _nombreController.text,
        apellidos: _apellidosController.text,
        dni: _dniController.text,
        celular: _celularController.text,
        fechaNacimiento: _fechaNacimiento!,
      );
      // The router moves to /verify-email, which removes the login and this
      // dialog with it; close it here only if it is somehow still on top.
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        Navigator.of(context).pop();
      }
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AuthDialog(
      icon: Icons.person_add_alt_1_rounded,
      title: 'Crear cuenta',
      subtitle:
          'Registro para docentes. Verificaremos tu correo y tu celular '
          'y luego crearás tu contraseña.',
      closable: !_isSubmitting,
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofocus: true,
                autofillHints: const [AutofillHints.givenName],
                inputFormatters: [LengthLimitingTextInputFormatter(80)],
                enabled: !_isSubmitting,
                decoration: authInputDecoration(context, label: 'Nombres', icon: Icons.person_outline_rounded),
                validator: (v) => Validators.required(v, field: 'El nombre'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _apellidosController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.familyName],
                inputFormatters: [LengthLimitingTextInputFormatter(80)],
                enabled: !_isSubmitting,
                decoration: authInputDecoration(context, label: 'Apellidos', icon: Icons.badge_outlined),
                validator: (v) => Validators.required(v, field: 'Los apellidos'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _dniController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                enabled: !_isSubmitting,
                decoration: authInputDecoration(context, label: 'DNI', icon: Icons.credit_card_rounded),
                validator: Validators.dni,
              ),
              const SizedBox(height: 14),
              FechaNacimientoField(
                valor: _fechaNacimiento,
                enabled: !_isSubmitting,
                onChanged: (fecha) => setState(() => _fechaNacimiento = fecha),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _celularController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumberNational],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
                enabled: !_isSubmitting,
                decoration: authCelularDecoration(context, helperText: 'Te enviaremos un código por SMS.'),
                validator: Validators.celular,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                autofillHints: const [AutofillHints.email],
                enabled: !_isSubmitting,
                onFieldSubmitted: (_) => _handleSubmit(),
                decoration: authInputDecoration(context, label: 'Correo electrónico', icon: Icons.mail_outline_rounded),
                validator: Validators.email,
              ),
              const SizedBox(height: 16),
              const _Pasos(),
              if (_error != null) ...[const SizedBox(height: 16), AuthMessage(_error!)],
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'Crear cuenta',
                loadingLabel: 'Creando cuenta...',
                icon: Icons.arrow_forward_rounded,
                loading: _isSubmitting,
                onPressed: _handleSubmit,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isSubmitting ? null : () => Navigator.of(context).maybePop(),
                style: TextButton.styleFrom(foregroundColor: tokens.textSecondary),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fecha de nacimiento: abre el calendario en la vista de años y valida la
/// edad con [Validators.fechaNacimiento]. También se usa en "Mi perfil".
class FechaNacimientoField extends StatelessWidget {
  final DateTime? valor;
  final bool enabled;
  final ValueChanged<DateTime> onChanged;

  const FechaNacimientoField({super.key, required this.valor, required this.onChanged, this.enabled = true});

  Future<void> _elegir(BuildContext context, FormFieldState<DateTime> campo) async {
    final hoy = DateTime.now();
    final ultima = DateTime(hoy.year - Validators.edadMinima, hoy.month, hoy.day);
    final elegida = await showDatePicker(
      context: context,
      initialDate: valor ?? DateTime(ultima.year - 12),
      firstDate: DateTime(hoy.year - Validators.edadMaxima),
      lastDate: ultima,
      initialDatePickerMode: valor == null ? DatePickerMode.year : DatePickerMode.day,
      helpText: 'Fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      fieldLabelText: 'Fecha (dd/mm/aaaa)',
    );
    if (elegida == null) return;
    onChanged(elegida);
    campo.didChange(elegida);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return FormField<DateTime>(
      initialValue: valor,
      validator: (_) => Validators.fechaNacimiento(valor),
      builder: (campo) {
        final fecha = valor;
        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: enabled ? () => _elegir(context, campo) : null,
          child: InputDecorator(
            isEmpty: fecha == null,
            decoration:
                authInputDecoration(
                  context,
                  label: 'Fecha de nacimiento',
                  icon: Icons.cake_outlined,
                  suffixIcon: const Icon(Icons.calendar_month_rounded),
                ).copyWith(
                  enabled: enabled,
                  errorText: campo.errorText,
                  helperText: fecha == null ? null : '${edadEn(fecha, DateTime.now())} años',
                ),
            child: fecha == null
                ? null
                : Text(
                    formatFechaLarga(fecha, conAnio: true),
                    style: TextStyle(fontSize: 16, color: tokens.textPrimary),
                  ),
          ),
        );
      },
    );
  }
}

/// The steps of the sign-up, so the teacher knows what comes next.
class _Pasos extends StatelessWidget {
  const _Pasos();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final primary = context.colors.primary;
    const pasos = ['Ingresa tus datos', 'Verifica tu correo', 'Verifica tu celular por SMS', 'Crea tu contraseña'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: tokens.surfaceMuted, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          for (var i = 0; i < pasos.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: primary.withValues(alpha: context.isDark ? 0.22 : 0.12),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(pasos[i], style: TextStyle(fontSize: 13.5, color: tokens.textPrimary)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
