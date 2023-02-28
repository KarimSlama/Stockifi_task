// Flutter Packages
import 'package:carousel_slider/carousel_slider.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/models/tutorial_media.dart';
import 'package:stocklio_flutter/providers/data/tutorials.dart';
import '../../../models/tutorial.dart';
import '../../common/connectivity_indicator.dart';

// ignore: depend_on_referenced_packages
import 'package:video_player/video_player.dart';

class TutorialGallery extends StatefulWidget {
  final Tutorial tutorial;

  const TutorialGallery({Key? key, required this.tutorial}) : super(key: key);

  @override
  State<TutorialGallery> createState() => _TutorialGalleryState();
}

class _TutorialGalleryState extends State<TutorialGallery> {
  int _current = 0;

  late PageController pageController;
  final CarouselController _controller = CarouselController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.tutorial.title ?? '',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ConnectivityIndicator(),
              const SizedBox(height: 16),
              CarouselSlider(
                options: CarouselOptions(
                  height:
                      kIsWeb ? MediaQuery.of(context).size.height - 180 : null,
                  enableInfiniteScroll: false,
                  aspectRatio: 16 / 9,
                  viewportFraction: 0.8,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _current = index;
                    });
                  },
                ),
                items: widget.tutorial.media?.map((path) {
                  return FutureBuilder<TutorialMedia?>(
                    future:
                        context.read<TutorialProvider>().getTutorialMedia(path),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final url = snapshot.data?.url ?? '';
                      final metadata = snapshot.data?.metadata;
                      final contextType = metadata?.contentType ?? '';

                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: InteractiveViewer(
                          child: contextType.toLowerCase().contains('video')
                              ? StockifiVideoPlayer(url: url)
                              : Image.network(
                                  url,
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
                      );
                    },
                  );
                }).toList(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [...widget.tutorial.media ?? []]
                    .asMap()
                    .entries
                    .map((entry) {
                  return GestureDetector(
                    onTap: () => _controller.animateToPage(entry.key),
                    child: Container(
                      width: 12.0,
                      height: 12.0,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 4.0),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black)
                              .withOpacity(_current == entry.key ? 0.9 : 0.4)),
                    ),
                  );
                }).toList(),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    widget.tutorial.description ?? '',
                    textAlign: TextAlign.left,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StockifiVideoPlayer extends StatefulWidget {
  final String url;

  const StockifiVideoPlayer({Key? key, required this.url}) : super(key: key);

  @override
  State<StockifiVideoPlayer> createState() => _StockifiVideoPlayerState();
}

class _StockifiVideoPlayerState extends State<StockifiVideoPlayer> {
  late final VideoPlayerController _videoPlayerController;
  late final ChewieController _chewieController;

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _videoPlayerController = VideoPlayerController.network(widget.url);
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoInitialize: true,
      errorBuilder: (context, errorMessage) {
        return Text(errorMessage);
      },
      looping: kIsWeb ? true : false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Chewie(
      controller: _chewieController,
    );
  }
}
