import 'package:flutter/material.dart';
import '../../../data/services/auth_service.dart';
import '../../translate/screens/translate_screen.dart';
import '../../dictionary/screens/dictionary_screen.dart';
import '../../progress/screens/progress_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  int currentIndex = 0;

  final List<Widget> screens = const [
    TranslateScreen(),
    DictionaryScreen(),
    ProgressScreen(),
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('SignSpeak'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              }
            },
          )
        ],
      ),

      body: screens[currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index){
          setState(() {
            currentIndex = index;
          });
        },
        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: "Traducir",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: "Diccionario",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: "Progreso",
          ),
        ],
      ),
    );
  }
}