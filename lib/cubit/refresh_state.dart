part of 'refresh_cubit.dart';

sealed class RefreshState extends Equatable {
  const RefreshState();

  @override
  List<Object> get props => [];
}

final class UserRefreshInitial extends RefreshState {}

final class ModifyUser extends RefreshState {
  const ModifyUser({required this.user, required this.action});

  final UserModel user;
  final UserAction action;

  @override
  List<Object> get props => [user, action];
}
