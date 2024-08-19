import 'package:flutter/material.dart';
import '/models/database_helper.dart';

class WelcomeContentWidget extends StatefulWidget {
  final ValueNotifier<Map<String, dynamic>> randomContentNotifier;
  final ValueNotifier<bool> showWelcomeContent;
  final VoidCallback onContentDismissed;

  const WelcomeContentWidget({Key? key, required this.randomContentNotifier, required this.showWelcomeContent, required this.onContentDismissed}) : super(key: key);

  @override
  _WelcomeContentWidgetState createState() => _WelcomeContentWidgetState();
}

class _WelcomeContentWidgetState extends State<WelcomeContentWidget> {
  final dbHelper = DatabaseHelper.instance; // Assuming you have an instance of your database helper
  final ValueNotifier<Map<String, dynamic>> _randomContentNotifier = ValueNotifier<Map<String, dynamic>>({});
  List<String> _favoriteContent = []; // Initialize an empty list

  @override
  void initState() {
    super.initState();
    updateFavoritesList();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.showWelcomeContent,
      builder: (BuildContext context, bool showWelcomeContent, Widget? child) {
        if (!showWelcomeContent) {
          return const SizedBox.shrink();
        }

        return ValueListenableBuilder<Map<String, dynamic>>(
          valueListenable: widget.randomContentNotifier,
          builder: (BuildContext context, Map<String, dynamic> randomContent, Widget? child) {
            if (randomContent.isNotEmpty) {
              return LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  String currentContentId = randomContent['id'];
                  bool showAuthor = randomContent['author'] != null && randomContent['author'].isNotEmpty;

                  return Dismissible(
                    key: Key(currentContentId),
                    onDismissed: (direction) {
                      widget.onContentDismissed();
                      widget.showWelcomeContent.value = false;
                    },
                    child: Container(
                      width: constraints.maxWidth,
                      padding: const EdgeInsets.fromLTRB(8, 0, 0, 8),
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.grey[200]
                            : Colors.grey[900],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Welcome Joke',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    fontFamily: 'OpenSans',
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: widget.onContentDismissed,
                                ),
                              ],
                            ),
                            Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 40), // Padding to accommodate the favorite icon
                                  child: Text(
                                    randomContent['quote'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.normal,
                                      fontFamily: 'Lato',
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: IconButton(
                                    key: Key(currentContentId),
                                    icon: Icon(
                                      _favoriteContent.contains(currentContentId)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: _favoriteContent.contains(currentContentId)
                                          ? Colors.red
                                          : Theme.of(context).iconTheme.color,
                                    ),
                                    onPressed: () async {
                                      if (_favoriteContent.contains(currentContentId)) {
                                       // print('Removing content $currentContentId from favorites');
                                        await dbHelper.removeFromDeviceFavorites(currentContentId);
                                       // Fluttertoast.showToast(msg: 'Content removed from favorites');
                                      } else {
                                      //  print('Adding content $currentContentId to favorites');
                                        await dbHelper.addToDeviceFavorites(currentContentId);
                                       // Fluttertoast.showToast(msg: 'Content added to favorites');
                                      }

                                      // Call the updateFavoritesList function to update _favoriteQuotes
                                      await updateFavoritesList();

                                      // Print the updated favorite content to the console
                                     // print('Updated favorite content: $_favoriteContent');
                                    },
                                  ),
                                ),
                              ],
                            ),
                            if (showAuthor)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  ' - ${randomContent['author']}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Lato',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        );
      },
    );
  }
  Future<void> updateFavoritesList() async {
    List<Map<String, dynamic>> favoriteContent = await dbHelper.queryAllDeviceFavoriteContent();
    setState(() {
      _favoriteContent = favoriteContent.map((content) => content['id'] as String).toList();
    });
  }
}