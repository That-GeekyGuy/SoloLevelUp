import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/supabase/supabase_config.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (SupabaseConfig.isConfigured) {
    await SupabaseConfig.initialize();
  }
  runApp(const ProviderScope(child: SoloLevelUpApp()));
}

class SoloLevelUpApp extends ConsumerWidget {
  const SoloLevelUpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!SupabaseConfig.isConfigured) {
      return MaterialApp(
        theme: AppTheme.dark,
        debugShowCheckedModeBanner: false,
        home: const _MissingConfigScreen(),
      );
    }

    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'SoloLevelUp',
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}

/// Shown when SUPABASE_URL/SUPABASE_ANON_KEY weren't passed via
/// --dart-define (see core/supabase/supabase_config.dart) — this repo ships
/// with no project provisioned, so this is the expected first-run screen
/// until you point it at your own Supabase project.
class _MissingConfigScreen extends StatelessWidget {
  const _MissingConfigScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.settings_suggest,
                size: 48,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 16),
              Text(
                'Supabase isn\'t configured yet',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Run with --dart-define=SUPABASE_URL=... '
                '--dart-define=SUPABASE_ANON_KEY=... '
                'after applying supabase/migrations to your project.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
