import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/games_cubit.dart';
import '../cubit/games_state.dart';
import 'package:game_store/features/game/presentation/pages/game_details_page.dart';
import 'package:game_store/features/home/presentation/pages/home_page.dart';
import 'package:game_store/features/games/data/models/game_model.dart';

class UpdatesPage extends StatefulWidget {
  const UpdatesPage({super.key});

  @override
  State<UpdatesPage> createState() => _UpdatesPageState();
}

class _UpdatesPageState extends State<UpdatesPage> {
  bool _wasActive = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isActive = ActiveTab.of(context);
    if (isActive && !_wasActive) {
      _checkForUpdates();
    }
    _wasActive = isActive;
  }

  void _checkForUpdates() {
    context.read<GamesCubit>().loadLibraryGames();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<GamesCubit, GamesState>(
      builder: (context, state) {
        if (state is GamesLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is GamesError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.12),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Failed to check for updates',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _checkForUpdates,
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary.withOpacity(0.2),
                    foregroundColor: scheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    'Try again',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        }

        if (state is GamesLoaded) {
          final upgradableGames = state.games.where((game) {
            return state.upgradableGames.any(
              (ref) => ref.contains(game.id) || game.id.contains(ref),
            );
          }).toList();

          if (upgradableGames.isEmpty) {
            return _UpdatesEmptyState(
              scheme: scheme,
              onCheck: _checkForUpdates,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: upgradableGames.length,
            itemBuilder: (context, index) {
              final game = upgradableGames[index];
              return _AnimatedRow(
                index: index,
                child: _UpdateItemCard(
                  game: game,
                  onUpdate: () {
                    context.read<GamesCubit>().upgradeGame(game.id);
                  },
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => GameDetailsPage(
                          game: game,
                          isInstalled: true,
                        ),
                        transitionDuration: const Duration(milliseconds: 320),
                        transitionsBuilder: (_, animation, __, child) => FadeTransition(
                          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
                          child: child,
                        ),
                      ),
                    ).then((_) {
                      _checkForUpdates();
                    });
                  },
                ),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Sub-widgets and Helpers
// ─────────────────────────────────────────────────────────────

class _UpdatesEmptyState extends StatelessWidget {
  final ColorScheme scheme;
  final VoidCallback onCheck;

  const _UpdatesEmptyState({required this.scheme, required this.onCheck});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.green.withOpacity(0.14), Colors.transparent],
              ),
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 80,
              color: Colors.green.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'All games are up to date',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'No updates are currently available. Check back later\nor trigger a manual verification.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: onCheck,
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary.withOpacity(0.2),
              foregroundColor: scheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(
              'Check for Updates',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateItemCard extends StatefulWidget {
  final GameModel game;
  final VoidCallback onUpdate;
  final VoidCallback onTap;

  const _UpdateItemCard({
    required this.game,
    required this.onUpdate,
    required this.onTap,
  });

  @override
  State<_UpdateItemCard> createState() => _UpdateItemCardState();
}

class _UpdateItemCardState extends State<_UpdateItemCard> {
  bool _isHovered = false;

  Widget _buildIcon(GameModel game) {
    final icon128 = game.icon128;
    final icon64 = game.icon64;

    if (icon128 != null && icon128.isNotEmpty) {
      return Image.file(
        File(icon128),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _FallbackIcon(),
      );
    } else if (icon64 != null && icon64.isNotEmpty) {
      return Image.file(
        File(icon64),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _FallbackIcon(),
      );
    }
    return _FallbackIcon();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: _isHovered ? Colors.white.withOpacity(0.09) : Colors.white.withOpacity(0.05),
            border: Border.all(
              color: _isHovered ? scheme.primary.withOpacity(0.4) : Colors.white.withOpacity(0.08),
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: scheme.primary.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            children: [
              // Icon thumbnail
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.black.withOpacity(0.2),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                padding: const EdgeInsets.all(8),
                child: _buildIcon(widget.game),
              ),
              const SizedBox(width: 16),
              // Name and Developer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.game.name ?? 'Unknown Game',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.game.developer ?? 'Unknown Developer',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Upgrade Button
              _UpdateButton(
                onPressed: widget.onUpdate,
                scheme: scheme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.videogame_asset_rounded,
      size: 28,
      color: Colors.white.withOpacity(0.25),
    );
  }
}

class _UpdateButton extends StatefulWidget {
  final VoidCallback onPressed;
  final ColorScheme scheme;

  const _UpdateButton({required this.onPressed, required this.scheme});

  @override
  State<_UpdateButton> createState() => _UpdateButtonState();
}

class _UpdateButtonState extends State<_UpdateButton> {
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
          borderRadius: BorderRadius.circular(12),
          color: _isHovered ? widget.scheme.primary.withOpacity(0.25) : widget.scheme.primary.withOpacity(0.12),
          border: Border.all(
            color: widget.scheme.primary.withOpacity(_isHovered ? 0.6 : 0.3),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.upgrade_rounded,
                    size: 16,
                    color: widget.scheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Update',
                    style: TextStyle(
                      color: widget.scheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
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

class _AnimatedRow extends StatefulWidget {
  final Widget child;
  final int index;
  const _AnimatedRow({required this.child, required this.index});

  @override
  State<_AnimatedRow> createState() => _AnimatedRowState();
}

class _AnimatedRowState extends State<_AnimatedRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 40 * widget.index.clamp(0, 12)), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
