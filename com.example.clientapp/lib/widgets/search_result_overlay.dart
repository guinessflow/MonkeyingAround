import 'package:flutter/material.dart';

class SearchResultOverlay extends StatelessWidget {
  final List<dynamic> results;

  const SearchResultOverlay({Key? key, required this.results}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(results[index], style: const TextStyle(color: Colors.white)),
            onTap: () {
              // Add functionality for tapping search result
            },
          );
        },
      ),
    );
  }
}
