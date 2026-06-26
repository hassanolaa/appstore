import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_store/service_locator.dart';
import 'package:game_store/features/games/data/models/game_model.dart';
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
      create: (_) => GameDetailsCubit(
        repository: sl(),
        gameId: game.id,
        initialGame: game,
        isInstalledInitially: isInstalled,
      )..loadDetails(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(game.name ?? 'Game Details'),
        ),
        body: BlocBuilder<GameDetailsCubit, GameDetailsState>(
          builder: (context, state) {
            bool isLoading = state is GameDetailsLoading;
            bool isGameInstalled = false;
            double? progress;
            String? progressStatus;
            GameModel activeGame = game;

            if (state is GameDetailsLoaded) {
              isGameInstalled = state.isInstalled;
              activeGame = state.game;
              progress = state.progress;
              progressStatus = state.progressStatus;
            } else if (state is GameDetailsInitial || state is GameDetailsLoading) {
              isGameInstalled = isInstalled;
            }

            return Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          if (activeGame.icon128 != null && activeGame.icon128!.isNotEmpty)
                            Image.file(
                              File(activeGame.icon128!),
                              width: 200,
                              height: 200,
                              errorBuilder: (_, __, ___) => const Icon(Icons.videogame_asset, size: 200),
                            )
                          else
                            const Icon(Icons.videogame_asset, size: 200),
                          const SizedBox(height: 32),
                          if (progress != null) ...[
                            Text(
                              progressStatus ?? 'Processing...',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(value: progress),
                            const SizedBox(height: 8),
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ] else if (isLoading)
                            const CircularProgressIndicator()
                          else if (isGameInstalled)
                            ElevatedButton.icon(
                              icon: const Icon(Icons.delete),
                              label: const Text('Uninstall'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              ),
                              onPressed: () {
                                context.read<GameDetailsCubit>().removeGame();
                              },
                            )
                          else
                            ElevatedButton.icon(
                              icon: const Icon(Icons.download),
                              label: const Text('Install'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              ),
                              onPressed: () {
                                context.read<GameDetailsCubit>().installGame();
                              },
                            ),
                          if (activeGame.bundles.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            const Divider(),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Bundle Info',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildMetadataItem('Ref', activeGame.bundles.first.flatpakRef),
                            _buildMetadataItem('Runtime', activeGame.bundles.first.runtime),
                            _buildMetadataItem('SDK', activeGame.bundles.first.sdk),
                            _buildMetadataItem('Arch', activeGame.bundles.first.arch),
                            _buildMetadataItem('Branch', activeGame.bundles.first.branch),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeGame.name ?? 'Unknown',
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Developer: ${activeGame.developer ?? 'Unknown'}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          activeGame.summary ?? '',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Description',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          flex: 3,
                          child: SingleChildScrollView(
                            child: Text(
                              activeGame.description ?? 'No description available.',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ),
                        if (activeGame.screenshots.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text(
                            'Screenshots',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            flex: 4,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: activeGame.screenshots.length,
                              itemBuilder: (context, index) {
                                final screenshot = activeGame.screenshots[index];
                                final source = screenshot.source ?? '';
                                final isNetwork = source.startsWith('http');

                                return Padding(
                                  padding: const EdgeInsets.only(right: 16.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: AspectRatio(
                                      aspectRatio: 16 / 9,
                                      child: isNetwork
                                          ? Image.network(
                                              source,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 64)),
                                            )
                                          : Image.file(
                                              File(source),
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 64)),
                                            ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetadataItem(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }
}
