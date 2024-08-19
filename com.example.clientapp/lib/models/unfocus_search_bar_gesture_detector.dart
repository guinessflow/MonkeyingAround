import 'package:flutter/material.dart';

class UnfocusSearchBarGestureDetector extends StatelessWidget {
  final Widget child;
  final FocusNode searchBarFocusNode;

  const UnfocusSearchBarGestureDetector({Key? key, 
    required this.child,
    required this.searchBarFocusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        searchBarFocusNode.unfocus();
      },
      child: child,
    );
  }
}
