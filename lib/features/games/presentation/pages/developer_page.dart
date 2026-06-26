import 'package:flutter/material.dart';
import 'package:game_store/service_locator.dart';
import 'package:game_store/features/games/data/repositories/games_repository_impl.dart';
import 'package:game_store/features/games/data/models/game_model.dart';
import 'package:game_store/features/game/presentation/pages/game_details_page.dart';
import '../widgets/game_card.dart';

class DeveloperPage extends StatefulWidget {
  final String developerName;

  const DeveloperPage({super.key, required this.developerName});

  @override
  State<DeveloperPage> createState() => _DeveloperPageState();
}

class _DeveloperPageState extends State<DeveloperPage> {
  late Future<(List<GameModel>, List<String>)> _dataFuture;
  final GamesRepositoryImpl _repository = sl();

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<(List<GameModel>, List<String>)> _loadData() async {
    final gamesResult = await _repository.getGames(developer: widget.developerName);
    final installedResult = await _repository.getInstalledGames();
    final games = gamesResult.fold((_) => <GameModel>[], (g) => g);
    final installed = installedResult.fold((_) => <String>[], (i) => i);
    return (games, installed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.developerName} Games'),
      ),
      body: FutureBuilder<(List<GameModel>, List<String>)>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading games: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.$1.isEmpty) {
            return const Center(child: Text('No games found for this developer.'));
          }

          final games = snapshot.data!.$1;
          final installedList = snapshot.data!.$2;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              final isInstalled = installedList.any((ref) => ref.contains(game.id) || game.id.contains(ref));

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
                    setState(() {
                      _dataFuture = _loadData();
                    });
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}
