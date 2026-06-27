import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/games_repository_impl.dart';
import '../../data/models/game_model.dart';
import 'games_state.dart';

class GamesCubit extends Cubit<GamesState> {
  final GamesRepositoryImpl repository;

  // Track pagination state
  String? _lastQuery;
  int? _lastCategoryId;
  int _currentOffset = 0;
  final int _limit = 50;
  bool _hasReachedMax = false;
  bool _isLoadingMore = false;

  GamesCubit({required this.repository}) : super(GamesInitial());

  Future<void> loadGames({String? query, int? categoryId}) async {
    _lastQuery = query;
    _lastCategoryId = categoryId;
    _currentOffset = 0;
    _hasReachedMax = false;
    _isLoadingMore = false;

    emit(GamesLoading());
    final gamesResult = await repository.getGames(
      limit: _limit,
      offset: _currentOffset,
      query: query,
      categoryId: categoryId,
    );
    final installedResult = await repository.getInstalledGames();
    final upgradableResult = await repository.getUpgradableGames();

    gamesResult.fold(
      (error) => emit(GamesError(error)),
      (games) {
        final installed = installedResult.fold((_) => <String>[], (list) => list);
        final upgradable = upgradableResult.fold((_) => <String>[], (list) => list);
        _hasReachedMax = games.length < _limit;
        _currentOffset = games.length;
        emit(GamesLoaded(games, installed, upgradable));
      },
    );
  }

  Future<void> loadMoreGames() async {
    final currentState = state;
    if (currentState is! GamesLoaded || _isLoadingMore || _hasReachedMax) return;

    _isLoadingMore = true;
    final gamesResult = await repository.getGames(
      limit: _limit,
      offset: _currentOffset,
      query: _lastQuery,
      categoryId: _lastCategoryId,
    );

    gamesResult.fold(
      (error) {
        _isLoadingMore = false;
      },
      (newGames) {
        _isLoadingMore = false;
        if (newGames.isEmpty) {
          _hasReachedMax = true;
        } else {
          _hasReachedMax = newGames.length < _limit;
          _currentOffset += newGames.length;
          final updatedGames = List<GameModel>.from(currentState.games)..addAll(newGames);
          emit(GamesLoaded(updatedGames, currentState.installedGames, currentState.upgradableGames));
        }
      },
    );
  }

  Future<void> installGame(String id) async {
    try {
      await repository.installGameStream(id).drain();
    } catch (_) {}
    loadGames(query: _lastQuery, categoryId: _lastCategoryId); // Refresh installed status
  }

  Future<void> removeGame(String id) async {
    try {
      await repository.removeGameStream(id).drain();
    } catch (_) {}
    loadGames(query: _lastQuery, categoryId: _lastCategoryId); // Refresh installed status
  }

  Future<void> upgradeGame(String id) async {
    try {
      await repository.upgradeGameStream(id).drain();
    } catch (_) {}
    loadGames(query: _lastQuery, categoryId: _lastCategoryId); // Refresh installed/upgradable status
  }
}
