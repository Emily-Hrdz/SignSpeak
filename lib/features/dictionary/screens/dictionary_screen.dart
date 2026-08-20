import 'package:flutter/material.dart';

import '../../../data/models/sign_model.dart';
import '../../../data/repositories/dictionary_repository.dart';
import '../widgets/category_chip.dart';
import '../widgets/sign_card.dart';
import '../widgets/sign_detail_modal.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final _signs = const DictionaryRepository().getSigns();
  final _searchController = TextEditingController();
  SignCategory? _selectedCategory;
  String _query = '';

  List<SignModel> get _filteredSigns {
    final query = _normalize(_query);
    return _signs.where((sign) {
      final categoryMatches =
          _selectedCategory == null || sign.category == _selectedCategory;
      return categoryMatches &&
          (query.isEmpty || _normalize(sign.name).contains(query));
    }).toList();
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('¿', '')
      .replaceAll('?', '');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSign(SignModel sign) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SignDetailScreen(sign: sign)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredSigns = _filteredSigns;
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            sliver: SliverList.list(
              children: [
                Text(
                  'Diccionario LENSEGUA',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text('${_signs.length} señas con demostración en video'),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Buscar letra, número o frase',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpiar búsqueda',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      CategoryFilterChip(
                        label: 'Todas',
                        icon: Icons.grid_view_rounded,
                        selected: _selectedCategory == null,
                        onSelected: () =>
                            setState(() => _selectedCategory = null),
                      ),
                      const SizedBox(width: 8),
                      for (final category in SignCategory.values) ...[
                        CategoryFilterChip(
                          label: category.label,
                          icon: iconForCategory(category),
                          selected: _selectedCategory == category,
                          onSelected: () =>
                              setState(() => _selectedCategory = category),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (filteredSigns.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('No se encontraron señas.')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverGrid.builder(
                itemCount: filteredSigns.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.12,
                ),
                itemBuilder: (context, index) {
                  final sign = filteredSigns[index];
                  return SignCard(sign: sign, onTap: () => _openSign(sign));
                },
              ),
            ),
        ],
      ),
    );
  }
}
