import 'dart:io';
import 'package:dartz/dartz.dart';
import '../datasources/games_local_data_source.dart';
import '../datasources/flatpak_data_source.dart';
import '../models/game_model.dart';
import '../models/flatpak_transaction_operation.dart';

class GamesRepositoryImpl {
  final GamesLocalDataSource localDataSource;
  final FlatpakDataSource flatpakDataSource;

  GamesRepositoryImpl({
    required this.localDataSource,
    required this.flatpakDataSource,
  });

  Future<Either<String, List<GameModel>>> getGames({int limit = 50, int offset = 0, String? query, int? categoryId, String? developer}) async {
    try {
      final games = await localDataSource.getGames(limit: limit, offset: offset, query: query, categoryId: categoryId, developer: developer);
      return Right(games);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, GameModel>> getGameDetails(String id) async {
    try {
      final game = await localDataSource.getGameById(id);
      if (game != null) {
        return Right(game);
      } else {
        return const Left('Game not found');
      }
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, List<String>>> getInstalledGames() async {
    try {
      final installed = await flatpakDataSource.listInstalled();
      return Right(installed);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, List<GameModel>>> getInstalledGameModels() async {
    try {
      final installedRefs = await flatpakDataSource.listInstalled();
      final appIds = installedRefs
          .where((ref) => ref.startsWith('app/'))
          .map((ref) => ref.split('/')[1])
          .toList();
      
      if (appIds.isEmpty) return const Right([]);
      
      final games = await localDataSource.getGamesByIds(appIds);
      return Right(games);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, List<String>>> getUpgradableGames() async {
    try {
      final upgradable = await flatpakDataSource.listUpgradable();
      return Right(upgradable);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Stream<FlatpakProgress> installGameStream(String id) async* {
    String ref = id;
    try {
      final game = await localDataSource.getGameById(id);
      if (game != null && game.bundles.isNotEmpty) {
        final bundleRef = game.bundles.first.flatpakRef;
        if (bundleRef != null && bundleRef.isNotEmpty) {
          ref = bundleRef;
        }
      }
    } catch (_) {}
    yield* flatpakDataSource.installAppStream(ref);
  }

  Stream<FlatpakProgress> removeGameStream(String id) async* {
    String ref = id;
    try {
      final game = await localDataSource.getGameById(id);
      if (game != null && game.bundles.isNotEmpty) {
        final bundleRef = game.bundles.first.flatpakRef;
        if (bundleRef != null && bundleRef.isNotEmpty) {
          ref = bundleRef;
        }
      }
    } catch (_) {}
    yield* flatpakDataSource.removeAppStream(ref);
  }

  Stream<FlatpakProgress> upgradeGameStream(String id) async* {
    String ref = id;
    try {
      final game = await localDataSource.getGameById(id);
      if (game != null && game.bundles.isNotEmpty) {
        final bundleRef = game.bundles.first.flatpakRef;
        if (bundleRef != null && bundleRef.isNotEmpty) {
          ref = bundleRef;
        }
      }
    } catch (_) {}
    yield* flatpakDataSource.upgradeAppStream(ref);
  }

  Future<Either<String, Map<String, dynamic>?>> getAppInfo(String id) async {
    try {
      String ref = id;
      final game = await localDataSource.getGameById(id);
      if (game != null && game.bundles.isNotEmpty) {
        final bundleRef = game.bundles.first.flatpakRef;
        if (bundleRef != null && bundleRef.isNotEmpty) {
          ref = bundleRef;
        }
      }
      final info = await flatpakDataSource.getAppInfo(ref);
      return Right(info);
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<void> openApp(String appId) async {
    String ref = appId;
    if (ref.contains('/')) {
      final parts = ref.split('/');
      if (parts.length > 1) {
        ref = parts[1];
      }
    }
    try {
      await Process.start('flatpak', ['run', ref], mode: ProcessStartMode.detached);
    } catch (e) {
      print('Failed to launch flatpak app: $e');
    }
  }
}
