import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/achievements_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/error_boundary.dart';
import 'services/localization_service.dart';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up global error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    // Log error for debugging
    developer.log(
      'Flutter error',
      error: details.exception,
      stackTrace: details.stack,
      name: 'MyRamadhan',
    );

    // In production, you might want to send this to a crash reporting service
    FlutterError.presentError(details);
  };

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final LocalizationService _localizationService = LocalizationService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeLocalization();
  }

  Future<void> _initializeLocalization() async {
    await _localizationService.initialize();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return ErrorBoundary(
      child: ChangeNotifierProvider(
        create: (_) => AppState()..loadActiveSession(),
        child: MaterialApp(
          title: 'MyRamadhan',
          debugShowCheckedModeBanner: false,
          locale: Locale(_localizationService.currentLanguage),
          supportedLocales: const [
            Locale('id', ''), // Indonesian
            Locale('en', ''), // English
          ],
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF111827), // Dark background
            primaryColor: const Color(0xFF10B981), // Emerald
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF10B981), // Emerald
              secondary: Color(0xFFD97706), // Gold
              surface: Color(0xFF1F2937), // Dark gray
              background: Color(0xFF111827), // Darker gray
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1F2937),
              elevation: 0,
            ),
            useMaterial3: true,
          ),
          home: MainScreen(localizationService: _localizationService),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final LocalizationService localizationService;

  const MainScreen({super.key, required this.localizationService});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const StatsScreen(),
    const AchievementsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final localization = widget.localizationService;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MyRamadhan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          // Combine fade and slide transitions
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(0.1, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ));

          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1F2937),
        selectedItemColor: const Color(0xFF10B981), // Emerald
        unselectedItemColor: Colors.white38,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: localization.translate('navigation.home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart),
            label: localization.translate('navigation.stats'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.emoji_events),
            label: localization.translate('navigation.achievements'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: localization.translate('navigation.profile'),
          ),
        ],
      ),
    );
  }
}

// Placeholder screen for screens not yet implemented
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title Screen\n(Coming Soon)',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 18,
        ),
      ),
    );
  }
}
