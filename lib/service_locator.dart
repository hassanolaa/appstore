import 'dart:io';

import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'features/games/data/datasources/flatpak_data_source.dart';
import 'features/games/data/datasources/games_local_data_source.dart';
import 'features/games/data/repositories/games_repository_impl.dart';
import 'features/games/presentation/cubit/games_cubit.dart';
import 'features/categories/data/datasources/categories_local_data_source.dart';
import 'features/categories/data/repositories/categories_repository_impl.dart';
import 'features/categories/presentation/cubit/categories_cubit.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  // Initialize SQLite
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Get the application support directory
  final appDir = await getApplicationSupportDirectory();
  final dbPath = p.join(appDir.path, 'store.db');

  // Copy the bundled database on first run
  if (!await File(dbPath).exists()) {
    await Directory(appDir.path).create(recursive: true);

    final data = await rootBundle.load('assets/db/store.db');

    await File(dbPath).writeAsBytes(data.buffer.asUint8List(), flush: true);
  }

  // Open the copied database
  final database = await databaseFactory.openDatabase(dbPath);

  // Core
  sl.registerLazySingleton<Database>(() => database);

  // Data sources
  sl.registerLazySingleton<GamesLocalDataSource>(
    () => GamesLocalDataSourceImpl(database: sl()),
  );
  sl.registerLazySingleton<FlatpakDataSource>(() => FlatpakDataSourceImpl());
  sl.registerLazySingleton<CategoriesLocalDataSource>(
    () => CategoriesLocalDataSourceImpl(database: sl()),
  );

  // Repositories
  sl.registerLazySingleton<GamesRepositoryImpl>(
    () => GamesRepositoryImpl(localDataSource: sl(), flatpakDataSource: sl()),
  );
  sl.registerLazySingleton<CategoriesRepositoryImpl>(
    () => CategoriesRepositoryImpl(localDataSource: sl()),
  );

  // Cubits
  sl.registerFactory(() => GamesCubit(repository: sl()));
  sl.registerFactory(() => CategoriesCubit(repository: sl()));
}
