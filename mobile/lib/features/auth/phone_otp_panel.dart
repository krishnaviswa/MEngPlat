import 'package:flutter/material.dart';
import 'package:merchanthub_mobile/ui/friendly_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import 'auth_provider.dart';

/// Phone OTP sign-in/sign-up panel (S-055 / M-74), mirrors
/// frontend/src/components/PhoneOtpPanel.tsx. Embedded in both LoginScreen
/// (fullName/role omitted -- a brand-new number surfaces the backend's "full
/// name required" error, same as web) and RegisterScreen (supplies the
/// in-progress registration form's fullName/role). Skips TOTP entirely on
/// success, same trust model as Google.
class PhoneOtpPanel extends ConsumerStatefulWidget {
  const PhoneOtpPanel({super.key, this.fullName, this.role});

  final String? fullName;
  final UserRole? role;

  @override
  ConsumerState<PhoneOtpPanel> createState() => _PhoneOtpPanelState();
}

class _PhoneOtpPanelState extends ConsumerState<PhoneOtpPanel> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  String _countryCode = '+91';
  bool _sent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).requestPhoneOtp(
            phone: '$_countryCode${_phoneController.text.trim()}',
          );
      setState(() => _sent = true);
    } catch (e) {
      setState(() => _error = friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyCode() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).signInWithPhone(
            phone: '$_countryCode${_phoneController.text.trim()}',
            code: _codeController.text.trim(),
            fullName: widget.fullName,
            role: widget.role,
          );
      // Success flips authControllerProvider's state to a real user; router redirects.
    } catch (e) {
      setState(() => _error = friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSend = !_busy && !_sent && _phoneController.text.trim().isNotEmpty;
    final canVerify = !_busy && _codeController.text.trim().length >= 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _error!,
              key: const Key('phoneOtpError'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Row(
          children: [
            DropdownButton<String>(
              key: const Key('phoneCountryCodeField'),
              value: _countryCode,
              items: const [
                DropdownMenuItem(value: '+91', child: Text('+91')),
                DropdownMenuItem(value: '+1', child: Text('+1')),
              ],
              onChanged: _busy || _sent ? null : (value) => setState(() => _countryCode = value ?? '+91'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                key: const Key('phoneNumberField'),
                controller: _phoneController,
                enabled: !_busy && !_sent,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile number'),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!_sent)
          OutlinedButton(
            key: const Key('sendPhoneCodeButton'),
            onPressed: canSend ? _sendCode : null,
            child: const Text('Send SMS code'),
          )
        else ...[
          TextField(
            key: const Key('phoneCodeField'),
            controller: _codeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '6-digit code'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('verifyPhoneCodeButton'),
            onPressed: canVerify ? _verifyCode : null,
            child: const Text('Verify and sign in'),
          ),
        ],
      ],
    );
  }
}
