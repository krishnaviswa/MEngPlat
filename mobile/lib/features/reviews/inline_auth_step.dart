import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:merchanthub_api/merchanthub_api.dart';
import 'package:merchanthub_mobile/ui/friendly_error.dart';

import '../auth/auth_provider.dart';
import '../auth/google_sign_in_button.dart';
import '../auth/phone_otp_panel.dart';

enum _Method { otp, password }

enum _Step { credentials, enroll, verify }

/// Sign-in surface hosted inline inside the QR review-collection flow (S-121),
/// rendered only when the customer taps "Post review" while unauthenticated.
/// Not a reuse of `LoginScreen` (that's a full `Scaffold`-owning page with a
/// "Create account"/"Continue as guest" footer and its own header — none of
/// which apply here). Composes the same reused widgets [PhoneOtpPanel] and
/// [GoogleSignInButton], plus a local password+TOTP mini state machine calling
/// the identical `authControllerProvider` methods `LoginScreen` calls.
///
/// Unlike its web counterpart there is no `onAuthenticated` callback: none of
/// [GoogleSignInButton]/[PhoneOtpPanel]/`AuthController`'s TOTP methods
/// navigate on mobile (ADR-018) — they only flip `authControllerProvider`'s
/// state, which the parent `CollectReviewScreen` observes itself via
/// `ref.listen` to trigger the auto-submit.
class InlineAuthStep extends ConsumerStatefulWidget {
  const InlineAuthStep({super.key});

  @override
  ConsumerState<InlineAuthStep> createState() => _InlineAuthStepState();
}

class _InlineAuthStepState extends ConsumerState<InlineAuthStep> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  _Method _method = _Method.otp;
  _Step _step = _Step.credentials;
  String? _mfaToken;
  TotpSetupResponse? _setup;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitCredentials() async {
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
      if (mounted) setState(() => _loading = false);
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
      if (mounted) setState(() => _loading = false);
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
      // Success flips authControllerProvider's state; CollectReviewScreen's
      // ref.listen picks it up and auto-submits (ADR-018) -- nothing to do here.
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
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Sign in to post your review', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _error!,
              key: const Key('inlineAuthError'),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        if (_step == _Step.credentials) ..._credentialsFields(theme),
        if (_step == _Step.enroll) ..._enrollFields(),
        if (_step == _Step.verify) ..._verifyFields(),
        if (_step != _Step.credentials) ...[
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('inlineAuthCodeSubmitButton'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: _loading || (_step == _Step.enroll && _setup == null) ? null : _submitCode,
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_step == _Step.enroll ? 'Confirm and sign in' : 'Verify and sign in'),
          ),
          TextButton(
            key: const Key('inlineAuthBackButton'),
            onPressed: _backToCredentials,
            child: const Text('Back'),
          ),
        ],
      ],
    );
  }

  List<Widget> _credentialsFields(ThemeData theme) {
    return [
      SegmentedButton<_Method>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: _Method.otp, label: Text('OTP', key: Key('inlineAuthMethodOtp'))),
          ButtonSegment(value: _Method.password, label: Text('Password', key: Key('inlineAuthMethodPassword'))),
        ],
        selected: {_method},
        onSelectionChanged: (next) {
          if (_loading || next.isEmpty) return;
          setState(() => _method = next.first);
        },
      ),
      const SizedBox(height: 16),
      if (_method == _Method.otp) const PhoneOtpPanel(role: UserRole.customer),
      if (_method == _Method.password) ...[
        TextField(
          key: const Key('inlineAuthEmailField'),
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('inlineAuthPasswordField'),
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Text(
          'Password sign-in uses an authenticator app next.',
          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('inlineAuthPasswordSubmitButton'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: _loading || _emailController.text.trim().isEmpty || _passwordController.text.isEmpty
              ? null
              : _submitCredentials,
          child: _loading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Sign in'),
        ),
      ],
      const SizedBox(height: 12),
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
    return TextField(
      key: const Key('inlineAuthCodeField'),
      controller: _codeController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(labelText: '6-digit code'),
    );
  }
}
