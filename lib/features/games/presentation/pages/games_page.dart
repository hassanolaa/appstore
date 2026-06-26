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
  int? _selectedCategoryId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<CategoriesCubit>().loadCategories();
    _loadData();
  }

  void _loadData() {
    context.read<GamesCubit>().loadGames(query: _searchQuery, categoryId: _selectedCategoryId);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onSubmitted: (value) {
              setState(() {
                _searchQuery = value;
              });
              _loadData();
            },
            decoration: InputDecoration(
              hintText: 'Search games...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                        _loadData();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
          ),
        ),

        // Categories Filter
        BlocBuilder<CategoriesCubit, CategoriesState>(
          builder: (context, state) {
            if (state is CategoriesLoaded) {
              return SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.categories.length + 1,
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final isSelected = isAll ? _selectedCategoryId == null : _selectedCategoryId == state.categories[index - 1].id;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(isAll ? 'All' : state.categories[index - 1].name),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategoryId = isAll ? null : state.categories[index - 1].id;
                            });
                            _loadData();
                          }
                        },
                      ),
                    );
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        const SizedBox(height: 16),

        // Games Grid
        Expanded(
          child: BlocBuilder<GamesCubit, GamesState>(
            builder: (context, state) {
              if (state is GamesLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is GamesLoaded) {
                if (state.games.isEmpty) {
                  return const Center(child: Text('No games found.'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: state.games.length,
                  itemBuilder: (context, index) {
                    final game = state.games[index];
                    final isInstalled = state.installedGames.contains(game.id);

                    return GameCard(
                      game: game,
                      isInstalled: isInstalled,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GameDetailsPage(game: game, isInstalled: isInstalled),
                          ),
                        ).then((_) {
                          _loadData();
                        });
                      },
                    );
                  },
                );
              } else if (state is GamesError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(state.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onFocusChange: (focused) {},
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      )
                    ],
                  ),
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
