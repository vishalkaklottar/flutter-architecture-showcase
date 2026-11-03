import 'package:flutter/widgets.dart';

import '../core/di/injection.dart';
import 'app.dart';

abstract final class AppBootstrap {
  static Future<void> run() async {
    WidgetsFlutterBinding.ensureInitialized();

    await configureDependencies();

    runApp(const App());
  }
}
