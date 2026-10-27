import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app/fitlife_app_frame.dart';
import 'modern_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      ['CoFID 2021'],
      '© Crown copyright 2021. Public Health England.\n'
      'Contains public sector information licensed under the Open Government Licence v3.0.\n'
      'https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/\n'
      'https://www.gov.uk/government/publications/composition-of-foods-integrated-dataset-cofid\n'
      'Curated subset; Russian display names added by FitLife.',
    );
  });
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
