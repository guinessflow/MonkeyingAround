import 'dart:ui';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
<<<<<<< Updated upstream
import 'package:path_provider/path_provider.dart';
=======
>>>>>>> Stashed changes
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
<<<<<<< Updated upstream
import 'package:package_info_plus/package_info_plus.dart';
=======
>>>>>>> Stashed changes
import 'package:share_plus/share_plus.dart';
import '/models/database_helper.dart';

class AuthorContentPage extends StatefulWidget {
  final String authorId;
  final String authorName;
  final String imagePath;
  final ValueNotifier<bool> backgroundImageEnabled;


  const AuthorContentPage({
    Key? key,
    required this.authorId,
    required this.authorName,
    required this.imagePath,
    required this.backgroundImageEnabled,
  }) : super(key: key);

  @override
  _AuthorContentPageState createState() => _AuthorContentPageState();

}

class _AuthorContentPageState extends State<AuthorContentPage> {
  late Future<List<Map<String, dynamic>>> _contentFuture;
  late DatabaseHelper _databaseHelper;
  Set<String> _favoriteContent = {};

  @override
  void initState() {
   _contentFuture =
        DatabaseHelper.instance.queryContentByAuthor(widget.authorId);
    _databaseHelper = DatabaseHelper.instance;
    _loadFavoriteContent();
  }

  Future<void> _loadFavoriteContent() async {
    final favoriteContent = await _databaseHelper.queryAllDeviceFavoriteContent();
    setState(() {
      _favoriteContent =
          favoriteContent.map((content) => content['id'] as String).toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.authorName),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _contentFuture,
        builder: (context, snapshot) {
          print('Snapshot data: ${snapshot.data}'); // Add this line
          print('Snapshot data length: ${snapshot.data?.length}'); // Add this line
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No content found for this author.'));
          }

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  widget.authorName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Raleway',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(

                    itemCount: snapshot.data!.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      childAspectRatio: 1.5,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      final content = snapshot.data![index];
                      GlobalKey contentWidgetKey = GlobalKey();

                      Widget contentWidget = Container(
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            RepaintBoundary(
                              key: contentWidgetKey,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Center(
                                    child: Text(
                                      content['quote'],
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      icon: Icon(_favoriteContent.contains(content['id'])
                                          ? Icons.favorite
                                          :
                                      Icons.favorite_border),
                                      onPressed: () async {
                                        if (_favoriteContent.contains(content['id'])) {
                                          print(
                                              'Removing content ${content['id']} from favorites');
                                          await _databaseHelper
                                              .removeFromDeviceFavorites(content['id']);
                                          setState(() {
                                            _favoriteContent.remove(content['id']);
                                          });
                                        } else {
                                          print(
                                              'Adding content ${content['id']} to favorites');
                                          await _databaseHelper.addToDeviceFavorites(
                                              content['id']);
                                          setState(() {
                                            _favoriteContent.add(content['id']);
                                          });
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.save_alt),
                                      onPressed: () async {
                                        await _saveAsImage(contentWidgetKey);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy),
                                      onPressed: () async {
                                        await _copyContent(content['quote']);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.share),
                                      onPressed: () {
                                        _shareContent(content['quote']);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                      return contentWidget;
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveAsImage(GlobalKey globalKey) async {
    PermissionStatus status;

    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

      if (androidInfo.version.sdkInt >= 33) {
        status = await Permission.storage.request();
        if (status.isGranted) {
          status = PermissionStatus.granted;
        } else {
          status = PermissionStatus.denied;
        }
      } else {
        status = await Permission.storage.request();
      }
    } else {
      status = await Permission.storage.request();
    }

    if (status.isGranted) {
      try {
        // Permission granted, perform the action
        // to save the image
        RenderRepaintBoundary? boundary =
        globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

        if (boundary == null) {
          print('Failed to find RenderRepaintBoundary');
          return;
        }

        ui.Image image = await boundary.toImage(pixelRatio: 3.0);

        // Convert image to bytes
        ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

        if (byteData == null) {
          print('Failed to convert image to ByteData');
          return;
        }

        Uint8List pngBytes = byteData.buffer.asUint8List();

        // Save the image using gal package
        await Gal.putImageBytes(pngBytes);

        print('Image saved using gal package');

      } catch (e) {
        print('Error saving image: $e');
      }
    } else if (status.isPermanentlyDenied) {
      // Show a dialog to inform the user and direct them to the app settings
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Permission Denied'),
            content: const Text(
                'The permission to access storage has been permanently denied. Please go to the app settings and grant the required permission.'),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Open Settings'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await openAppSettings();
                },
              ),
            ],
          );
        },
      );
    } else {
      // Show a snackbar to inform the user that permission was denied
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Permission denied. Please grant permission to save the image.'),
        ),
      );
    }
  }

  Future<void> _shareContent(String content) async {
    await Share.share(content);
  }

  Future<void> _copyContent(String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Content copied to clipboard.'),
      ),
    );
  }
}