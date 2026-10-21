import 'package:flutter/material.dart';

class SnapCarousel extends StatefulWidget {
  const SnapCarousel({
    super.key,
    required this.itemSpacing,
    required this.itemCount,
    required this.itemBuilder,
    this.initialIndex = 0,
    this.onIndexChanged,
    this.scrollToTappedItem = false,
  });

  /// Distance between the centers of two neighbouring items.
  final double itemSpacing;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int initialIndex;
  final ValueChanged<int>? onIndexChanged;

  /// When true, tapping an item scrolls it to the center.
  final bool scrollToTappedItem;

  @override
  State<SnapCarousel> createState() => _SnapCarouselState();
}

class _SnapCarouselState extends State<SnapCarousel> {
  late PageController _controller;
  double? _screenWidth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.sizeOf(context).width;
    if (width == _screenWidth) return;

    // viewportFraction depends on the width and can't be changed on an
    // existing controller, so a resize needs a new one.
    final isFirstBuild = _screenWidth == null;
    _screenWidth = width;
    final page = isFirstBuild ? widget.initialIndex : _currentPage();

    if (!isFirstBuild) {
      // The PageView still uses the old controller until the next frame.
      final old = _controller;
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }

    _controller = PageController(
      viewportFraction: (widget.itemSpacing / width).clamp(0.1, 1.0),
      initialPage: page,
    );
  }

  int _currentPage() {
    final page = _controller.hasClients ? _controller.page : null;
    return page?.round() ?? _controller.initialPage;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scrollTo(int index) {
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      itemCount: widget.itemCount,
      onPageChanged: widget.onIndexChanged,
      itemBuilder: (context, index) {
        final item = widget.itemBuilder(context, index);
        return Center(
          child: widget.scrollToTappedItem
              ? GestureDetector(onTap: () => _scrollTo(index), child: item)
              : item,
        );
      },
    );
  }
}
