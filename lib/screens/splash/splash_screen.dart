import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/home_provider.dart';
import '../home/home_screen.dart';
import 'widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const minimumDuration = Duration(milliseconds: 1500);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _logoAlignment = Alignment(0, -0.11);

  @override
  void initState() {
    super.initState();
    _continueWhenReady();
  }

  Future<void> _continueWhenReady() async {
    final home = context.read<HomeProvider>();
    await Future.wait([
      Future<void>.delayed(SplashScreen.minimumDuration),
      _loaded(home),
    ]);
    if (!mounted) return;
    // TODO: once sign-in exists, open "Create account" when there is no
    // player instead of the home screen.
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, _) => const HomeScreen(),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Future<void> _loaded(HomeProvider home) {
    if (home.status != HomeStatus.loading) return Future.value();
    final done = Completer<void>();
    void listener() {
      if (home.status == HomeStatus.loading) return;
      home.removeListener(listener);
      done.complete();
    }

    home.addListener(listener);
    return done.future;
  }

  @override
  Widget build(BuildContext context) {
    return const AnnotatedRegion<SystemUiOverlayStyle>(
      // Dark status bar icons on the light beige.
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.splashBackground,
        body: Align(alignment: _logoAlignment, child: AppLogo()),
      ),
    );
  }
}
