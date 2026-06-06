import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'utils/app_theme.dart';
import 'screens/home_screen.dart';

// ═══════════════════════════════════════════════════════════════════
//  ENTRY POINT
// ═══════════════════════════════════════════════════════════════════
void main() async {
  // Ensure Flutter engine is ready before touching platform channels
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — all game layout is designed portrait-only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Immersive UI: hide status bar, keep navigation bar visible
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top],
  );

  // Translucent system bars so our vibrant background shows through
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(
    // ProviderScope is the Riverpod root — must wrap the entire widget tree.
    // All providers (gameStateProvider, currentLevelIndexProvider, etc.)
    // live inside this scope and are lazily initialised on first read.
    const ProviderScope(
      child: ScrewPuzzleApp(),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
//  ROOT APP WIDGET
// ═══════════════════════════════════════════════════════════════════
class ScrewPuzzleApp extends StatelessWidget {
  const ScrewPuzzleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Screw Puzzle',
      debugShowCheckedModeBanner: false,

      // ── Vibrant light theme (no dark mode) ──
      theme: AppTheme.theme,
      themeMode: ThemeMode.light, // always light — dark mode disabled by design

      // ── Initial route ──────────────────────
      home: const HomeScreen(),

      // ── Named routes (for future nav needs) ─
      // routes: {
      //   '/home': (_) => const HomeScreen(),
      //   '/game': (_) => const GameScreen(),
      // },

      // ── Global scroll physics ──────────────
      scrollBehavior: const _AppScrollBehavior(),

      // ── Builder: wrap every screen in MediaQuery override ──
      // Prevents font scaling from breaking puzzle layout
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling, // pin text scale to 1.0
          ),
          child: child!,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  CUSTOM SCROLL BEHAVIOR
//  Enables touch scrolling on all platforms
//  (important for web / desktop testing).
// ─────────────────────────────────────────────
class _AppScrollBehavior extends ScrollBehavior {
  const _AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) =>
      child; // no visible scrollbar on mobile
}
