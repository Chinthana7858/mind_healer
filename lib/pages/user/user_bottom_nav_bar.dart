import 'package:flutter/material.dart';
import 'package:mind_healer/const/colors.dart';
import 'package:mind_healer/pages/user/favourite_doctors.dart';
import 'package:mind_healer/pages/user/user_home_page.dart';
import 'package:mind_healer/pages/user/user_appointments.dart';

class UserBottomBar extends StatefulWidget {
  const UserBottomBar({super.key, required this.selectedIndex});

  final int selectedIndex;

  @override
  State<UserBottomBar> createState() => _UserBottomBarState();
}

class _UserBottomBarState extends State<UserBottomBar> {
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
        floatingActionButton: FloatingActionButton(
          shape: const CircleBorder(),
          onPressed: () => _onNavItemPressed(0),
          backgroundColor: primegreen,
          foregroundColor: Colors.white,
          elevation: 0,
          child: const Icon(Icons.home),
        ),
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
                  onPressed: () => _onNavItemPressed(1),
                  icon: const Icon(
                    Icons.people,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () => _onNavItemPressed(2),
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
        return  UserHomePage();
      case 1:
        return const FavoriteDoctors();
      case 2:
        return const UserAppointments();
      default:
        return Container();
    }
  }
}
