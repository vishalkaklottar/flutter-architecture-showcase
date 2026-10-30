import 'package:flutter/widgets.dart';

import 'app.dart';

abstract final class AppBootstrap {
  static Future<void> run() async {
    WidgetsFlutterBinding.ensureInitialized();

    runApp(const App());
  }
}
