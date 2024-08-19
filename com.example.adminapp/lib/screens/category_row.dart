import 'package:flutter/material.dart';

class CategoryRow extends DataRow {
  final String id;
  final String name;

  CategoryRow({required this.id, required this.name})
      : super(
    cells: [
      DataCell(Text(name)),
      DataCell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Edit function
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              // Delete function
            },
          ),
        ],
      )),
    ],
  );
}
