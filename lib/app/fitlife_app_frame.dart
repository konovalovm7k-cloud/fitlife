import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'fitlife_theme.dart';

/// Production and compatibility entry points share one application setup.
class FitLifeAppFrame extends StatelessWidget {
  const FitLifeAppFrame({super.key, required this.home});
  final Widget home;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'FitLife',
    locale: const Locale('ru'),
    supportedLocales: const [Locale('ru')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: fitLifeTheme(),
    home: home,
  );
}
