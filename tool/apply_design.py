from pathlib import Path

p = Path('lib/app/app.dart')
s = p.read_text(encoding='utf-8')

replacements = {
    "const bg = Color(0xFFF7F9FB);": "const bg = Color(0xFFF6F8F7);",
    "const blue = Color(0xFF3F6F9F);": "const blue = Color(0xFF167A55);",
    "const blueLight = Color(0xFFE8F0F7);": "const blueLight = Color(0xFFE7F4EE);",
    "const green = Color(0xFF5BAF78);": "const green = Color(0xFF16A36A);",
    "const orange = Color(0xFFF3A33B);": "const orange = Color(0xFFF59E3D);",
    "const pink = Color(0xFFD85A9B);": "const pink = Color(0xFFB85ACF);",
    "const muted = Color(0xFF7B858E);": "const muted = Color(0xFF68746F);",
}
for old, new in replacements.items():
    s = s.replace(old, new)

old_theme = '''      theme: ThemeData(\n        useMaterial3: true,\n        scaffoldBackgroundColor: bg,\n        colorScheme: ColorScheme.fromSeed(seedColor: blue),\n        inputDecorationTheme: const InputDecorationTheme(\n          border: OutlineInputBorder(),\n        ),\n      ),'''
new_theme = '''      theme: ThemeData(\n        useMaterial3: true,\n        scaffoldBackgroundColor: bg,\n        colorScheme: ColorScheme.fromSeed(\n          seedColor: green,\n          brightness: Brightness.light,\n        ),\n        visualDensity: VisualDensity.standard,\n        cardTheme: const CardThemeData(\n          color: Colors.white,\n          elevation: 0,\n          margin: EdgeInsets.zero,\n        ),\n        navigationBarTheme: NavigationBarThemeData(\n          backgroundColor: Colors.white,\n          indicatorColor: blueLight,\n          labelTextStyle: WidgetStatePropertyAll(\n            TextStyle(fontSize: 12, fontWeight: FontWeight.w600),\n          ),\n        ),\n        inputDecorationTheme: InputDecorationTheme(\n          filled: true,\n          fillColor: Colors.white,\n          border: OutlineInputBorder(\n            borderRadius: BorderRadius.circular(16),\n            borderSide: BorderSide.none,\n          ),\n          enabledBorder: OutlineInputBorder(\n            borderRadius: BorderRadius.circular(16),\n            borderSide: BorderSide(color: Color(0xFFE1E8E4)),\n          ),\n          focusedBorder: OutlineInputBorder(\n            borderRadius: BorderRadius.circular(16),\n            borderSide: BorderSide(color: green, width: 2),\n          ),\n        ),\n      ),'''
if old_theme not in s:
    raise SystemExit('Expected ThemeData block was not found')
s = s.replace(old_theme, new_theme)

# Give all custom cards a softer premium surface and slightly lighter shadow.
s = s.replace(
    "borderRadius: BorderRadius.circular(22),\n        boxShadow: const [\n          BoxShadow(\n            color: Color(0x10000000),\n            blurRadius: 10,\n            offset: Offset(0, 3),\n          ),\n        ],",
    "borderRadius: BorderRadius.circular(24),\n        border: Border.all(color: Color(0xFFE6ECE9)),\n        boxShadow: const [\n          BoxShadow(\n            color: Color(0x0D000000),\n            blurRadius: 18,\n            offset: Offset(0, 6),\n          ),\n        ],",
)

p.write_text(s, encoding='utf-8')
print('FitLife Modern Green design applied to lib/app/app.dart')
