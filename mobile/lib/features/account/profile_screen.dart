import 'package:flutter/material.dart';
import 'package:merchanthub_mobile/ui/friendly_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../auth/auth_provider.dart';

typedef ProfileAvatarPicker = Future<({List<int> bytes, String filename})?> Function();

String? _blankToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Editable profile (S-029 / M-48). Email and role stay read-only.
/// Favorites remain on `/favorites` (M-43), not duplicated here.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({this.pickAvatar, super.key});

  final ProfileAvatarPicker? pickAvatar;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
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
    setState(() {
      _saving = true;
      _success = null;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(
            UserProfileUpdate((b) => b
              ..fullName = _nameController.text.trim()
              ..phone = _blankToNull(_phoneController.text)
              ..addressLine1 = _blankToNull(_address1Controller.text)
              ..addressLine2 = _blankToNull(_address2Controller.text)
              ..city = _blankToNull(_cityController.text)
              ..state = _blankToNull(_stateController.text)
              ..postalCode = _blankToNull(_postalController.text)
              ..country = _blankToNull(_countryController.text)
              ..nationalIdType = _nationalIdType
              ..nationalIdNumber = _blankToNull(_nationalIdController.text)),
          );
      setState(() => _success = 'Profile updated.');
    } catch (e) {
      setState(() => _error = friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _securityCopy(UserResponse user) {
    if (user.authProvider == 'google' && user.totpEnabled != true) {
      return 'You sign in with Gmail/Google. Authenticator MFA is not required on that path.';
    }
    if (user.totpEnabled == true) {
      return 'Authenticator app enabled — required for email/password sign-in.';
    }
    return 'Authenticator setup is required the next time you sign in with your password.';
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
                  Text('Email', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  Text(
                    user.email ?? 'No email on file',
                    key: const Key('profileEmailReadOnly'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Email changes aren\'t supported yet.',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  Text('Role', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  Text(user.role.name, key: const Key('profileRoleReadOnly'), style: const TextStyle(fontWeight: FontWeight.w600)),
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
                    Text(
                      _error!,
                      key: const Key('profileError'),
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
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
