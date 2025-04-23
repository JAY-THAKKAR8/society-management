import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:society_management/cubit/refresh_cubit.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/splash/view/splash_page.dart';
import 'package:society_management/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return AppWrapper(
      child: MaterialApp(
        title: 'KDV Management',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale.fromSubtags(languageCode: 'en'),
        home: const SplashPage(),
      ),
    );
  }
}

class AppWrapper extends StatelessWidget {
  const AppWrapper({
    required this.child,
    super.key,
  });
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<RefreshCubit>(),
        ),
      ],
      child: child,
    );
  }
}
