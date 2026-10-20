import 'package:flutter/material.dart';

import 'app.dart';
import 'data/fake_game_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fake data until the Firestore repository exists: a player with two
  // completed cases and one in progress.
  final repository = await FakeGameRepository.withHistory(
    latency: const Duration(milliseconds: 150),
  );

  runApp(JudgeApp(repository: repository));
}
