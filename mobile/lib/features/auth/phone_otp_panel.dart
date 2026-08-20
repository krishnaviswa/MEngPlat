import 'package:flutter/material.dart';
import 'package:merchanthub_mobile/ui/friendly_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import 'auth_provider.dart';

/// Phone OTP sign-in/sign-up panel (S-055 / M-74), mirrors
/// frontend/src/components/PhoneOtpPanel.tsx. Embedded in both LoginScreen
/// and RegisterScreen. New numbers get an optional name; the backend generates
/// a User ID when name is omitted. Skips TOTP on success, same as Google.
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
  final _nameController = TextEditingController();

  String _countryCode = '+91';
  bool _sent = false;
  bool _busy = false;
  String? _error;

  static const _filled48 = Size.fromHeight(48);

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _nameController.dispose();
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
      final typed = _nameController.text.trim();
      await ref.read(authControllerProvider.notifier).signInWithPhone(
            phone: '$_countryCode${_phoneController.text.trim()}',
            code: _codeController.text.trim(),
            fullName: typed.isEmpty ? widget.fullName : typed,
            role: widget.role,
          );
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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _error!,
              key: const Key('phoneOtpError'),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        InputDecorator(
          key: const Key('phoneNumberRow'),
          decoration: const InputDecoration(
            labelText: 'Mobile number',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    key: const Key('phoneCountryCodeField'),
                    value: _countryCode,
                    items: const [
                      DropdownMenuItem(value: '+91', child: Text('+91')),
                      DropdownMenuItem(value: '+1', child: Text('+1')),
                    ],
                    onChanged: _busy || _sent ? null : (value) => setState(() => _countryCode = value ?? '+91'),
                  ),
                ),
                const VerticalDivider(width: 16),
                Expanded(
                  child: TextField(
                    key: const Key('phoneNumberField'),
                    controller: _phoneController,
                    enabled: !_busy && !_sent,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: '98765 43210',
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (!_sent)
          FilledButton(
            key: const Key('sendPhoneCodeButton'),
            style: FilledButton.styleFrom(minimumSize: _filled48),
            onPressed: canSend ? _sendCode : null,
            child: const Text('Send SMS code'),
          )
        else ...[
          if (widget.fullName == null || widget.fullName!.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                key: const Key('phoneOptionalNameField'),
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name (optional)',
                  helperText: 'We’ll generate a User ID if you leave this blank.',
                ),
              ),
            ),
          TextField(
            key: const Key('phoneCodeField'),
            controller: _codeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '6-digit code'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          FilledButton(
            key: const Key('verifyPhoneCodeButton'),
            style: FilledButton.styleFrom(minimumSize: _filled48),
            onPressed: canVerify ? _verifyCode : null,
            child: const Text('Verify and sign in'),
          ),
        ],
      ],
    );
  }
}
