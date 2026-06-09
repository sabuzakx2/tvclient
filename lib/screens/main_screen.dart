import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'now_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String _profileUuid = '';
  String _profileName = 'pass';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileUuid = prefs.getString('profile_uuid') ?? '';
      _profileName = prefs.getString('profile_name') ?? 'pass';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(),
          NowScreen(profileUuid: _profileUuid),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF1A1A2E),
        indicatorColor: const Color(0xFF1565C0).withOpacity(0.3),
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list, color: Colors.grey),
            selectedIcon: Icon(Icons.list, color: Color(0xFF42A5F5)),
            label: '채널',
          ),
          NavigationDestination(
            icon: Icon(Icons.fiber_manual_record, color: Colors.grey),
            selectedIcon: Icon(Icons.fiber_manual_record, color: Colors.red),
            label: 'NOW',
          ),
        ],
      ),
    );
  }
}
