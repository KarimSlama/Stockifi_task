// Flutter Packages
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// 3rd-Party Packages
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stocklio_flutter/providers.dart';
import 'package:stocklio_flutter/providers/data/app_config.dart';
import 'package:stocklio_flutter/providers/data/users.dart';
import 'package:stocklio_flutter/providers/ui/language_settings_provider.dart';
import 'package:stocklio_flutter/tools/session_recorder/session_recorder.dart';
import 'package:stocklio_flutter/utils/analytics_util.dart';
import 'package:stocklio_flutter/utils/app_theme_util.dart';
import 'package:stocklio_flutter/utils/asset_util.dart';
import 'package:stocklio_flutter/utils/package_util.dart';
import 'package:stocklio_flutter/utils/presence.dart';
import 'package:stocklio_flutter/utils/router/go_router.dart';

import 'firebase_options.dart' as firebase_options;
import 'firebase_options_dev.dart' as firebase_options_dev;

// Providers
import 'providers/data/auth.dart';
import 'service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // This was used to notify user to refresh web app
  // on service worker / app update found event
  // UpdateFinder.instance?.init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(
    name: TargetPlatform.android == defaultTargetPlatform
        ? (kDebugMode)
            ? 'stocklio-playground'
            : 'stocklio-beta'
        : null,
    options: kDebugMode
        ? firebase_options_dev.DefaultFirebaseOptions.currentPlatform
        : null,
    // : firebase_options.DefaultFirebaseOptions.currentPlatform,
  );

  await PackageUtil.initPackageInfo();

  await setupLocator();

  await AssetUtil.loadSilhouettePaths(rootBundle);

  if (kDebugMode) {
    runApp(const MyApp());
    return;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: MultiProvider(
        providers: providers,
        builder: (context, child) {
          final user =
              context.select<AuthProvider, User?>((value) => value.user);

          final isDemo = user?.email?.startsWith('demo') ?? false;
          if (!kDebugMode && user != null && !isDemo) {
            SessionRecorder.instance?.init(user);
          }
          final isAdmin =
              context.select<AuthProvider, bool>((value) => value.isAdmin);
          if (user != null && !isAdmin /* && !isDemo */) {
            Analytics.logEvent('login', user.uid, user.email);
            Presence().setUserPresence(user.uid);
          }
          return const StocklioApp();
        },
      ),
    );
  }
}

class StocklioApp extends StatefulWidget {
  const StocklioApp({
    Key? key,
  }) : super(key: key);

  @override
  State<StocklioApp> createState() => _StocklioAppState();
}

class _StocklioAppState extends State<StocklioApp> {
  @override
  Widget build(BuildContext context) {
    final appRouter = getRouter(context);
    final languageSettingsProvider = context.read<LanguageSettingsProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final isLocalizationEnabled = profileProvider.profile.isLocalizationEnabled;

    String localeString = isLocalizationEnabled
        ? languageSettingsProvider.languagePreference ??
            profileProvider.profile.language
        : 'en';

    return FutureBuilder<String?>(
        future: languageSettingsProvider.getSavedLanguagePref(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            routerDelegate: appRouter.routerDelegate,
            routeInformationParser: appRouter.routeInformationParser,
            routeInformationProvider: appRouter.routeInformationProvider,
            title: 'Stockifi',
            theme: AppTheme.instance.themeData,
            locale: Locale(snapshot.data ?? localeString),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('no'),
            ],
          );
        });
  }
}
