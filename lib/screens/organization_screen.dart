import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/models/profile.dart';
import 'package:stocklio_flutter/providers/data/admin.dart';
import 'package:stocklio_flutter/providers/data/app_config.dart';
import 'package:stocklio_flutter/providers/data/organization.dart';
import 'package:stocklio_flutter/providers/data/subsidiaries.dart';
import 'package:stocklio_flutter/services/helper/stream_subscription_helper.dart';
import 'package:stocklio_flutter/utils/constants.dart';
import 'package:stocklio_flutter/utils/string_util.dart';
import 'package:stocklio_flutter/utils/url_launcher_util.dart';
import 'package:stocklio_flutter/widgets/common/responsive.dart';
import 'package:stocklio_flutter/widgets/common/search_text_field.dart';
import 'package:stocklio_flutter/widgets/common/version_text.dart';
import '../models/organization.dart';
import '../providers/data/auth.dart';

class OrganizationScreen extends StatefulWidget {
  final int index;
  const OrganizationScreen({Key? key, this.index = 0}) : super(key: key);

  @override
  State<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends State<OrganizationScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  final getIt = GetIt.instance;

  late final TabController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.index,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(OrganizationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.index = widget.index;
  }

  void _menuSelected(value) async {
    if (value == 'logout') {
      setState(() {
        _isLoading = true;
      });

      context.read<OrganizationProvider>().setSelectedSubsidiaryId(null);
      await context.read<AuthProvider>().signOut();

      final streamSubscriptionHelper = getIt.get<StreamSubscriptionHelper>();
      if (mounted) {
        streamSubscriptionHelper.cancelGroupStreamSubscription(context);
      }

      setState(() {
        _isLoading = false;
      });
      return;
    } else if (value == 'change-user') {
      context.goNamed('admin');
      context.read<AdminProvider>().setSelectedProfileId(null, false);
      context.read<OrganizationProvider>().setSelectedSubsidiaryId(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final organization = context.select<OrganizationProvider, Organization>(
        (value) => value.organization);
    final isLoadingOrg =
        context.select<OrganizationProvider, bool>((value) => value.isLoading);
    final appConfigProvider = context.watch<AppConfigProvider>()..appConfig;

    if (isLoadingOrg || appConfigProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final isAdmin =
        context.select<AuthProvider, bool>((value) => value.isAdmin);
    return Scaffold(
      appBar: AppBar(
        // FIXME: Back button on the AppBar is broken in admin login
        // Gesture, browser back button, and Change User button works
        automaticallyImplyLeading: false,
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
              '${organization.name}',
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
                  organization.name![0],
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
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Center(
                  child: SizedBox(
                    width:
                        isDesktop ? Constants.largeScreenSize.toDouble() : null,
                    child: const UsersList(),
                  ),
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
  String _query = '';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subsidiariesProvider = context.watch<SubsidiariesProvider>()
      ..profiles;

    if (subsidiariesProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final profiles = _query.isEmpty
        ? subsidiariesProvider.profiles
        : subsidiariesProvider.search(_query);

    final isListReversed = subsidiariesProvider.isListReversed;
    final isSortedByName = subsidiariesProvider.isSortedByName;
    final isSortedByCostPercentage =
        subsidiariesProvider.isSortedByCostPercentage;

    final sortIconArrow = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Icon(
        !isListReversed
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded,
        color: Theme.of(context).colorScheme.primary,
        size: 16,
      ),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SearchTextField(
            controller: _textController,
            onChanged: (value) {
              setState(() {
                _query = value;
              });
            },
            hintText: StringUtil.localize(context).hint_text_search_users,
            clearCallback: () {
              setState(() {
                _textController.clear();
                _query = _textController.text;
              });
            },
          ),
        ),
        Row(
          children: [
            Expanded(
              flex: 4,
              child: InkWell(
                onTap: () {
                  subsidiariesProvider.isSortedByName = true;
                  subsidiariesProvider.toggleIsListReversed();
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        StringUtil.localize(context).label_name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (isSortedByName) sortIconArrow,
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: InkWell(
                onTap: subsidiariesProvider.isSortByCostPercentageEnabled
                    ? () {
                        subsidiariesProvider.isSortedByCostPercentage = true;
                        subsidiariesProvider.toggleIsListReversed();
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        '${StringUtil.localize(context).label_total_cost} %',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (isSortedByCostPercentage) sortIconArrow,
                    ],
                  ),
                ),
              ),
            ),
            const Align(
              alignment: Alignment.centerRight,
              child: SizedBox(width: 48),
            ),
          ],
        ),
        Expanded(
          child: ListView.separated(
            separatorBuilder: (context, index) => const Divider(height: 2),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              return SubsidiaryListTile(profile: profile);
            },
          ),
        ),
      ],
    );
  }
}

class SubsidiaryListTile extends StatelessWidget {
  const SubsidiaryListTile({
    Key? key,
    required this.profile,
  }) : super(key: key);

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AuthProvider>().isAdmin;

    final countDate =
        context.read<SubsidiariesProvider>().getLatestCountDate(profile.id!);

    final costPercentage = context
        .read<SubsidiariesProvider>()
        .getLatestCountCostPercentage(profile.id!);

    final costPercentageText = costPercentage == null
        ? '-'
        : '${(costPercentage * 100).toStringAsFixed(2)}%';

    Uri uri;

    if (isAdmin) {
      uri = Uri(
        path: '/admin/org/subsidiary',
        queryParameters: {
          'selectedProfileId': profile.organizationId!,
          'subsidiaryId': profile.id!,
          'isOrg': 'true'
        },
      );
    } else {
      uri = Uri(
        path: '/org/subsidiary',
        queryParameters: {
          'selectedProfileId': profile.organizationId!,
          'subsidiaryId': profile.id!,
        },
      );
    }

    return Link(
      uri: uri,
      builder: (context, followLink) {
        return InkWell(
          onTap: () {
            context.go(uri.toString());
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    profile.name ?? '',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        costPercentageText,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        countDate ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.navigate_next_sharp,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
