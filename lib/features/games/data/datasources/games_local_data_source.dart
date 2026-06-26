import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/game_model.dart';

abstract class GamesLocalDataSource {
  Future<List<GameModel>> getGames({int limit = 50, int offset = 0, String? query, int? categoryId, String? developer});
  Future<GameModel?> getGameById(String id);
}

class GamesLocalDataSourceImpl implements GamesLocalDataSource {
  final Database database;

  GamesLocalDataSourceImpl({required this.database});

  @override
  Future<List<GameModel>> getGames({int limit = 50, int offset = 0, String? query, int? categoryId, String? developer}) async {
    List<String> conditions = [];
    List<dynamic> whereArgs = [];

    if (query != null && query.isNotEmpty) {
      conditions.add('(name LIKE ? OR summary LIKE ?)');
      whereArgs.addAll(['%$query%', '%$query%']);
    }

    if (developer != null && developer.isNotEmpty) {
      conditions.add('developer = ?');
      whereArgs.add(developer);
    }

    String whereClause = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';

    if (categoryId != null) {
      // If we need to filter by category, we need to join with app_categories
      final String sql = '''
        SELECT a.* FROM apps a
        INNER JOIN app_categories ac ON a.id = ac.app_id
        ${whereClause.isEmpty ? 'WHERE ac.category_id = ?' : '$whereClause AND ac.category_id = ?'}
        LIMIT ? OFFSET ?
      ''';
      
      final List<Object?> args = [];
      if (whereClause.isEmpty) {
        args.add(categoryId);
      } else {
        args.addAll(whereArgs);
        args.add(categoryId);
      }
      args.addAll([limit, offset]);

      final List<Map<String, dynamic>> maps = await database.rawQuery(sql, args);
      return maps.map((map) => GameModel.fromMap(map)).toList();
    } else {
      final List<Map<String, dynamic>> maps = await database.query(
        'apps',
        where: conditions.isEmpty ? null : conditions.join(' AND '),
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        limit: limit,
        offset: offset,
      );
      return maps.map((map) => GameModel.fromMap(map)).toList();
    }
  }

  @override
  Future<GameModel?> getGameById(String id) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'apps',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      final List<Map<String, dynamic>> screenshotMaps = await database.query(
        'screenshots',
        where: 'app_id = ?',
        whereArgs: [id],
      );
      final screenshots = screenshotMaps.map((map) => ScreenshotModel.fromMap(map)).toList();

      final List<Map<String, dynamic>> bundleMaps = await database.query(
        'bundles',
        where: 'app_id = ?',
        whereArgs: [id],
      );
      final bundles = bundleMaps.map((map) => BundleModel.fromMap(map)).toList();

      return GameModel.fromMap(maps.first, screenshots: screenshots, bundles: bundles);
    }
    return null;
  }
}
