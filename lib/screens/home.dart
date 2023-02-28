import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:stocklio_flutter/main.dart';
import 'package:stocklio_flutter/providers/data/app_config.dart';
import 'package:stocklio_flutter/providers/data/auth.dart';
import 'package:stocklio_flutter/providers/data/counts.dart';
import 'package:stocklio_flutter/providers/ui/count_item_search_fab_ui_provider.dart';
import 'package:stocklio_flutter/providers/ui/home_navigation.dart';
import 'package:stocklio_flutter/providers/ui/user_center_provider.dart';
import 'package:stocklio_flutter/screens/user_center.dart';
import 'package:stocklio_flutter/services/helper/stream_subscription_helper.dart';
import 'package:stocklio_flutter/tools/update_finder/update_finder.dart';
import 'package:stocklio_flutter/utils/package_util.dart';
import 'package:stocklio_flutter/utils/router/go_router.dart';
import 'package:stocklio_flutter/utils/string_util.dart';
import 'package:stocklio_flutter/utils/url_launcher_util.dart';
import 'package:stocklio_flutter/widgets/common/connectivity_indicator.dart';
import 'package:stocklio_flutter/widgets/common/count_item_search_button.dart';
import 'package:stocklio_flutter/widgets/common/toasts.dart';
import 'package:stocklio_flutter/widgets/common/tutorial_button.dart';
import 'package:stocklio_flutter/widgets/common/version_text.dart';
import 'package:stocklio_flutter/widgets/features/admin/admin_powers_switch.dart';
import 'package:stocklio_flutter/widgets/home_screen/home_screen_titles.dart';
import 'package:stocklio_flutter/widgets/home_screen/selected_icon.dart';
import 'package:stocklio_flutter/widgets/home_screen/selected_label.dart';
import 'package:stocklio_flutter/widgets/shimmer/stocklio_shimmer.dart';
import '../providers/data/users.dart';
import '../screens/settings.dart';
import '../widgets/common/page.dart';
import '../widgets/common/responsive.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../utils/presence.dart';
import 'in_progress_new.dart';

class HomeScreen extends StatefulWidget {
  final int mainIndex;
  final int listsTabIndex;
  final Widget child;

  const HomeScreen({
    Key? key,
    this.mainIndex = 0,
    this.listsTabIndex = 0,
    required this.child,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  final getIt = GetIt.instance;

  void _menuSelected(value) async {
    if (value == 'logout') {
      setState(() {
        _isLoading = true;
      });

      final uid = context.read<AuthProvider>().user?.uid ?? '';

      await Presence().updateUserPresence(uid);
      if (mounted) {
        await context.read<AuthProvider>().signOut();
      }
      final streamSubscriptionHelper = getIt.get<StreamSubscriptionHelper>();
      if (mounted) {
        streamSubscriptionHelper.cancelGroupStreamSubscription(context);
      }

      setState(() {
        _isLoading = false;
      });

      return;
    } else if (value == 'settings') {
      await Navigator.push(
        context,
        InProgressRoute(
          builder: (context) {
            final isDesktop = Responsive.isDesktop(context);
            return StocklioModal(
              title: 'Settings',
              child: Center(
                child: Container(
                  alignment: Alignment.topCenter,
                  width: isDesktop
                      ? Constants.largeScreenSize - Constants.navRailWidth * 2
                      : null,
                  child: const SettingsPage(),
                ),
              ),
            );
          },
        ),
      );
    } else if (value == 'change-user') {
      context.goNamed('admin');
      // context.read<AdminProvider>().setSelectedProfileId(null);
      // context.read<OrganizationProvider>().setSelectedSubsidiaryId(null);
    }
  }

  void _insertOverlay(BuildContext context) {
    return Overlay.of(context).insert(
      OverlayEntry(builder: (context) {
        return const StocklioToast();
      }),
    );
  }

  @override
  void initState() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _insertOverlay(context));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isAdmin = authProvider.isAdmin;
    final isOrg = authProvider.isOrg;

    final appConfigProvider = context.watch<AppConfigProvider>()..appConfig;

    if (appConfigProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final buildNumber = PackageUtil.packageInfo.buildNumber;
    final isNewVersion =
        appConfigProvider.appConfig.version < (int.tryParse(buildNumber) ?? 0);

    if (isNewVersion) return const StocklioApp();

    final isDesktop = Responsive.isDesktop(context);
    final userProvider = context.watch<ProfileProvider>();
    final fabProvider = context.watch<CountItemSearchFabUIProvider>();
    final countProvider = context.watch<CountProvider>()..counts;

    final profile = userProvider.profile;

    if (userProvider.isLoading || countProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: () {
        context.read<UserCenterProvider>().hideUserCenter();
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: Constants.navRailWidth,
          leadingWidth: Constants.navRailWidth,
          leading: InkWell(
            onTap: () {
              context.read<HomeNavigationProvider>().toggleNavRail();
              context.read<UserCenterProvider>().hideUserCenter();
            },
            child: const Icon(Icons.menu, size: Constants.navRailIconSize),
          ),
          title: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    StringUtil.localize(context).label_stockifi,
                    style: const TextStyle(fontSize: 18.0),
                  ),
                ],
              ),
              Text(
                profile.name ?? '',
                style: const TextStyle(fontSize: 12.0),
              )
            ],
          ),
          actions: [
            const UserCenterButton(),
            Theme(
              data: Theme.of(context).copyWith(
                cardColor: Theme.of(context).colorScheme.background,
              ),
              child: PopupMenuButton(
                offset: const Offset(50, 50),
                icon: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    profile.name![0],
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                iconSize: Constants.navRailIconSize,
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'settings',
                    child: Row(
                      children: [
                        const Icon(Icons.settings),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              StringUtil.localize(context).label_settings,
                            ),
                          ),
                        ),
                        const TutorialButton(tutorialName: 'settings'),
                      ],
                    ),
                  ),
                  if (isAdmin)
                    const PopupMenuItem<String>(
                      padding: EdgeInsets.zero,
                      value: 'admin-powers-switch',
                      child: AdminPowersSwitch(),
                    ),
                  if (isAdmin)
                    PopupMenuItem<String>(
                      value: 'change-user',
                      child: Row(
                        children: [
                          const Icon(Icons.person_rounded),
                          Container(
                            margin: const EdgeInsets.only(left: 8.0),
                            child: Text(
                                StringUtil.localize(context).label_change_user),
                          ),
                        ],
                      ),
                    ),
                  if (!isAdmin && !isOrg)
                    PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          const Icon(Icons.logout),
                          Container(
                            margin: const EdgeInsets.only(left: 8.0),
                            child: Text(
                                StringUtil.localize(context).label_log_out),
                          ),
                        ],
                      ),
                    ),
                ],
                onSelected: _menuSelected,
              ),
            ),
          ],
          elevation: 0,
        ),
        body: (_isLoading)
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        const ConnectivityIndicator(),
                        if (UpdateFinder.isUpdateFound)
                          Container(
                            color: Theme.of(context).colorScheme.background,
                            margin: const EdgeInsets.only(
                                left: Constants.navRailWidth),
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    StringUtil.localize(context)
                                        .label_new_version_available,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                GestureDetector(
                                  onTap: () => UpdateFinder.instance?.install(),
                                  child: Stack(
                                      alignment: AlignmentDirectional.center,
                                      children: [
                                        StocklioShimmer(
                                          baseColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          highlightColor: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                            width: 80,
                                            height: 28,
                                          ),
                                        ),
                                        Text(StringUtil.localize(context)
                                            .label_refresh),
                                      ]),
                                ),
                              ],
                            ),
                          ),
                        Container(
                          alignment: Alignment.centerLeft,
                          margin: const EdgeInsets.only(
                              left: Constants.navRailWidth),
                          padding: const EdgeInsets.all(8),
                          child: SelectedTitle(
                            selectedIndex: widget.mainIndex,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            alignment: isDesktop ? Alignment.center : null,
                            margin: isDesktop
                                ? null
                                : const EdgeInsets.only(
                                    left: Constants.navRailWidth),
                            width: isDesktop
                                ? Constants.largeScreenSize -
                                    Constants.navRailWidth * 2
                                : null,
                            child: widget.child,
                          ),
                        ),
                      ],
                    ),
                    if (!isOrg)
                      Row(
                        children: [
                          // FIXME: linter suggests using const, but doing so makes NavigationRail not change selected icon
                          StocklioNavigationRail(activeIndex: widget.mainIndex),
                          Expanded(
                            child: context
                                    .watch<HomeNavigationProvider>()
                                    .isNavRailExtended
                                ? GestureDetector(onTap: () {
                                    context
                                        .read<HomeNavigationProvider>()
                                        .toggleNavRail();
                                  })
                                : const SizedBox(),
                          ),
                        ],
                      ),
                    const UserCenterPopup(),
                    // const StocklioToast(),
                  ],
                ),
              ),
        floatingActionButton: fabProvider.isSearchFabEnabled
            ? const CountItemSearchButton()
            : null,
      ),
    );
  }
}

class StockifiNewVersion extends StatelessWidget {
  const StockifiNewVersion({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Image(image: AssetImage('assets/images/logo.png')),
            const SizedBox(height: 8),
            Text(StringUtil.localize(context).label_new_version_available),
            const SizedBox(height: 8),
            Text(StringUtil.localize(context)
                .label_please_download_latest_version),
            const SizedBox(height: 32),
            if (defaultTargetPlatform == TargetPlatform.iOS)
              const StoreLink(
                url: Stores.appStore,
                assetName: 'assets/images/app_store.png',
              )
            else if (defaultTargetPlatform == TargetPlatform.android)
              const StoreLink(
                url: Stores.playStore,
                assetName: 'assets/images/play_store.png',
              )
          ],
        ),
      ),
    );
  }
}

class StoreLink extends StatelessWidget {
  final String url;
  final String assetName;

  const StoreLink({
    Key? key,
    required this.url,
    required this.assetName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width / 2;
    return GestureDetector(
      onTap: () async {
        await UrlLauncherUtil.launchUrlString(url);
      },
      child: Container(
        width: width,
        alignment: Alignment.center,
        child: Image(
          image: AssetImage(assetName),
        ),
      ),
    );
  }
}

enum NavType {
  user,
  org,
  admin,
}

class StocklioNavigationRail extends StatelessWidget {
  final int activeIndex;
  final NavType navType;
  const StocklioNavigationRail({
    Key? key,
    this.activeIndex = 0,
    this.navType = NavType.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final accessLevel = profileProvider.profile.accessLevel;
    final currentProfile = profileProvider.profile;

    final orgDestinations = [
      NavigationRailDestination(
        padding: EdgeInsets.zero,
        icon:
            const Icon(Icons.history_rounded, size: Constants.navRailIconSize),
        selectedIcon:
            SelectedIcon(context: context, icon: Icons.history_rounded),
        label: activeIndex == 2
            ? SelectedLabel(
                context: context,
                title: StringUtil.localize(context).nav_label_previous_counts)
            : Text(StringUtil.localize(context).nav_label_previous_counts),
      ),
      NavigationRailDestination(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.insert_chart_outlined_rounded,
            size: Constants.navRailIconSize),
        selectedIcon: SelectedIcon(
            context: context, icon: Icons.insert_chart_outlined_rounded),
        label: activeIndex == 5
            ? SelectedLabel(
                context: context,
                title: StringUtil.localize(context).nav_label_reports)
            : Text(StringUtil.localize(context).nav_label_reports),
      ),
    ];

    final userDestinations = [
      NavigationRailDestination(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.dashboard_rounded,
            size: Constants.navRailIconSize),
        selectedIcon:
            SelectedIcon(context: context, icon: Icons.dashboard_rounded),
        label: activeIndex == 0
            ? SelectedLabel(
                context: context,
                title: StringUtil.localize(context).nav_label_dashboard)
            : Text(StringUtil.localize(context).nav_label_dashboard),
      ),
      NavigationRailDestination(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.play_arrow_rounded,
            size: Constants.navRailIconSize),
        selectedIcon:
            SelectedIcon(context: context, icon: Icons.play_arrow_rounded),
        label: activeIndex == 1
            ? SelectedLabel(
                context: context,
                title: StringUtil.localize(context).nav_label_current_count)
            : Text(StringUtil.localize(context).nav_label_current_count),
      ),
      NavigationRailDestination(
        padding: EdgeInsets.zero,
        icon:
            const Icon(Icons.history_rounded, size: Constants.navRailIconSize),
        selectedIcon:
            SelectedIcon(context: context, icon: Icons.history_rounded),
        label: activeIndex == 2
            ? SelectedLabel(
                context: context,
                title: StringUtil.localize(context).nav_label_previous_counts)
            : Text(StringUtil.localize(context).nav_label_previous_counts),
      ),
      NavigationRailDestination(
        padding: EdgeInsets.zero,
        icon: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.request_quote_outlined,
              size: Constants.navRailIconSize,
            ),
            accessLevel < 2
                ? const Positioned(
                    top: -6,
                    right: -6,
                    child: Icon(
                      Icons.lock_rounded,
                      size: 14,
                      color: Colors.amberAccent,
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        ),
        selectedIcon: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            SelectedIcon(
              context: context,
              icon: Icons.request_quote_outlined,
            ),
            accessLevel < 2
                ? const Positioned(
                    top: 3,
                    right: 3,
                    child: Icon(
                      Icons.lock_rounded,
                      size: 14,
                      color: Colors.amberAccent,
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        ),
        label: activeIndex == 3
            ? SelectedLabel(
                context: context,
                title: StringUtil.localize(context).nav_label_invoices)
            : Text(StringUtil.localize(context).nav_label_invoices),
      ),
      NavigationRailDestination(
        padding: EdgeInsets.zero,
        icon:
            const Icon(Icons.list_alt_rounded, size: Constants.navRailIconSize),
        selectedIcon:
            SelectedIcon(context: context, icon: Icons.list_alt_rounded),
        label: activeIndex == 4
            ? SelectedLabel(
                context: context,
                title: StringUtil.localize(context).nav_label_lists)
            : Text(StringUtil.localize(context).nav_label_lists),
      ),
      NavigationRailDestination(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.insert_chart_outlined_rounded,
            size: Constants.navRailIconSize),
        selectedIcon: SelectedIcon(
            context: context, icon: Icons.insert_chart_outlined_rounded),
        label: activeIndex == 5
            ? SelectedLabel(
                context: context,
                title: StringUtil.localize(context).nav_label_reports)
            : Text(StringUtil.localize(context).nav_label_reports),
      ),
      if (currentProfile.inventoryScreen)
        NavigationRailDestination(
          padding: EdgeInsets.zero,
          icon: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.preview_rounded,
                size: Constants.navRailIconSize,
              ),
              accessLevel < 3
                  ? const Positioned(
                      top: -6,
                      right: -6,
                      child: Icon(
                        Icons.lock_rounded,
                        size: 14,
                        color: Colors.amberAccent,
                      ),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
          selectedIcon: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              SelectedIcon(
                context: context,
                icon: Icons.preview_rounded,
              ),
              accessLevel < 3
                  ? const Positioned(
                      top: 3,
                      right: 3,
                      child: Icon(
                        Icons.lock_rounded,
                        size: 14,
                        color: Colors.amberAccent,
                      ),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
          label: activeIndex == 6
              ? SelectedLabel(
                  context: context,
                  title: StringUtil.localize(context).nav_label_inventory)
              : Text(StringUtil.localize(context).nav_label_inventory),
        ),
    ];

    List<NavigationRailDestination> localDestinations = [];

    switch (navType) {
      case NavType.user:
        localDestinations = userDestinations;
        break;
      case NavType.org:
        localDestinations = orgDestinations;
        break;
      default:
    }

    return Stack(
      children: [
        NavigationRail(
          backgroundColor: Theme.of(context).colorScheme.background,
          extended: context.select<HomeNavigationProvider, bool>(
              (homeNavProvider) => homeNavProvider.isNavRailExtended),
          minWidth: Constants.navRailWidth,
          minExtendedWidth: Constants.navRailExtendedWidth,
          selectedLabelTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
          destinations: localDestinations,
          onDestinationSelected: (value) {
            final isAdmin = context.read<AuthProvider>().isAdmin;
            final profile = context.read<ProfileProvider>().profile;

            final tab = RouterUtil.userNavRailRoutes[value];
            if (isAdmin) {
              context.goNamed(
                'admin-$tab',
                queryParams: {'selectedProfileId': profile.id!},
              );
            } else {
              context.goNamed(tab);
            }
          },
          selectedIndex: activeIndex,
        ),
        Positioned(
          bottom: 0,
          child: SafeArea(
            child: SizedBox(
              width: Constants.navRailWidth,
              child: VersionText(),
            ),
          ),
        ),
      ],
    );
  }
}
