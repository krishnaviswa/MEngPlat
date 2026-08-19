import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merchanthub_api/merchanthub_api.dart';

import '../businesses/business_list_provider.dart';
import 'admin_back_app_bar.dart';
import 'admin_copy.dart';

/// Admin category create/list (M-63) plus search and distinct create errors (M-83, M-84).
class AdminCategoriesScreen extends ConsumerStatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  ConsumerState<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends ConsumerState<AdminCategoriesScreen> {
  final _nameController = TextEditingController();
  final _search = TextEditingController();
  Timer? _debounce;
  List<CategoryResponse> _categories = [];
  String? _error;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    _search.dispose();
    super.dispose();
  }

  static String _slugify(String name) =>
      name.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _load(q: value.trim()));
  }

  Future<void> _load({String? q}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final categories =
          await ref.read(businessRepositoryProvider).listCategories(q: q ?? _search.text.trim());
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final slug = _slugify(name);
      await ref.read(businessRepositoryProvider).createCategory(CategoryCreate((b) => b
        ..name = name
        ..slug = slug));
      _nameController.clear();
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = categoryCreateErrorMessage(error, name));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('adminCategoriesScreen'),
      appBar: adminBackAppBar(context, title: 'Categories'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    key: const Key('adminCategoriesSearchField'),
                    controller: _search,
                    decoration: const InputDecoration(labelText: 'Search categories', isDense: true),
                    onChanged: _onSearchChanged,
                  ),
                  const SizedBox(height: 12),
                  if (_error != null) ...[
                    Text(_error!, key: const Key('categoryCreateError'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('newCategoryNameField'),
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'New category name', isDense: true),
                          onSubmitted: (_) => _submit(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        key: const Key('addCategoryButton'),
                        onPressed: _submitting ? null : _submit,
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_categories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No categories yet', key: Key('noCategoriesEmptyState')),
                    )
                  else
                    Wrap(
                      key: const Key('categoryList'),
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final category in _categories)
                          ActionChip(
                            label: Text(category.name),
                            onPressed: () => context.push('/businesses?category=${category.slug}'),
                          ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}
