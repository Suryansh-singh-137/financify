import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runanywhere/runanywhere.dart';
import 'package:runanywhere_llamacpp/runanywhere_llamacpp.dart';
import 'package:runanywhere_onnx/runanywhere_onnx.dart';

import 'services/model_service.dart';
import 'services/ai_cfo_service.dart';
import 'theme/app_theme.dart';
import 'views/dashboard_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the RunAnywhere SDK
  await RunAnywhere.initialize();

  // Register backends
  await LlamaCpp.register();
  await Onnx.register();

  // Register models
  ModelService.registerDefaultModels();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ModelService()),
        ChangeNotifierProvider(create: (_) => AICFOService()),
      ],
      child: const PocketCFOApp(),
    ),
  );
}

class PocketCFOApp extends StatelessWidget {
  const PocketCFOApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pocket CFO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme.copyWith(
        primaryColor: const Color(0xFF2563EB),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF2563EB),
          secondary: const Color(0xFF10B981),
          error: const Color(0xFFEF4444),
        ),
      ),
      home: const DashboardView(),
    );
  }
}
