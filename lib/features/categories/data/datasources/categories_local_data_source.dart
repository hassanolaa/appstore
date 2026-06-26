import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/category_model.dart';

abstract class CategoriesLocalDataSource {
  Future<List<CategoryModel>> getCategories();
}

class CategoriesLocalDataSourceImpl implements CategoriesLocalDataSource {
  final Database database;

  CategoriesLocalDataSourceImpl({required this.database});

  @override
  Future<List<CategoryModel>> getCategories() async {
    final List<Map<String, dynamic>> maps = await database.query('categories');
    return maps.map((map) => CategoryModel.fromMap(map)).toList();
  }
}
