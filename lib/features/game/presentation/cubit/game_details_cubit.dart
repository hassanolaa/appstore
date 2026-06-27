import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_store/features/games/data/repositories/games_repository_impl.dart';
import 'package:game_store/features/games/data/models/game_model.dart';

abstract class GameDetailsState {}

class GameDetailsInitial extends GameDetailsState {}

class GameDetailsLoading extends GameDetailsState {}

class GameDetailsLoaded extends GameDetailsState {
  final bool isInstalled;
  final GameModel game;
  final double? progress;
  final String? progressStatus;
  final Map<String, dynamic>? appInfo;

  GameDetailsLoaded({
    required this.isInstalled,
    required this.game,
    this.progress,
    this.progressStatus,
    this.appInfo,
  });
}

class GameDetailsError extends GameDetailsState {
  final String message;

  GameDetailsError(this.message);
}

class GameDetailsCubit extends Cubit<GameDetailsState> {
  final GamesRepositoryImpl repository;
  final String gameId;
  GameModel _game;
  Map<String, dynamic>? _appInfo;

  GameDetailsCubit({
    required this.repository,
    required this.gameId,
    required GameModel initialGame,
    required bool isInstalledInitially,
  })  : _game = initialGame,
        super(GameDetailsLoaded(isInstalled: isInstalledInitially, game: initialGame));

  Future<void> loadDetails() async {
    final result = await repository.getGameDetails(gameId);
    final installedResult = await repository.getInstalledGames();
    final appInfoResult = await repository.getAppInfo(gameId);

    _appInfo = appInfoResult.fold((_) => null, (info) => info);

    result.fold(
      (error) => emit(GameDetailsError(error)),
      (gameDetails) {
        _game = gameDetails;
        final isInstalled = installedResult.fold(
          (_) => false,
          (list) {
            if (list.contains(gameId)) return true;
            for (final ref in list) {
              if (ref.contains(gameId)) return true;
              for (final bundle in gameDetails.bundles) {
                if (bundle.flatpakRef != null && (ref == bundle.flatpakRef || ref.contains(bundle.flatpakRef!))) {
                  return true;
                }
              }
            }
            return false;
          },
        );
        emit(GameDetailsLoaded(isInstalled: isInstalled, game: _game, appInfo: _appInfo));
      },
    );
  }

  Future<void> installGame() async {
    emit(GameDetailsLoaded(
      isInstalled: false,
      game: _game,
      progress: 0.0,
      progressStatus: "Starting install...",
      appInfo: _appInfo,
    ));

    repository.installGameStream(gameId).listen(
      (progressData) {
        emit(GameDetailsLoaded(
          isInstalled: false,
          game: _game,
          progress: progressData.progress,
          progressStatus: progressData.status ?? "Installing...",
          appInfo: _appInfo,
        ));
      },
      onError: (error) {
        emit(GameDetailsError(error.toString()));
      },
      onDone: () {
        emit(GameDetailsLoaded(isInstalled: true, game: _game, appInfo: _appInfo));
      },
    );
  }

  Future<void> removeGame() async {
    emit(GameDetailsLoaded(
      isInstalled: true,
      game: _game,
      progress: 0.0,
      progressStatus: "Starting removal...",
      appInfo: _appInfo,
    ));

    repository.removeGameStream(gameId).listen(
      (progressData) {
        emit(GameDetailsLoaded(
          isInstalled: true,
          game: _game,
          progress: progressData.progress,
          progressStatus: progressData.status ?? "Uninstalling...",
          appInfo: _appInfo,
        ));
      },
      onError: (error) {
        emit(GameDetailsError(error.toString()));
      },
      onDone: () {
        emit(GameDetailsLoaded(isInstalled: false, game: _game, appInfo: _appInfo));
      },
    );
  }

  Future<void> openGame() async {
    await repository.openApp(gameId);
  }
}
