// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/models/item.dart';
import 'package:stocklio_flutter/providers/data/admin.dart';
import 'package:stocklio_flutter/providers/data/auth.dart';
import 'package:stocklio_flutter/providers/data/count_areas.dart';
import 'package:stocklio_flutter/providers/data/count_items.dart';
import 'package:stocklio_flutter/providers/data/counts.dart';
import 'package:stocklio_flutter/providers/data/global_items.dart';
import 'package:stocklio_flutter/providers/data/invoices.dart';
import 'package:stocklio_flutter/providers/data/items.dart';
import 'package:stocklio_flutter/providers/data/notifications.dart';
import 'package:stocklio_flutter/providers/data/pos_items.dart';
import 'package:stocklio_flutter/providers/data/recipes.dart';
import 'package:stocklio_flutter/providers/data/suppliers.dart';
import 'package:stocklio_flutter/providers/data/users.dart';
import 'package:stocklio_flutter/providers/ui/camera_settings.dart';
import 'package:stocklio_flutter/providers/ui/existing_count_ui_provider.dart';
import 'package:stocklio_flutter/providers/ui/home_navigation.dart';
import 'package:stocklio_flutter/providers/ui/recipe_ui_provider.dart';
import 'package:stocklio_flutter/providers/ui/report_items_expanded.dart';
import 'package:stocklio_flutter/providers/ui/search_button.dart';
import 'package:stocklio_flutter/providers/ui/toast_provider.dart';
import 'package:stocklio_flutter/screens/reports.dart';
import 'package:stocklio_flutter/services/admin_service.dart';
import 'package:stocklio_flutter/services/auth_service.dart';
import 'package:stocklio_flutter/services/item_service.dart';
import 'package:stocklio_flutter/services/organization_service.dart';
import 'package:stocklio_flutter/services/pos_item_service.dart';
import 'package:stocklio_flutter/services/profile_service.dart';
import 'package:stocklio_flutter/services/recipe_service.dart';
import 'package:stocklio_flutter/widgets/features/items/item_list_tile.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Providers
void main() {
  late FirebaseAuth firebaseAuth;
  late AuthService authService;
  late ProfileService profileService;
  late ItemService itemService;
  late RecipeService recipeService;
  late PosItemService posItemService;
  late AdminService adminService;

  setUp(() async {
    // A MockFirebaseAuth instance
    firebaseAuth = MockFirebaseAuth();
    // Mocks of admin service and organization service
    adminService = MockAdminService();
    final organizationService = MockOrganizationService();

    // An AuthService instance with a fake Firestore instance
    authService = AuthServiceImpl(
      firebaseAuth: firebaseAuth,
      adminService: adminService,
      organizationService: organizationService,
    );

    // Service mocks
    profileService = MockProfileService();
    itemService = MockItemService();
    recipeService = MockRecipeService();
    posItemService = MockPOSItemService();

    await authService.signInWithEmailAndPassword(
      email: 'demo4@stockl.io',
      password: r'$XQYBnhY9HUikibhX%bO@94!Ud@o7WvU32y5GK1B',
    );
  });

  testWidgets('ItemListTile has an item', (WidgetTester tester) async {
    // GIVEN
    // An Item instance with the following parameters
    final item = Item(
      name: 'Test Item',
      unit: 'ml',
      type: 'Cider',
      variety: 'Cider',
      size: 750,
      cost: 10,
    );

    // WHEN
    final widget = WidgetTesting(
      adminService: adminService,
      authService: authService,
      profileService: profileService,
      child: ItemListTile(item: item),
    );

    await tester.pumpWidget(widget);

    await tester.pumpAndSettle();

    // THEN
    expect(find.byWidget(widget), findsOneWidget);
  });

  testWidgets('ReportsPage is rendered', (WidgetTester tester) async {
    // GIVEN
    final widget = WidgetTesting(
      itemService: itemService,
      recipeService: recipeService,
      posItemService: posItemService,
      authService: authService,
      child: const SizedBox(width: 1000, child: ReportsPage()),
    );

    // WHEN
    await tester.pumpWidget(widget);

    await tester.pumpAndSettle();

    // THEN
    expect(find.byWidget(widget), findsOneWidget);
  });
}

// Use this when testing widgets
class WidgetTesting extends StatelessWidget {
  final AuthService? authService;
  final ItemService? itemService;
  final RecipeService? recipeService;
  final PosItemService? posItemService;
  final ProfileService? profileService;
  final AdminService? adminService;

  const WidgetTesting({
    Key? key,
    this.authService,
    this.itemService,
    this.adminService,
    this.recipeService,
    this.posItemService,
    this.profileService,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
      ],
      title: 'Flutter Testing',
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => AuthProvider(authService: authService),
          ),
          ChangeNotifierProvider(
            create: (context) => AdminProvider(
              adminService: adminService,
            ),
          ),
          ChangeNotifierProvider(
            create: (context) => ProfileProvider(
              profileService: profileService,
            ),
          ),
          ChangeNotifierProvider(
            create: (context) => ItemProvider(
              itemService: itemService,
            ),
          ),
          ChangeNotifierProvider(
            create: (context) => RecipeProvider(
              recipeService: recipeService,
              authService: authService,
            ),
          ),
          ChangeNotifierProvider(
            create: (context) => CountProvider(),
          ),
          ChangeNotifierProvider(
            create: (context) => CountAreaProvider(),
          ),
          ChangeNotifierProvider(
            create: (context) => CountItemProvider(),
          ),
          ChangeNotifierProvider(
            create: (context) => InvoiceProvider(),
          ),
          ChangeNotifierProvider(
            create: (context) => PosItemProvider(
              posItemService: posItemService,
            ),
          ),
          ChangeNotifierProvider(
            create: (context) => GlobalItemProvider(),
          ),
          ChangeNotifierProvider(
            create: (context) => NotificationProvider(),
          ),
          ChangeNotifierProvider(
            create: (context) => SupplierProvider(),
          ),
          ChangeNotifierProvider(
            create: (context) => HomeNavigationProvider(),
          ),
          ChangeNotifierProvider(
            create: (context) => SearchButtonProvider(),
          ),
          ChangeNotifierProvider(
            create: (context) => ExistingCountUIProvider(),
          ),
          ChangeNotifierProvider(
            create: (context) => CameraSettingsProvider(),
          ),
          ChangeNotifierProvider(
            create: (context) => InvoiceUIProvider(),
          ),
          ChangeNotifierProvider(
            create: (context) => RecipeUIProvider(),
          ),
          ChangeNotifierProvider(
            create: (context) => ReportItemExpandedProvider(),
          ),
          ChangeNotifierProvider(
            create: (context) => ToastProvider(),
          ),
        ],
        child: Scaffold(
          body: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [child],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
