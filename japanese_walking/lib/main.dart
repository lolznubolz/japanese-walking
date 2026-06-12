import 'package:flutter/material.dart';

import 'models/app_settings.dart';
import 'services/heart_rate_service.dart';
import 'theme.dart';
import 'ui/home_screen.dart';
import 'ui/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.load();
  runApp(JapaneseWalkingApp(settings: settings));
}

class JapaneseWalkingApp extends StatefulWidget {
  const JapaneseWalkingApp({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<JapaneseWalkingApp> createState() => _JapaneseWalkingAppState();
}

class _JapaneseWalkingAppState extends State<JapaneseWalkingApp> {
  final HeartRateService hr = HeartRateService();

  @override
  void dispose() {
    hr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (context, _) => MaterialApp(
        title: 'Japanese Walking',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: widget.settings.onboarded
            ? HomeScreen(settings: widget.settings, hr: hr)
            : OnboardingScreen(settings: widget.settings),
      ),
    );
  }
}
