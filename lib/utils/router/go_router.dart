// Flutter Packages
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/models/task.dart';
import 'package:stocklio_flutter/models/report_item.dart';
import 'package:stocklio_flutter/providers/data/admin.dart';
import 'package:stocklio_flutter/providers/data/app_config.dart';
import 'package:stocklio_flutter/providers/data/auth.dart';
import 'package:stocklio_flutter/providers/data/counts.dart';
import 'package:stocklio_flutter/providers/data/file_upload.dart';
import 'package:stocklio_flutter/providers/data/items.dart';
import 'package:stocklio_flutter/providers/data/organization.dart';
import 'package:stocklio_flutter/providers/data/pos_items.dart';
import 'package:stocklio_flutter/providers/data/tasks.dart';
import 'package:stocklio_flutter/providers/data/users.dart';
import 'package:stocklio_flutter/providers/ui/language_settings_provider.dart';
import 'package:stocklio_flutter/providers/ui/recipe_list_ui_provider.dart';
import 'package:stocklio_flutter/providers/ui/wastage_ui_provider.dart';
import 'package:stocklio_flutter/screens/admin_screen.dart';
import 'package:stocklio_flutter/screens/dashboard.dart';

// 3rd-Party Packages
import 'package:stocklio_flutter/screens/home.dart';
import 'package:stocklio_flutter/screens/in_progress_new.dart';
import 'package:stocklio_flutter/screens/inventory.dart';
import 'package:stocklio_flutter/screens/invoices.dart';
import 'package:stocklio_flutter/screens/lists_page.dart';
import 'package:stocklio_flutter/screens/login.dart';
import 'package:stocklio_flutter/screens/organization_screen.dart';
import 'package:stocklio_flutter/screens/reports.dart';
import 'package:stocklio_flutter/screens/subsidiary_screen.dart';
import 'package:stocklio_flutter/utils/string_util.dart';
import 'package:stocklio_flutter/widgets/common/page.dart';
import 'package:stocklio_flutter/widgets/features/items/edit_item_dialog.dart';
import 'package:stocklio_flutter/widgets/features/pos_items/edit_pos_item_dialog.dart';

import '../../providers/ui/pos_item_ui.dart';
import '../../providers/ui/recipe_ui_provider.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
const listsKey = ValueKey('listsKey');
const recipeListsKey = ValueKey('recipeListsKey');

class RouterUtil {
  static List<String> userNavRailRoutes = [
    'dashboard',
    'current-count',
    'counts',
    'invoices',
    'lists',
    'reports',
    'inventory'
  ];
  static List<String> listsTabRoutes = [
    'items',
    'recipes',
    'posbuttons',
    'wastage',
  ];
  static List<String> recipeTypeRoutes = [
    'prebatch',
    'dish',
  ];

  static int getMainTabIndex(String mainTab) {
    return userNavRailRoutes.indexWhere(
        (element) => element == mainTab || mainTab.contains(element));
  }

  static int getListsTabIndex(String listsTab) {
    return listsTabRoutes.indexWhere(
        (element) => element == listsTab || listsTab.contains(element));
  }

  static int getRecipeTypeIndex(String recipeType) {
    return recipeTypeRoutes.indexWhere(
        (element) => element == recipeType || recipeType.contains(element));
  }
}

GoRouter getRouter(BuildContext context) {
  MaterialPage buildEditPOSItemDialog(
    BuildContext context,
    GoRouterState state,
  ) {
    final id = state.params['id'];
    final taskId = state.queryParams['taskId'];
    final posItemProvider = context.watch<PosItemProvider>()
      ..posItems
      ..getArchivedPosItems();

    Widget child;

    if (id != null) {
      final posItem = posItemProvider.findById(id);
      if (posItem == null) {
        child = Scaffold(
          body: Center(
              child: Text(
                  StringUtil.localize(context).label_pos_item_does_not_exist)),
        );
      } else {
        child = EditPOSItemDialog(
          posItem: posItem,
          taskId: taskId,
        );
      }
    } else {
      child = const Center(
        child: CircularProgressIndicator(),
      );
    }

    return MaterialPage(
      key: state.pageKey,
      fullscreenDialog: true,
      child: child,
    );
  }

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authProvider = context.read<AuthProvider>();

      final loggedIn = authProvider.user != null;
      final loggingIn = state.subloc == '/login';

      var fromp = state.subloc == '/' ? '' : '?from=${state.location}';

      if (authProvider.isInit) fromp = '';

      if (!loggedIn) return loggingIn ? null : '/login$fromp';

      if (loggingIn) return state.queryParams['from'] ?? '/';

      if (loggedIn) {
        final appConfigProvider = context.read<AppConfigProvider>()..appConfig;

        if (!appConfigProvider.isLoading) {
          if (appConfigProvider.newVersionAvailable) {
            return state.subloc == '/new-version' ? null : '/new-version';
          }
        }

        final isAdmin = authProvider.isAdmin;
        final isOrg = authProvider.isOrg;

        if (isOrg) {
          final subsidiaryId = state.queryParams['subsidiaryId'];
          if (subsidiaryId != null) {
            return (state.location ==
                    '/org/subsidiary?subsidiaryId=$subsidiaryId')
                ? null
                : '/org/subsidiary?subsidiaryId=$subsidiaryId';
          }
          return (state.location == '/org') ? null : '/org';
        }

        if (isAdmin) {
          final selectedProfileId = state.queryParams['selectedProfileId'];
          final isOrg = state.queryParams['isOrg'];

          if (selectedProfileId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context
                  .read<AdminProvider>()
                  .setSelectedProfileId(selectedProfileId);
            });
          }

          if (isOrg == 'true') {
            if (selectedProfileId != null) {
              final subsidiaryId = state.queryParams['subsidiaryId'];
              if (subsidiaryId != null) {
                return (state.location ==
                        '/admin/org/subsidiary?subsidiaryId=$subsidiaryId&selectedProfileId=$selectedProfileId&isOrg=true')
                    ? null
                    : '/admin/org/subsidiary?subsidiaryId=$subsidiaryId&selectedProfileId=$selectedProfileId&isOrg=true';
              }

              return (state.location ==
                      '/admin/org?selectedProfileId=$selectedProfileId&isOrg=true')
                  ? null
                  : '/admin/org?selectedProfileId=$selectedProfileId&isOrg=true';
            }
          }

          if (selectedProfileId != null) return null;

          return (state.fullpath != '/admin') ? null : '/admin';
        }
      }
      return null;
    },
    refreshListenable: Listenable.merge([
      GoRouterRefreshStream(context.read<AppConfigProvider>().newVersionStream),
      GoRouterRefreshStream(context.read<AuthProvider>().idTokenResultStream),
      context.watch<LanguageSettingsProvider>(),
    ]),
    errorPageBuilder: (context, state) => MaterialPage(
      child: Scaffold(
        body: Center(
          child: Text(state.error.toString()),
        ),
      ),
    ),
    routes: [
      GoRoute(
        name: 'new-version',
        path: '/new-version',
        pageBuilder: (context, state) {
          return MaterialPage(
            key: state.pageKey,
            child: const StockifiNewVersion(),
          );
        },
      ),
      GoRoute(
        name: 'login',
        path: '/login',
        pageBuilder: (context, state) {
          final isAuthLoading = context.read<AuthProvider>().isLoading;

          return MaterialPage(
            key: state.pageKey,
            child: isAuthLoading ? const SizedBox() : const LoginScreen(),
          );
        },
      ),
      GoRoute(
        name: 'root',
        path: '/',
        redirect: (context, state) {
          final isUploading = context.read<FileUploadProvider>().isUploading;
          if (isUploading) return null;

          final isAdmin = context.read<AuthProvider>().isAdmin;
          final isOrg = context.read<AuthProvider>().isOrg;

          if (isAdmin) return '/admin';
          if (isOrg) return '/org';

          return '/dashboard';
        },
      ),
      GoRoute(
        name: 'task',
        path: '/tasks/:taskId',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SizedBox(),
        ),
        routes: [
          GoRoute(
            path: 'edit-item/:itemId',
            redirect: (context, state) {
              final taskId = state.params['taskId'];
              final itemId = state.params['itemId'];

              final isAdmin = context.read<AuthProvider>().isAdmin;

              if (isAdmin) {
                return '/admin/lists/items/edit-item/$itemId?taskId=$taskId';
              }

              return '/lists/items/edit-item/$itemId?taskId=$taskId';
            },
          ),
          GoRoute(
            path: 'edit-pos-item/:itemId',
            redirect: (context, state) {
              final taskId = state.params['taskId'];
              final itemId = state.params['itemId'];

              final isAdmin = context.read<AuthProvider>().isAdmin;
              final profile = context.read<ProfileProvider>().profile;

              if (profile.isPosItemsAsMenuItemsEnabled) {
                if (isAdmin) {
                  return '/admin/lists/recipes/edit-pos-item/$itemId?taskId=$taskId';
                }

                return '/lists/recipes/edit-pos-item/$itemId?taskId=$taskId';
              }

              if (isAdmin) {
                return '/admin/lists/posbuttons/edit-pos-item/$itemId?taskId=$taskId';
              }

              return '/lists/posbuttons/edit-pos-item/$itemId?taskId=$taskId';
            },
          ),
        ],
      ),
      GoRoute(
        name: 'home',
        path: '/home/lists',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SizedBox(),
        ),
        routes: [
          GoRoute(
            path: 'edit-item/:itemId',
            redirect: (context, state) {
              final taskId = state.queryParams['taskId'];
              final itemId = state.params['itemId'];

              final isAdmin = context.read<AuthProvider>().isAdmin;
              final selectedProfileId = state.queryParams['selectedProfileId'];

              if (isAdmin) {
                return '/admin/lists/items/edit-item/$itemId?taskId=$taskId&selectedProfileId=$selectedProfileId';
              }

              return '/lists/items/edit-item/$itemId?taskId=$taskId';
            },
          ),
          GoRoute(
            path: 'edit-pos-item/:itemId',
            redirect: (context, state) {
              final taskId = state.queryParams['taskId'];
              final itemId = state.params['itemId'];

              final isAdmin = context.read<AuthProvider>().isAdmin;
              final selectedProfileId = state.queryParams['selectedProfileId'];
              final profile = context.read<ProfileProvider>().profile;

              if (profile.isPosItemsAsMenuItemsEnabled) {
                if (isAdmin) {
                  return '/admin/lists/recipes/edit-pos-item/$itemId?taskId=$taskId';
                }

                return '/lists/recipes/edit-pos-item/$itemId?taskId=$taskId';
              }

              if (isAdmin) {
                return '/admin/lists/posbuttons/edit-pos-item/$itemId?taskId=$taskId&selectedProfileId=$selectedProfileId';
              }

              return '/lists/posbuttons/edit-pos-item/$itemId?taskId=$taskId';
            },
          ),
        ],
      ),
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          var mainTabIndex = 0;
          if (state.fullpath != null) {
            final breadcrumbs = state.fullpath!.split('/')
              ..removeWhere((element) => element == '');

            mainTabIndex = RouterUtil.getMainTabIndex(breadcrumbs.first);
          }

          return HomeScreen(
            mainIndex: mainTabIndex,
            child: child,
          );
        },
        routes: <RouteBase>[
          GoRoute(
            name: 'dashboard',
            path: '/dashboard',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return NoTransitionPage<void>(
                key: state.pageKey,
                child: const Scaffold(body: DashboardPage()),
              );
            },
          ),
          GoRoute(
            name: 'current-count',
            path: '/current-count',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return NoTransitionPage<void>(
                key: state.pageKey,
                child: Scaffold(body: InProgressPage()),
              );
            },
            routes: [
              GoRoute(
                name: 'locate',
                path: 'locate/:itemName',
                pageBuilder: (BuildContext context, GoRouterState state) {
                  var itemName = state.params['itemName'];
                  return NoTransitionPage<void>(
                    key: state.pageKey,
                    child: Scaffold(
                        body: InProgressPage(
                      itemName: itemName,
                    )),
                  );
                },
              ),
              GoRoute(
                parentNavigatorKey: _rootNavigatorKey,
                name: 'count-report-preview',
                path: 'count-report-preview/:countId',
                redirect: (context, state) {
                  if (context
                      .read<ProfileProvider>()
                      .profile
                      .isCountReportPreviewEnabled) {
                    return null;
                  } else {
                    return '/current-count';
                  }
                },
                pageBuilder: (context, state) {
                  final countId = state.params['countId'];

                  return MaterialPage(
                    fullscreenDialog: true,
                    child: FutureBuilder<Map<String, List<ReportItem>>?>(
                      future: context
                          .read<CountProvider>()
                          .getCountReport(countId!),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return StocklioModal(
                            title: StringUtil.localize(context)
                                .label_preview_count_report,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 16),
                                  Text(StringUtil.localize(context)
                                      .label_generating_preview)
                                ],
                              ),
                            ),
                          );
                        }
                        final endDateTime = DateTime.now();
                        final reports = snapshot.data;

                        final count =
                            context.read<CountProvider>().findById(countId);

                        if (count == null || reports == null) {
                          return const SizedBox();
                        }

                        return StocklioModal(
                          title: StringUtil.localize(context)
                              .label_preview_count_report,
                          subtitle:
                              'Generated on ${DateFormat.Hms().format(endDateTime)}',
                          child: const SizedBox(),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            name: 'counts',
            path: '/counts',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return NoTransitionPage<void>(
                key: state.pageKey,
                child: const Scaffold(body: SizedBox()),
              );
            },
          ),
          GoRoute(
            name: 'invoices',
            path: '/invoices',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return NoTransitionPage<void>(
                key: state.pageKey,
                child: const Scaffold(body: InvoicesPage()),
              );
            },
          ),
          GoRoute(
            name: 'lists',
            path: '/lists',
            builder: (BuildContext context, GoRouterState state) =>
                const SizedBox(),
            redirect: (context, state) {
              return '/lists/items';
            },
          ),
          GoRoute(
            name: 'lists-tab',
            path: '/lists/:listsTab',
            redirect: (context, state) {
              final searchQuery = state.queryParams['search_query'] ?? '';
              final listsTab = state.params['listsTab'];
              final recipeType = state.queryParams['recipeType'];

              int listsIndex = 0;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (listsTab != null) {
                  listsIndex = RouterUtil.getListsTabIndex(listsTab);
                  switch (listsIndex) {
                    case 0:
                      context.read<ItemProvider>().queryString = searchQuery;
                      break;
                    case 1:
                      context.read<RecipeUIProvider>().queryString =
                          searchQuery;

                      if (recipeType != null) {
                        final recipeTypeIndex =
                            RouterUtil.getRecipeTypeIndex(recipeType);
                        context
                            .read<RecipeListUIProvider>()
                            .setRecipeListIndex(recipeTypeIndex);
                      }
                      break;
                    case 2:
                      context.read<POSItemUIProvider>().posItemsQueryString =
                          searchQuery;
                      break;
                    case 3:
                      context.read<WastageUIProvider>().queryString =
                          searchQuery;
                      break;
                    default:
                  }
                }
              });

              return null;
            },
            pageBuilder: (context, state) {
              final listsTab = state.params['listsTab'];
              final listsIndex =
                  RouterUtil.getListsTabIndex(listsTab ?? 'items');

              return NoTransitionPage(
                key: listsKey,
                child: ListsPage(listsTabIndex: listsIndex),
              );
            },
            routes: [
              GoRoute(
                path: ':recipeType',
                redirect: (context, state) {
                  final recipeType = state.params['recipeType'];
                  return '/lists/recipes?recipeType=$recipeType';
                },
              ),
              GoRoute(
                parentNavigatorKey: _rootNavigatorKey,
                name: 'edit-item',
                path: 'edit-item/:id',
                pageBuilder: (context, state) {
                  final id = state.params['id'];
                  final taskId = state.queryParams['taskId'];
                  final itemProvider = context.watch<ItemProvider>()
                    ..getItems();

                  Widget child;

                  if (id != null) {
                    final item = itemProvider.findById(id);
                    if (item == null) {
                      child = Scaffold(
                        body: Center(
                            child: Text(StringUtil.localize(context)
                                .label_item_does_not_exist)),
                      );
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (item?.cost != 0) {
                        context.read<TaskProvider>().softDeleteTask(
                          type: TaskType.zeroCostItem,
                          path: '/edit-item/${item?.id}',
                          data: {'itemId': item?.id},
                        );
                      }
                    });
                  }

                  child = EditItemDialog(
                    itemId: id,
                    taskId: taskId,
                  );

                  return MaterialPage(
                    key: state.pageKey,
                    fullscreenDialog: true,
                    child: child,
                  );
                },
              ),
              GoRoute(
                parentNavigatorKey: _rootNavigatorKey,
                name: 'edit-pos-item',
                path: 'edit-pos-item/:id',
                pageBuilder: buildEditPOSItemDialog,
              ),
            ],
          ),
          GoRoute(
            name: 'reports',
            path: '/reports',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return NoTransitionPage(
                key: state.pageKey,
                child: const Scaffold(
                  body: ReportsPage(),
                ),
              );
            },
          ),
          GoRoute(
            name: 'inventory',
            path: '/inventory',
            redirect: (context, state) {
              return (!context.read<ProfileProvider>().profile.inventoryScreen)
                  ? '/dashboard'
                  : null;
            },
            pageBuilder: (BuildContext context, GoRouterState state) {
              return NoTransitionPage(
                key: state.pageKey,
                child: const Scaffold(
                  body: InventoryPage(),
                ),
              );
            },
          ),
        ],
      ),
      GoRoute(
        name: 'admin',
        path: '/admin',
        pageBuilder: (context, state) {
          return MaterialPage(
            key: state.pageKey,
            child: const AdminScreen(),
          );
        },
        routes: [
          GoRoute(
            name: 'admin-home',
            path: 'home/lists',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const SizedBox(),
            ),
            routes: [
              GoRoute(
                path: 'edit-item/:itemId',
                redirect: (context, state) {
                  final taskId = state.queryParams['taskId'];
                  final itemId = state.params['itemId'];

                  final isAdmin = context.read<AuthProvider>().isAdmin;
                  final selectedProfileId =
                      state.queryParams['selectedProfileId'];

                  if (isAdmin) {
                    return '/admin/lists/items/edit-item/$itemId?taskId=$taskId&selectedProfile=$selectedProfileId';
                  }

                  return '/lists/items/edit-item/$itemId?taskId=$taskId';
                },
              ),
              GoRoute(
                path: 'edit-pos-item/:itemId',
                redirect: (context, state) {
                  final taskId = state.queryParams['taskId'];
                  final itemId = state.params['itemId'];

                  final isAdmin = context.read<AuthProvider>().isAdmin;
                  final selectedProfileId =
                      state.queryParams['selectedProfileId'];

                  final profile = context.read<ProfileProvider>().profile;

                  if (profile.isPosItemsAsMenuItemsEnabled) {
                    if (isAdmin) {
                      return '/admin/lists/recipes/edit-pos-item/$itemId?taskId=$taskId';
                    }

                    return '/lists/recipes/edit-pos-item/$itemId?taskId=$taskId';
                  }

                  if (isAdmin) {
                    return '/admin/lists/posbuttons/edit-pos-item/$itemId?taskId=$taskId&selectedProfile=$selectedProfileId';
                  }

                  return '/lists/posbuttons/edit-pos-item/$itemId?taskId=$taskId';
                },
              ),
            ],
          ),
          ShellRoute(
            builder: (BuildContext context, GoRouterState state, Widget child) {
              var mainTabIndex = 0;
              if (state.fullpath != null) {
                final breadcrumbs = state.fullpath!.split('/')
                  ..removeWhere((element) => element == '');

                mainTabIndex = RouterUtil.getMainTabIndex(breadcrumbs[1]);
              }

              return HomeScreen(
                mainIndex: mainTabIndex,
                child: child,
              );
            },
            routes: <RouteBase>[
              GoRoute(
                name: 'admin-dashboard',
                path: 'dashboard',
                pageBuilder: (BuildContext context, GoRouterState state) {
                  return NoTransitionPage<void>(
                    key: state.pageKey,
                    child: const Scaffold(body: DashboardPage()),
                  );
                },
              ),
              GoRoute(
                name: 'admin-current-count',
                path: 'current-count',
                pageBuilder: (BuildContext context, GoRouterState state) {
                  return NoTransitionPage(
                    key: state.pageKey,
                    child: Scaffold(
                      body: InProgressPage(),
                    ),
                  );
                },
                routes: [
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    name: 'admin-count-report-preview',
                    path: 'count-report-preview/:countId',
                    pageBuilder: (context, state) {
                      final countId = state.params['countId'];

                      return MaterialPage(
                        fullscreenDialog: true,
                        child: FutureBuilder<Map<String, List<ReportItem>>?>(
                          future: context
                              .read<CountProvider>()
                              .getCountReport(countId!),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return StocklioModal(
                                title: StringUtil.localize(context)
                                    .label_preview_count_report,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const CircularProgressIndicator(),
                                      const SizedBox(height: 16),
                                      Text(StringUtil.localize(context)
                                          .label_generating_preview)
                                    ],
                                  ),
                                ),
                              );
                            }
                            final endDateTime = DateTime.now();
                            final reports = snapshot.data;

                            final count =
                                context.read<CountProvider>().findById(countId);

                            if (count == null || reports == null) {
                              return const SizedBox();
                            }

                            return StocklioModal(
                              title: StringUtil.localize(context)
                                  .label_preview_count_report,
                              subtitle:
                                  'Generated on ${DateFormat.Hms().format(endDateTime)}',
                              child: const SizedBox(),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
              GoRoute(
                name: 'admin-counts',
                path: 'counts',
                pageBuilder: (BuildContext context, GoRouterState state) {
                  return NoTransitionPage(
                    key: state.pageKey,
                    child: const Scaffold(
                      body: SizedBox(),
                    ),
                  );
                },
              ),
              GoRoute(
                name: 'admin-invoices',
                path: 'invoices',
                pageBuilder: (BuildContext context, GoRouterState state) {
                  return NoTransitionPage(
                    key: state.pageKey,
                    child: const Scaffold(
                      body: InvoicesPage(),
                    ),
                  );
                },
              ),
              GoRoute(
                name: 'admin-lists',
                path: 'lists',
                builder: (BuildContext context, GoRouterState state) =>
                    const SizedBox(),
                redirect: (context, state) {
                  final selectedProfileId =
                      state.queryParams['selectedProfileId'];

                  return '/admin/lists/items?selectedProfileId=$selectedProfileId';
                },
              ),
              GoRoute(
                name: 'admin-lists-tab',
                path: 'lists/:listsTab',
                redirect: (context, state) {
                  final searchQuery = state.queryParams['search_query'] ?? '';
                  final listsTab = state.params['listsTab'];
                  final recipeType = state.queryParams['recipeType'];

                  int listsIndex = 0;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (listsTab != null) {
                      listsIndex = RouterUtil.getListsTabIndex(listsTab);
                      switch (listsIndex) {
                        case 0:
                          context.read<ItemProvider>().queryString =
                              searchQuery;
                          break;
                        case 1:
                          context.read<RecipeUIProvider>().queryString =
                              searchQuery;
                          if (recipeType != null) {
                            final recipeTypeIndex =
                                RouterUtil.getRecipeTypeIndex(recipeType);
                            context
                                .read<RecipeListUIProvider>()
                                .setRecipeListIndex(recipeTypeIndex);
                          }
                          break;
                        case 2:
                          context
                              .read<POSItemUIProvider>()
                              .posItemsQueryString = searchQuery;
                          break;
                        case 3:
                          context.read<WastageUIProvider>().queryString =
                              searchQuery;
                          break;
                        default:
                      }
                    }
                  });

                  return null;
                },
                pageBuilder: (context, state) {
                  final listsTab = state.params['listsTab'];
                  final listsIndex =
                      RouterUtil.getListsTabIndex(listsTab ?? 'items');

                  return NoTransitionPage(
                    key: listsKey,
                    child: ListsPage(listsTabIndex: listsIndex),
                  );
                },
                routes: [
                  GoRoute(
                    path: ':recipeType',
                    redirect: (context, state) {
                      final recipeType = state.params['recipeType'];
                      return '/lists/recipes?recipeType=$recipeType';
                    },
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    name: 'admin-edit-item',
                    path: 'edit-item/:id',
                    pageBuilder: (context, state) {
                      final id = state.params['id'];
                      final taskId = state.queryParams['taskId'];
                      final itemProvider = context.watch<ItemProvider>()
                        ..getItems();

                      Widget child;

                      if (id != null) {
                        final item = itemProvider.findById(id);
                        if (item == null) {
                          child = Scaffold(
                            body: Center(
                                child: Text(StringUtil.localize(context)
                                    .label_item_does_not_exist)),
                          );
                        }

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (item?.cost != 0) {
                            context.read<TaskProvider>().softDeleteTask(
                              type: TaskType.zeroCostItem,
                              path: '/edit-item/${item?.id}',
                              data: {'itemId': item?.id},
                            );
                          }
                        });
                      }

                      child = EditItemDialog(
                        itemId: id,
                        taskId: taskId,
                      );

                      return MaterialPage(
                        key: state.pageKey,
                        fullscreenDialog: true,
                        child: child,
                      );
                    },
                  ),
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    name: 'admin-edit-pos-item',
                    path: 'edit-pos-item/:id',
                    pageBuilder: buildEditPOSItemDialog,
                  ),
                ],
              ),
              GoRoute(
                name: 'admin-reports',
                path: 'reports',
                pageBuilder: (BuildContext context, GoRouterState state) {
                  return NoTransitionPage(
                    key: state.pageKey,
                    child: const Scaffold(
                      body: ReportsPage(),
                    ),
                  );
                },
              ),
              GoRoute(
                name: 'admin-inventory',
                path: 'inventory',
                redirect: (context, state) {
                  return (!context
                          .read<ProfileProvider>()
                          .profile
                          .inventoryScreen)
                      ? '/dashboard'
                      : null;
                },
                pageBuilder: (BuildContext context, GoRouterState state) {
                  return NoTransitionPage(
                    key: state.pageKey,
                    child: const Scaffold(
                      body: InventoryPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            name: 'admin-org',
            path: 'org',
            redirect: (context, state) {
              final selectedProfileId = state.queryParams['selectedProfileId'];
              final isOrg = state.queryParams['isOrg'] == 'true';

              context
                  .read<AdminProvider>()
                  .setSelectedProfileId(selectedProfileId, isOrg);
              context
                  .read<OrganizationProvider>()
                  .setSelectedSubsidiaryId(null);

              return null;
            },
            pageBuilder: (context, state) {
              return MaterialPage(
                key: state.pageKey,
                child: const OrganizationScreen(),
              );
            },
            routes: [
              GoRoute(
                name: 'admin-subsidiary',
                path: 'subsidiary',
                redirect: (context, state) {
                  final subsidiaryId = state.queryParams['subsidiaryId'];
                  final selectedProfileId =
                      state.queryParams['selectedProfileId'];

                  context
                      .read<AdminProvider>()
                      .setSelectedProfileId(selectedProfileId, true);
                  context
                      .read<OrganizationProvider>()
                      .setSelectedSubsidiaryId(subsidiaryId);
                  return null;
                },
                pageBuilder: (context, state) {
                  return MaterialPage(
                    key: state.pageKey,
                    child: const SubsidiaryScreen(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        name: 'org',
        path: '/org',
        redirect: (context, state) {
          final selectedSubsidiaryId =
              context.read<OrganizationProvider>().selectedSubsidiaryId;
          if (selectedSubsidiaryId != null) {
            context.read<OrganizationProvider>().setSelectedSubsidiaryId(null);
          }
          return null;
        },
        pageBuilder: (context, state) {
          return MaterialPage(
            key: state.pageKey,
            child: const OrganizationScreen(),
          );
        },
        routes: [
          GoRoute(
            name: 'subsidiary',
            path: 'subsidiary',
            redirect: (context, state) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final subsidiaryId = state.queryParams['subsidiaryId'];
                context
                    .read<OrganizationProvider>()
                    .setSelectedSubsidiaryId(subsidiaryId);
              });
              return null;
            },
            pageBuilder: (context, state) {
              return MaterialPage(
                key: state.pageKey,
                child: const SubsidiaryScreen(),
              );
            },
          ),
        ],
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
