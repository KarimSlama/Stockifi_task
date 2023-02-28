// Flutter Packages
import 'dart:async';
import 'package:flutter/foundation.dart';

// 3rd-Party Packages
import 'package:get_it/get_it.dart';

// Models
import 'package:stocklio_flutter/models/app_config.dart';

// Services
import 'package:stocklio_flutter/services/app_config_service.dart';
import 'package:stocklio_flutter/utils/package_util.dart';

class AppConfigProvider with ChangeNotifier {
  late AppConfigService _appConfigService;

  AppConfigProvider({AppConfigService? appConfigService}) {
    _appConfigService = appConfigService ?? GetIt.instance<AppConfigService>();
  }

  // States
  AppConfig _appConfig = AppConfig();
  StreamSubscription<AppConfig>? _appConfigStreamSub;
  bool _isLoading = true;
  bool _isInit = false;
  bool newVersionAvailable = false;

  final StreamController<bool> _newVersionStreamController =
      StreamController.broadcast();

  Stream<bool> get newVersionStream => _newVersionStreamController.stream;

  // Getters
  bool get isLoading => _isLoading;
  AppConfig get appConfig {
    _appConfigStreamSub ?? _listenToAppConfigStream();
    return _appConfig;
  }

  Future<void>? cancelStreamSubscriptions() {
    return _appConfigStreamSub?.cancel();
  }

  void _listenToAppConfigStream() {
    final appConfigStream = _appConfigService.getAppConfigStream();
    _appConfigStreamSub = appConfigStream.listen((AppConfig appConfig) {
      _appConfig = appConfig;

      final buildNumber = PackageUtil.packageInfo.buildNumber;
      final isNewVersion = appConfig.version > (int.tryParse(buildNumber) ?? 0);

      if (isNewVersion) {
        _newVersionStreamController.add(isNewVersion);
        newVersionAvailable = isNewVersion;
      }

      if (!_isInit) {
        _isInit = true;
        _isLoading = false;
      }

      notifyListeners();
    });
  }

  @override
  void dispose() {
    cancelStreamSubscriptions();
    super.dispose();
  }
}
