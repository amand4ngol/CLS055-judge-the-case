import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/game_repository.dart';
import 'providers/home_provider.dart';
import 'screens/splash/splash_screen.dart';

/// Root widget: registers the providers and the theme.
class JudgeApp extends StatelessWidget {
  const JudgeApp({super.key, required this.repository});

  final GameRepository repository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // The data source every provider reads from.
        Provider<GameRepository>.value(value: repository),
        ChangeNotifierProvider(
          create: (context) =>
              HomeProvider(context.read<GameRepository>())..load(),
        ),
      ],
      child: MaterialApp(
        title: 'Judge the Case',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashScreen(),
      ),
    );
  }
}
