import 'package:flutter/material.dart';

import '../auth/auth_session.dart';

import '../models/client.dart';
import '../models/service.dart';
import '../models/appointment.dart';

import 'home_screen.dart';
import 'calendar_screen.dart';
import 'clients_screen.dart';
import 'finances_screen.dart';
import 'more_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const Color tanzeemGreen = Color(0xFF0B5F4A);
  static const Color tanzeemBackground = Color(0xFFF7F9F8);
  static const Color tanzeemMuted = Color(0xFF7B8883);

  int selectedIndex = 0;

  final List<Client> clients = [];
  final List<Service> services = [];
  final List<Appointment> appointments = [];

  bool get isOwner => AuthSession.role == 'OWNER';

  void changeScreen(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        clients: clients,
        services: services,
        appointments: appointments,
        onSeeAllAppointments: () {
          changeScreen(1);
        },
      ),

      CalendarScreen(
        appointments: appointments,
        clients: clients,
        services: services,
      ),

      ClientsScreen(clients: clients),

      if (isOwner) const FinancesScreen(),

      MoreScreen(services: services),
    ];

    final List<BottomNavigationBarItem> navigationItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined, size: 23),
        activeIcon: Icon(Icons.home_rounded, size: 23),
        label: 'Home',
      ),

      const BottomNavigationBarItem(
        icon: Icon(Icons.calendar_today_outlined, size: 22),
        activeIcon: Icon(Icons.calendar_month_rounded, size: 23),
        label: 'Calendar',
      ),

      const BottomNavigationBarItem(
        icon: Icon(Icons.people_outline_rounded, size: 23),
        activeIcon: Icon(Icons.people_rounded, size: 23),
        label: 'Customers',
      ),

      if (isOwner)
        const BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet_outlined, size: 22),
          activeIcon: Icon(Icons.account_balance_wallet_rounded, size: 22),
          label: 'Finances',
        ),

      const BottomNavigationBarItem(
        icon: Icon(Icons.more_horiz_rounded, size: 24),
        activeIcon: Icon(Icons.menu_rounded, size: 23),
        label: 'More',
      ),
    ];

    return Scaffold(
      backgroundColor: tanzeemBackground,

      body: IndexedStack(index: selectedIndex, children: screens),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE8ECEA))),
        ),

        child: SafeArea(
          top: false,

          child: SizedBox(
            height: 68,

            child: BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: changeScreen,

              type: BottomNavigationBarType.fixed,

              backgroundColor: Colors.white,

              selectedItemColor: tanzeemGreen,
              unselectedItemColor: tanzeemMuted,

              selectedFontSize: 11,
              unselectedFontSize: 11,

              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),

              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
              ),

              elevation: 0,

              items: navigationItems,
            ),
          ),
        ),
      ),
    );
  }
}
