import 'package:flutter/material.dart';

import '../../../models.dart';
import 'category_chip.dart';

/// Horizontally scrolling row of category chips, left-aligned with the page
/// margin. The selected chip is scrolled into view when it changes.
class CategoryBar extends StatefulWidget {
  const CategoryBar({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<CaseCategory> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  State<CategoryBar> createState() => _CategoryBarState();
}

class _CategoryBarState extends State<CategoryBar> {
  static const double _gap = 23;

  late List<GlobalKey> _chipKeys = _keys();

  List<GlobalKey> _keys() => [for (final _ in widget.categories) GlobalKey()];

  @override
  void didUpdateWidget(CategoryBar old) {
    super.didUpdateWidget(old);
    if (old.categories.length != widget.categories.length) {
      _chipKeys = _keys();
    }
    if (old.selectedIndex != widget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected());
    }
  }

  void _revealSelected() {
    if (widget.selectedIndex >= _chipKeys.length) return;
    final chip = _chipKeys[widget.selectedIndex].currentContext;
    if (chip == null || !chip.mounted) return;
    Scrollable.ensureVisible(
      chip,
      alignment: 0.5,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final (i, category) in widget.categories.indexed) ...[
            if (i > 0) const SizedBox(width: _gap),
            CategoryChip(
              key: _chipKeys[i],
              label: category.label,
              selected: i == widget.selectedIndex,
              onTap: () => widget.onSelected(i),
            ),
          ],
        ],
      ),
    );
  }
}
