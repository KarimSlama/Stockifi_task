import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/models/organization.dart';
import 'package:stocklio_flutter/providers/data/admin.dart';
import 'package:stocklio_flutter/providers/data/auth.dart';
import 'package:stocklio_flutter/providers/data/organization.dart';
import 'package:stocklio_flutter/providers/data/users.dart';
import 'package:stocklio_flutter/screens/reports.dart';
import 'package:stocklio_flutter/services/helper/stream_subscription_helper.dart';
import 'package:stocklio_flutter/utils/constants.dart';
import 'package:stocklio_flutter/widgets/common/responsive.dart';
import 'package:stocklio_flutter/utils/string_util.dart';

class SubsidiaryScreen extends StatefulWidget {
  // final String subsidiaryId;

  const SubsidiaryScreen({Key? key}) : super(key: key);

  @override
  State<SubsidiaryScreen> createState() => _SubsidiaryScreenState();
}

class _SubsidiaryScreenState extends State<SubsidiaryScreen> {
  bool _isLoading = false;
  final getIt = GetIt.instance; //FIXME: Let's not use GetIt in the UI Layer

  void _menuSelected(BuildContext context, value) async {
    if (value == 'logout') {
      setState(() {
        _isLoading = true;
      });

      context.read<AdminProvider>().setSelectedProfileId(null);
      context.read<OrganizationProvider>().setSelectedSubsidiaryId(null);
      await context.read<AuthProvider>().signOut();

      final streamSubscriptionHelper = getIt.get<StreamSubscriptionHelper>();
      if (mounted) {
        streamSubscriptionHelper.cancelGroupStreamSubscription(context);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final organization = context.select<OrganizationProvider, Organization>(
        (value) => value.organization);
    final isLoadingOrg =
        context.select<OrganizationProvider, bool>((value) => value.isLoading);

    return (_isLoading || isLoadingOrg)
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : WillPopScope(
            onWillPop: () async {
              GoRouter.of(context)
                  .go('/admin/org?selectedProfileId=${organization.id}');
              return false;
            },
            child: Scaffold(
              appBar: AppBar(
                toolbarHeight: Constants.navRailWidth,
                leadingWidth: Constants.navRailWidth,
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
                                child: Text(
                                    StringUtil.localize(context).label_log_out),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) => _menuSelected(context, value),
                    ),
                  ),
                ],
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
              ),
              body: Center(
                child: SizedBox(
                  width:
                      isDesktop ? Constants.largeScreenSize.toDouble() : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0, left: 16),
                        child:
                            Consumer<ProfileProvider>(builder: (_, value, __) {
                          final profile = value.profile;
                          if (value.isLoading) return const SizedBox();

                          return Text(
                            '${profile.name}',
                            style: const TextStyle(fontSize: 22),
                          );
                        }),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: ReportsPage(),
                      ),
                      const Divider(height: 2),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ),
              ),
            ),
          );
  }
}
