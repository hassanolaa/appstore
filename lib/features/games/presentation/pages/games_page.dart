import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_store/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:game_store/features/categories/presentation/cubit/categories_state.dart';
import '../cubit/games_cubit.dart';
import '../cubit/games_state.dart';
import '../widgets/game_card.dart';
import 'package:game_store/features/game/presentation/pages/game_details_page.dart';

class GamesPage extends StatefulWidget {
  const GamesPage({super.key});

  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int? _selectedCategoryId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<CategoriesCubit>().loadCategories();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<GamesCubit>().loadMoreGames();
    }
  }

  void _loadData() {
    context.read<GamesCubit>().loadGames(
      query: _searchQuery,
      categoryId: _selectedCategoryId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Search + sort bar ──────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: _SearchField(
                  controller: _searchController,
                  query: _searchQuery,
                  onChanged: (v) {
                    setState(() => _searchQuery = v);
                    _loadData();
                  },
                ),
              ),
              const SizedBox(width: 12),
              _IconPill(
                icon: Icons.tune_rounded,
                tooltip: 'Filters',
                scheme: scheme,
              ),
              const SizedBox(width: 8),
              _IconPill(
                icon: Icons.swap_vert_rounded,
                tooltip: 'Sort',
                scheme: scheme,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Category chips ─────────────────────────────────────
        BlocBuilder<CategoriesCubit, CategoriesState>(
          builder: (context, state) {
            if (state is! CategoriesLoaded) return const SizedBox.shrink();
            return SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: state.categories.length + 1,
                itemBuilder: (context, index) {
                  final isAll = index == 0;
                  final category = isAll ? null : state.categories[index - 1];
                  final isSelected =
                      isAll
                          ? _selectedCategoryId == null
                          : _selectedCategoryId == category!.id;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _CategoryPill(
                      label: isAll ? 'All Games' : category!.name,
                      isSelected: isSelected,
                      scheme: scheme,
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = isAll ? null : category!.id;
                        });
                        _loadData();
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        // ── Games grid ─────────────────────────────────────────
        Expanded(
          child: BlocBuilder<GamesCubit, GamesState>(
            builder: (context, state) {
              if (state is GamesLoading) {
                return _ShimmerGrid();
              }

              if (state is GamesError) {
                return _ErrorState(
                  message: state.message,
                  onRetry: _loadData,
                  scheme: scheme,
                );
              }

              if (state is GamesLoaded) {
                if (state.games.isEmpty) {
                  return _EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No games found',
                    subtitle: 'Try a different search or category filter.',
                  );
                }

                return GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: state.games.length,
                  itemBuilder: (context, index) {
                    final game = state.games[index];
                    final isInstalled = state.installedGames.any(
                      (ref) => ref.contains(game.id) || game.id.contains(ref),
                    );

                    return _AnimatedGameCard(
                      index: index,
                      child: GameCard(
                        game: game,
                        isInstalled: isInstalled,
                        onTap:
                            () => Navigator.push(
                              context,
                              _fadeRoute(
                                GameDetailsPage(
                                  game: game,
                                  isInstalled: isInstalled,
                                ),
                              ),
                            ).then((_) => _loadData()),
                      ),
                    );
                  },
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.query,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.07),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Search games, genres, publishers…',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.38)),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.white.withOpacity(0.5),
            size: 20,
          ),
          suffixIcon:
              query.isNotEmpty
                  ? IconButton(
                    icon: Icon(
                      Icons.cancel_rounded,
                      color: Colors.white.withOpacity(0.45),
                      size: 18,
                    ),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _IconPill extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final ColorScheme scheme;

  const _IconPill({
    required this.icon,
    required this.tooltip,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.07),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.white70, size: 20),
          onPressed: () {},
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ColorScheme scheme;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.label,
    required this.isSelected,
    required this.scheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color:
            isSelected
                ? scheme.primary.withOpacity(0.22)
                : Colors.white.withOpacity(0.06),
        border: Border.all(
          color:
              isSelected
                  ? scheme.primary.withOpacity(0.55)
                  : Colors.white.withOpacity(0.09),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? scheme.primary : Colors.white70,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedGameCard extends StatefulWidget {
  final Widget child;
  final int index;

  const _AnimatedGameCard({required this.child, required this.index});

  @override
  State<_AnimatedGameCard> createState() => _AnimatedGameCardState();
}

class _AnimatedGameCardState extends State<_AnimatedGameCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Stagger by index (cap at 12 to avoid long delays)
    Future.delayed(Duration(milliseconds: 40 * widget.index.clamp(0, 12)), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.06),
            ),
            child: Icon(icon, size: 52, color: Colors.white30),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 14,
            ),
          ),
        ],
      ),
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
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}
