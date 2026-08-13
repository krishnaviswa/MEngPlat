import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../businesses/business_list_provider.dart';
import 'merchant_providers.dart';

/// Create or edit a merchant business (M-54). Hours/gallery upload stay n/a (M-55/M-56).
class BusinessEditorScreen extends ConsumerStatefulWidget {
  const BusinessEditorScreen({this.businessId, super.key});

  final String? businessId;

  bool get isEditing => businessId != null;

  @override
  ConsumerState<BusinessEditorScreen> createState() => _BusinessEditorScreenState();
}

class _BusinessEditorScreenState extends ConsumerState<BusinessEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _postal = TextEditingController();
  final _country = TextEditingController(text: 'IN');
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _website = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final Set<String> _categoryIds = {};
  String? _error;
  bool _saving = false;
  bool _hydrated = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _address.dispose();
    _city.dispose();
    _state.dispose();
    _postal.dispose();
    _country.dispose();
    _phone.dispose();
    _email.dispose();
    _website.dispose();
    _lat.dispose();
    _lng.dispose();
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

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit business' : 'Create business')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const Key('businessNameField'),
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Name is required' : null,
            ),
            TextFormField(controller: _description, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
            TextFormField(
              key: const Key('businessAddressField'),
              controller: _address,
              decoration: const InputDecoration(labelText: 'Address'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Address is required' : null,
            ),
            TextFormField(
              key: const Key('businessCityField'),
              controller: _city,
              decoration: const InputDecoration(labelText: 'City'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'City is required' : null,
            ),
            TextFormField(controller: _state, decoration: const InputDecoration(labelText: 'State')),
            TextFormField(controller: _postal, decoration: const InputDecoration(labelText: 'Postal code')),
            TextFormField(controller: _country, decoration: const InputDecoration(labelText: 'Country')),
            TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone')),
            TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            TextFormField(controller: _website, decoration: const InputDecoration(labelText: 'Website')),
            TextFormField(controller: _lat, decoration: const InputDecoration(labelText: 'Latitude'), keyboardType: TextInputType.number),
            TextFormField(controller: _lng, decoration: const InputDecoration(labelText: 'Longitude'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
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
                        label: Text(category.name),
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
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, key: const Key('businessEditorError'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('businessEditorSave'),
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save'),
            ),
          ],
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
    _state.text = business.state ?? '';
    _postal.text = business.postalCode ?? '';
    _country.text = business.country;
    _phone.text = business.phone ?? '';
    _email.text = business.email ?? '';
    _website.text = business.website ?? '';
    _lat.text = business.latitude?.toString() ?? '';
    _lng.text = business.longitude?.toString() ?? '';
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
    final lat = double.tryParse(_lat.text.trim());
    final lng = double.tryParse(_lng.text.trim());
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
              ..state = _optional(_state.text)
              ..postalCode = _optional(_postal.text)
              ..phone = _optional(_phone.text)
              ..email = _optional(_email.text)
              ..website = _optional(_website.text)
              ..latitude = lat
              ..longitude = lng;
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
              ..state = _optional(_state.text)
              ..postalCode = _optional(_postal.text)
              ..country = _country.text.trim().isEmpty ? 'IN' : _country.text.trim()
              ..phone = _optional(_phone.text)
              ..email = _optional(_email.text)
              ..website = _optional(_website.text)
              ..latitude = lat
              ..longitude = lng;
            b.categoryIds = ListBuilder(_categoryIds);
          }),
        );
      }
      ref.invalidate(ownedBusinessesProvider);
      ref.invalidate(myBusinessIdsProvider);
      if (!mounted) return;
      context.go('/merchant');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
