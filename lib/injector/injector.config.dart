// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:cloud_functions/cloud_functions.dart' as _i809;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:firebase_storage/firebase_storage.dart' as _i457;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;
import 'package:society_management/auth/service/auth_service.dart' as _i253;
import 'package:society_management/chat/di/chat_module.dart' as _i886;
import 'package:society_management/chat/repository/chat_repository.dart'
    as _i154;
import 'package:society_management/chat/service/ai_service.dart' as _i967;
import 'package:society_management/complaints/repository/complaint_repository.dart'
    as _i849;
import 'package:society_management/complaints/repository/i_complaint_repository.dart'
    as _i571;
import 'package:society_management/cubit/refresh_cubit.dart' as _i998;
import 'package:society_management/dashboard/repository/dashboard_stats_repository.dart'
    as _i522;
import 'package:society_management/dashboard/repository/i_dashboard_stats_repository.dart'
    as _i272;
import 'package:society_management/expenses/repository/expense_repository.dart'
    as _i756;
import 'package:society_management/expenses/repository/i_expense_repository.dart'
    as _i484;
import 'package:society_management/injector/firebase_injectors.dart' as _i446;
import 'package:society_management/injector/shared_preference_injectable_module.dart'
    as _i24;
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart'
    as _i100;
import 'package:society_management/maintenance/repository/maintenance_repository.dart'
    as _i10;
import 'package:society_management/meetings/repository/i_meeting_repository.dart'
    as _i786;
import 'package:society_management/meetings/repository/meeting_repository.dart'
    as _i994;
import 'package:society_management/users/repository/i_user_repository.dart'
    as _i816;
import 'package:society_management/users/repository/user_repository.dart'
    as _i728;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final sharedPrefrenceInjectableModule = _$SharedPrefrenceInjectableModule();
    final chatModule = _$ChatModule();
    final firebaseInjectableModule = _$FirebaseInjectableModule();
    final firebaseAuthInjectableModule = _$FirebaseAuthInjectableModule();
    final firebaseStorageInjectableModule = _$FirebaseStorageInjectableModule();
    final firebaseFunctionsInjectableModule =
        _$FirebaseFunctionsInjectableModule();
    gh.factory<_i253.AuthService>(() => _i253.AuthService());
    gh.factory<_i998.RefreshCubit>(() => _i998.RefreshCubit());
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => sharedPrefrenceInjectableModule.prefs,
      preResolve: true,
    );
    gh.singleton<_i154.IChatRepository>(() => chatModule.chatRepository);
    gh.singleton<_i967.AIService>(() => chatModule.aiService);
    gh.lazySingleton<_i974.FirebaseFirestore>(
        () => firebaseInjectableModule.firestore);
    gh.lazySingleton<_i59.FirebaseAuth>(
        () => firebaseAuthInjectableModule.firestoreAuth);
    gh.lazySingleton<_i457.FirebaseStorage>(
        () => firebaseStorageInjectableModule.firestoreStorage);
    gh.lazySingleton<_i809.FirebaseFunctions>(
        () => firebaseFunctionsInjectableModule.firestoreStorage);
    gh.factory<_i816.IUserRepository>(
        () => _i728.UserRepository(gh<_i974.FirebaseFirestore>()));
    gh.factory<_i100.IMaintenanceRepository>(
        () => _i10.MaintenanceRepository(gh<_i974.FirebaseFirestore>()));
    gh.factory<_i484.IExpenseRepository>(
        () => _i756.ExpenseRepository(gh<_i974.FirebaseFirestore>()));
    gh.factory<_i571.IComplaintRepository>(
        () => _i849.ComplaintRepository(gh<_i974.FirebaseFirestore>()));
    gh.factory<_i272.IDashboardStatsRepository>(
        () => _i522.DashboardStatsRepository(gh<_i974.FirebaseFirestore>()));
    gh.factory<_i786.IMeetingRepository>(
        () => _i994.MeetingRepository(gh<_i974.FirebaseFirestore>()));
    return this;
  }
}

class _$SharedPrefrenceInjectableModule
    extends _i24.SharedPrefrenceInjectableModule {}

class _$ChatModule extends _i886.ChatModule {}

class _$FirebaseInjectableModule extends _i446.FirebaseInjectableModule {}

class _$FirebaseAuthInjectableModule
    extends _i446.FirebaseAuthInjectableModule {}

class _$FirebaseStorageInjectableModule
    extends _i446.FirebaseStorageInjectableModule {}

class _$FirebaseFunctionsInjectableModule
    extends _i446.FirebaseFunctionsInjectableModule {}
