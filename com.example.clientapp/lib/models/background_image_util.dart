import 'dart:math';
import '/models/database_helper.dart';

class BackgroundImageUtil {
  static final _databaseHelper = DatabaseHelper.instance;

  static Future<Map<String, dynamic>?> getRandomBackgroundImage() async {
    final images = await _databaseHelper.queryAllBackgroundImages();
    if (images.isNotEmpty) {
      return images[Random().nextInt(images.length)];
    }
    return null;
  }

  static Future<String> initBackgroundImage() async {
    final backgroundImage = await getRandomBackgroundImage();
    if (backgroundImage != null) {
      return backgroundImage['back_img_remote_url'];
    }
    return '';
  }
}
