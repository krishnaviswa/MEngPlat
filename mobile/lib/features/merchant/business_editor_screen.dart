import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:merchanthub_mobile/core/network/api_exception.dart';
import 'package:merchanthub_mobile/ui/friendly_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../../ui/nav.dart';
import '../businesses/business_list_provider.dart';
import 'country_state.dart';
import 'merchant_providers.dart';

const _fieldGap = SizedBox(height: 14);

/// Create or edit a merchant business (M-54). Hours/gallery upload stay n/a (M-55/M-56).
class BusinessEditorScreen extends ConsumerStatefulWidget {
  const BusinessEditorScreen({this.businessId, super.key});

  final String? businessId;

  bool get isEditing => businessId != null;

  @override
  ConsumerState<BusinessEditorScreen> createState() => _BusinessEditorScreenState();
}

final _emailFormat = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
final _phoneFormat = RegExp(r'^\+?\d{7,15}$');

class _BusinessEditorScreenState extends ConsumerState<BusinessEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _postal = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _website = TextEditingController();
  final _addressOtp = TextEditingController();
  final Set<String> _categoryIds = {};
  String _country = 'IN';
  String? _stateCode;
  String? _error;
  bool _saving = false;
  bool _hydrated = false;
  bool _addressOtpRequired = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _address.dispose();
    _city.dispose();
    _postal.dispose();
    _phone.dispose();
    _email.dispose();
    _website.dispose();
    _addressOtp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(searchFacetsProvider);
    if (widget.isEditing && !_hydrated) {
      final owned = ref.watch(ownedBusinessesProvider).valueOrNull ?? const [];
      final match = owned.where((b) => b.id == widget.businessId);
      if (match.isNotEmpty) {
        _hydrate(match.first);
      }
    }

    final theme = Theme.of(context);
    final states = getStatesForCountry(_country);
    final apiCities = categoriesAsync.valueOrNull?.$1 ?? const <String>[];
    final cities = citySuggestions(countryCode: _country, fromApi: apiCities, current: _city.text);

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit business' : 'Create business')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget.isEditing) ...[
                Text(
                  '* Required field',
                  key: const Key('requiredFieldLegend'),
                  style: theme.textTheme.bodySmall,
                ),
                _fieldGap,
              ],
              TextFormField(
                key: const Key('businessNameField'),
                controller: _name,
                style: theme.textTheme.bodyLarge,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Name is required' : null,
              ),
              _fieldGap,
              TextFormField(
                controller: _description,
                style: theme.textTheme.bodyLarge,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              _fieldGap,
              TextFormField(
                key: const Key('businessAddressField'),
                controller: _address,
                style: theme.textTheme.bodyLarge,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Address is required' : null,
              ),
              _fieldGap,
              DropdownButtonFormField<String>(
                key: const Key('businessCountryField'),
                isExpanded: true,
                initialValue: getCountries().any((c) => c.code == _country) ? _country : null,
                decoration: const InputDecoration(labelText: 'Country'),
                items: [
                  for (final country in getCountries())
                    DropdownMenuItem(value: country.code, child: Text(country.name, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (code) {
                  if (code == null) return;
                  setState(() {
                    _country = code;
                    _stateCode = matchingStateCode(code, _stateCode);
                  });
                },
              ),
              _fieldGap,
              if (states.isNotEmpty)
                DropdownButtonFormField<String>(
                  key: const Key('businessStateField'),
                  isExpanded: true,
                  initialValue: states.any((s) => s.code == _stateCode) ? _stateCode : null,
                  decoration: const InputDecoration(labelText: 'State'),
                  items: [
                    for (final state in states)
                      DropdownMenuItem(value: state.code, child: Text(state.name, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (code) => setState(() => _stateCode = code),
                )
              else
                InputDecorator(
                  key: const Key('businessStateField'),
                  decoration: const InputDecoration(labelText: 'State', hintText: 'Not applicable'),
                  child: Text('Not applicable', style: theme.textTheme.bodyLarge),
                ),
              _fieldGap,
              if (cities.isNotEmpty)
                DropdownButtonFormField<String>(
                  key: const Key('businessCityPicker'),
                  isExpanded: true,
                  initialValue: () {
                    final typed = _city.text.trim();
                    if (typed.isEmpty) return null;
                    for (final city in cities) {
                      if (city.toLowerCase() == typed.toLowerCase()) return city;
                    }
                    return null;
                  }(),
                  decoration: const InputDecoration(labelText: 'City'),
                  items: [
                    for (final city in cities)
                      DropdownMenuItem(value: city, child: Text(city, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (city) {
                    if (city == null) return;
                    setState(() => _city.text = city);
                  },
                ),
              if (cities.isNotEmpty) _fieldGap,
              TextFormField(
                controller: _city,
                key: const Key('businessCityField'),
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  labelText: cities.isEmpty ? 'City' : 'Or type a city',
                  helperText: cities.isEmpty ? null : 'Pick above or type if yours is missing.',
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'City is required' : null,
              ),
              _fieldGap,
              TextFormField(
                controller: _postal,
                style: theme.textTheme.bodyLarge,
                keyboardType: TextInputType.streetAddress,
                decoration: const InputDecoration(
                  labelText: 'Postal code',
                  helperText: 'PIN / ZIP, not the state name.',
                ),
              ),
              _fieldGap,
              TextFormField(
                key: const Key('businessPhoneField'),
                controller: _phone,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(labelText: widget.isEditing ? 'Phone' : 'Phone *'),
                keyboardType: TextInputType.phone,
                validator: widget.isEditing ? null : _validatePhone,
              ),
              _fieldGap,
              TextFormField(
                key: const Key('businessEmailField'),
                controller: _email,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(labelText: widget.isEditing ? 'Email' : 'Email *'),
                keyboardType: TextInputType.emailAddress,
                validator: widget.isEditing ? null : _validateEmail,
              ),
              _fieldGap,
              TextFormField(
                controller: _website,
                style: theme.textTheme.bodyLarge,
                decoration: const InputDecoration(labelText: 'Website'),
              ),
              _fieldGap,
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
                data: (facets) {
                  final categories = facets.$2;
                  if (categories.isEmpty) return const SizedBox.shrink();
                  return Wrap(
                    spacing: 8,
                    children: [
                      for (final category in categories)
                        FilterChip(
                          label: Text(category.name, style: theme.textTheme.labelLarge),
                          selected: _categoryIds.contains(category.id),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _categoryIds.add(category.id);
                              } else {
                                _categoryIds.remove(category.id);
                              }
                            });
                          },
                        ),
                    ],
                  );
                },
              ),
              if (_addressOtpRequired) ...[
                _fieldGap,
                Text(
                  'Confirm this address change — enter the code sent to your business phone.',
                  style: theme.textTheme.bodyMedium,
                ),
                _fieldGap,
                TextFormField(
                  key: const Key('addressOtpField'),
                  controller: _addressOtp,
                  style: theme.textTheme.bodyLarge,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'OTP'),
                ),
              ],
              if (_error != null) ...[
                _fieldGap,
                Text(_error!, key: const Key('businessEditorError'), style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('businessEditorSave'),
                onPressed: _saving ? null : _save,
                child: Text(
                  _saving
                      ? 'Saving...'
                      : _addressOtpRequired
                          ? 'Verify & save'
                          : 'Save',
                  style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _hydrate(BusinessResponse business) {
    _hydrated = true;
    _name.text = business.name;
    _description.text = business.description ?? '';
    _address.text = business.address;
    _city.text = business.city;
    _country = business.country.trim().isEmpty ? 'IN' : business.country;
    if (!getCountries().any((c) => c.code == _country)) {
      _country = 'IN';
    }
    _stateCode = matchingStateCode(_country, business.state);
    _postal.text = business.postalCode ?? '';
    _phone.text = business.phone ?? '';
    _email.text = business.email ?? '';
    _website.text = business.website ?? '';
    _categoryIds
      ..clear()
      ..addAll(business.categories?.map((c) => c.id) ?? const <String>[]);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(businessRepositoryProvider);
      if (widget.isEditing) {
        await repo.updateBusiness(
          businessId: widget.businessId!,
          payload: BusinessUpdate((b) {
            b
              ..name = _name.text.trim()
              ..description = _optional(_description.text)
              ..address = _address.text.trim()
              ..city = _city.text.trim()
              ..state = _optional(_stateCode ?? '')
              ..postalCode = _optional(_postal.text)
              ..country = _country
              ..phone = _optional(_phone.text)
              ..email = _optional(_email.text)
              ..website = _optional(_website.text)
              ..addressOtpCode = _optional(_addressOtp.text);
            b.categoryIds = ListBuilder(_categoryIds);
          }),
        );
      } else {
        await repo.createBusiness(
          BusinessCreate((b) {
            b
              ..name = _name.text.trim()
              ..description = _optional(_description.text)
              ..address = _address.text.trim()
              ..city = _city.text.trim()
              ..state = _optional(_stateCode ?? '')
              ..postalCode = _optional(_postal.text)
              ..country = _country
              ..phone = _optional(_phone.text)
              ..email = _optional(_email.text)
              ..website = _optional(_website.text);
            b.categoryIds = ListBuilder(_categoryIds);
          }),
        );
      }
      _addressOtpRequired = false;
      _addressOtp.clear();
      ref.invalidate(ownedBusinessesProvider);
      ref.invalidate(myBusinessIdsProvider);
      if (!mounted) return;
      popOrGo(context, '/merchant');
    } catch (error) {
      if (!mounted) return;
      if (widget.isEditing && _needsAddressOtp(error)) {
        setState(() => _addressOtpRequired = true);
        try {
          await ref.read(businessRepositoryProvider).requestAddressOtp(widget.businessId!);
          if (!mounted) return;
          setState(() => _error = 'We sent an OTP to your business phone. Enter it and save again.');
        } catch (otpError) {
          if (!mounted) return;
          setState(() => _error = friendlyMessage(otpError));
        }
      } else {
        setState(() => _error = friendlyMessage(error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _needsAddressOtp(Object error) {
    final text = error is ApiException ? error.message : error.toString();
    return RegExp('verification code required', caseSensitive: false).hasMatch(text);
  }

  String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  // Required only on create -- mirrors backend BusinessCreate.phone/.email
  // (required) vs BusinessUpdate (still optional), same as web's BusinessForm.
  String? _validatePhone(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Phone number is required.';
    if (!_phoneFormat.hasMatch(trimmed)) return 'Enter a valid phone number.';
    return null;
  }

  String? _validateEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Email is required.';
    if (!_emailFormat.hasMatch(trimmed)) return 'Enter a valid email address.';
    return null;
  }
}
