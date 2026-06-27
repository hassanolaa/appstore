import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_store/service_locator.dart';
import 'package:game_store/features/games/data/models/game_model.dart';
import 'package:game_store/features/games/presentation/pages/developer_page.dart';
import '../cubit/game_details_cubit.dart';

class GameDetailsPage extends StatelessWidget {
  final GameModel game;
  final bool isInstalled;

  const GameDetailsPage({
    super.key,
    required this.game,
    required this.isInstalled,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) => GameDetailsCubit(
            repository: sl(),
            gameId: game.id,
            initialGame: game,
            isInstalledInitially: isInstalled,
          )..loadDetails(),
      child: _GameDetailsView(game: game, isInstalled: isInstalled),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Main view
// ─────────────────────────────────────────────────────────────

class _GameDetailsView extends StatelessWidget {
  final GameModel game;
  final bool isInstalled;

  const _GameDetailsView({required this.game, required this.isInstalled});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B1020), Color(0xFF11182B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: BlocBuilder<GameDetailsCubit, GameDetailsState>(
            builder: (context, state) {
              final bool isLoading = state is GameDetailsLoading;
              bool isGameInstalled = isInstalled;
              double? progress;
              String? progressStatus;
              GameModel activeGame = game;

              if (state is GameDetailsLoaded) {
                isGameInstalled = state.isInstalled;
                activeGame = state.game;
                progress = state.progress;
                progressStatus = state.progressStatus;
              }

              return Column(
                children: [
                  _TopBar(
                    title: activeGame.name ?? 'Game Details',
                    scheme: scheme,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 280,
                            child: _LeftPanel(
                              game: activeGame,
                              isLoading: isLoading,
                              isInstalled: isGameInstalled,
                              progress: progress,
                              progressStatus: progressStatus,
                              scheme: scheme,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _RightPanel(
                              game: activeGame,
                              scheme: scheme,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String title;
  final ColorScheme scheme;

  const _TopBar({required this.title, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          _GlassIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back',
            onTap: () => Navigator.of(context).pop(),
            scheme: scheme,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Left panel
// ─────────────────────────────────────────────────────────────

class _LeftPanel extends StatelessWidget {
  final GameModel game;
  final bool isLoading;
  final bool isInstalled;
  final double? progress;
  final String? progressStatus;
  final ColorScheme scheme;

  const _LeftPanel({
    required this.game,
    required this.isLoading,
    required this.isInstalled,
    required this.progress,
    required this.progressStatus,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CoverArtBox(game: game, scheme: scheme),
            const SizedBox(height: 24),
            if (progress != null)
              _ProgressSection(
                progress: progress!,
                status: progressStatus,
                scheme: scheme,
              )
            else if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (isInstalled)
              _InstalledActions(scheme: scheme)
            else
              _InstallButton(scheme: scheme),
            if (game.bundles.isNotEmpty) ...[
              const SizedBox(height: 24),
              _GlassDivider(),
              const SizedBox(height: 16),
              _SectionLabel('Bundle Info'),
              const SizedBox(height: 12),
              _MetadataItem('Ref', game.bundles.first.flatpakRef),
              _MetadataItem('Runtime', game.bundles.first.runtime),
              _MetadataItem('SDK', game.bundles.first.sdk),
              _MetadataItem('Arch', game.bundles.first.arch),
              _MetadataItem('Branch', game.bundles.first.branch),
            ],
          ],
        ),
      ),
    );
  }
}

class _CoverArtBox extends StatelessWidget {
  final GameModel game;
  final ColorScheme scheme;

  const _CoverArtBox({required this.game, required this.scheme});

  Widget _resolveImage() {
    if (game.icon128 != null && game.icon128!.isNotEmpty) {
      return Image.file(
        File(game.icon128!),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => _FallbackIcon(),
      );
    }
    if (game.icon64 != null && game.icon64!.isNotEmpty) {
      return Image.file(
        File(game.icon64!),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => _FallbackIcon(),
      );
    }
    return _FallbackIcon();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.black.withOpacity(0.3),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withOpacity(0.12),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: _resolveImage()),
        ),
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final double progress;
  final String? status;
  final ColorScheme scheme;

  const _ProgressSection({
    required this.progress,
    required this.status,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          status ?? 'Processing…',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.white.withOpacity(0.08),
            valueColor: AlwaysStoppedAnimation(scheme.primary),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(progress * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            color: scheme.primary,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
      ],
    );
  }
}

class _InstalledActions extends StatelessWidget {
  final ColorScheme scheme;
  const _InstalledActions({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActionButton(
          icon: Icons.play_arrow_rounded,
          label: 'Play Now',
          backgroundColor: const Color(0xFF1DB954),
          foregroundColor: Colors.white,
          onPressed: () => context.read<GameDetailsCubit>().openGame(),
        ),
        const SizedBox(height: 10),
        _ActionButton(
          icon: Icons.delete_outline_rounded,
          label: 'Uninstall',
          backgroundColor: Colors.red.withOpacity(0.15),
          foregroundColor: Colors.redAccent,
          borderColor: Colors.red.withOpacity(0.3),
          onPressed: () => context.read<GameDetailsCubit>().removeGame(),
        ),
      ],
    );
  }
}

class _InstallButton extends StatelessWidget {
  final ColorScheme scheme;
  const _InstallButton({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return _ActionButton(
      icon: Icons.download_rounded,
      label: 'Install',
      backgroundColor: scheme.primary.withOpacity(0.18),
      foregroundColor: scheme.primary,
      borderColor: scheme.primary.withOpacity(0.35),
      onPressed: () => context.read<GameDetailsCubit>().installGame(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Action button — Material + InkWell (no Matrix4 transform)
// ─────────────────────────────────────────────────────────────

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
    required this.onPressed,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color:
              _isHovered
                  ? widget.backgroundColor.withOpacity(
                    (widget.backgroundColor.opacity * 1.6).clamp(0.0, 0.9),
                  )
                  : widget.backgroundColor,
          border: Border.all(color: widget.borderColor ?? Colors.transparent),
          boxShadow:
              _isHovered
                  ? [
                    BoxShadow(
                      color: widget.foregroundColor.withOpacity(0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: widget.onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, color: widget.foregroundColor, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.foregroundColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
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
// Right panel
// ─────────────────────────────────────────────────────────────

class _RightPanel extends StatelessWidget {
  final GameModel game;
  final ColorScheme scheme;

  const _RightPanel({required this.game, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              game.name ?? 'Unknown',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),

            // Developer chip
            if (game.developer != null && game.developer!.isNotEmpty)
              _DeveloperChip(developer: game.developer!, scheme: scheme)
            else
              Text(
                'Unknown Developer',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 14,
                ),
              ),

            const SizedBox(height: 16),

            // Summary
            if (game.summary != null && game.summary!.isNotEmpty) ...[
              Text(
                game.summary!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 16,
                  height: 1.55,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),
            ],

            _GlassDivider(),
            const SizedBox(height: 20),

            _SectionLabel('About this game'),
            const SizedBox(height: 10),

            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  game.description ?? 'No description available.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    height: 1.75,
                  ),
                ),
              ),
            ),

            // Screenshots
            if (game.screenshots.isNotEmpty) ...[
              const SizedBox(height: 20),
              _GlassDivider(),
              const SizedBox(height: 16),
              _SectionLabel('Screenshots'),
              const SizedBox(height: 14),
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: game.screenshots.length,
                  itemBuilder: (context, index) {
                    final source = game.screenshots[index].source ?? '';
                    return _ScreenshotThumbnail(
                      source: source,
                      index: index,
                      allScreenshots:
                          game.screenshots.map((s) => s.source ?? '').toList(),
                      scheme: scheme,
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Developer chip — Material + InkWell
// ─────────────────────────────────────────────────────────────

class _DeveloperChip extends StatefulWidget {
  final String developer;
  final ColorScheme scheme;

  const _DeveloperChip({required this.developer, required this.scheme});

  @override
  State<_DeveloperChip> createState() => _DeveloperChipState();
}

class _DeveloperChipState extends State<_DeveloperChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color:
              _isHovered
                  ? widget.scheme.primary.withOpacity(0.2)
                  : widget.scheme.primary.withOpacity(0.1),
          border: Border.all(
            color: widget.scheme.primary.withOpacity(_isHovered ? 0.5 : 0.25),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap:
                () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder:
                        (_, __, ___) =>
                            DeveloperPage(developerName: widget.developer),
                    transitionDuration: const Duration(milliseconds: 300),
                    transitionsBuilder:
                        (_, animation, __, child) => FadeTransition(
                          opacity: CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOut,
                          ),
                          child: child,
                        ),
                  ),
                ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 15,
                    color: widget.scheme.primary,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    widget.developer,
                    style: TextStyle(
                      color: widget.scheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 12,
                    color: widget.scheme.primary.withOpacity(0.6),
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
// Screenshot thumbnail — Material + InkWell
// ─────────────────────────────────────────────────────────────

class _ScreenshotThumbnail extends StatefulWidget {
  final String source;
  final int index;
  final List<String> allScreenshots;
  final ColorScheme scheme;

  const _ScreenshotThumbnail({
    required this.source,
    required this.index,
    required this.allScreenshots,
    required this.scheme,
  });

  @override
  State<_ScreenshotThumbnail> createState() => _ScreenshotThumbnailState();
}

class _ScreenshotThumbnailState extends State<_ScreenshotThumbnail> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isNetwork = widget.source.startsWith('http');

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  _isHovered
                      ? widget.scheme.primary.withOpacity(0.6)
                      : Colors.white.withOpacity(0.08),
              width: _isHovered ? 2 : 1,
            ),
            boxShadow:
                _isHovered
                    ? [
                      BoxShadow(
                        color: widget.scheme.primary.withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                    : [],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            child: InkWell(
              borderRadius: BorderRadius.circular(13),
              onTap:
                  () => showDialog(
                    context: context,
                    barrierColor: Colors.black.withOpacity(0.9),
                    builder:
                        (_) => ScreenshotViewer(
                          screenshots: widget.allScreenshots,
                          initialIndex: widget.index,
                        ),
                  ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child:
                      isNetwork
                          ? Image.network(
                            widget.source,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _BrokenImage(),
                          )
                          : Image.file(
                            File(widget.source),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _BrokenImage(),
                          ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Screenshot viewer dialog
// ─────────────────────────────────────────────────────────────

class ScreenshotViewer extends StatefulWidget {
  final List<String> screenshots;
  final int initialIndex;

  const ScreenshotViewer({
    super.key,
    required this.screenshots,
    required this.initialIndex,
  });

  @override
  State<ScreenshotViewer> createState() => _ScreenshotViewerState();
}

class _ScreenshotViewerState extends State<ScreenshotViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentIndex < widget.screenshots.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = widget.screenshots.length;

    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF111827), Color(0xFF060A14)],
            radius: 1.2,
          ),
        ),
        child: Focus(
          autofocus: true,
          onKeyEvent: (_, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;
            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _next();
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _prev();
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.of(context).pop();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Stack(
            children: [
              // ── Page view ────────────────────────────────────────
              PageView.builder(
                controller: _pageController,
                itemCount: total,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (_, index) {
                  final source = widget.screenshots[index];
                  final isNetwork = source.startsWith('http');
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(88, 80, 88, 80),
                      child: InteractiveViewer(
                        clipBehavior: Clip.none,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child:
                              isNetwork
                                  ? Image.network(
                                    source,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (_, __, ___) => _BrokenImage(),
                                  )
                                  : Image.file(
                                    File(source),
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (_, __, ___) => _BrokenImage(),
                                  ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // ── Top bar — IgnorePointer on blur, real buttons on top ──
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      color: Colors.black.withOpacity(0.35),
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _DotIndicators(
                              total: total,
                              current: _currentIndex,
                              scheme: scheme,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white.withOpacity(0.08),
                            ),
                            child: Text(
                              '${_currentIndex + 1} / $total',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _GlassIconButton(
                            icon: Icons.close_rounded,
                            tooltip: 'Close (Esc)',
                            onTap: () => Navigator.of(context).pop(),
                            scheme: scheme,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Prev arrow ───────────────────────────────────────
              if (_currentIndex > 0)
                Positioned(
                  left: 20,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _NavArrow(
                      icon: Icons.chevron_left_rounded,
                      onTap: _prev,
                      scheme: scheme,
                    ),
                  ),
                ),

              // ── Next arrow ───────────────────────────────────────
              if (_currentIndex < total - 1)
                Positioned(
                  right: 20,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _NavArrow(
                      icon: Icons.chevron_right_rounded,
                      onTap: _next,
                      scheme: scheme,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Dot indicators
// ─────────────────────────────────────────────────────────────

class _DotIndicators extends StatelessWidget {
  final int total;
  final int current;
  final ColorScheme scheme;

  const _DotIndicators({
    required this.total,
    required this.current,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    if (total <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: isActive ? scheme.primary : Colors.white.withOpacity(0.25),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Nav arrow — Material + InkWell with CircleBorder
// ─────────────────────────────────────────────────────────────

class _NavArrow extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final ColorScheme scheme;

  const _NavArrow({
    required this.icon,
    required this.onTap,
    required this.scheme,
  });

  @override
  State<_NavArrow> createState() => _NavArrowState();
}

class _NavArrowState extends State<_NavArrow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              _isHovered
                  ? Colors.white.withOpacity(0.15)
                  : Colors.white.withOpacity(0.07),
          border: Border.all(
            color: Colors.white.withOpacity(_isHovered ? 0.2 : 0.09),
          ),
          boxShadow:
              _isHovered
                  ? [
                    BoxShadow(
                      color: widget.scheme.primary.withOpacity(0.15),
                      blurRadius: 16,
                    ),
                  ]
                  : [],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.onTap,
            child: Center(
              child: Icon(widget.icon, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Glass icon button — Material + InkWell
// ─────────────────────────────────────────────────────────────

class _GlassIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final ColorScheme scheme;

  const _GlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.scheme,
  });

  @override
  State<_GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<_GlassIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color:
                _isHovered
                    ? Colors.white.withOpacity(0.12)
                    : Colors.white.withOpacity(0.07),
            border: Border.all(
              color: Colors.white.withOpacity(_isHovered ? 0.15 : 0.08),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: widget.onTap,
              child: Center(
                child: Icon(widget.icon, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shared utility widgets
// ─────────────────────────────────────────────────────────────

class _GlassPanel extends StatelessWidget {
  final Widget child;
  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.videogame_asset_rounded,
      size: 72,
      color: Colors.white.withOpacity(0.15),
    );
  }
}

class _BrokenImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withOpacity(0.05),
      child: Center(
        child: Icon(
          Icons.broken_image_rounded,
          size: 48,
          color: Colors.white.withOpacity(0.2),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _GlassDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(color: Colors.white.withOpacity(0.08), height: 1);
  }
}

class _MetadataItem extends StatelessWidget {
  final String label;
  final String? value;

  const _MetadataItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.38),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
