import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import 'auth_provider.dart';
import 'google_sign_in_button.dart';
import 'google_sign_in_client.dart';
import 'phone_otp_panel.dart';
import '../../ui/friendly_error.dart';
import '../../ui/widgets.dart';
import '../theme/theme_toggle_button.dart';

/// Customer / merchant sign-up. Password accounts must still enroll TOTP on
/// first login (web `RegisterForm`). Google skips MFA and always creates a
/// customer when the account is new.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  UserRole _role = UserRole.customer;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // PhoneOtpPanel below reads _nameController.text/_role at build time, so
    // it needs a rebuild whenever the in-progress name changes too, not just
    // when _role's own onChanged fires setState.
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() => setState(() {});

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).register(
            email: _emailController.text.trim(),
            fullName: _nameController.text.trim(),
            password: _passwordController.text,
            role: _role,
          );
      if (!mounted) return;
      final email = Uri.encodeComponent(_emailController.text.trim());
      context.go('/login?registered=1&email=$email');
    } catch (e) {
      setState(() => _error = friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onGoogleCredential(String credential) async {
    setState(() => _error = null);
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle(credential: credential);
    } catch (e) {
      setState(() => _error = friendlyMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account'), actions: const [ThemeToggleButton()]),
      body: MhCanvas(
        child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MhAuthHeader(title: 'Create account', subtitle: 'Join MerchantHub in a minute'),
                  const SizedBox(height: 24),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        key: const Key('registerError'),
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  TextFormField(
                    key: const Key('registerFullNameField'),
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('registerEmailField'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) => (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('registerPasswordField'),
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password (min 12 chars, letter + digit)'),
                    validator: (value) => (value == null || value.length < 12) ? 'Password is too short' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UserRole>(
                    key: const Key('roleDropdown'),
                    initialValue: UserRole.customer,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'I am a'),
                    items: const [
                      DropdownMenuItem(value: UserRole.customer, child: Text('Customer')),
                      DropdownMenuItem(value: UserRole.merchant, child: Text('Merchant')),
                    ],
                    onChanged: _loading ? null : (value) => setState(() => _role = value ?? UserRole.customer),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    googleSignInIsConfigured(ref.watch(googleSignInClientProvider))
                        ? 'After sign-up you will set up an authenticator app (required for email/password sign-in). '
                            'Gmail sign-in below skips that step.'
                        : 'After sign-up you will set up an authenticator app (required for email/password sign-in).',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const Key('registerSubmitButton'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign up'),
                  ),
                  TextButton(
                    key: const Key('signInLink'),
                    onPressed: _loading ? null : () => context.go('/login'),
                    child: const Text('Already have an account? Sign in'),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('or')),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GoogleSignInButton(
                    onCredential: _onGoogleCredential,
                    onError: (message) => setState(() => _error = message),
                    enabled: !_loading,
                  ),
                  const SizedBox(height: 8),
                  PhoneOtpPanel(
                    fullName: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
                    role: _role,
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
