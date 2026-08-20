import 'package:flutter/material.dart';
import 'package:merchanthub_mobile/ui/friendly_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../../ui/widgets.dart';
import '../auth/auth_provider.dart';

typedef ProfileAvatarPicker = Future<({List<int> bytes, String filename})?> Function();

String? _blankToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

bool _looksMaskedNationalId(String? value) {
  if (value == null || value.isEmpty) return false;
  return value.contains('*') || value.contains('•');
}

String _roleLabel(UserRole role) {
  if (role == UserRole.merchant) return 'Merchant';
  if (role == UserRole.admin) return 'Admin';
  return 'Customer';
}

enum _ReauthMethod { password, phone, authenticator }

/// Editable profile (S-029 / M-48 / S-107). Role is a read-only chip.
/// Email edits require step-up reauth before PATCH. Favorites stay on `/favorites`.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({this.pickAvatar, super.key});

  final ProfileAvatarPicker? pickAvatar;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalController = TextEditingController();
  final _countryController = TextEditingController();
  final _nationalIdController = TextEditingController();

  NationalIdType? _nationalIdType;
  bool _hydrated = false;
  bool _saving = false;
  String? _success;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalController.dispose();
    _countryController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }

  void _hydrate(UserResponse user) {
    _nameController.text = user.fullName;
    _emailController.text = user.email ?? '';
    _phoneController.text = user.phone ?? '';
    _address1Controller.text = user.addressLine1 ?? '';
    _address2Controller.text = user.addressLine2 ?? '';
    _cityController.text = user.city ?? '';
    _stateController.text = user.state ?? '';
    _postalController.text = user.postalCode ?? '';
    _countryController.text = user.country ?? '';
    _nationalIdType = user.nationalIdType;
    _nationalIdController.text = user.nationalIdNumber ?? '';
    _hydrated = true;
  }

  Future<void> _changeAvatar() async {
    setState(() {
      _saving = true;
      _success = null;
      _error = null;
    });
    try {
      final picker = widget.pickAvatar ??
          () async {
            final file = await ImagePicker().pickImage(source: ImageSource.gallery);
            if (file == null) return null;
            return (bytes: await file.readAsBytes(), filename: file.name);
          };
      final picked = await picker();
      if (picked == null) return;
      await ref.read(authControllerProvider.notifier).uploadAvatar(bytes: picked.bytes, filename: picked.filename);
      setState(() => _success = 'Photo updated.');
    } catch (e) {
      setState(() => _error = friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;

    final newEmail = _emailController.text.trim();
    final oldEmail = (user.email ?? '').trim();
    final emailChanged = newEmail != oldEmail;

    String? reauthToken;
    if (emailChanged) {
      final method = await _pickReauthMethod();
      if (method == null || !mounted) return;
      reauthToken = await _completeReauth(method, user);
      if (reauthToken == null || !mounted) return;
    }

    setState(() {
      _saving = true;
      _success = null;
      _error = null;
    });
    try {
      final idNumber = _blankToNull(_nationalIdController.text);
      await ref.read(authControllerProvider.notifier).updateProfile(
            UserProfileUpdate((b) {
              b
                ..fullName = _nameController.text.trim()
                ..phone = _blankToNull(_phoneController.text)
                ..addressLine1 = _blankToNull(_address1Controller.text)
                ..addressLine2 = _blankToNull(_address2Controller.text)
                ..city = _blankToNull(_cityController.text)
                ..state = _blankToNull(_stateController.text)
                ..postalCode = _blankToNull(_postalController.text)
                ..country = _blankToNull(_countryController.text)
                ..nationalIdType = _nationalIdType;
              if (!_looksMaskedNationalId(idNumber)) {
                b.nationalIdNumber = idNumber;
              }
            }),
            reauthToken: reauthToken,
            email: emailChanged ? (newEmail.isEmpty ? null : newEmail) : null,
            includeEmail: emailChanged,
          );
      setState(() => _success = 'Profile updated.');
    } catch (e) {
      setState(() => _error = friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<_ReauthMethod?> _pickReauthMethod() {
    return showModalBottomSheet<_ReauthMethod>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('reauthPassword'),
              title: const Text('Password'),
              onTap: () => Navigator.pop(ctx, _ReauthMethod.password),
            ),
            ListTile(
              key: const Key('reauthPhone'),
              title: const Text('Phone OTP'),
              onTap: () => Navigator.pop(ctx, _ReauthMethod.phone),
            ),
            ListTile(
              key: const Key('reauthAuthenticator'),
              title: const Text('Authenticator'),
              onTap: () => Navigator.pop(ctx, _ReauthMethod.authenticator),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _completeReauth(_ReauthMethod method, UserResponse user) async {
    final notifier = ref.read(authControllerProvider.notifier);
    try {
      switch (method) {
        case _ReauthMethod.password:
          final password = await _promptSecret(
            title: 'Confirm with password',
            label: 'Password',
            obscure: true,
          );
          if (password == null || password.isEmpty) return null;
          return notifier.reauth(password: password);
        case _ReauthMethod.phone:
          final phone = user.phone?.trim() ?? '';
          if (phone.isEmpty) {
            setState(() => _error = 'Add a mobile number before using phone verification.');
            return null;
          }
          await notifier.requestPhoneOtp(phone: phone);
          final code = await _promptSecret(
            title: 'Enter the SMS code',
            label: '6-digit code',
          );
          if (code == null || code.isEmpty) return null;
          return notifier.reauth(phone: phone, otpCode: code);
        case _ReauthMethod.authenticator:
          final code = await _promptSecret(
            title: 'Authenticator code',
            label: '6-digit code',
          );
          if (code == null || code.isEmpty) return null;
          return notifier.reauth(totpCode: code);
      }
    } catch (e) {
      if (mounted) setState(() => _error = friendlyMessage(e));
      return null;
    }
  }

  Future<String?> _promptSecret({
    required String title,
    required String label,
    bool obscure = false,
  }) async {
    final controller = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: obscure,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue')),
        ],
      ),
    );
    final value = controller.text.trim();
    controller.dispose();
    if (submitted != true) return null;
    return value;
  }

  String _securityCopy(UserResponse user) {
    if (user.totpEnabled == true) {
      return 'Authenticator app enabled.';
    }
    if (user.authProvider == 'google') {
      return 'You sign in with Gmail/Google. Authenticator MFA is not required on that path.';
    }
    return 'You can sign in with password, phone, or an authenticator app.';
  }

  String _nationalIdHelperText(UserResponse user) {
    if (user.role == UserRole.merchant) {
      return 'Required for merchants before you can submit a listing. Stored for your account — not verified as government KYC.';
    }
    return 'Optional. Stored for your account only — not verified as KYC in this version.';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    if (user != null && !_hydrated) {
      _hydrate(user);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const Center(child: Text('Sign in to view your profile'))
          : Form(
              key: _formKey,
              child: ListView(
                key: const Key('profileScreen'),
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    key: const Key('fullNameField'),
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Display name'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('phoneField'),
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile number',
                      helperText: 'Used for account contact. Password sign-in uses an authenticator app, not SMS.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const Key('changeAvatarButton'),
                    onPressed: _saving ? null : _changeAvatar,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Change photo'),
                  ),
                  const SizedBox(height: 16),
                  Text('Address', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('addressLine1Field'),
                    controller: _address1Controller,
                    decoration: const InputDecoration(labelText: 'Address line 1'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('addressLine2Field'),
                    controller: _address2Controller,
                    decoration: const InputDecoration(labelText: 'Address line 2'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('cityField'),
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('stateField'),
                    controller: _stateController,
                    decoration: const InputDecoration(labelText: 'State'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('postalCodeField'),
                    controller: _postalController,
                    decoration: const InputDecoration(labelText: 'Postal code'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('countryField'),
                    controller: _countryController,
                    decoration: const InputDecoration(labelText: 'Country'),
                  ),
                  const SizedBox(height: 16),
                  Text('National ID', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<NationalIdType?>(
                    key: const Key('nationalIdTypeDropdown'),
                    initialValue: _nationalIdType,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'ID type'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Select type')),
                      DropdownMenuItem(value: NationalIdType.pan, child: Text('PAN (India)')),
                      DropdownMenuItem(value: NationalIdType.aadhaar, child: Text('Aadhaar (India)')),
                      DropdownMenuItem(value: NationalIdType.other, child: Text('Other national ID')),
                    ],
                    onChanged: _saving ? null : (value) => setState(() => _nationalIdType = value),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('nationalIdNumberField'),
                    controller: _nationalIdController,
                    decoration: InputDecoration(
                      labelText: 'ID number',
                      helperText: _nationalIdHelperText(user),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('profileEmailReadOnly'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      helperText: 'Changing email requires confirming your identity.',
                    ),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) return null;
                      if (!trimmed.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Text('Role', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      label: Text(
                        _roleLabel(user.role),
                        key: const Key('profileRoleReadOnly'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Sign-in security', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  Text(_securityCopy(user)),
                  const SizedBox(height: 12),
                  if (_success != null)
                    Text(
                      _success!,
                      key: const Key('profileSuccess'),
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),
                  if (_error != null)
                    MhError(
                      key: const Key('profileError'),
                      error: _error!,
                    ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const Key('saveProfileButton'),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save changes'),
                  ),
                ],
              ),
            ),
    );
  }
}
