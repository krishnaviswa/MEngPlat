import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import 'auth_provider.dart';
import 'google_sign_in_button.dart';
import 'google_sign_in_client.dart';
import 'phone_otp_panel.dart';
import '../../ui/friendly_error.dart';
import '../../ui/widgets.dart';
import '../theme/theme_toggle_button.dart';

enum _Step { credentials, enroll, verify }

enum _LoginMethod { password, phone, authenticator }

/// Password login (mandatory authenticator, see S-020): credentials, then
/// either a first-time enrollment step (QR + secret) or a returning-user
/// code-verify step. Mirrors frontend/src/components/LoginForm.tsx.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.registered = false, this.prefillEmail});

  final bool registered;
  final String? prefillEmail;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  _Step _step = _Step.credentials;
  _LoginMethod _loginMethod = _LoginMethod.password;
  String? _mfaToken;
  TotpSetupResponse? _setup;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final prefill = widget.prefillEmail;
    if (prefill != null && prefill.isNotEmpty) {
      _emailController.text = prefill;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_step == _Step.credentials) {
      await _submitCredentials();
      return;
    }
    await _submitCode();
  }

  Future<void> _submitCredentials() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(authControllerProvider.notifier).submitCredentials(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (result.mfaEnrollmentRequired == true && result.mfaToken != null) {
        setState(() {
          _mfaToken = result.mfaToken;
          _step = _Step.enroll;
          _setup = null;
        });
        await _loadSetup();
        return;
      }
      if (result.mfaRequired == true && result.mfaToken != null) {
        setState(() => _step = _Step.verify);
        _mfaToken = result.mfaToken;
        return;
      }
      setState(() => _error = 'Unexpected login response');
    } catch (e) {
      setState(() => _error = friendlyMessage(e));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadSetup() async {
    setState(() => _loading = true);
    try {
      final setup = await ref.read(authControllerProvider.notifier).startTotpEnrollment(mfaToken: _mfaToken!);
      setState(() => _setup = setup);
    } catch (e) {
      setState(() => _error = friendlyMessage(e));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitCode() async {
    final mfaToken = _mfaToken;
    if (mfaToken == null) {
      setState(() {
        _step = _Step.credentials;
        _error = 'Session expired — sign in again';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final notifier = ref.read(authControllerProvider.notifier);
      if (_step == _Step.enroll) {
        await notifier.confirmTotpEnrollment(mfaToken: mfaToken, code: _codeController.text.trim());
      } else {
        await notifier.verifyTotp(mfaToken: mfaToken, code: _codeController.text.trim());
      }
      // Success flips authControllerProvider's state to a real user; router redirects.
    } catch (e) {
      setState(() => _error = friendlyMessage(e));
    } finally {
      setState(() => _loading = false);
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

  void _backToCredentials() {
    setState(() {
      _step = _Step.credentials;
      _mfaToken = null;
      _setup = null;
      _codeController.clear();
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titleFor(_step)), actions: const [ThemeToggleButton()]),
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
                  MhAuthHeader(
                    title: 'MerchantHub',
                    subtitle: _step == _Step.credentials ? 'Sign in to continue' : null,
                  ),
                  const SizedBox(height: 24),
                  if (widget.registered && _step == _Step.credentials)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Account created. Sign in with your password to set up your authenticator app.',
                        key: const Key('registeredNote'),
                        style: TextStyle(color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  if (_step == _Step.credentials) ..._credentialsFields(),
                  if (_step == _Step.enroll) ..._enrollFields(),
                  if (_step == _Step.verify) ..._verifyFields(),
                  if (_step != _Step.credentials || _loginMethod != _LoginMethod.phone) ...[
                    const SizedBox(height: 12),
                    FilledButton(
                      key: const Key('submitButton'),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      onPressed: _loading || (_step == _Step.enroll && _setup == null) ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_buttonLabelFor(_step)),
                    ),
                  ],
                  if (_step != _Step.credentials)
                    TextButton(
                      key: const Key('backButton'),
                      onPressed: _backToCredentials,
                      child: const Text('Back'),
                    ),
                  if (_step == _Step.credentials) ...[
                    TextButton(
                      key: const Key('createAccountLink'),
                      onPressed: _loading ? null : () => context.go('/register'),
                      child: const Text('Create account'),
                    ),
                    FilledButton(
                      key: const Key('continueAsGuestButton'),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      onPressed: _loading ? null : () => context.go('/home'),
                      child: const Text('Continue without signing in'),
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
                  ],
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }

  List<Widget> _credentialsFields() {
    return [
      SegmentedButton<_LoginMethod>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(
            value: _LoginMethod.password,
            label: Text('Password', key: Key('loginMethodPassword')),
          ),
          ButtonSegment(
            value: _LoginMethod.phone,
            label: Text('Phone', key: Key('loginMethodPhone')),
          ),
          ButtonSegment(
            value: _LoginMethod.authenticator,
            label: Text('Authenticator', key: Key('loginMethodAuthenticator')),
          ),
        ],
        selected: {_loginMethod},
        onSelectionChanged: (next) {
          if (_loading || next.isEmpty) return;
          setState(() => _loginMethod = next.first);
        },
      ),
      const SizedBox(height: 16),
      if (_loginMethod == _LoginMethod.phone) const PhoneOtpPanel(),
      if (_loginMethod != _LoginMethod.phone) ...[
        TextFormField(
          key: const Key('emailField'),
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
          validator: (value) => (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('passwordField'),
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
          validator: (value) => (value == null || value.length < 8) ? 'Password is too short' : null,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            key: const Key('forgotPasswordLink'),
            onPressed: _loading ? null : () => context.go('/forgot-password'),
            child: const Text('Forgot password?'),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _loginMethod == _LoginMethod.authenticator
              ? "You'll enter your authenticator code next"
              : googleSignInIsConfigured(ref.watch(googleSignInClientProvider))
                  ? 'Email and password sign-in requires an authenticator app (Google Authenticator, Authy, etc.). '
                      'Gmail sign-in below skips that step.'
                  : 'Email and password sign-in requires an authenticator app (Google Authenticator, Authy, etc.).',
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    ];
  }

  List<Widget> _enrollFields() {
    final setup = _setup;
    return [
      const Text(
        'Scan this QR code with your authenticator app, or enter the secret manually. '
        'Then enter the 6-digit code to finish.',
      ),
      const SizedBox(height: 12),
      if (setup != null) ...[
        Center(child: SizedBox(width: 180, height: 180, child: SvgPicture.string(setup.qrSvg))),
        const SizedBox(height: 8),
        SelectableText(
          setup.secret,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ] else
        const Center(child: Padding(padding: EdgeInsets.all(12), child: Text('Preparing authenticator…'))),
      const SizedBox(height: 12),
      _codeField(),
    ];
  }

  List<Widget> _verifyFields() {
    return [
      const Text('Enter the 6-digit code from your authenticator app.'),
      const SizedBox(height: 12),
      _codeField(),
    ];
  }

  Widget _codeField() {
    return TextFormField(
      key: const Key('mfaCodeField'),
      controller: _codeController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(labelText: '6-digit code'),
    );
  }

  String _titleFor(_Step step) => switch (step) {
        _Step.credentials => 'Sign in',
        _Step.enroll => 'Set up authenticator',
        _Step.verify => 'Authenticator code',
      };

  String _buttonLabelFor(_Step step) => switch (step) {
        _Step.credentials => 'Sign in',
        _Step.enroll => 'Confirm and sign in',
        _Step.verify => 'Verify and sign in',
      };
}
