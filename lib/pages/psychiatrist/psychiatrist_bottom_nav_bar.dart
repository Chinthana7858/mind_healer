import 'package:flutter/material.dart';
import 'package:newproject/const/colors.dart';
import 'package:newproject/pages/psychiatrist/psychiatrist_appointments.dart';
import 'package:newproject/pages/psychiatrist/psychiatrist_home_page.dart';

class PsyBottomBar extends StatefulWidget {
  const PsyBottomBar({super.key, required this.selectedIndex});

  final int selectedIndex;

  @override
  State<PsyBottomBar> createState() => _PsyBottomBarState();
}

class _PsyBottomBarState extends State<PsyBottomBar> {
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
                    Icons.class_,
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
        return const PsychiatristHomePage();
      case 1:
        return const PsychiatristAppointments();
      default:
        return Container();
    }
  }
}
