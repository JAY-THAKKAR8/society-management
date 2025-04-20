import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:society_management/enums/enum_file.dart';
import 'package:society_management/users/model/user_model.dart';

part 'refresh_state.dart';

@injectable
class RefreshCubit extends Cubit<RefreshState> {
  RefreshCubit() : super(UserRefreshInitial());

  void modifyUser(UserModel? user, UserAction action) {
    emit(ModifyUser(user: user ?? const UserModel(), action: action));
  }
}
