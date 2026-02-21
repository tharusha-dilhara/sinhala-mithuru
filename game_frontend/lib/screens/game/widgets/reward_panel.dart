import 'package:flutter/material.dart';

import 'dart:ui';
import '../../../models/game_item.dart';

class RewardPanel extends StatelessWidget {
  final List<GameItem> items;
  final bool isCompact; // True for mobile portrait mode (top/bottom bar style)
  final VoidCallback? onTap; // Callback for tap interaction
  final bool isLocked; // Add locked state

  const RewardPanel({
    super.key,
    required this.items,
    this.isCompact = false,
    this.onTap,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    // Glassmorphism container
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: isCompact
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: items
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: _RewardItemWidget(
                              item: item,
                              isCompact: true,
                              isLocked: isLocked,
                            ),
                          ),
                        )
                        .toList(),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: items
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _RewardItemWidget(
                              item: item,
                              isCompact: false,
                              isLocked: isLocked,
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ),
      ),
    );
  }
}

class _RewardItemWidget extends StatefulWidget {
  final GameItem item;
  final bool isCompact;
  final bool isLocked;

  const _RewardItemWidget({
    required this.item,
    required this.isCompact,
    required this.isLocked,
  });

  @override
  State<_RewardItemWidget> createState() => _RewardItemWidgetState();
}

class _RewardItemWidgetState extends State<_RewardItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    if (!widget.isLocked) {
      _controller.repeat(reverse: true);
    }

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant _RewardItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLocked != oldWidget.isLocked) {
      if (widget.isLocked) {
        _controller.stop();
        _controller.animateTo(0, duration: const Duration(milliseconds: 300));
      } else {
        _controller.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: widget.isLocked ? 0.7 : 1.0,
            child: Container(
              padding: widget.isCompact
                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                  : const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.isLocked
                        ? Colors.grey.withOpacity(0.2)
                        : _getColorForType(widget.item.type).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: widget.isCompact
                  ? _buildCompactView()
                  : _buildExpandedView(),
            ),
          ),
          if (widget.isLocked)
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ... (keep _buildCompactView and _buildExpandedView as is) ...

  Widget _buildCompactView() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.add_rounded,
          size: 40,
          color: widget.isLocked ? Colors.grey : Colors.black,
        ),
        const SizedBox(width: 5),
        _buildImage(50),
      ],
    );
  }

  Widget _buildExpandedView() {
    return Column(
      children: [
        Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isLocked
                ? Colors.grey.withOpacity(0.1)
                : _getColorForType(widget.item.type).withOpacity(0.1),
          ),
          child: Center(child: _buildImage(40)),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: widget.isLocked
                ? Colors.grey
                : _getColorForType(widget.item.type),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            "${widget.item.count}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage(double size) {
    return Image.asset(
      widget.item.imagePath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.image_not_supported_rounded,
          size: size,
          color: Colors.grey,
        );
      },
    );
  }

  Color _getColorForType(GameItemType type) {
    switch (type) {
      case GameItemType.food:
        return Colors.orangeAccent;
      case GameItemType.medicine:
        return Colors.blueAccent;
      case GameItemType.toy:
        return Colors.purpleAccent;
    }
  }
}
