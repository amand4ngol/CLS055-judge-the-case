import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'data/fake_game_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Fake data until the account screens exist: a player with two completed
  // cases and one in progress. FirestoreGameRepository() replaces it then.
  final repository = await FakeGameRepository.withHistory(
    latency: const Duration(milliseconds: 150),
  );

  runApp(JudgeApp(repository: repository));
}
