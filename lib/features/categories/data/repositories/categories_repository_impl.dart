import 'package:dartz/dartz.dart';
import '../datasources/categories_local_data_source.dart';
import '../models/category_model.dart';

class CategoriesRepositoryImpl {
  final CategoriesLocalDataSource localDataSource;

  CategoriesRepositoryImpl({required this.localDataSource});

  Future<Either<String, List<CategoryModel>>> getCategories() async {
    try {
      final categories = await localDataSource.getCategories();
      return Right(categories);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
