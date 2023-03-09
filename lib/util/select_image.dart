import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:customer/interfaces/select_image.dart';
import 'package:permission_handler/permission_handler.dart';

Future<SelectImageResult?> selectImage(ImagePicker _picker) async {
  if (await Permission.storage.request().isGranted) {
    XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      Uint8List bytes = await image.readAsBytes();
      return SelectImageResult(bytes: bytes, image: image);
    }
  }
  return null;
}
