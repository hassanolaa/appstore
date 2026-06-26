import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/games_cubit.dart';
import '../cubit/games_state.dart';
import '../widgets/game_card.dart';
import 'package:game_store/features/game/presentation/pages/game_details_page.dart';

class UpdatesPage extends StatelessWidget {
  const UpdatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GamesCubit, GamesState>(
      builder: (context, state) {
        if (state is GamesLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is GamesLoaded) {
          final upgradableGames = state.games.where((game) => state.upgradableGames.contains(game.id)).toList();

          if (upgradableGames.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'All games are up to date!',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: upgradableGames.length,
            itemBuilder: (context, index) {
              final game = upgradableGames[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(game.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(game.developer ?? 'Unknown Developer'),
                  trailing: ElevatedButton.icon(
                    icon: const Icon(Icons.upgrade),
                    label: const Text('Update'),
                    onPressed: () {
                      context.read<GamesCubit>().upgradeGame(game.id);
                    },
                  ),
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
                ),
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
