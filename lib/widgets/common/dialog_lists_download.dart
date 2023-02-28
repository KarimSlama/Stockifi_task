import 'dart:math';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:stocklio_flutter/utils/file_util.dart';
import 'package:stocklio_flutter/utils/logger_util.dart';
import 'package:stocklio_flutter/utils/string_util.dart';
import 'package:stocklio_flutter/widgets/common/slide_button.dart';
import 'package:stocklio_flutter/widgets/shimmer/stocklio_shimmer.dart';

Future<void> downloadLists(
  BuildContext context,
  String title, {
  Excel? excel,
}) async {
  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    builder: (_) {
      final width = MediaQuery.of(context).size.width;
      return Dialog(
        child: SizedBox(
          height: 160,
          width: min(500, width),
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                onPressed: Navigator.of(context, rootNavigator: true).pop,
                icon: const Icon(Icons.close),
              ),
              centerTitle: false,
              title: Text(
                '${StringUtil.localize(context).label_file}: $title',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            body: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin:
                    const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
                height: 60,
                width: double.infinity,
                child: Center(
                  child: DownloadButton(
                    title: title,
                    excel: excel,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class DownloadButton extends StatefulWidget {
  const DownloadButton({
    Key? key,
    required this.title,
    this.excel,
  }) : super(key: key);

  final String title;
  final Excel? excel;

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  @override
  Widget build(BuildContext context) {
    return StockifiSlideButton(
      action: () {
        FileUtil.saveExcel(
          context,
          '${widget.title}.xlsx',
          widget.excel!,
          true,
        );
      },
    );
  }
}

class StockifiSlideButton extends StatefulWidget {
  final VoidCallback action;

  const StockifiSlideButton({super.key, required this.action});

  @override
  State<StockifiSlideButton> createState() => _StockifiSlideButtonState();
}

class _StockifiSlideButtonState extends State<StockifiSlideButton> {
  late String buttonLabel;
  double sliderValue = 0;
  bool labelIsCentered = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    setState(() {
      buttonLabel = StringUtil.localize(context).label_slide_to_download;
    });

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    num maxWidth = min(500, MediaQuery.of(context).size.width);

    return LayoutBuilder(builder: (context, constraints) {
      double percentage;
      if (maxWidth >= 500) {
        percentage = (175 / constraints.maxWidth) +
            (((constraints.maxWidth - 200) / 2) / constraints.maxWidth);
        logger.d(percentage);
      } else {
        percentage = (150 / constraints.maxWidth) +
            (((constraints.maxWidth - 170) / 2) / constraints.maxWidth);
      }

      return SlideButton(
        action: widget.action,
        height: 64,
        confirmPercentage: 1.0,
        slidingChild: Center(
          child: StocklioShimmer(
            period: const Duration(milliseconds: 2500),
            baseColor: Colors.white,
            highlightColor: Theme.of(context).colorScheme.primary,
            child: AnimatedAlign(
              alignment: labelIsCentered
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              duration: const Duration(milliseconds: 200),
              curve: Curves.fastOutSlowIn,
              child: RichText(
                softWrap: false,
                text: TextSpan(
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  children: [
                    if (!labelIsCentered)
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(Icons.chevron_right,
                            color: Colors.white, size: 30),
                      ),
                    WidgetSpan(
                      child: Text(
                        buttonLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      alignment: PlaceholderAlignment.middle,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        initialSliderPercentage: percentage,
        borderRadius: 0.0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        slidingBarColor: Theme.of(context).colorScheme.primary,
        onButtonOpened: () {
          setState(() {
            buttonLabel =
                StringUtil.localize(context).label_release_to_download;
            labelIsCentered = true;
          });
        },
        onButtonClosed: () {},
        onButtonSlide: (value) {
          if (labelIsCentered && value != 1.0) {
            setState(() {
              buttonLabel =
                  StringUtil.localize(context).label_slide_to_download;
              labelIsCentered = false;
            });
          }
        },
      );
    });
  }
}
