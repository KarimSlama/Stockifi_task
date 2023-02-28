import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stocklio_flutter/models/count_area.dart';
import 'package:stocklio_flutter/models/currency.dart';
import 'package:stocklio_flutter/models/profile.dart';
import 'package:stocklio_flutter/providers/ui/language_settings_provider.dart';
import 'package:stocklio_flutter/utils/string_util.dart';
import 'package:stocklio_flutter/widgets/common/base_button.dart';
import 'package:stocklio_flutter/widgets/common/confirm.dart';
import 'package:stocklio_flutter/widgets/common/stocklio_scrollview.dart';
import '../providers/data/counts.dart';
import '../providers/data/count_areas.dart';
import '../providers/data/users.dart';
import 'package:provider/provider.dart';

const defaultPadding = 4.0;

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<Currency> currencyList = [];

  @override
  void initState() {
    super.initState();
    final profileProvider = context.read<ProfileProvider>()..profile;
    final currenciesList = profileProvider.currencies;

    for (var currency in currenciesList) {
      final symbol =
          currency.keys.isNotEmpty ? currency.keys.first.toString() : 'NOK';
      final currencyObject = Currency.fromJson(currency[symbol]);
      setState(() {
        currencyList.add(currencyObject);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<ProfileProvider>();
    final countAreaProvider = context.watch<CountAreaProvider>();

    final user = userProvider.profile;
    final countAreas = countAreaProvider.countAreas;

    if (userProvider.isLoading || countAreaProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (countAreas.isEmpty) {
      return Center(
        child: Text(StringUtil.localize(context).label_no_count_areas_found),
      );
    }

    return SettingsForm(
      user: user,
      countAreas: countAreas,
      currencies: currencyList,
    );
  }
}

class SettingsForm extends StatefulWidget {
  final Profile user;
  final List<CountArea> countAreas;
  final List<Currency> currencies;

  const SettingsForm({
    Key? key,
    required this.user,
    required this.countAreas,
    required this.currencies,
  }) : super(key: key);

  @override
  State<SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<SettingsForm> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.countAreas.isEmpty) {
      return Text(StringUtil.localize(context).label_no_count_areas_found);
    }

    return StocklioScrollView(
      controller: _scrollController,
      child: Column(
        children: [
          const SizedBox(height: defaultPadding),
          SettingsFormCountAreas(countAreas: widget.countAreas),
          const Divider(thickness: 2),
          SettingsFormContactMail(
            email: widget.user.email,
          ),
          const Divider(thickness: 2),
          SettingsFormNumberFormat(
            numberFormat: widget.user.numberFormat,
          ),
          const Divider(thickness: 2),
          SettingsCurrency(
            currencies: widget.currencies,
          ),
          const Divider(thickness: 2),
          if (widget.user.isLocalizationEnabled) const SettingsLanguage(),
          if (widget.user.isLocalizationEnabled) const Divider(thickness: 2),
          SettingsFormSortReport(
            sortReport: widget.user.sortReport,
          ),
          const Divider(thickness: 2),
          const IsTutorialsEnabledSwitch(),
          const IsSearchHighlightEnabledSwitch(),
        ],
      ),
    );
  }
}

class SettingsFormCountAreas extends StatefulWidget {
  final List<CountArea> countAreas;

  const SettingsFormCountAreas({Key? key, required this.countAreas})
      : super(key: key);

  @override
  State<SettingsFormCountAreas> createState() => _SettingsFormCountAreasState();
}

class _SettingsFormCountAreasState extends State<SettingsFormCountAreas> {
  Future<void> _showAreaDialog(CountArea? countArea, bool isInProgress) async {
    final controller = TextEditingController(text: countArea?.name ?? '');
    final countAreaProvider = context.read<CountAreaProvider>();

    void renameArea(CountArea countArea) {
      final name = controller.text.trim();
      if (name.isEmpty || name == countArea.name) return;

      if (widget.countAreas.any(
        (area) => area.name.toUpperCase() == name.toUpperCase(),
      )) {
        showToast(
            context, StringUtil.localize(context).message_area_name_invalid);
        return;
      }

      countAreaProvider.updateAreaName(countArea, name);
      Navigator.pop(context);

      showToast(context, StringUtil.localize(context).message_area_renamed);
    }

    void createArea() {
      final name = controller.text.trim();
      if (name.isEmpty) return;

      if (widget.countAreas.any(
        (area) => area.name.toUpperCase() == name.toUpperCase(),
      )) {
        showToast(
            context, StringUtil.localize(context).message_area_name_invalid);
        return;
      }

      countAreaProvider.createArea(name);
      Navigator.pop(context);
      showToast(context, StringUtil.localize(context).message_area_created);
    }

    void deleteArea(CountArea countArea) async {
      if (isInProgress) {
        showToast(
          context,
          StringUtil.localize(context).message_area_delete_under_review_invalid,
        );
        return;
      } else if (widget.countAreas.length > 1) {
        final isConfirmed = await confirm(
            context,
            Text(
                '${StringUtil.localize(context).alert_delete_area} ${countArea.name}?'));
        if (!isConfirmed) {
          return;
        }

        await countAreaProvider.updateAreaDeleted(countArea.id!);
        if (mounted) Navigator.pop(context);
        if (mounted) {
          showToast(context, StringUtil.localize(context).message_area_deleted);
        }
      } else if (widget.countAreas.length == 1) {
        showToast(
            context, StringUtil.localize(context).message_area_delete_invalid);
      }
    }

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: ListTile(
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            title: Text(countArea != null
                ? StringUtil.localize(context).label_rename_area
                : StringUtil.localize(context).label_create_area),
            subtitle: countArea != null ? Text(countArea.name) : null,
            trailing: countArea != null
                ? IconButton(
                    onPressed: () => deleteArea(countArea),
                    icon: const Icon(Icons.delete, color: Colors.red),
                  )
                : null,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: StringUtil.localize(context).label_name,
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: countArea != null
                  ? () => renameArea(countArea)
                  : () => createArea(),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: Text(
                countArea != null
                    ? StringUtil.localize(context).label_rename
                    : StringUtil.localize(context).label_create,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: Text(
                StringUtil.localize(context).label_cancel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final countProvider = context.watch<CountProvider>()..counts;

    if (countProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isInProgress = countProvider.findStartedOrPendingCount() != null;
    return Column(
      children: [
        Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(defaultPadding),
          child: Text(
              '${StringUtil.localize(context).label_active_counting_areas}:'),
        ),
        Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.only(
              left: defaultPadding, top: defaultPadding, right: defaultPadding),
          child: Column(
            children: [
              Wrap(
                spacing: 2,
                runSpacing: 2,
                children: [
                  for (var area in widget.countAreas)
                    SettingsAreaChip(
                      onTap: () => _showAreaDialog(area, isInProgress),
                      child: Text(
                        area.name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: defaultPadding),
                child: StockifiButton(
                  onPressed: () => _showAreaDialog(null, isInProgress),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        StringUtil.localize(context).label_add_new_area,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.add_rounded),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsAreaChip extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const SettingsAreaChip({
    Key? key,
    required this.onTap,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: LayoutBuilder(builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 0.66 * constraints.maxWidth),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(1)),
                color: Theme.of(context).colorScheme.primary,
              ),
              padding: const EdgeInsets.all(defaultPadding),
              child: child,
            ),
          );
        }),
      ),
    );
  }
}

class SettingsFormSortReport extends StatelessWidget {
  final String? sortReport;

  const SettingsFormSortReport({Key? key, this.sortReport}) : super(key: key);

  void _onChanged(BuildContext context, String? value) async {
    await context.read<ProfileProvider>().updateSortReport(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(defaultPadding),
          child: Text('${StringUtil.localize(context).label_sort_report_by}:'),
        ),
        SizedBox(
          height: 28,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Radio<String>(
                activeColor: Theme.of(context).colorScheme.primary,
                groupValue: sortReport,
                onChanged: (value) => _onChanged(context, value),
                value: 'type',
              ),
              const SizedBox(
                width: 2,
              ),
              Text(StringUtil.localize(context).label_type)
            ],
          ),
        ),
        SizedBox(
          height: 28,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Radio<String>(
                activeColor: Theme.of(context).colorScheme.primary,
                groupValue: sortReport,
                onChanged: (value) => _onChanged(context, value),
                value: 'variety',
              ),
              const SizedBox(
                width: 2,
              ),
              Text(StringUtil.localize(context).label_variety),
            ],
          ),
        ),
        SizedBox(
          height: 28,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Radio<String>(
                activeColor: Theme.of(context).colorScheme.primary,
                groupValue: sortReport,
                onChanged: (value) => _onChanged(context, value),
                value: 'area',
              ),
              const SizedBox(
                width: 2,
              ),
              Text(StringUtil.localize(context).label_area)
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsFormNumberFormat extends StatelessWidget {
  final String? numberFormat;

  const SettingsFormNumberFormat({Key? key, this.numberFormat})
      : super(key: key);

  void _onChanged(BuildContext context, String? value) async {
    await context.read<ProfileProvider>().updateNumberFormat(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(defaultPadding),
          child: Text('${StringUtil.localize(context).label_number_format}:'),
        ),
        SizedBox(
          height: 28,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Radio<String>(
                activeColor: Theme.of(context).colorScheme.primary,
                groupValue: numberFormat,
                onChanged: (value) => _onChanged(context, value),
                value: 'eu',
              ),
              const SizedBox(
                width: 2,
              ),
              const Text('1.234,00')
            ],
          ),
        ),
        SizedBox(
          height: 28,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Radio<String>(
                activeColor: Theme.of(context).colorScheme.primary,
                groupValue: numberFormat,
                onChanged: (value) => _onChanged(context, value),
                value: 'us',
              ),
              const SizedBox(
                width: 2,
              ),
              const Text('1,234.00')
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsCurrency extends StatefulWidget {
  final List<Currency> currencies;
  const SettingsCurrency({super.key, required this.currencies});

  @override
  State<SettingsCurrency> createState() => _SettingsCurrencyState();
}

class _SettingsCurrencyState extends State<SettingsCurrency> {
  String dropdownvalue = 'NOK';

  @override
  void initState() {
    super.initState();
    final profileProvider = context.read<ProfileProvider>()..profile;
    dropdownvalue = profileProvider.profile.currencyLong;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.all(defaultPadding),
      child: Row(
        children: [
          Text('${StringUtil.localize(context).label_currency}:'),
          const SizedBox(
            width: 8,
          ),
          DropdownButton(
              value: dropdownvalue,
              menuMaxHeight: 300,
              underline: const SizedBox.shrink(),
              items: widget.currencies
                  .map((currency) => currency.code!)
                  .toList()
                  .map((code) =>
                      DropdownMenuItem(value: code, child: Text(code)))
                  .toList(),
              onChanged: (String? value) {
                setState(() {
                  dropdownvalue = value!;
                });
                Currency selectedCurrency = widget.currencies
                    .firstWhere((currency) => currency.code == value);
                context.read<ProfileProvider>().updateCurrency(
                    selectedCurrency.code, selectedCurrency.symbol_native);
              }),
        ],
      ),
    );
  }
}

class SettingsLanguage extends StatelessWidget {
  const SettingsLanguage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageSettingsProvider = context.read<LanguageSettingsProvider>();
    final profileProvider = context.read<ProfileProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(defaultPadding),
          child: Text('${StringUtil.localize(context).label_language}:'),
        ),
        SizedBox(
          height: 28,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Radio<String>(
                activeColor: Theme.of(context).colorScheme.primary,
                groupValue: languageSettingsProvider.languagePreference ??
                    profileProvider.profile.language,
                onChanged: (value) async {
                  final isEnglishChosen = await confirm(
                      context,
                      Text(StringUtil.localize(context)
                          .label_language_preference),
                      content: StringUtil.localize(context)
                          .label_language_preference_en);
                  if (isEnglishChosen) {
                    await languageSettingsProvider.setPreferedLanguage(value!);
                  }
                },
                value: 'en',
              ),
              const SizedBox(
                width: 2,
              ),
              const Text('English')
            ],
          ),
        ),
        SizedBox(
          height: 28,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Radio<String>(
                activeColor: Theme.of(context).colorScheme.primary,
                groupValue: languageSettingsProvider.languagePreference ??
                    profileProvider.profile.language,
                onChanged: (value) async {
                  final isNorwegianChosen = await confirm(
                      context,
                      Text(StringUtil.localize(context)
                          .label_language_preference),
                      content: StringUtil.localize(context)
                          .label_language_preference_no);
                  if (isNorwegianChosen) {
                    await languageSettingsProvider.setPreferedLanguage(value!);
                  }
                },
                value: 'no',
              ),
              const SizedBox(
                width: 2,
              ),
              const Text('Norwegian')
            ],
          ),
        ),
      ],
    );
  }
}

// TODO: use a single chip (or some better widget?) with a dialog
// TODO: use email_validator package
class SettingsFormContactMail extends StatefulWidget {
  final String? email;

  const SettingsFormContactMail({Key? key, this.email}) : super(key: key);

  @override
  State<SettingsFormContactMail> createState() =>
      _SettingsFormContactMailState();
}

class _SettingsFormContactMailState extends State<SettingsFormContactMail> {
  final _controller = TextEditingController();

  @override
  void initState() {
    _controller.text = widget.email ?? '';
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(defaultPadding),
          child: Text('${StringUtil.localize(context).label_contact_mail}:'),
        ),
        TextField(
          controller: _controller,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(12),
            isDense: true,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            filled: true,
            fillColor: Colors.white,
            focusColor: Theme.of(context).colorScheme.primary,
          ),
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: defaultPadding),
        StockifiButton.async(
          onPressed: () async {
            final mailRegex = RegExp(r'^.+@.+\.\w{2,4}$');
            if (!mailRegex.hasMatch(_controller.text)) {
              showToast(context, 'Please enter a valid email.');
              return;
            }

            final result = await context
                .read<ProfileProvider>()
                .updateEmail(_controller.text);
            if (mounted) showToast(context, result);
          },
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child: Text(
            StringUtil.localize(context).label_save,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
      ],
    );
  }
}

class IsTutorialsEnabledSwitch extends StatelessWidget {
  const IsTutorialsEnabledSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final isTutorialsEnabled = context.select<ProfileProvider, bool>(
        (value) => value.profile.isTutorialsEnabled);

    return ListTile(
      title: Text(StringUtil.localize(context).label_show_app_tutorials),
      trailing: Switch(
        value: isTutorialsEnabled,
        activeColor: Theme.of(context).colorScheme.primary,
        onChanged: (value) {
          context.read<ProfileProvider>().updateIsTutorialsEnabled(value);
        },
      ),
    );
  }
}

class IsSearchHighlightEnabledSwitch extends StatelessWidget {
  const IsSearchHighlightEnabledSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final isSearchHighlightEnabled = context.select<ProfileProvider, bool>(
        (value) => value.profile.isSearchHighlightEnabled);

    return ListTile(
      title:
          Text(StringUtil.localize(context).label_enable_search_text_highlight),
      trailing: Switch(
        value: isSearchHighlightEnabled,
        activeColor: Theme.of(context).colorScheme.primary,
        onChanged: (value) {
          context.read<ProfileProvider>().updateIsSearchHighlighEnabled(value);
        },
      ),
    );
  }
}
