import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/games_repository_impl.dart';
import 'games_state.dart';

class GamesCubit extends Cubit<GamesState> {
  final GamesRepositoryImpl repository;

  GamesCubit({required this.repository}) : super(GamesInitial());

  Future<void> loadGames({String? query, int? categoryId}) async {
    emit(GamesLoading());
    final gamesResult = await repository.getGames(query: query, categoryId: categoryId);
    final installedResult = await repository.getInstalledGames();
    final upgradableResult = await repository.getUpgradableGames();

    gamesResult.fold(
      (error) => emit(GamesError(error)),
      (games) {
        final installed = installedResult.fold((_) => <String>[], (list) => list);
        final upgradable = upgradableResult.fold((_) => <String>[], (list) => list);
        emit(GamesLoaded(games, installed, upgradable));
      },
    );
  }

  Future<void> installGame(String id) async {
    try {
      await repository.installGameStream(id).drain();
    } catch (_) {}
    loadGames(); // Refresh installed status
  }

  Future<void> removeGame(String id) async {
    try {
      await repository.removeGameStream(id).drain();
    } catch (_) {}
    loadGames(); // Refresh installed status
  }

  Future<void> upgradeGame(String id) async {
    try {
      await repository.upgradeGameStream(id).drain();
    } catch (_) {}
    loadGames(); // Refresh installed/upgradable status
  }
}
