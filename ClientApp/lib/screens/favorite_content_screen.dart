import 'package:flutter/material.dart';
import '/widgets/content_carousel.dart';

typedef BackgroundImageCallback = Future<void> Function();

class FavoriteContentScreen extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> content;
  final Set<String> favoriteContent;
  final bool isAuthorContent;
  final bool isCategoryContent;
  final bool isCultureContent;
  final bool isAllFavoritesContent;
  final String? authorId;
  final String? categoryId;
  final String? cultureId;
  final String? selectedId;
  final BackgroundImageCallback onBackgroundImageChange;
  final ValueNotifier<bool> backgroundImageEnabled;

  const FavoriteContentScreen({Key? key,
    required this.title,
    required this.content,
    required this.favoriteContent,
    this.isAuthorContent = false,
    this.isCategoryContent = false,
    this.isCultureContent = false,
    this.isAllFavoritesContent = false,
    this.authorId,
    this.categoryId,
    this.cultureId,
    this.selectedId,
    required this.onBackgroundImageChange,
    required this.backgroundImageEnabled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ContentCarousel(
        content: content,
        favoriteContent: favoriteContent,
        source: 'favorites',
        isAuthorContent: isAuthorContent,
        isCategoryContent: isCategoryContent,
        isCultureContent: isCultureContent,
        authorId: authorId, // Add this line
        categoryId: categoryId, // Add this line
        cultureId: cultureId, // Add this line
        onBackgroundImageChange: onBackgroundImageChange,
        backgroundImageEnabled: backgroundImageEnabled,
      ),
    );
  }
}
