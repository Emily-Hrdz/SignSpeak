import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/widgets/app_brand_logo.dart';
import '../../../core/widgets/gradient_background.dart';
import '../../../data/services/auth_service.dart';
import '../../settings/controllers/theme_controller.dart';
import '../../translate/screens/translate_screen.dart';
import '../../dictionary/screens/dictionary_screen.dart';
import '../widgets/app_tutorial_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  final List<Widget> screens = const [TranslateScreen(), DictionaryScreen()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _showFirstUseTutorial(),
    );
  }

  Future<void> _showFirstUseTutorial() async {
    final userId = AuthService().currentUser?.uid;
    if (userId == null) return;
    final preferences = await SharedPreferences.getInstance();
    final preferenceKey = 'tutorial_seen_$userId';
    if (preferences.getBool(preferenceKey) == true || !mounted) return;

    await _showTutorial();
    await preferences.setBool(preferenceKey, true);
  }

  Future<void> _showTutorial() async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AppTutorialDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            const AppBrandLogo(size: 42),
            const SizedBox(width: 10),
            const Text(
              'SignSpeak',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Ver tutorial',
            onPressed: _showTutorial,
            icon: const Icon(Icons.help_outline_rounded),
          ),
          Consumer<ThemeController>(
            builder: (context, themeController, _) => IconButton(
              tooltip: themeController.isDarkMode
                  ? 'Activar tema claro'
                  : 'Activar tema oscuro',
              onPressed: themeController.toggleTheme,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  themeController.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  key: ValueKey(themeController.isDarkMode),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),

      body: GradientBackground(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: KeyedSubtree(
            key: ValueKey(currentIndex),
            child: screens[currentIndex],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: GlassSurface(
          borderRadius: 24,
          child: NavigationBar(
            height: 68,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedIndex: currentIndex,
            onDestinationSelected: (index) =>
                setState(() => currentIndex = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.camera_alt_outlined),
                selectedIcon: Icon(Icons.camera_alt_rounded),
                label: 'Traducir',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book_rounded),
                label: 'Diccionario',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
