import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:stocklio_flutter/providers/data/item_transfers.dart';
import 'package:stocklio_flutter/providers/data/tags.dart';
import 'package:stocklio_flutter/providers/data/wastage_items.dart';
import 'package:stocklio_flutter/providers/data/wastages.dart';
import 'package:stocklio_flutter/providers/data/tutorials.dart';
import 'package:stocklio_flutter/providers/data/shortcuts.dart';
import 'package:stocklio_flutter/providers/ui/count_item_search_fab_ui_provider.dart';
import 'package:stocklio_flutter/providers/ui/dishes_ui_provider.dart';
import 'package:stocklio_flutter/providers/ui/edit_recipe_ui_provider.dart';
import 'package:stocklio_flutter/providers/ui/end_count_confetti_provider.dart';
import 'package:stocklio_flutter/providers/ui/language_settings_provider.dart';
import 'package:stocklio_flutter/providers/ui/pending_count_timer_provider.dart';
import 'package:stocklio_flutter/providers/ui/recipe_list_ui_provider.dart';
import 'package:stocklio_flutter/providers/ui/supplier_ui_provider.dart';
import 'package:stocklio_flutter/providers/ui/tags_ui_provider.dart';
import 'package:stocklio_flutter/services/connectivity_service.dart';
import 'package:stocklio_flutter/utils/enums.dart';

// Data Providers
import 'providers/data/admin.dart';
import 'providers/data/app_config.dart';
import 'providers/data/file_upload.dart';
import 'providers/data/notifications.dart';
import 'providers/data/organization.dart';
import 'providers/data/subsidiaries.dart';
import 'providers/data/tasks.dart';
import 'providers/data/auth.dart';
import 'providers/data/global_items.dart';
import 'providers/data/count_areas.dart';
import 'providers/data/invoices.dart';
import 'providers/data/pos_items.dart';
import 'providers/data/items.dart';
import 'providers/data/recipes.dart';
import 'providers/data/counts.dart';
import 'providers/data/count_items.dart';
import 'providers/data/users.dart';
import 'providers/data/suppliers.dart';

// UI Providers
import 'providers/ui/camera_settings.dart';
import 'providers/ui/count_item_view_ui_provider.dart';
import 'providers/ui/existing_count_ui_provider.dart';
import 'providers/ui/home_navigation.dart';
import 'providers/ui/notification_settings.dart';
import 'providers/ui/pos_item_ui.dart';
import 'providers/ui/recipe_ui_provider.dart';
import 'providers/ui/report_items_expanded.dart';
import 'providers/ui/search_button.dart';
import 'providers/ui/toast_provider.dart';
import 'providers/ui/user_center_provider.dart';
import 'providers/ui/wastage_ui_provider.dart';

List<SingleChildWidget> providers = [
  StreamProvider<ConnectivityStatus>(
    initialData: ConnectivityStatus.online,
    create: (context) => ConnectivityService().stream,
  ),
  ChangeNotifierProvider(
    create: (context) => AuthProvider(),
  ),
  ChangeNotifierProvider<AppConfigProvider>(
    create: (context) => AppConfigProvider(),
  ),
  ChangeNotifierProxyProvider<AuthProvider, TutorialProvider>(
    create: (context) => TutorialProvider(),
    update: (context, value, previous) => TutorialProvider(auth: value),
  ),
  ChangeNotifierProvider<AdminProvider>(
    create: (context) => AdminProvider(),
  ),
  ChangeNotifierProvider<SupplierUIProvider>(
    create: (context) => SupplierUIProvider(),
  ),
  ChangeNotifierProvider<LanguageSettingsProvider>(
    create: (context) => LanguageSettingsProvider(),
  ),
  ChangeNotifierProxyProvider2<AdminProvider, AuthProvider,
      OrganizationProvider>(
    create: (context) => OrganizationProvider(),
    update: (context, value, value2, previous) => OrganizationProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, SubsidiariesProvider>(
    create: (context) => SubsidiariesProvider(),
    update: (context, value, previous) => SubsidiariesProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, ProfileProvider>(
    create: (context) => ProfileProvider(),
    update: (context, value, previous) => ProfileProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, TagsProvider>(
    create: (context) => TagsProvider(),
    update: (context, value, previous) => TagsProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, ItemProvider>(
    create: (context) => ItemProvider(),
    update: (context, value, previous) => ItemProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, PosItemProvider>(
    create: (context) => PosItemProvider(),
    update: (context, value, previous) => PosItemProvider(),
  ),
  ChangeNotifierProxyProvider2<ProfileProvider, PosItemProvider,
      RecipeProvider>(
    create: (context) => RecipeProvider(),
    update: (context, value, value2, previous) {
      if (!value.profile.isPosItemsAsMenuItemsEnabled) {
        if (value.profile.id == previous?.userId) {
          return previous ?? RecipeProvider();
        }

        return RecipeProvider();
      }

      return RecipeProvider(
        posItems: value2.posItems,
      );
    },
  ),
  ChangeNotifierProxyProvider2<OrganizationProvider, AuthProvider,
      CountProvider>(
    create: (context) => CountProvider(),
    update: (context, value, auth, previous) => CountProvider(auth: auth),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, CountAreaProvider>(
    create: (context) => CountAreaProvider(),
    update: (context, value, previous) => CountAreaProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, CountItemProvider>(
    create: (context) => CountItemProvider(),
    update: (context, value, previous) => CountItemProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, CountItemViewUIProvider>(
    create: (context) => CountItemViewUIProvider(),
    update: (context, value, previous) => CountItemViewUIProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, InvoiceProvider>(
    create: (context) => InvoiceProvider(),
    update: (context, value, previous) => InvoiceProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, GlobalItemProvider>(
    create: (context) => GlobalItemProvider(),
    update: (context, value, previous) => GlobalItemProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, NotificationProvider>(
    create: (context) => NotificationProvider(),
    update: (context, value, previous) => NotificationProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, SupplierProvider>(
    create: (context) => SupplierProvider(),
    update: (context, value, previous) => SupplierProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, HomeNavigationProvider>(
    create: (context) => HomeNavigationProvider(),
    update: (context, value, previous) => HomeNavigationProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, SearchButtonProvider>(
    create: (context) => SearchButtonProvider(),
    update: (context, value, previous) => SearchButtonProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, ExistingCountUIProvider>(
    create: (context) => ExistingCountUIProvider(),
    update: (context, value, previous) => ExistingCountUIProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, CameraSettingsProvider>(
    create: (context) => CameraSettingsProvider(),
    update: (context, value, previous) => CameraSettingsProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider,
      NotificationSettingsProvider>(
    create: (context) => NotificationSettingsProvider(),
    update: (context, value, previous) => NotificationSettingsProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, InvoiceUIProvider>(
    create: (context) => InvoiceUIProvider(),
    update: (context, value, previous) => InvoiceUIProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, RecipeUIProvider>(
    create: (context) => RecipeUIProvider(),
    update: (context, value, previous) => RecipeUIProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, RecipeListUIProvider>(
    create: (context) => RecipeListUIProvider(),
    update: (context, value, previous) => RecipeListUIProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, ReportItemExpandedProvider>(
    create: (context) => ReportItemExpandedProvider(),
    update: (context, value, previous) => ReportItemExpandedProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, ToastProvider>(
    create: (context) => ToastProvider(),
    update: (context, value, previous) => ToastProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, POSItemUIProvider>(
    create: (context) => POSItemUIProvider(),
    update: (context, value, previous) => POSItemUIProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, UserCenterProvider>(
    create: (context) => UserCenterProvider(),
    update: (context, value, previous) => UserCenterProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, FileUploadProvider>(
    create: (context) => FileUploadProvider(),
    update: (context, value, previous) => FileUploadProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, SupplierProvider>(
    create: (context) => SupplierProvider(),
    update: (context, value, previous) => SupplierProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, CountItemViewUIProvider>(
    create: (context) => CountItemViewUIProvider(),
    update: (context, value, previous) => CountItemViewUIProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, TaskProvider>(
    create: (context) => TaskProvider(),
    update: (context, value, previous) => TaskProvider(),
  ),
  ChangeNotifierProxyProvider2<OrganizationProvider, AuthProvider,
      ShortcutProvider>(
    create: (context) => ShortcutProvider(),
    update: (context, value, auth, previous) => ShortcutProvider(auth: auth),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, DishesUIProvider>(
    create: (context) => DishesUIProvider(),
    update: (context, value, previous) => DishesUIProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, WastageProvider>(
    create: (context) => WastageProvider(),
    update: (context, value, previous) => WastageProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, WastageUIProvider>(
    create: (context) => WastageUIProvider(),
    update: (context, value, previous) => WastageUIProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, WastageItemProvider>(
    create: (context) => WastageItemProvider(),
    update: (context, value, previous) => WastageItemProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, EditRecipeUIProvider>(
    create: (context) => EditRecipeUIProvider(),
    update: (context, value, previous) => EditRecipeUIProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider,
      CountItemSearchFabUIProvider>(
    create: (context) => CountItemSearchFabUIProvider(),
    update: (context, value, previous) => CountItemSearchFabUIProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, TagsUIProvider>(
    create: (context) => TagsUIProvider(),
    update: (context, value, previous) => TagsUIProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, ConfettiProvider>(
    create: (context) => ConfettiProvider(),
    update: (context, value, previous) => ConfettiProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, PendingCountTimerProvider>(
    create: (context) => PendingCountTimerProvider(),
    update: (context, value, previous) => PendingCountTimerProvider(),
  ),
  ChangeNotifierProxyProvider<OrganizationProvider, ItemTransferProvider>(
    create: (context) => ItemTransferProvider(),
    update: (context, value, previous) => ItemTransferProvider(),
  ),
];
