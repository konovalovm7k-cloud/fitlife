import 'package:flutter/material.dart';
import '../core/models/food.dart';
import '../core/nutrition/nutrition_calculator.dart';

const bg = Color(0xFF081018);
const card = Color(0xFF121C26);
const accent = Color(0xFF35E56B);

class FitLifeApp extends StatelessWidget {
  const FitLifeApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FitLife',
        theme: ThemeData(useMaterial3: true, brightness: Brightness.dark, scaffoldBackgroundColor: bg, colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark)),
        home: const FitLifeShell(),
      );
}

class FitLifeShell extends StatefulWidget {
  const FitLifeShell({super.key});
  @override
  State<FitLifeShell> createState() => _FitLifeShellState();
}

class _FitLifeShellState extends State<FitLifeShell> {
  int tab = 0;
  double weight = 92.4, startWeight = 92.4, goalWeight = 85;
  int age = 35, height = 178, water = 0;
  String sex = 'Мужской';
  double activity = 1.45;
  final List<FoodEntry> meals = [];
  final List<WeightEntry> weights = [];

  NutritionGoals get goals => const NutritionCalculator().calculate(weight: weight, height: height, age: age, sex: sex, activity: activity);
  int get kcal => meals.fold(0, (s, e) => s + e.kcal);
  double get protein => meals.fold(0.0, (s, e) => s + e.protein);
  double get fat => meals.fold(0.0, (s, e) => s + e.fat);
  double get carbs => meals.fold(0.0, (s, e) => s + e.carbs);
  double get progress { final total = startWeight - goalWeight; return total <= 0 ? 0 : ((startWeight - weight) / total).clamp(0.0, 1.0).toDouble(); }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[_home(), _nutrition(), _weight(), _statistics(), _profile()];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        backgroundColor: card,
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
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

  Widget _card(Widget child) => Card(color: card, child: Padding(padding: const EdgeInsets.all(16), child: child));

  Widget _home() => ListView(padding: const EdgeInsets.all(16), children: [
        Text('FitLife', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const Text('Умный дневник похудения'),
        const SizedBox(height: 16),
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Вес', style: TextStyle(color: Colors.grey)),
          Text('${weight.toStringAsFixed(1)} кг', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          Text('Цель ${goalWeight.toStringAsFixed(1)} кг'),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: progress, minHeight: 8),
          const SizedBox(height: 8),
          Text('${(progress * 100).round()}% пути к цели'),
        ])),
        _nutritionCard(),
        Row(children: [
          Expanded(child: _quick('Вода', '$water мл', Icons.water_drop, () => setState(() => water += 250))),
          const SizedBox(width: 10),
          Expanded(child: _quick('Еда', 'Добавить', Icons.add_circle, () => setState(() => tab = 1))),
        ]),
      ]);

  Widget _nutritionCard() => _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Сегодня', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text('$kcal / ${goals.calories} ккал', style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: (kcal / goals.calories).clamp(0.0, 1.0).toDouble()),
        const SizedBox(height: 12),
        Text('Белки ${protein.toStringAsFixed(1)} / ${goals.protein} г'),
        Text('Жиры ${fat.toStringAsFixed(1)} / ${goals.fat} г'),
        Text('Углеводы ${carbs.toStringAsFixed(1)} / ${goals.carbs} г'),
      ]));

  Widget _quick(String title, String value, IconData icon, VoidCallback onTap) => Card(color: card, child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [Icon(icon), Text(title), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]))));

  Widget _nutrition() => ListView(padding: const EdgeInsets.all(16), children: [
        Text('Питание', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        _nutritionCard(),
        if (meals.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Продуктов пока нет'))),
        ...meals.asMap().entries.map((e) => _card(ListTile(title: Text(e.value.food.name), subtitle: Text('${e.value.grams.round()} г • Б ${e.value.protein.toStringAsFixed(1)} • Ж ${e.value.fat.toStringAsFixed(1)} • У ${e.value.carbs.toStringAsFixed(1)}'), trailing: Text('${e.value.kcal} ккал'), onLongPress: () => setState(() => meals.removeAt(e.key))))),
        FilledButton.icon(onPressed: _addFood, icon: const Icon(Icons.add), label: const Text('Добавить продукт')),
      ]);

  Future<void> _addFood() async {
    final food = await showModalBottomSheet<Food>(context: context, isScrollControlled: true, builder: (context) => ListView(shrinkWrap: true, padding: const EdgeInsets.all(16), children: [
          const Text('Выберите продукт', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ...defaultFoods.map((f) => ListTile(title: Text(f.name), subtitle: Text('${f.kcal} ккал / 100 г'), onTap: () => Navigator.pop(context, f))),
        ]));
    if (food == null || !mounted) return;
    final c = TextEditingController(text: '100');
    final grams = await showDialog<double>(context: context, builder: (context) => AlertDialog(title: Text(food.name), content: TextField(controller: c, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Граммы')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')), FilledButton(onPressed: () => Navigator.pop(context, double.tryParse(c.text.replaceAll(',', '.'))), child: const Text('Добавить'))]));
    c.dispose();
    if (grams == null || grams <= 0 || !mounted) return;
    setState(() => meals.add(FoodEntry.fromFood(food, grams)));
  }

  Widget _weight() => ListView(padding: const EdgeInsets.all(16), children: [
        Text('Вес', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${weight.toStringAsFixed(1)} кг', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)), Text('Цель ${goalWeight.toStringAsFixed(1)} кг')])),
        FilledButton.icon(onPressed: _addWeight, icon: const Icon(Icons.add), label: const Text('Записать вес')),
        ...weights.reversed.map((e) => ListTile(title: Text('${e.weight.toStringAsFixed(1)} кг'), trailing: Text(e.date))),
      ]);

  Future<void> _addWeight() async {
    final c = TextEditingController(text: weight.toStringAsFixed(1));
    final value = await showDialog<double>(context: context, builder: (context) => AlertDialog(title: const Text('Вес'), content: TextField(controller: c, keyboardType: const TextInputType.numberWithOptions(decimal: true)), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')), FilledButton(onPressed: () => Navigator.pop(context, double.tryParse(c.text.replaceAll(',', '.'))), child: const Text('Сохранить'))]));
    c.dispose();
    if (value == null || value <= 0 || !mounted) return;
    final now = DateTime.now();
    setState(() { weight = value; weights.add(WeightEntry(value, '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}')); });
  }

  Widget _statistics() => ListView(padding: const EdgeInsets.all(16), children: [
        Text('Статистика', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        _card(Text('Снижение: ${(startWeight - weight).toStringAsFixed(1)} кг\nДо цели: ${(weight - goalWeight).clamp(0.0, 999.0).toStringAsFixed(1)} кг\nДневная цель: ${goals.calories} ккал')),
      ]);

  Widget _profile() => ListView(padding: const EdgeInsets.all(16), children: [
        Text('Профиль', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        _card(Column(children: [_row('Пол', sex), _row('Возраст', '$age лет'), _row('Рост', '$height см'), _row('Вес', '${weight.toStringAsFixed(1)} кг'), _row('Цель', '${goalWeight.toStringAsFixed(1)} кг'), FilledButton.icon(onPressed: _editProfile, icon: const Icon(Icons.edit), label: const Text('Изменить'))])),
      ]);

  Future<void> _editProfile() async {
    final ageC = TextEditingController(text: '$age');
    final heightC = TextEditingController(text: '$height');
    final weightC = TextEditingController(text: weight.toStringAsFixed(1));
    final goalC = TextEditingController(text: goalWeight.toStringAsFixed(1));
    final result = await showDialog<List<double>>(context: context, builder: (context) => AlertDialog(title: const Text('Профиль'), content: SingleChildScrollView(child: Column(children: [TextField(controller: ageC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Возраст')), TextField(controller: heightC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Рост, см')), TextField(controller: weightC, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Вес, кг')), TextField(controller: goalC, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Цель, кг'))])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')), FilledButton(onPressed: () => Navigator.pop(context, [double.tryParse(ageC.text) ?? age.toDouble(), double.tryParse(heightC.text) ?? height.toDouble(), double.tryParse(weightC.text.replaceAll(',', '.')) ?? weight, double.tryParse(goalC.text.replaceAll(',', '.')) ?? goalWeight]), child: const Text('Сохранить'))]));
    ageC.dispose(); heightC.dispose(); weightC.dispose(); goalC.dispose();
    if (result == null || !mounted) return;
    setState(() { age = result[0].round(); height = result[1].round(); weight = result[2]; goalWeight = result[3]; });
  }

  Widget _row(String label, String value) => ListTile(title: Text(label), trailing: Text(value));
}

class FoodEntry {
  final Food food;
  final double grams;
  const FoodEntry(this.food, this.grams);
  factory FoodEntry.fromFood(Food food, double grams) => FoodEntry(food, grams);
  int get kcal => (food.kcal * grams / 100).round();
  double get protein => food.protein * grams / 100;
  double get fat => food.fat * grams / 100;
  double get carbs => food.carbs * grams / 100;
}

class WeightEntry {
  final double weight;
  final String date;
  const WeightEntry(this.weight, this.date);
}

const defaultFoods = <Food>[
  Food(name: 'Яйцо куриное', kcal: 143, protein: 12.6, fat: 9.5, carbs: 0.7),
  Food(name: 'Куриная грудка', kcal: 165, protein: 31, fat: 3.6, carbs: 0),
  Food(name: 'Овсянка', kcal: 370, protein: 13, fat: 6.5, carbs: 62),
  Food(name: 'Творог 5%', kcal: 121, protein: 17.2, fat: 5, carbs: 1.8),
  Food(name: 'Рис варёный', kcal: 130, protein: 2.7, fat: 0.3, carbs: 28.2),
  Food(name: 'Яблоко', kcal: 52, protein: 0.3, fat: 0.2, carbs: 13.8),
  Food(name: 'Банан', kcal: 89, protein: 1.1, fat: 0.3, carbs: 22.8),
];
