import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_provider.dart';
import '../../ui/friendly_error.dart';
import '../../ui/widgets.dart';
import '../theme/theme_toggle_button.dart';

/// Request half of forgot/reset password (S-054 / M-65). Mirrors
/// frontend/src/components/ForgotPasswordForm.tsx. No in-app reset screen:
/// no deep-link infra exists yet and the emailed reset link always points at
/// the web app, so the confirmation state sends users there instead.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _loading = false;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).forgotPassword(email: _emailController.text.trim());
      setState(() => _submitted = true);
    } catch (e) {
      setState(() => _error = friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password'), actions: const [ThemeToggleButton()]),
      body: MhCanvas(
        child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const MhAuthHeader(
                  title: 'Forgot password',
                  subtitle: 'We’ll email a reset link that opens in the web app.',
                ),
                const SizedBox(height: 16),
                ...(_submitted ? _confirmationFields() : _formFields()),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  List<Widget> _formFields() {
    return [
      const Text(
        'Enter the email on your account. If it matches one, we\'ll send password-reset instructions to it.',
      ),
      const SizedBox(height: 16),
      Form(
        key: _formKey,
        child: TextFormField(
          key: const Key('emailField'),
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
          validator: (value) => (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
        ),
      ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            _error!,
            key: const Key('forgotPasswordError'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      const SizedBox(height: 16),
      FilledButton(
        key: const Key('submitButton'),
        onPressed: _loading ? null : _submit,
        child: _loading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Send reset instructions'),
      ),
      TextButton(
        key: const Key('backToSignInLink'),
        onPressed: _loading ? null : () => context.go('/login'),
        child: const Text('Back to sign in'),
      ),
    ];
  }

  List<Widget> _confirmationFields() {
    return [
      const Text(
        'If an account exists for that email, we sent password-reset instructions.',
        key: Key('forgotPasswordConfirmation'),
      ),
      const SizedBox(height: 12),
      Text(
        'Open the link from that email in your phone\'s browser to finish resetting your password.',
        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 16),
      TextButton(
        key: const Key('backToSignInLink'),
        onPressed: () => context.go('/login'),
        child: const Text('Back to sign in'),
      ),
    ];
  }
}
