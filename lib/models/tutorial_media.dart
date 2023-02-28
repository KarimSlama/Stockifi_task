import 'package:firebase_storage/firebase_storage.dart';

class TutorialMedia {
  final String url;
  FullMetadata? metadata;

  TutorialMedia({required this.url, this.metadata});
}
