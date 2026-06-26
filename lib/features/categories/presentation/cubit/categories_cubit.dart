import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/categories_repository_impl.dart';
import 'categories_state.dart';

class CategoriesCubit extends Cubit<CategoriesState> {
  final CategoriesRepositoryImpl repository;

  CategoriesCubit({required this.repository}) : super(CategoriesInitial());

  Future<void> loadCategories() async {
    emit(CategoriesLoading());
    final result = await repository.getCategories();
    result.fold(
      (error) => emit(CategoriesError(error)),
      (categories) => emit(CategoriesLoaded(categories)),
    );
  }
}
