import 'package:equatable/equatable.dart';
import '../../data/models/game_model.dart';

abstract class GamesState extends Equatable {
  const GamesState();

  @override
  List<Object?> get props => [];
}

class GamesInitial extends GamesState {}

class GamesLoading extends GamesState {}

class GamesLoaded extends GamesState {
  final List<GameModel> games;
  final List<String> installedGames;
  final List<String> upgradableGames;

  const GamesLoaded(this.games, this.installedGames, this.upgradableGames);

  @override
  List<Object?> get props => [games, installedGames, upgradableGames];
}

class GamesError extends GamesState {
  final String message;

  const GamesError(this.message);

  @override
  List<Object?> get props => [message];
}
