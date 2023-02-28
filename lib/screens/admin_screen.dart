import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/providers/data/admin.dart';
import 'package:stocklio_flutter/services/helper/stream_subscription_helper.dart';
import 'package:stocklio_flutter/utils/constants.dart';
import 'package:stocklio_flutter/utils/router/go_router.dart';
import 'package:stocklio_flutter/utils/string_util.dart';
import 'package:stocklio_flutter/utils/url_launcher_util.dart';
import 'package:stocklio_flutter/widgets/common/responsive.dart';
import 'package:stocklio_flutter/widgets/common/version_text.dart';
import 'package:stocklio_flutter/widgets/features/admin/admin_powers_switch.dart';

import '../providers/data/auth.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isLoading = false;
  final getIt = GetIt.instance;

  void _menuSelected(value) async {
    if (value == 'logout') {
      setState(() {
        _isLoading = true;
      });

      context.read<AdminProvider>().setSelectedProfileId(null);
      await context.read<AuthProvider>().signOut();

      final streamSubscriptionHelper = getIt.get<StreamSubscriptionHelper>();
      if (mounted) {
        streamSubscriptionHelper.cancelGroupStreamSubscription(context);
      }

      setState(() {
        _isLoading = false;
      });

      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: Constants.navRailWidth,
        leadingWidth: Constants.navRailWidth,
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
              StringUtil.localize(context).label_admin,
              style: const TextStyle(fontSize: 12.0),
            )
          ],
        ),
        actions: [
          Theme(
            data: Theme.of(context).copyWith(
              cardColor: Theme.of(context).colorScheme.background,
            ),
            child: PopupMenuButton(
              offset: const Offset(50, 50),
              icon: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  'A',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              iconSize: Constants.navRailIconSize,
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  padding: EdgeInsets.zero,
                  value: 'admin-powers-switch',
                  child: AdminPowersSwitch(),
                ),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout),
                      Container(
                        margin: const EdgeInsets.only(left: 8.0),
                        child: Text(StringUtil.localize(context).label_log_out),
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
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : const UsersList(),
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
      ),
    );
  }
}

class UsersList extends StatefulWidget {
  const UsersList({Key? key}) : super(key: key);

  @override
  State<UsersList> createState() => _UsersListState();
}

class _UsersListState extends State<UsersList> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  String _query = '';
  bool _isInit = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() async {
    if (_isInit) {
      _isLoading = true;
      await context.read<AdminProvider>().fetchAndSetProfiles();
    }

    setState(() {
      _isInit = false;
      _isLoading = false;
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final adminProvider = context.read<AdminProvider>()..profiles;
    final profiles = adminProvider.search(_query);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Center(
      child: SizedBox(
        width: isDesktop ? Constants.largeScreenSize.toDouble() : null,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextField(
                controller: _textController,
                onChanged: (value) {
                  setState(() {
                    _query = value;
                    _scrollController.jumpTo(0);
                  });
                },
                decoration: InputDecoration(
                  hintText: StringUtil.localize(context).hint_text_search_users,
                  suffixIcon: _textController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _textController.clear();
                              _query = _textController.text;
                            });
                          },
                        ),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                separatorBuilder: (_, __) => const Divider(thickness: 2),
                controller: _scrollController,
                itemCount: profiles.length,
                itemBuilder: (context, index) {
                  final profile = profiles[index];

                  Uri uri;

                  if (!profile.organization) {
                    uri = Uri(
                      path: '/admin/${RouterUtil.userNavRailRoutes[0]}',
                      queryParameters: {'selectedProfileId': profile.id!},
                    );
                  } else {
                    uri = Uri(
                      path: '/admin/org',
                      queryParameters: {
                        'selectedProfileId': profile.id!,
                        'isOrg': 'true',
                      },
                    );
                  }

                  final isOnline = profile.isOnline;
                  final hasActiveCount = profile.hasAnActiveCount ?? false;

                  final isActive = isOnline || hasActiveCount;

                  return Link(
                    uri: uri,
                    builder: (context, followLink) {
                      return ListTile(
                        title: Row(
                          children: [
                            if (isActive)
                              Icon(
                                Icons.circle,
                                color: isOnline ? Colors.green : Colors.orange,
                                size: 10,
                              ),
                            if (isActive) const SizedBox(width: 8),
                            Text(profile.name ?? ''),
                            if (profile.organization)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Chip(
                                  label: Text(StringUtil.localize(context)
                                      .label_organization),
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(profile.email ?? ''),
                        onTap: () {
                          context.go(uri.toString());
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
