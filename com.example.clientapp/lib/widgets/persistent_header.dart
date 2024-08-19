import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/models/ThemeProvider.dart';

class PersistentHeader extends StatefulWidget implements PreferredSizeWidget {
  final String title;

  const PersistentHeader({Key? key, required this.title}) : super(key: key);

  @override
  _PersistentHeaderState createState() => _PersistentHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _PersistentHeaderState extends State<PersistentHeader> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final appBarTheme = theme.appBarTheme;

    return AppBar(
      backgroundColor: appBarTheme.backgroundColor,
      title: Text(widget.title, style: appBarTheme.titleTextStyle),
      actions: [
        IconButton(
          icon: const Icon(Icons.brightness_6),
          onPressed: () {
            setState(() {
              themeProvider.toggleTheme();
            });
          },
        ),
      ],
    );
  }
}
