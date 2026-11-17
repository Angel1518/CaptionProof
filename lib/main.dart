import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/captions/ui/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: CaptionProofApp()));
}

class CaptionProofApp extends ConsumerWidget {
  const CaptionProofApp({super.key});

  static const Color accentIndigo = Color(0xFF4338CA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'CaptionProof',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(accent: accentIndigo),
      darkTheme: AppTheme.dark(accent: accentIndigo),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
