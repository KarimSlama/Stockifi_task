import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/providers/data/users.dart';

class CountCamera extends StatefulWidget {
  const CountCamera({Key? key}) : super(key: key);

  @override
  State<CountCamera> createState() => _CountCameraState();
}

class _CountCameraState extends State<CountCamera> {
  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>()..profile;

    if (profileProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return CameraWidget(
      isCameraEnabled: profileProvider.profile.isCameraEnabled,
    );
  }
}

class CameraWidget extends StatefulWidget {
  final bool isCameraEnabled;

  const CameraWidget({
    Key? key,
    this.isCameraEnabled = false,
  }) : super(key: key);

  @override
  State<CameraWidget> createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {
  List<CameraDescription> cameraDescription = [];
  CameraController? cameraController;

  @override
  void initState() {
    super.initState();

    if (widget.isCameraEnabled) getCameraDescription();
  }

  void getCameraDescription() async {
    final cameras = await availableCameras();

    cameraController = CameraController(
      cameras.first,
      ResolutionPreset.max,
      enableAudio: false,
    );
    await cameraController!.initialize();

    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return !widget.isCameraEnabled
        ? const SizedBox()
        : Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 80,
                height: 100,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: Colors.white,
                ),
                child: cameraController != null
                    ? cameraController?.value.isInitialized ?? false
                        ? CameraPreview(
                            cameraController!,
                          )
                        : Center(
                            child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                    : Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
              ),
            ),
          );
  }
}
