import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class SelectImageResult {
  XFile? image;
  Uint8List bytes;

  SelectImageResult({this.image, required this.bytes});
}
