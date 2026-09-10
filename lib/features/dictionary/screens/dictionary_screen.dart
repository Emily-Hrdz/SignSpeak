import 'package:flutter/material.dart';

import '../../../data/models/sign_model.dart';
import '../../../data/repositories/dictionary_repository.dart';
import '../../../core/widgets/clay_components.dart';
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
                ClaySurface(
                  borderRadius: 18,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF202B40)
                          : const Color(0xFFF8FBFF),
                      hintText: 'Buscar letra, número o frase',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
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
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.5,
                  children: [
                    _CategoryTile(
                      label: 'Todos',
                      count: _signs.length,
                      icon: Icons.play_arrow_rounded,
                      color: const Color(0xFFFF91AA),
                      selected: _selectedCategory == null,
                      onTap: () => setState(() => _selectedCategory = null),
                    ),
                    _CategoryTile(
                      label: SignCategory.alphabet.label,
                      count: _signs
                          .where(
                            (sign) => sign.category == SignCategory.alphabet,
                          )
                          .length,
                      icon: iconForCategory(SignCategory.alphabet),
                      color: colorForCategory(SignCategory.alphabet),
                      selected: _selectedCategory == SignCategory.alphabet,
                      onTap: () => setState(
                        () => _selectedCategory = SignCategory.alphabet,
                      ),
                    ),
                    _CategoryTile(
                      label: SignCategory.numbers.label,
                      count: _signs
                          .where(
                            (sign) => sign.category == SignCategory.numbers,
                          )
                          .length,
                      icon: iconForCategory(SignCategory.numbers),
                      color: colorForCategory(SignCategory.numbers),
                      selected: _selectedCategory == SignCategory.numbers,
                      onTap: () => setState(
                        () => _selectedCategory = SignCategory.numbers,
                      ),
                    ),
                    _CategoryTile(
                      label: 'Frases',
                      count: _signs
                          .where(
                            (sign) => sign.category == SignCategory.phrases,
                          )
                          .length,
                      icon: iconForCategory(SignCategory.phrases),
                      color: colorForCategory(SignCategory.phrases),
                      selected: _selectedCategory == SignCategory.phrases,
                      onTap: () => setState(
                        () => _selectedCategory = SignCategory.phrases,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _selectedCategory == null
                      ? 'Todas las señas'
                      : _selectedCategory!.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
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

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = color.computeLuminance() > 0.55
        ? const Color(0xFF3D4150)
        : Colors.white;
    return ClaySurface(
      color: color,
      borderRadius: 22,
      hardShadow: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.48),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: foreground, size: 28),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '$count señas',
                        style: TextStyle(
                          color: foreground.withValues(alpha: 0.78),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded, color: foreground, size: 19),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
