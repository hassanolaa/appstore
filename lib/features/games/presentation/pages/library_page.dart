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
    return BlocBuilder<GamesCubit, GamesState>(
      builder: (context, state) {
        if (state is GamesLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is GamesLoaded) {
          final installedGames = state.games.where((game) => state.installedGames.contains(game.id)).toList();

          if (installedGames.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videogame_asset_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Your library is empty.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: installedGames.length,
            itemBuilder: (context, index) {
              final game = installedGames[index];
              return GameCard(
                game: game,
                isInstalled: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GameDetailsPage(game: game, isInstalled: true),
                    ),
                  ).then((_) {
                    context.read<GamesCubit>().loadGames();
                  });
                },
              );
            },
          );
        } else if (state is GamesError) {
          return Center(child: Text(state.message));
        }
        return const SizedBox.shrink();
      },
    );
  }
}
