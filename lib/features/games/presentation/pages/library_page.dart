import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/games_cubit.dart';
import '../cubit/games_state.dart';
import '../widgets/game_card.dart';
import 'package:game_store/features/game/presentation/pages/game_details_page.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<GamesCubit, GamesState>(
      builder: (context, state) {
        if (state is GamesLoading) {
          return _ShimmerGrid();
        }

        if (state is GamesError) {
          return _ErrorState(
            message: state.message,
            scheme: scheme,
            onRetry: () {
              context.read<GamesCubit>().loadGames();
            },
          );
        }

        if (state is GamesLoaded) {
          final installed =
              state.games.where((game) {
                return state.installedGames.any(
                  (ref) => ref.contains(game.id) || game.id.contains(ref),
                );
              }).toList();

          if (installed.isEmpty) {
            return _LibraryEmptyState(scheme: scheme);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Summary row ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    _StatBadge(
                      icon: Icons.videogame_asset_rounded,
                      label: '${installed.length} installed',
                      scheme: scheme,
                    ),
                    const SizedBox(width: 10),
                    _StatBadge(
                      icon: Icons.storage_rounded,
                      label: 'Local storage',
                      scheme: scheme,
                    ),
                    const Spacer(),
                    _SortButton(scheme: scheme),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Grid ────────────────────────────────────────────────
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: installed.length,
                  itemBuilder: (context, index) {
                    final game = installed[index];

                    return _AnimatedGameCard(
                      index: index,
                      child: GameCard(
                        game: game,
                        isInstalled: true,
                        onTap:
                            () => Navigator.push(
                              context,
                              _fadeRoute(
                                GameDetailsPage(game: game, isInstalled: true),
                              ),
                            ).then(
                              (_) => context.read<GamesCubit>().loadGames(),
                            ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Library-specific sub-widgets
// ─────────────────────────────────────────────────────────────

class _LibraryEmptyState extends StatelessWidget {
  final ColorScheme scheme;

  const _LibraryEmptyState({required this.scheme});

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
                colors: [scheme.primary.withOpacity(0.14), Colors.transparent],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 80,
                  color: Colors.white.withOpacity(0.12),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primary.withOpacity(0.18),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your library is empty',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Head to Browse Store to discover\nand install your first game.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary.withOpacity(0.2),
              foregroundColor: scheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.storefront_rounded, size: 18),
            label: const Text(
              'Browse Store',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme scheme;

  const _StatBadge({
    required this.icon,
    required this.label,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final ColorScheme scheme;

  const _SortButton({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
      ),
      child: PopupMenuButton<String>(
        color: const Color(0xFF1A2035),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tooltip: 'Sort library',
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 12),
            Icon(
              Icons.swap_vert_rounded,
              size: 17,
              color: Colors.white.withOpacity(0.7),
            ),
            const SizedBox(width: 6),
            Text(
              'Sort',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
        onSelected: (_) {},
        itemBuilder:
            (_) => [
              _sortItem(Icons.sort_by_alpha_rounded, 'Name A–Z'),
              _sortItem(Icons.access_time_rounded, 'Recently played'),
              _sortItem(Icons.download_done_rounded, 'Install date'),
              _sortItem(Icons.storage_rounded, 'File size'),
            ],
      ),
    );
  }

  PopupMenuItem<String> _sortItem(IconData icon, String label) {
    return PopupMenuItem(
      value: label,
      child: Row(
        children: [
          Icon(icon, size: 17, color: Colors.white54),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// Reuse from GamesPage — place these in a shared widgets file
class _AnimatedGameCard extends StatefulWidget {
  final Widget child;
  final int index;
  const _AnimatedGameCard({required this.child, required this.index});

  @override
  State<_AnimatedGameCard> createState() => _AnimatedGameCardState();
}

class _AnimatedGameCardState extends State<_AnimatedGameCard>
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
      begin: const Offset(0, 0.07),
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

class _ShimmerGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        childAspectRatio: 0.72,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 8,
      itemBuilder: (_, __) => _ShimmerCard(),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final shimmerColor =
            Color.lerp(
              Colors.white.withOpacity(0.05),
              Colors.white.withOpacity(0.12),
              (0.5 - (_ctrl.value - 0.5).abs()) * 2,
            )!;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: shimmerColor,
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final ColorScheme scheme;

  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
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
              Icons.wifi_off_rounded,
              size: 48,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Something went wrong',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: onRetry,
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
}

Route _fadeRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 320),
    transitionsBuilder:
        (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
  );
}
