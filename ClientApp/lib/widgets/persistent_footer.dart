import 'package:flutter/material.dart';

class PersistentFooter extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onItemTapped;
  final Widget segmentMenu;

  const PersistentFooter({Key? key, 
    required this.selectedIndex,
    required this.onItemTapped,
    required this.segmentMenu,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor = isDarkTheme ? Colors.grey[850]! : Colors.grey.shade200;

    Color activeColor = Colors.green.shade600;
    Color iconColor = isDarkTheme ? Colors.grey.shade300 : Colors.grey.shade600;

    String getIconPath(int index) {
      switch (index) {
        case 0:
          return 'assets/icons/home.png';
        case 1:
          return 'assets/icons/proverbs.png';
        case 2:
          return 'assets/icons/favorite.png';
        case 3:
          return 'assets/icons/segment_menu.png';
        default:
          return 'assets/icons/home.png';
      }
    }

    Widget buildMenuItem(int index) {
      return InkWell(
        onTap: () {
          onItemTapped(index);
          if (index == 0 && Navigator.canPop(context)) {
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        },
        child: Container(
          width: MediaQuery.of(context).size.width / 4,
          height: 60.0,
          color: backgroundColor,
          child: Center(
            child: IconTheme(
              data: IconThemeData(
                color: selectedIndex == index ? activeColor : iconColor,
                size: 24,
              ),
              child: ImageIcon(
                AssetImage(getIconPath(index)),
              ),
            ),
          ),
        ),
      );
    }

    // sample ad widget
    Widget sampleAdWidget = const Card(
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Text(
          'This is a sample ad',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );

    return Stack(
      children: [
        Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: 60.0,
            child: Row(
              children: List.generate(4, (index) {
                if (index == 3) {
                  return InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return GestureDetector(
                            onTap: () {},
                            behavior: HitTestBehavior.opaque,
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height*0.7,
                              width: MediaQuery.of(context).size.width,
                              child: GestureDetector(
                                onTap: () {},
                                behavior: HitTestBehavior.opaque,
                                child: segmentMenu,
                              ),
                            ),
                          );
                        },
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                      );
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width / 4,
                      height: 60.0,
                      color: backgroundColor,
                      child: Center(
                        child: IconTheme(
                          data: IconThemeData(
                            color: iconColor,
                            size: 24,
                          ),
                          child: const ImageIcon(
                            AssetImage('assets/icons/segment_menu.png'),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return buildMenuItem(index);
              }),
            ),
          ),
        ),
      ],
    );
  }
}




