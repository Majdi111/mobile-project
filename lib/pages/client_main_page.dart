import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'client_dashboard.dart';
import 'providers_map_page.dart';
import 'agenda_page.dart';
import 'account_page.dart';

class ClientMainPage extends StatefulWidget {
  const ClientMainPage({super.key});

  @override
  State<ClientMainPage> createState() => _ClientMainPageState();
}

class _ClientMainPageState extends State<ClientMainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const ClientDashboard(),
    const ProvidersMapPage(),
    const AgendaPage(),
    const AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 1,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: NavigationBarTheme(
                  data: NavigationBarThemeData(
                    backgroundColor: Colors.white.withValues(alpha: 0.95),
                    indicatorColor: Colors.purple[100],
                    indicatorShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                    labelTextStyle:
                        WidgetStateProperty.resolveWith<TextStyle>((states) {
                      final selected = states.contains(WidgetState.selected);
                      return TextStyle(
                        fontSize: selected ? 12 : 11,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? Colors.purple[600] : Colors.grey[500],
                      );
                    }),
                    iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
                        (states) {
                      final selected = states.contains(WidgetState.selected);
                      return IconThemeData(
                        size: 26,
                        color: selected ? Colors.purple[600] : Colors.grey[400],
                      );
                    }),
                  ),
                  child: NavigationBar(
                    height: 70,
                    selectedIndex: _currentIndex,
                    labelBehavior:
                        NavigationDestinationLabelBehavior.onlyShowSelected,
                    destinations: [
                      NavigationDestination(
                        icon: const Icon(Icons.home_outlined),
                        selectedIcon: const Icon(Icons.home_rounded),
                        label: 'Home',
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.location_on_outlined),
                        selectedIcon: const Icon(Icons.location_on_rounded),
                        label: 'GPS',
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.calendar_month_outlined),
                        selectedIcon: const Icon(Icons.calendar_month_rounded),
                        label: 'Agenda',
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.person_outline_rounded),
                        selectedIcon: const Icon(Icons.person_rounded),
                        label: 'Account',
                      ),
                    ],
                    onDestinationSelected: (index) {
                      if (index == _currentIndex) return;
                      HapticFeedback.selectionClick();
                      setState(() => _currentIndex = index);
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
