import 'package:flutter/material.dart';
import 'package:newproject/const/colors.dart';
import 'package:newproject/pages/home_page.dart';
import 'package:newproject/pages/user_list_page.dart';

class BottomBar extends StatefulWidget {
  const BottomBar({super.key, required this.selectedIndex});

  final int selectedIndex;

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: _getPage(_selectedIndex),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        // floatingActionButton: FloatingActionButton(
        //   shape: const CircleBorder(),
        //   onPressed: () => _onNavItemPressed(1),
        //   backgroundColor: Colors.amber,
        //   foregroundColor: Colors.white,
        //   elevation: 0,
        //   child: const Icon(Icons.home),
        // ),
        bottomNavigationBar: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
          child: BottomAppBar(
            height: 70,
            shape: const CircularNotchedRectangle(),
            notchMargin: 5.0,
            color: primegreen,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              mainAxisSize: MainAxisSize.max,
              children: [
                IconButton(
                  onPressed: () => _onNavItemPressed(0),
                  icon: const Icon(
                    Icons.home,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () => _onNavItemPressed(1),
                  icon: const Icon(
                    Icons.event,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  void _onNavItemPressed(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return HomePage();
      case 1:
        return UserList();
      default:
        return Container();
    }
  }
}
