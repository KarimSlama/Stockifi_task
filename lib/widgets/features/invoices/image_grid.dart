// Flutter Packages
import 'package:flutter/material.dart';

// 3rd-Party Packages
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/utils/app_theme_util.dart';
import 'package:stocklio_flutter/utils/constants.dart';
import 'package:stocklio_flutter/widgets/common/responsive.dart';
import 'package:stocklio_flutter/widgets/shimmer/stocklio_shimmer.dart';
import 'package:stocklio_flutter/utils/string_util.dart';

// Models
import '../../../models/invoice.dart';

// Providers
import '../../../providers/data/invoices.dart';

// Widgets
import '../../../widgets/common/confirm.dart';
import '../../common/connectivity_indicator.dart';

class InvoiceImageGrid extends StatelessWidget {
  final Invoice invoice;

  const InvoiceImageGrid({
    Key? key,
    required this.invoice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final images = (invoice.files != null && invoice.files!.isNotEmpty)
        ? invoice.files!
        : [invoice.url!];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          width: 1,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: images.length > 1 ? 2 : 1,
        ),
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: images.length,
        itemBuilder: (context, index) => GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ImageGallery(
                  invoice: invoice,
                  initialImage: images[index],
                ),
              ),
            );
          },
          child: InvoiceSingleImage(
            imageUrl: invoice.thumbnails[images[index]] ?? images[index],
            imagesLength: images.length,
          ),
        ),
      ),
    );
  }
}

class InvoiceSingleImage extends StatelessWidget {
  const InvoiceSingleImage({
    Key? key,
    required this.imageUrl,
    required this.imagesLength,
  }) : super(key: key);
  final String imageUrl;
  final int imagesLength;

  @override
  Widget build(BuildContext context) {
    var stocklioShimmer = StocklioShimmer(
      baseColor: AppTheme.instance.shimmerBaseColor,
      highlightColor: AppTheme.instance.shimmerHighlightColor,
      child: Container(
        decoration: BoxDecoration(
            color: AppTheme.instance.shimmerBaseColor,
            borderRadius: BorderRadius.circular(8)),
        width: Constants.imageGridSize / (imagesLength > 1 ? 2 : 1),
        height: Constants.imageGridSize / (imagesLength > 1 ? 2 : 1),
      ),
    );

    if (imageUrl == 'loading') return stocklioShimmer;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
      ),
      clipBehavior: Clip.hardEdge,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (BuildContext context, Widget child,
            ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return stocklioShimmer;
        },
      ),
    );
  }
}

class ImageGallery extends StatefulWidget {
  final Invoice invoice;
  final String initialImage;

  const ImageGallery({
    Key? key,
    required this.invoice,
    required this.initialImage,
  }) : super(key: key);

  @override
  State<ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  int selectedImageIndex = 0;
  List<String> images = [];

  late PageController pageController;
  var isLoading = false;

  @override
  void initState() {
    final imageFiles = widget.invoice.files!;
    final imageUrl = widget.invoice.url!;
    images = (widget.invoice.files != null && widget.invoice.files!.isNotEmpty)
        ? [...imageFiles]
        : [imageUrl];

    ///TODO: check if error is at this point where the dialog does not exit
    selectedImageIndex =
        images.indexWhere((element) => element == widget.initialImage);
    pageController = PageController(
      initialPage: selectedImageIndex,
    );
    super.initState();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void onDeleteImage(BuildContext context, [String? imageUrl]) async {
    var isLastImage = false;
    var isConfirmed = true;
    final invoiceProvider = context.read<InvoiceProvider>();
    var navigator = Navigator.of(context);

    if (images.length <= 1) {
      isLastImage = true;
      isConfirmed = await confirm(context,
          Text('${StringUtil.localize(context).label_cancel_invoice}?'));
    } else {
      isConfirmed = await confirm(
        context,
        Text(
            '${StringUtil.localize(context).label_remove_image_from_invoice}?'),
      );
    }

    if (!isConfirmed) return;

    if (isLastImage) {
      setState(() {
        isLoading = true;
      });
      await invoiceProvider
          .softDeleteInvoice(widget.invoice.id!, imageUrl)
          .then((_) {
        setState(() {
          isLoading = false;
        });
        navigator.pop();
      });
    } else {
      await invoiceProvider.deleteInvoiceImage(widget.invoice.id!, imageUrl!);
      setState(() {
        final index = images.indexWhere((element) => element == imageUrl);
        final oldImagesLength = images.length;

        images = images..removeAt(index);

        if (index == oldImagesLength - 1) {
          pageController.previousPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.ease,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var imageLength = images.length;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.black,
        title: imageLength > 0
            ? Text(
                '${selectedImageIndex + 1}/${images.length}',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(fontSize: 16),
              )
            : Text(
                StringUtil.localize(context).label_text_no_image,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(fontSize: 16),
              ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,
            color: Colors.black,
          ),
          isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ConnectivityIndicator(),
                    Expanded(
                      child: PageView.builder(
                        scrollDirection: Axis.horizontal,
                        controller: pageController,
                        onPageChanged: (value) {
                          setState(() {
                            selectedImageIndex = value;
                          });
                        },
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              InteractiveViewer(
                                child: Image.network(
                                  images[index],
                                  frameBuilder: (_, child, loadingBuilder, __) {
                                    if (loadingBuilder == null) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }
                                    return child;
                                  },
                                  loadingBuilder: (BuildContext context,
                                      Widget child,
                                      ImageChunkEvent? loadingProgress) {
                                    return (loadingProgress == null)
                                        ? child
                                        : const Center(
                                            child: CircularProgressIndicator());
                                  },
                                ),
                              ),
                              Visibility(
                                visible: !Responsive.isMobile(context) &&
                                    images.length > 1 &&
                                    index >= 1,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: IconButton(
                                    onPressed: () {
                                      pageController.previousPage(
                                        duration:
                                            const Duration(milliseconds: 500),
                                        curve: Curves.ease,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.arrow_back_sharp,
                                    ),
                                  ),
                                ),
                              ),
                              Visibility(
                                visible: !Responsive.isMobile(context) &&
                                    images.length > 1 &&
                                    index >= 0 &&
                                    index < images.length - 1,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    onPressed: () {
                                      pageController.nextPage(
                                        duration:
                                            const Duration(milliseconds: 500),
                                        curve: Curves.ease,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.arrow_forward_sharp,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    Visibility(
                      visible: widget.invoice.state != 'resolved',
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: IconButton(
                          onPressed: () => onDeleteImage(
                              context, images[selectedImageIndex]),
                          icon: Icon(
                            Icons.delete,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
