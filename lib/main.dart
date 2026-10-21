import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app/fitlife_app_frame.dart';
import 'modern_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Manrope'], license);
  });
  runApp(const FitLifeRoot());
}

class FitLifeRoot extends StatelessWidget {
  const FitLifeRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return const FitLifeAppFrame(home: FitLifeHome());
  }
}
