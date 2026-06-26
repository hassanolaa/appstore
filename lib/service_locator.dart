import 'package:get_it/get_it.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'features/games/data/datasources/flatpak_data_source.dart';
import 'features/games/data/datasources/games_local_data_source.dart';
import 'features/games/data/repositories/games_repository_impl.dart';
import 'features/games/presentation/cubit/games_cubit.dart';
import 'features/categories/data/datasources/categories_local_data_source.dart';
import 'features/categories/data/repositories/categories_repository_impl.dart';
import 'features/categories/presentation/cubit/categories_cubit.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  // Database
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final database = await databaseFactory.openDatabase('/home/hassanola/Desktop/converter/store.db');

  // Core
  sl.registerLazySingleton<Database>(() => database);

  // Data sources
  sl.registerLazySingleton<GamesLocalDataSource>(
    () => GamesLocalDataSourceImpl(database: sl()),
  );
  sl.registerLazySingleton<FlatpakDataSource>(
    () => FlatpakDataSourceImpl(),
  );
  sl.registerLazySingleton<CategoriesLocalDataSource>(
    () => CategoriesLocalDataSourceImpl(database: sl()),
  );

  // Repositories
  sl.registerLazySingleton<GamesRepositoryImpl>(
    () => GamesRepositoryImpl(
      localDataSource: sl(),
      flatpakDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<CategoriesRepositoryImpl>(
    () => CategoriesRepositoryImpl(
      localDataSource: sl(),
    ),
  );

  // Cubits
  sl.registerFactory(() => GamesCubit(repository: sl()));
  sl.registerFactory(() => CategoriesCubit(repository: sl()));
}
