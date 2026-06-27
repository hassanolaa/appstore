import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/game_model.dart';

class GameCard extends StatefulWidget {
  final GameModel game;
  final bool isInstalled;
  final VoidCallback onTap;

  const GameCard({
    super.key,
    required this.game,
    required this.isInstalled,
    required this.onTap,
  });

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  bool get _isActive => _isHovered || _isFocused;

  Widget _buildCoverImage() {
    final icon128 = widget.game.icon128;
    final icon64 = widget.game.icon64;

    Widget imageWidget;

    if (icon128 != null && icon128.isNotEmpty) {
      imageWidget = Image.file(
        File(icon128),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => _FallbackIcon(),
      );
    } else if (icon64 != null && icon64.isNotEmpty) {
      imageWidget = Image.file(
        File(icon64),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => _FallbackIcon(),
      );
    } else {
      imageWidget = _FallbackIcon();
    }

    return imageWidget;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
             event.logicalKey == LogicalKeyboardKey.space)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              final glowOpacity =
                  _isFocused
                      ? 0.35 + _glowAnimation.value * 0.25
                      : (_isHovered ? 0.2 : 0.0);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                transform:
                    Matrix4.identity()
                      ..scale(_isPressed ? 0.96 : (_isHovered ? 1.03 : 1.0)),
                transformAlignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color:
                        _isActive
                            ? scheme.primary.withOpacity(0.55)
                            : Colors.white.withOpacity(0.08),
                    width: _isFocused ? 2 : 1,
                  ),
                  boxShadow: [
                    if (_isActive)
                      BoxShadow(
                        color: scheme.primary.withOpacity(glowOpacity),
                        blurRadius: 24,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(21),
              child: Stack(
                children: [
                  // ── Glass background ────────────────────────────────
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors:
                            _isActive
                                ? [
                                  Colors.white.withOpacity(0.13),
                                  Colors.white.withOpacity(0.05),
                                ]
                                : [
                                  Colors.white.withOpacity(0.08),
                                  Colors.white.withOpacity(0.03),
                                ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),

                  // ── Content ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cover art area
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: Colors.black.withOpacity(0.3),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.06),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Blurred background tint
                                Positioned.fill(
                                  child: ColoredBox(
                                    color: Colors.black.withOpacity(0.15),
                                  ),
                                ),
                                // Game icon
                                Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Center(child: _buildCoverImage()),
                                ),
                                // Installed shimmer badge (top-right)
                                if (widget.isInstalled)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: _InstalledBadge(scheme: scheme),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Game name
                        Text(
                          widget.game.name ?? 'Unknown Game',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        // Developer + action hint row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.game.developer ?? 'Unknown Developer',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.45),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 180),
                              opacity: _isActive ? 1.0 : 0.0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: scheme.primary.withOpacity(0.18),
                                ),
                                child: Text(
                                  widget.isInstalled ? 'Play' : 'View',
                                  style: TextStyle(
                                    color: scheme.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Focus ring overlay ───────────────────────────────
                  if (_isFocused)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _glowAnimation,
                          builder:
                              (_, __) => DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(21),
                                  border: Border.all(
                                    color: scheme.primary.withOpacity(
                                      0.3 + _glowAnimation.value * 0.3,
                                    ),
                                    width: 2,
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────

class _FallbackIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.videogame_asset_rounded,
          size: 52,
          color: Colors.white.withOpacity(0.18),
        ),
      ],
    );
  }
}

class _InstalledBadge extends StatelessWidget {
  final ColorScheme scheme;

  const _InstalledBadge({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: scheme.primary.withOpacity(0.22),
            border: Border.all(color: scheme.primary.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.download_done_rounded,
                size: 11,
                color: scheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Installed',
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
