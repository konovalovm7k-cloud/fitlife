import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const bg = Color(0xFF081018);
const card = Color(0xFF121C26);
const accent = Color(0xFF35E56B);

class Food {
  final String name;
  final int kcal;
  final double protein;
  final double fat;
  final double carbs;

  const Food(this.name, this.kcal, this.protein, this.fat, this.carbs);
}

const foods = <Food>[
  Food('Яйцо куриное', 143, 12.6, 9.5, 0.7),
  Food('Куриная грудка', 165, 31, 3.6, 0),
  Food('Индейка, филе', 135, 29, 1.6, 0),
  Food('Ветчина из индейки', 90, 17, 2, 1),
  Food('Овсянка', 370, 13, 6.5, 62),
  Food('Творог 5%', 121, 17.2, 5, 1.8),
  Food('Рис варёный', 130, 2.7, 0.3, 28.2),
  Food('Яблоко', 52, 0.3, 0.2, 13.8),
  Food('Банан', 89, 1.1, 0.3, 22.8),
  Food('Красный перец', 31, 1, 0.3, 6),
  Food('Айсберг', 14, 0.9, 0.1, 3),
  Food('Лосось', 208, 20.4, 13.4, 0),
];

void main() => runApp(const FitLife());

class FitLife extends StatelessWidget {
  const FitLife({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitLife',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.dark,
        ),
      ),
      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  bool loading = true;
  bool onboarding = true;
  double weight = 92.4;
  double startWeight = 92.4;
  double goalWeight = 85;
  int age = 35;
  int height = 178;
  String sex = 'Мужской';
  double activity = 1.45;
  int water = 0;
  int kcalGoal = 2000;
  int proteinGoal = 150;
  int fatGoal = 67;
  int carbsGoal = 200;
  String dayKey = '';
  List<Map<String, dynamic>> meals = [];
  List<Map<String, dynamic>> history = [];
  List<Map<String, dynamic>> customFoods = [];

  String get todayKey {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  int get kcal => meals.fold(0, (sum, x) => sum + ((x['kcal'] as num?)?.round() ?? 0));
  int get protein => meals.fold(0, (sum, x) => sum + ((x['p'] as num?)?.round() ?? 0));
  int get fat => meals.fold(0, (sum, x) => sum + ((x['f'] as num?)?.round() ?? 0));
  int get carbs => meals.fold(0, (sum, x) => sum + ((x['c'] as num?)?.round() ?? 0));

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<Map<String, dynamic>> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(raw));
    } catch (_) {
      return [];
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    onboarding = prefs.getBool('onboard') ?? true;
    weight = prefs.getDouble('weight') ?? weight;
    startWeight = prefs.getDouble('start') ?? weight;
    goalWeight = prefs.getDouble('goal') ?? goalWeight;
    age = prefs.getInt('age') ?? age;
    height = prefs.getInt('height') ?? height;
    sex = prefs.getString('sex') ?? sex;
    activity = prefs.getDouble('activity') ?? activity;
    water = prefs.getInt('water') ?? 0;
    history = _decode(prefs.getString('history'));
    customFoods = _decode(prefs.getString('custom'));
    dayKey = prefs.getString('dayKey') ?? todayKey;
    meals = dayKey == todayKey ? _decode(prefs.getString('meals')) : [];
    dayKey = todayKey;
    _calculateGoals();
    if (mounted) setState(() => loading = false);
    await _save();
  }

  void _calculateGoals() {
    final bmr = sex == 'Мужской'
        ? 10 * weight + 6.25 * height - 5 * age + 5
        : 10 * weight + 6.25 * height - 5 * age - 161;
    kcalGoal = math.max(1200, (bmr * activity - 450).round());
    proteinGoal = math.max(90, (weight * 1.6).round());
    fatGoal = math.max(35, (kcalGoal * 0.30 / 9).round());
    carbsGoal = math.max(80, ((kcalGoal - proteinGoal * 4 - fatGoal * 9) / 4).round());
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboard', onboarding);
    await prefs.setDouble('weight', weight);
    await prefs.setDouble('start', startWeight);
    await prefs.setDouble('goal', goalWeight);
    await prefs.setInt('age', age);
    await prefs.setInt('height', height);
    await prefs.setString('sex', sex);
    await prefs.setDouble('activity', activity);
    await prefs.setInt('water', water);
    await prefs.setString('dayKey', dayKey);
    await prefs.setString('meals', jsonEncode(meals));
    await prefs.setString('history', jsonEncode(history));
    await prefs.setString('custom', jsonEncode(customFoods));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (onboarding) return _onboarding();

    final pages = [_home(), _foodPage(), _weightPage(), _statsPage(), _profilePage()];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        backgroundColor: card,
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Главная'),
          NavigationDestination(icon: Icon(Icons.restaurant_outlined), selectedIcon: Icon(Icons.restaurant), label: 'Питание'),
          NavigationDestination(icon: Icon(Icons.monitor_weight_outlined), selectedIcon: Icon(Icons.monitor_weight), label: 'Вес'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Статистика'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }

  Widget _onboarding() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monitor_weight, size: 80, color: accent),
                const SizedBox(height: 16),
                const Text('FitLife', style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('Умный дневник похудения', style: TextStyle(fontSize: 20)),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final saved = await _profileDialog();
                      if (saved && mounted) {
                        setState(() => onboarding = false);
                        await _save();
                      }
                    },
                    child: const Padding(padding: EdgeInsets.all(14), child: Text('Начать')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(Widget child) => Card(color: card, child: Padding(padding: const EdgeInsets.all(16), child: child));

  Widget _home() {
    final denominator = startWeight - goalWeight;
    final progress = denominator.abs() < 0.01 ? 1.0 : ((startWeight - weight) / denominator).clamp(0.0, 1.0).toDouble();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Сегодня', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _card(Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${weight.toStringAsFixed(1)} кг'), Text('Цель ${goalWeight.toStringAsFixed(1)} кг')]),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: progress, minHeight: 8),
          const SizedBox(height: 8),
          Text('${(progress * 100).round()}% пути к цели'),
        ])),
        _nutrition(),
        Row(children: [
          Expanded(child: _quick('Вода', '$water / 2500 мл', Icons.water_drop, () { setState(() => water = math.min(3000, water + 250)); _save(); })),
          const SizedBox(width: 10),
          Expanded(child: _quick('Вес', 'Записать', Icons.monitor_weight, _addWeight)),
        ]),
        _card(ListTile(leading: const Icon(Icons.auto_awesome), title: const Text('Авторасчёт'), subtitle: Text('$kcalGoal ккал • Б $proteinGoal г • Ж $fatGoal г • У $carbsGoal г'))),
      ],
    );
  }

  Widget _nutrition() {
    final calorieProgress = (kcal / math.max(1, kcalGoal)).clamp(0.0, 1.0).toDouble();
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Калории'),
      Text('$kcal / $kcalGoal ккал', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      LinearProgressIndicator(value: calorieProgress, minHeight: 8),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Б $protein/$proteinGoal г'), Text('Ж $fat/$fatGoal г'), Text('У $carbs/$carbsGoal г')]),
    ]));
  }

  Widget _quick(String title, String value, IconData icon, VoidCallback onTap) {
    return Card(color: card, child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [Icon(icon), Text(title), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]))));
  }

  Widget _foodPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Питание', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        _nutrition(),
        ...meals.asMap().entries.map((entry) => _card(ListTile(title: Text('${entry.value['name']}'), subtitle: Text('${entry.value['grams']} г'), trailing: Text('${entry.value['kcal']} ккал'), onLongPress: () { setState(() => meals.removeAt(entry.key)); _save(); })) ),
        FilledButton.icon(onPressed: _addFoodDialog, icon: const Icon(Icons.add), label: const Text('Добавить продукт')),
      ],
    );
  }

  Future<void> _addFoodDialog() async {
    final search = TextEditingController();
    final grams = TextEditingController(text: '100');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final all = [
            ...foods,
            ...customFoods.map((x) => Food(x['name'], (x['kcal'] as num).round(), (x['p'] as num).toDouble(), (x['f'] as num).toDouble(), (x['c'] as num).toDouble())),
          ];
          final query = search.text.toLowerCase();
          final shown = all.where((food) => food.name.toLowerCase().contains(query)).toList();
          return AlertDialog(
            title: const Text('Добавить продукт'),
            content: SizedBox(
              width: 420,
              height: 430,
              child: Column(children: [
                TextField(controller: search, onChanged: (_) => setDialogState(() {}), decoration: const InputDecoration(labelText: 'Поиск')),
                TextField(controller: grams, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Граммы')),
                const SizedBox(height: 8),
                Expanded(child: ListView(children: shown.map((food) => ListTile(title: Text(food.name), subtitle: Text('${food.kcal} ккал / 100 г'), onTap: () { final g = double.tryParse(grams.text.replaceAll(',', '.')) ?? 100; final q = g / 100; setState(() { meals.add({'name': food.name, 'grams': g.round(), 'kcal': (food.kcal * q).round(), 'p': (food.protein * q).round(), 'f': (food.fat * q).round(), 'c': (food.carbs * q).round()}); }); Navigator.pop(dialogContext); _save(); })).toList())),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _weightPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Вес', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)), IconButton(onPressed: _addWeight, icon: const Icon(Icons.add_circle))]),
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${weight.toStringAsFixed(1)} кг', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)), Text('Цель ${goalWeight.toStringAsFixed(1)} кг'), const SizedBox(height: 16), SizedBox(height: 220, child: history.length < 2 ? const Center(child: Text('Добавьте минимум 2 измерения')) : CustomPaint(painter: WeightPainter(history.map((x) => (x['weight'] as num).toDouble()).toList()))) ])),
        ...history.reversed.map((x) => ListTile(title: Text('${x['weight']} кг'), trailing: Text('${x['date']}'))),
      ],
    );
  }

  Future<void> _addWeight() async {
    final controller = TextEditingController(text: weight.toStringAsFixed(1));
    final value = await showDialog<double>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Записать вес'), content: TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'кг')), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Отмена')), FilledButton(onPressed: () => Navigator.pop(dialogContext, double.tryParse(controller.text.replaceAll(',', '.'))), child: const Text('Сохранить'))]));
    if (value == null || value <= 0) return;
    final now = DateTime.now();
    setState(() { weight = value; history.add({'weight': value, 'date': '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}'}); if (history.length > 90) history.removeAt(0); _calculateGoals(); });
    await _save();
  }

  Widget _statsPage() => ListView(padding: const EdgeInsets.all(16), children: [Text('Статистика', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)), _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Прогресс веса'), const SizedBox(height: 12), Text('${startWeight.toStringAsFixed(1)} → ${weight.toStringAsFixed(1)} → ${goalWeight.toStringAsFixed(1)} кг'), const SizedBox(height: 12), SizedBox(height: 220, child: history.length < 2 ? const Center(child: Text('Нужно минимум 2 измерения')) : CustomPaint(painter: WeightPainter(history.map((x) => (x['weight'] as num).toDouble()).toList()))) ])), _card(Text('Сегодня: $kcal ккал • Б $protein г • Ж $fat г • У $carbs г'))]);

  Widget _profilePage() => ListView(padding: const EdgeInsets.all(16), children: [Text('Профиль', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)), _card(Column(children: [ListTile(title: const Text('Пол'), trailing: Text(sex)), ListTile(title: const Text('Возраст'), trailing: Text('$age лет')), ListTile(title: const Text('Рост'), trailing: Text('$height см')), ListTile(title: const Text('Вес'), trailing: Text('${weight.toStringAsFixed(1)} кг')), ListTile(title: const Text('Цель'), trailing: Text('${goalWeight.toStringAsFixed(1)} кг')), ListTile(title: const Text('Активность'), trailing: Text(_activityName())), FilledButton.icon(onPressed: _profileDialog, icon: const Icon(Icons.edit), label: const Text('Изменить'))]))]);

  String _activityName() => {1.2: 'Минимальная', 1.375: 'Низкая', 1.45: 'Умеренная', 1.65: 'Высокая', 1.8: 'Очень высокая'}[activity] ?? 'Умеренная';

  Future<bool> _profileDialog() async {
    final w = TextEditingController(text: weight.toStringAsFixed(1));
    final g = TextEditingController(text: goalWeight.toStringAsFixed(1));
    final h = TextEditingController(text: height.toString());
    final a = TextEditingController(text: age.toString());
    String localSex = sex;
    double localActivity = activity;
    final saved = await showDialog<bool>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(title: const Text('Профиль'), content: SingleChildScrollView(child: Column(children: [DropdownButtonFormField<String>(initialValue: localSex, items: const [DropdownMenuItem(value: 'Мужской', child: Text('Мужской')), DropdownMenuItem(value: 'Женский', child: Text('Женский'))], onChanged: (v) => setDialogState(() => localSex = v ?? localSex), decoration: const InputDecoration(labelText: 'Пол')), TextField(controller: a, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Возраст')), TextField(controller: h, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Рост, см')), TextField(controller: w, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Вес, кг')), TextField(controller: g, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Цель, кг')), DropdownButtonFormField<double>(initialValue: localActivity, items: const [DropdownMenuItem(value: 1.2, child: Text('Минимальная')), DropdownMenuItem(value: 1.375, child: Text('Низкая')), DropdownMenuItem(value: 1.45, child: Text('Умеренная')), DropdownMenuItem(value: 1.65, child: Text('Высокая')), DropdownMenuItem(value: 1.8, child: Text('Очень высокая'))], onChanged: (v) => setDialogState(() => localActivity = v ?? localActivity), decoration: const InputDecoration(labelText: 'Активность'))])), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Отмена')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Сохранить'))]));
    if (saved != true) return false;
    final newWeight = double.tryParse(w.text.replaceAll(',', '.'));
    final newGoal = double.tryParse(g.text.replaceAll(',', '.'));
    final newAge = int.tryParse(a.text);
    final newHeight = int.tryParse(h.text);
    if (newWeight == null || newGoal == null || newAge == null || newHeight == null || newWeight <= 0 || newGoal <= 0 || newAge < 12 || newHeight < 100) return false;
    setState(() { weight = newWeight; goalWeight = newGoal; age = newAge; height = newHeight; sex = localSex; activity = localActivity; if (startWeight <= 0) startWeight = newWeight; _calculateGoals(); });
    return true;
  }
}

class WeightPainter extends CustomPainter {
  final List<double> values;
  WeightPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = math.max(0.5, maxValue - minValue);
    final line = Paint()..color = accent..strokeWidth = 3..style = PaintingStyle.stroke;
    final dot = Paint()..color = accent;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i * size.width / (values.length - 1);
      final y = size.height - ((values[i] - minValue) / range) * (size.height - 20) - 10;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
      canvas.drawCircle(Offset(x, y), 4, dot);
    }
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant WeightPainter oldDelegate) => oldDelegate.values != values;
}
