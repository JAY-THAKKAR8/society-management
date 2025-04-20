import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:society_management/constants/app_assets.dart';
import 'package:society_management/dashboard/dashboard_page.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/widget/app_asset_image.dart';
import 'package:society_management/widget/common_button.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 7),
            child: AppAssetImage(
              AppAssets.splashCar,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppAssetImage(
                  AppAssets.carLogo,
                  height: 51,
                  width: 188,
                ),
                const Gap(14),
                Text(
                  'Dents Fixed, Hassle Free',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Gap(6),
                Text(
                  'Book dent repairs with ease. Quick service, realtime updates, and transparent pricing -anytime anywhere.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Gap(24),
                CommonButton(
                  text: 'Get started',
                  onTap: () {
                    // navigation();
                    context.push(const AdminDashboard());
                  },
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
