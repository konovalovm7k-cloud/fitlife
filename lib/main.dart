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
  final double p, f, c;
  const Food(this.name, this.kcal, this.p, this.f, this.c);
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
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FitLife',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: bg,
          colorScheme: ColorScheme.fromSeed(
            seedColor: accent,
            brightness: Brightness.dark,
          ),
        ),
        home: const Shell(),
      );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  bool first = true;
  bool loading = true;
  double weight = 92.4, start = 92.4, goal = 85;
  int age = 35, height = 178;
  String sex = 'Мужской';
  double activity = 1.45;
  int kcal = 0, p = 0, f = 0, carb = 0, water = 0;
  int kcalGoal = 2000, pGoal = 150, fGoal = 67, cGoal = 200;
  String dayKey = '';
  List<Map<String, dynamic>> meals = [];
  List<Map<String, dynamic>> history = [];
  List<Map<String, dynamic>> customFoods = [];
  List<Map<String, dynamic>> recipes = [];

  String get todayKey {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      first = s.getBool('onboard') ?? true;
      weight = s.getDouble('weight') ?? weight;
      start = s.getDouble('start') ?? weight;
      goal = s.getDouble('goal') ?? goal;
      age = s.getInt('age') ?? age;
      height = s.getInt('height') ?? height;
      sex = s.getString('sex') ?? sex;
      activity = s.getDouble('activity') ?? activity;
      water = s.getInt('water') ?? 0;
      history = _decodeList(s.getString('history'));
      customFoods = _decodeList(s.getString('custom'));
      recipes = _decodeList(s.getString('recipes'));
      dayKey = s.getString('dayKey') ?? todayKey;
      if (dayKey == todayKey) {
        meals = _decodeList(s.getString('meals'));
      } else {
        meals = [];
        dayKey = todayKey;
        water = 0;
      }
      _recalculate();
      _rebuildNutrition();
      loading = false;
    });
    await _save();
  }

  List<Map<String, dynamic>> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(raw));
    } catch (_) {
      return [];
    }
  }

  void _recalculate() {
    final bmr = sex == 'Мужской'
        ? 10 * weight + 6.25 * height - 5 * age + 5
        : 10 * weight + 6.25 * height - 5 * age - 161;
    final maintenance = bmr * activity;
    kcalGoal = math.max(1200, (maintenance - 450).round());
    pGoal = math.max(90, (weight * 1.6).round());
    fGoal = math.max(35, (kcalGoal * 0.30 / 9).round());
    cGoal = math.max(80, ((kcalGoal - pGoal * 4 - fGoal * 9) / 4).round());
  }

  void _rebuildNutrition() {
    kcal = p = f = carb = 0;
    for (final m in meals) {
      kcal += (m['kcal'] as num?)?.round() ?? 0;
      p += (m['p'] as num?)?.round() ?? 0;
      f += (m['f'] as num?)?.round() ?? 0;
      carb += (m['c'] as num?)?.round() ?? 0;
    }
  }

  Future<void> _save() async {
    final s = await SharedPreferences.getInstance();
    await s.setBool('onboard', first);
    await s.setDouble('weight', weight);
    await s.setDouble('start', start);
    await s.setDouble('goal', goal);
    await s.setInt('age', age);
    await s.setInt('height', height);
    await s.setString('sex', sex);
    await s.setDouble('activity', activity);
    await s.setInt('water', water);
    await s.setString('dayKey', dayKey);
    await s.setString('meals', jsonEncode(meals));
    await s.setString('history', jsonEncode(history));
    await s.setString('custom', jsonEncode(customFoods));
    await s.setString('recipes', jsonEncode(recipes));
  }

  void _finishOnboarding() {
    setState(() {
      first = false;
      dayKey = todayKey;
    });
    _recalculate();
    _save();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (first) return Onboard(onDone: _openProfileAfterOnboard);
    final pages = [_home(), _foodDiary(), _weightPage(), _stats(), _profilePage()];
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

  Future<void> _openProfileAfterOnboard() async {
    await _profileDialog();
    _finishOnboarding();
  }

  Widget _home() {
    final progress = start <= goal ? 1.0 : ((start - weight) / (start - goal)).clamp(0.0, 1.0);
    final remaining = math.max(0, (weight - goal));
    final date = DateTime.now();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Сегодня', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text('${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}', style: TextStyle(color: Colors.grey.shade400)),
          ]),
          IconButton(onPressed: _profileDialog, icon: const Icon(Icons.settings)),
        ]),
        const SizedBox(height: 12),
        _card(Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _metric('Вес', '${weight.toStringAsFixed(1)} кг'),
            Text('${(progress * 100).round()}%', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            _metric('Цель', '${goal.toStringAsFixed(1)} кг'),
          ]),
          const SizedBox(height: 14),
          LinearProgressIndicator(value: progress, minHeight: 8),
          const SizedBox(height: 8),
          Text(remaining > 0 ? 'Осталось ${remaining.toStringAsFixed(1)} кг' : 'Цель достигнута!'),
        ])),
        _nutritionCard(),
        Row(children: [
          Expanded(child: _tile('Вода', '$water / 2500 мл', Icons.water_drop, () {
            setState(() => water = math.min(3000, water + 250));
            _save();
          })),
          const SizedBox(width: 10),
          Expanded(child: _tile('Шаги', 'Добавить вручную', Icons.directions_walk, _stepsInfo)),
        ]),
        _card(ListTile(
          leading: const Icon(Icons.auto_awesome),
          title: const Text('Цель рассчитана автоматически'),
          subtitle: Text('$kcalGoal ккал • Б $pGoal г • Ж $fGoal г • У $cGoal г'),
          onTap: _profileDialog,
        )),
        const SizedBox(height: 8),
        const Text('Быстрые действия', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Row(children: [
          Expanded(child: _action('Добавить еду', Icons.add_circle, _openFoods)),
          const SizedBox(width: 8),
          Expanded(child: _action('Записать вес', Icons.monitor_weight, _addWeight)),
        ]),
      ],
    );
  }

  Widget _nutritionCard() => _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Калории'),
        Text('$kcal / $kcalGoal ккал', style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: (kcal / math.max(1, kcalGoal)).clamp(0.0, 1.0), minHeight: 8),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _macro('Белки', p, pGoal), _macro('Жиры', f, fGoal), _macro('Углеводы', carb, cGoal),
        ]),
      ]);

  Widget _foodDiary() => ListView(padding: const EdgeInsets.all(16), children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Питание', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          IconButton(onPressed: _openFoods, icon: const Icon(Icons.add_circle)),
        ]),
        _nutritionCard(),
        if (meals.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('Добавьте первый продукт'))),
        ...meals.asMap().entries.map((e) => _card(ListTile(
          leading: const Icon(Icons.restaurant),
          title: Text(e.value['name'] as String),
          subtitle: Text('${e.value['grams']} г • Б ${e.value['p']} г • Ж ${e.value['f']} г • У ${e.value['c']} г'),
          trailing: Text('${e.value['kcal']} ккал'),
          onLongPress: () => _removeMeal(e.key),
        ))),
        if (meals.isNotEmpty) const Padding(padding: EdgeInsets.only(top: 4), child: Text('Удерживайте продукт, чтобы удалить его', textAlign: TextAlign.center)),
      ];

  Future<void> _openFoods() async {
    final search = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        final all = [...foods, ...customFoods.map((x) => Food(x['name'], x['kcal'], (x['p'] as num).toDouble(), (x['f'] as num).toDouble(), (x['c'] as num).toDouble()))];
        final q = search.text.trim().toLowerCase();
        final shown = all.where((x) => x.name.toLowerCase().contains(q)).toList();
        return SizedBox(
          height: MediaQuery.of(ctx).size.height * .85,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            const Text('Добавить продукт', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: search, onChanged: (_) => setSheet(() {}), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Поиск продукта', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            ...shown.map((x) => ListTile(
              title: Text(x.name),
              subtitle: Text('${x.kcal} ккал • Б ${x.p} • Ж ${x.f} • У ${x.c} / 100 г'),
              trailing: const Icon(Icons.add_circle),
              onTap: () { Navigator.pop(ctx); _addFood(x); },
            )),
            FilledButton.icon(onPressed: () { Navigator.pop(ctx); _customFood(); }, icon: const Icon(Icons.edit), label: const Text('Создать свой продукт')),
            OutlinedButton.icon(onPressed: () { Navigator.pop(ctx); _recipe(); }, icon: const Icon(Icons.menu_book), label: const Text('Создать рецепт')),
          ],),
        );
      }),
    );
  }

  Future<void> _addFood(Food x) async {
    final grams = await _numberDialog('Количество', 'Граммы', '100');
    if (grams == null || grams <= 0) return;
    final q = grams / 100;
    setState(() {
      meals.add({'name': x.name, 'grams': grams.round(), 'kcal': (x.kcal * q).round(), 'p': (x.p * q).round(), 'f': (x.f * q).round(), 'c': (x.c * q).round()});
      _rebuildNutrition();
    });
    await _save();
  }

  void _removeMeal(int index) {
    setState(() { meals.removeAt(index); _rebuildNutrition(); });
    _save();
  }

  Future<void> _customFood() async {
    final name = await _textDialog('Название продукта', 'Например, йогурт');
    if (name == null || name.trim().isEmpty) return;
    final k = await _numberDialog('Калории', 'ккал / 100 г', '100');
    final pp = await _numberDialog('Белки', 'г / 100 г', '10');
    final ff = await _numberDialog('Жиры', 'г / 100 г', '3');
    final cc = await _numberDialog('Углеводы', 'г / 100 г', '10');
    if ([k, pp, ff, cc].any((v) => v == null)) return;
    setState(() => customFoods.add({'name': name.trim(), 'kcal': k!.round(), 'p': pp!, 'f': ff!, 'c': cc!}));
    await _save();
  }

  Future<void> _recipe() async {
    final name = await _textDialog('Название рецепта', 'Например, омлет');
    if (name == null || name.trim().isEmpty) return;
    final k = await _numberDialog('Калории рецепта', 'ккал / порция', '0');
    if (k == null) return;
    setState(() => recipes.add({'name': name.trim(), 'kcal': k.round()}));
    await _save();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Рецепт сохранён')));
  }

  Widget _weightPage() => ListView(padding: const EdgeInsets.all(16), children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Вес', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)), IconButton(onPressed: _addWeight, icon: const Icon(Icons.add_circle))]),
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${weight.toStringAsFixed(1)} кг', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)), Text('Цель ${goal.toStringAsFixed(1)} кг'), const SizedBox(height: 12), SizedBox(height: 220, child: WeightChart(history: history))])),
        if (history.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Добавьте первое измерение'))),
        ...history.reversed.map((x) => ListTile(leading: const Icon(Icons.monitor_weight), title: Text('${x['weight']} кг'), trailing: Text(x['date']))),
      ];

  Future<void> _addWeight() async {
    final v = await _numberDialog('Записать вес', 'кг', weight.toStringAsFixed(1), decimal: true);
    if (v == null || v <= 0) return;
    final d = DateTime.now();
    setState(() {
      weight = v;
      history.add({'date': '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}', 'weight': v});
      if (history.length > 90) history.removeAt(0);
      _recalculate();
    });
    await _save();
  }

  Widget _stats() => ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Статистика', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Прогресс веса', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text('Старт ${start.toStringAsFixed(1)} кг → сейчас ${weight.toStringAsFixed(1)} кг → цель ${goal.toStringAsFixed(1)} кг'),
          const SizedBox(height: 16), SizedBox(height: 230, child: WeightChart(history: history)),
        ])),
        _card(ListTile(leading: const Icon(Icons.local_fire_department), title: const Text('Средняя цель'), subtitle: Text('$kcalGoal ккал в день'))),
        _card(ListTile(leading: const Icon(Icons.restaurant), title: const Text('Сегодня съедено'), subtitle: Text('$kcal ккал • Б $p г • Ж $f г • У $carb г'))),
      ];

  Widget _profilePage() => ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Профиль', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        _card(Column(children: [
          _profileRow('Пол', sex), _profileRow('Возраст', '$age лет'), _profileRow('Рост', '$height см'), _profileRow('Вес', '${weight.toStringAsFixed(1)} кг'), _profileRow('Цель', '${goal.toStringAsFixed(1)} кг'), _profileRow('Активность', _activityName()),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: _profileDialog, icon: const Icon(Icons.edit), label: const Text('Изменить профиль')),
        ])),
        if (recipes.isNotEmpty) _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Мои рецепты', style: TextStyle(fontWeight: FontWeight.bold)), ...recipes.map((r) => ListTile(title: Text(r['name']), trailing: Text('${r['kcal']} ккал')))])),
      ];

  Future<void> _profileDialog() async {
    final w = TextEditingController(text: weight.toStringAsFixed(1));
    final h = TextEditingController(text: height.toString());
    final a = TextEditingController(text: age.toString());
    final g = TextEditingController(text: goal.toStringAsFixed(1));
    String localSex = sex; double localActivity = activity;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, set) => AlertDialog(
      title: const Text('Профиль и цель'),
      content: SingleChildScrollView(child: Column(children: [
        DropdownButtonFormField<String>(value: localSex, items: const [DropdownMenuItem(value: 'Мужской', child: Text('Мужской')), DropdownMenuItem(value: 'Женский', child: Text('Женский'))], onChanged: (v) => set(() => localSex = v ?? localSex), decoration: const InputDecoration(labelText: 'Пол')),
        TextField(controller: a, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Возраст')),
        TextField(controller: h, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Рост, см')),
        TextField(controller: w, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Текущий вес, кг')),
        TextField(controller: g, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Целевой вес, кг')),
        DropdownButtonFormField<double>(value: localActivity, items: const [DropdownMenuItem(value: 1.2, child: Text('Минимальная')), DropdownMenuItem(value: 1.375, child: Text('Низкая')), DropdownMenuItem(value: 1.45, child: Text('Умеренная')), DropdownMenuItem(value: 1.65, child: Text('Высокая')), DropdownMenuItem(value: 1.8, child: Text('Очень высокая'))], onChanged: (v) => set(() => localActivity = v ?? localActivity), decoration: const InputDecoration(labelText: 'Активность')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Сохранить'))],
    )));
    if (ok != true) return;
    final nw = double.tryParse(w.text.replaceAll(',', '.'));
    final ng = double.tryParse(g.text.replaceAll(',', '.'));
    final na = int.tryParse(a.text), nh = int.tryParse(h.text);
    if (nw == null || ng == null || na == null || nh == null || nw <= 0 || ng <= 0 || na < 12 || nh < 100) return;
    setState(() { weight = nw; goal = ng; age = na; height = nh; sex = localSex; activity = localActivity; if (start <= 0 || start == 92.4) start = nw; _recalculate(); });
    await _save();
  }

  String _activityName() => {1.2: 'Минимальная', 1.375: 'Низкая', 1.45: 'Умеренная', 1.65: 'Высокая', 1.8: 'Очень высокая'}[activity] ?? 'Умеренная';
  Widget _profileRow(String a, String b) => ListTile(title: Text(a), trailing: Text(b, style: const TextStyle(fontWeight: FontWeight.bold)));
  Widget _macro(String n, int v, int g) => Column(children: [Text(n), Text('$v / $g г', style: const TextStyle(fontWeight: FontWeight.bold))]);
  Widget _metric(String a, String b) => Column(children: [Text(a, style: TextStyle(color: Colors.grey.shade400)), Text(b, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]);
  Widget _card(Widget child) => Card(color: card, child: Padding(padding: const EdgeInsets.all(16), child: child));
  Widget _tile(String a, String b, IconData i, VoidCallback f) => Card(color: card, child: InkWell(onTap: f, child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [Icon(i), const SizedBox(height: 5), Text(a), Text(b, style: const TextStyle(fontWeight: FontWeight.bold))]))));
  Widget _action(String t, IconData i, VoidCallback f) => FilledButton.tonalIcon(onPressed: f, icon: Icon(i), label: Text(t));
  Future<void> _stepsInfo() async { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Шаги пока вводятся вручную — интеграцию Samsung Health добавим следующим этапом.'))); }

  Future<double?> _numberDialog(String title, String label, String initial, {bool decimal = true}) async {
    final c = TextEditingController(text: initial);
    return showDialog<double>(context: context, builder: (ctx) => AlertDialog(title: Text(title), content: TextField(controller: c, autofocus: true, keyboardType: decimal ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number, decoration: InputDecoration(labelText: label)), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')), FilledButton(onPressed: () => Navigator.pop(ctx, double.tryParse(c.text.replaceAll(',', '.'))), child: const Text('Сохранить'))]);
  }

  Future<String?> _textDialog(String title, String hint) async {
    final c = TextEditingController();
    return showDialog<String>(context: context, builder: (ctx) => AlertDialog(title: Text(title), content: TextField(controller: c, autofocus: true, decoration: InputDecoration(hintText: hint)), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')), FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Сохранить'))]));
  }
}

class Onboard extends StatelessWidget {
  final VoidCallback onDone;
  const Onboard({super.key, required this.onDone});
  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.monitor_weight, size: 76, color: accent), const SizedBox(height: 18),
    const Text('FitLife', style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold)),
    const SizedBox(height: 12), const Text('Умный дневник похудения', textAlign: TextAlign.center, style: TextStyle(fontSize: 20)),
    const SizedBox(height: 16), const Text('Профиль, расчёт калорий и БЖУ, продукты, вес и прогресс — всё в одном приложении.', textAlign: TextAlign.center),
    const SizedBox(height: 32), SizedBox(width: double.infinity, child: FilledButton(onPressed: onDone, child: const Padding(padding: EdgeInsets.all(14), child: Text('Начать')))),
  ]))));
}

class WeightChart extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  const WeightChart({super.key, required this.history});
  @override
  Widget build(BuildContext context) {
    if (history.length < 2) return const Center(child: Text('Нужно минимум 2 измерения для графика'));
    return CustomPaint(painter: _ChartPainter(history.map((e) => (e['weight'] as num).toDouble()).toList()), child: const SizedBox.expand());
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> values;
  _ChartPainter(this.values);
  @override
  void paint(Canvas canvas, Size size) {
    final minV = values.reduce(math.min), maxV = values.reduce(math.max);
    final range = math.max(0.5, maxV - minV);
    final paint = Paint()..color = accent..strokeWidth = 3..style = PaintingStyle.stroke;
    final dot = Paint()..color = accent..style = PaintingStyle.fill;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i * size.width / (values.length - 1);
      final y = size.height - ((values[i] - minV) / range) * (size.height - 20) - 10;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
      canvas.drawCircle(Offset(x, y), 4, dot);
    }
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant _ChartPainter old) => old.values != values;
}
