import 'package:flutter/material.dart';

class SearchBar extends StatelessWidget {
  const SearchBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: "Search",
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              // clear the search input
            },
          ),
        ),
      ),
    );
  }
}
