// Core Flutter UI library providing widgets, themes, and material design components
import 'package:flutter/material.dart';

// The main game screen containing the game loop, physics, graphics, and HUD
import 'package:flappy_bird/home_page.dart';

/// The main application entry point where code execution begins.
void main() {
  // Ensures that Flutter's engine, hardware bindings, and services are fully initialized
  // before any widgets are built or native platform calls are made.
  WidgetsFlutterBinding.ensureInitialized();

  // Attaches the root widget (MyApp) to the screen and starts the Flutter framework.
  runApp(const MyApp());
}

/// The root widget of the application that configures global app-wide settings.
class MyApp extends StatelessWidget {
  // Constant constructor with optional key for widget tree identification
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp wraps the entire application and configures navigation, theme, and title.
    return MaterialApp(
      // The application name displayed in the operating system task manager / browser tab
      title: 'Flappy Bird',

      // Hides the debug banner from the top-right corner of the screen
      debugShowCheckedModeBanner: false,

      // Global visual theme settings
      theme: ThemeData(
        // Dark brightness for an immersive arcade cabinet look
        brightness: Brightness.dark,
        // Enables Google's latest Material Design 3 specifications
        useMaterial3: true,
      ),

      // The initial screen displayed when the app launches (our Flappy Bird game)
      home: const HomePage(),
    );
  }
}
