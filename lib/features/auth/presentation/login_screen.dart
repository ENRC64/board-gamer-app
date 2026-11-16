import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/custom_button.dart';
import 'auth_controller.dart';

/// Anmelden und Registrieren in einem Screen (Umschalter).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegister = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final controller = ref.read(authControllerProvider.notifier);
    if (_isRegister) {
      await controller.signUp(
        _emailController.text,
        _passwordController.text,
        _nameController.text,
      );
    } else {
      await controller.signIn(_emailController.text, _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(authControllerProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.casino_outlined,
                      size: 72,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Board-Gamer-App',
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _isRegister
                          ? 'Neues Konto für die Spielgruppe anlegen'
                          : 'Willkommen zurück',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Anmelden')),
                        ButtonSegment(value: true, label: Text('Registrieren')),
                      ],
                      selected: {_isRegister},
                      onSelectionChanged: isLoading
                          ? null
                          : (s) => setState(() => _isRegister = s.first),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (_isRegister) ...[
                      TextFormField(
                        key: const Key('nameField'),
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Anzeigename',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().length < 2)
                            ? 'Bitte einen Namen mit mindestens 2 Zeichen eingeben.'
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    TextFormField(
                      key: const Key('emailField'),
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-Mail',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      validator: validateEmail,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      key: const Key('passwordField'),
                      controller: _passwordController,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Passwort',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscure
                              ? 'Passwort anzeigen'
                              : 'Passwort verbergen',
                          icon: Icon(
                            _obscure ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      onFieldSubmitted: (_) => _submit(),
                      validator: validatePassword,
                    ),
                    if (state.hasError) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        state.error.toString(),
                        key: const Key('authError'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    CustomButton(
                      key: const Key('submitButton'),
                      label: _isRegister ? 'Konto anlegen' : 'Anmelden',
                      isLoading: isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Prüft das E-Mail-Format (einfach, die genaue Prüfung macht Firebase).
String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Bitte eine E-Mail-Adresse eingeben.';
  final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  return pattern.hasMatch(v)
      ? null
      : 'Bitte eine gültige E-Mail-Adresse eingeben.';
}

/// Firebase verlangt mindestens 6 Zeichen.
String? validatePassword(String? value) {
  final v = value ?? '';
  if (v.isEmpty) return 'Bitte ein Passwort eingeben.';
  return v.length < 6 ? 'Das Passwort braucht mindestens 6 Zeichen.' : null;
}
