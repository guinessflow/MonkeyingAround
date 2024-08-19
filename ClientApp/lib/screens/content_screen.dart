import 'package:flutter/material.dart';

class QuoteScreen extends StatelessWidget {
  final String categoryName;

  const QuoteScreen({Key? key, required this.categoryName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: 10,
        itemBuilder: (ctx, i) => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.blue[100 * ((i + 2) % 9 + 1)], // Different color background
          ),
          child: Text(
            'Quote ${i + 1}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white, // White text
            ),
          ),
        ),
      ),
    );
  }
}
