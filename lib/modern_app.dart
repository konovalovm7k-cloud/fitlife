import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const green = Color(0xFF3D9B70);
const greenDark = Color(0xFF287451);
const mint = Color(0xFFE8F5EE);
const bg = Color(0xFFF6F8F6);
const ink = Color(0xFF17231D);
const muted = Color(0xFF7A857E);
const line = Color(0xFFE5EAE6);

class ModernFitLifeApp extends StatelessWidget {
  const ModernFitLifeApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FitLife',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: bg,
          colorScheme: ColorScheme.fromSeed(seedColor: green),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: line)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: line)),
          ),
        ),
        home: const FitLifeHome(),
      );
}

class FoodItem {
  final String id;
  final String name;
  final double kcal;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;

  const FoodItem(this.id, this.name, this.kcal, this.protein, this.fat, this.carbs, this.fiber);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'kcal': kcal, 'protein': protein, 'fat': fat, 'carbs': carbs, 'fiber': fiber};
  factory FoodItem.fromJson(Map<String, dynamic> j) => FoodItem(
        j['id'] as String,
        j['name'] as String,
        (j['kcal'] as num).toDouble(),
        (j['protein'] as num).toDouble(),
        (j['fat'] as num).toDouble(),
        (j['carbs'] as num).toDouble(),
        (j['fiber'] as num).toDouble(),
      );
}

class DiaryItem {
  final String id;
  final String meal;
  final FoodItem food;
  final double grams;
  final String time;

  DiaryItem({required this.id, required this.meal, required this.food, required this.grams, required this.time});

  double get kcal => food.kcal * grams / 100;
  double get protein => food.protein * grams / 100;
  double get fat => food.fat * grams / 100;
  double get carbs => food.carbs * grams / 100;
  double get fiber => food.fiber * grams / 100;

  Map<String, dynamic> toJson() => {'id': id, 'meal': meal, 'food': food.toJson(), 'grams': grams, 'time': time};
  factory DiaryItem.fromJson(Map<String, dynamic> j) => DiaryItem(
        id: j['id'] as String,
        meal: j['meal'] as String,
        food: FoodItem.fromJson(Map<String, dynamic>.from(j['food'] as Map)),
        grams: (j['grams'] as num).toDouble(),
        time: j['time'] as String,
      );
}

const builtInFoods = <FoodItem>[
  FoodItem('egg', 'Яйцо', 157, 12.7, 10.9, 0.7, 0),
  FoodItem('turkey_ham', 'Ветчина из индейки', 84, 18, 2, 2, 0),
  FoodItem('oats', 'Овсяные хлопья, сухие', 366, 12.3, 6.1, 59.5, 8.3),
  FoodItem('chicken', 'Куриная грудка, сырая', 120, 22.5, 2.6, 0, 0),
  FoodItem('buckwheat', 'Гречка, сухая', 343, 13.6, 3.4, 71.5, 10),
  FoodItem('couscous', 'Кускус, сухой', 376, 12.8, 0.6, 77.4, 5),
  FoodItem('potato', 'Картофель, отварной', 82, 2, 0.4, 17, 1.8),
  FoodItem('greek_yogurt', 'Греческий йогурт', 73, 9, 2.5, 3.8, 0),
  FoodItem('skyr', 'Skyr', 35, 6, 0, 3, 0),
  FoodItem('pepper', 'Перец красный', 31, 1, 0.3, 6, 2.1),
  FoodItem('iceberg', 'Салат айсберг', 14, 0.9, 0.1, 3, 1.2),
  FoodItem('tomato', 'Помидор', 18, 0.9, 0.2, 3.9, 1.2),
  FoodItem('cucumber', 'Огурец', 15, 0.7, 0.1, 3.6, 0.5),
  FoodItem('apple', 'Яблоко', 52, 0.3, 0.2, 13.8, 2.4),
  FoodItem('peach', 'Персик', 39, 0.9, 0.3, 9.5, 1.5),
  FoodItem('blackberry', 'Ежевика', 43, 1.4, 0.5, 9.6, 5.3),
  FoodItem('mushroom', 'Шампиньоны', 22, 3.1, 0.3, 3.3, 1),
  FoodItem('sour_cream', 'Сметана 25%', 248, 2.6, 25, 3.2, 0),
  FoodItem('ketchup', 'Кетчуп', 110, 1.2, 0.2, 25, 0.7),
];

class _FitLifeHomeState extends State<FitLifeHome> {
  int tab = 0;
  double water = 1.5;
  double weight = 104.2;
  List<DiaryItem> diary = [];
  List<FoodItem> customFoods = [];
  bool loading = true;

  List<FoodItem> get foods => [...builtInFoods, ...customFoods];
  double get calories => diary.fold(0, (s, x) => s + x.kcal);
  double get protein => diary.fold(0, (s, x) => s + x.protein);
  double get fat => diary.fold(0, (s, x) => s + x.fat);
  double get carbs => diary.fold(0, (s, x) => s + x.carbs);
  double get fiber => diary.fold(0, (s, x) => s + x.fiber);
  double get remainingCalories => (1900 - calories).clamp(0, 1900);
  double get proteinToMin => (160 - protein).clamp(0, 160);
  double get proteinToMax => (180 - protein).clamp(0, 180);
  double get fatRemaining => (65 - fat).clamp(0, 65);
  double get fiberRemaining => (30 - fiber).clamp(0, 30);

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get dayKey {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('diary_$dayKey');
    final custom = p.getString('custom_foods');
    if (!mounted) return;
    setState(() {
      water = p.getDouble('water') ?? 1.5;
      weight = p.getDouble('weight') ?? 104.2;
      diary = raw == null
          ? []
          : (jsonDecode(raw) as List).map((x) => DiaryItem.fromJson(Map<String, dynamic>.from(x))).toList();
      customFoods = custom == null
          ? []
          : (jsonDecode(custom) as List).map((x) => FoodItem.fromJson(Map<String, dynamic>.from(x))).toList();
      loading = false;
    });
  }

  Future<void> _persistDiary() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('diary_$dayKey', jsonEncode(diary.map((x) => x.toJson()).toList()));
  }

  Future<void> _persistCustomFoods() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('custom_foods', jsonEncode(customFoods.map((x) => x.toJson()).toList()));
  }

  Future<void> _saveDouble(String key, double value) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(key, value);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: green)));
    final pages = <Widget>[_today(), _diaryPage(), _weightPage(), _progressPage(), _profilePage()];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        backgroundColor: Colors.white,
        indicatorColor: mint,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Сегодня'),
          NavigationDestination(icon: Icon(Icons.restaurant_menu_outlined), selectedIcon: Icon(Icons.restaurant_menu_rounded), label: 'Питание'),
          NavigationDestination(icon: Icon(Icons.monitor_weight_outlined), selectedIcon: Icon(Icons.monitor_weight_rounded), label: 'Вес'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights_rounded), label: 'Прогресс'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Профиль'),
        ],
      ),
      floatingActionButton: tab <= 1
          ? FloatingActionButton.extended(
              onPressed: _addFood,
              backgroundColor: green,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Добавить еду'),
            )
          : null,
    );
  }

  Widget _today() => ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
        children: [
          _header('Сегодня', _dateLabel()),
          const SizedBox(height: 14),
          _petCard(),
          const SizedBox(height: 14),
          _calorieCard(),
          const SizedBox(height: 12),
          _macroCard(),
          const SizedBox(height: 12),
          Row(children: [
            _statCard(Icons.water_drop_outlined, 'Вода', '${water.toStringAsFixed(1)} л', _addWater),
            const SizedBox(width: 8),
            _statCard(Icons.monitor_weight_outlined, 'Вес', '${weight.toStringAsFixed(1).replaceAll('.', ',')} кг', _addWeight),
            const SizedBox(width: 8),
            _statCard(Icons.restaurant_outlined, 'Приёмов', '${_mealNames().length}', null),
          ]),
          const SizedBox(height: 18),
          _nextAction(),
          const SizedBox(height: 18),
          const Text('Дневник питания', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: ink)),
          const SizedBox(height: 7),
          if (diary.isEmpty) _emptyDiary() else ..._mealGroups(),
        ],
      );

  String _dateLabel() {
    const days = ['понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота', 'воскресенье'];
    final d = DateTime.now();
    return '${d.day}.${d.month}.${d.year} · ${days[d.weekday - 1]}';
  }

  Widget _petCard() => _surfaceCard(Row(children: [
        Container(width: 72, height: 72, decoration: const BoxDecoration(color: mint, shape: BoxShape.circle), child: const Center(child: Text('🐼', style: TextStyle(fontSize: 42)))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Твой помощник', style: TextStyle(color: muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          const Text('Панда на хорошем ходу 💚', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: ink)),
          const SizedBox(height: 7),
          Text('Сегодня · ${diary.isEmpty ? 'начинаем день' : 'дневник заполнен на ${((calories / 1900).clamp(0, 1) * 100).round()}%'}', style: const TextStyle(color: greenDark, fontWeight: FontWeight.w800)),
        ])),
      ]));

  Widget _calorieCard() => _darkCard(Row(children: [
        SizedBox(width: 112, height: 112, child: Stack(alignment: Alignment.center, children: [
          CircularProgressIndicator(value: (calories / 1900).clamp(0, 1), strokeWidth: 10, color: const Color(0xFF7BE0A8), backgroundColor: const Color(0x334A5A50)),
          Column(mainAxisSize: MainAxisSize.min, children: [Text('${remainingCalories.round()}', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Colors.white)), const Text('осталось', style: TextStyle(color: Colors.white60))]),
        ])),
        const SizedBox(width: 18),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Дневная цель', style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 3),
          Text('${calories.round()} из 1 900 ккал', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 7),
          Text('Белок ${protein.round()} г · клетчатка ${fiber.round()} г', style: const TextStyle(color: Colors.white70)),
        ])),
      ]));

  Widget _macroCard() => _surfaceCard(Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Макросы', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: ink)),
          Text('Б ${protein.round()} · Ж ${fat.round()} · У ${carbs.round()}', style: const TextStyle(color: muted, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 13),
        Row(children: [
          Expanded(child: _macroBar('Белок', protein, 180)),
          const SizedBox(width: 10),
          Expanded(child: _macroBar('Жиры', fat, 65)),
          const SizedBox(width: 10),
          Expanded(child: _macroBar('Углеводы', carbs, 180)),
        ]),
      ]));

  Widget _macroBar(String label, double value, double target) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: (value / target).clamp(0, 1), minHeight: 7, color: green, backgroundColor: mint)),
        const SizedBox(height: 3),
        Text('${value.round()} г', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: ink)),
      ]);

  Widget _nextAction() {
    final String text;
    if (proteinToMin > 0) {
      text = 'Добери ещё ${proteinToMin.round()} г белка';
    } else if (fiberRemaining > 0) {
      text = 'Добавь ещё ${fiberRemaining.round()} г клетчатки';
    } else {
      text = 'Основные цели на сегодня закрыты';
    }
    return _surfaceCard(Row(children: [
      Container(width: 44, height: 44, decoration: const BoxDecoration(color: mint, shape: BoxShape.circle), child: const Icon(Icons.auto_awesome, color: greenDark)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Следующий шаг', style: TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w900, color: ink)),
        const SizedBox(height: 2),
        Text(remainingCalories > 0 ? 'Осталось ${remainingCalories.round()} ккал. Можно спокойно планировать следующий приём.' : 'Не нужно компенсировать еду голодом или тренировкой.', style: const TextStyle(color: muted, fontSize: 12)),
      ])),
    ]));
  }

  Widget _diaryPage() => ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
        children: [
          _header('Питание', 'Сегодня · ${diary.length} продуктов'),
          const SizedBox(height: 16),
          _summaryCard(),
          const SizedBox(height: 12),
          if (diary.isEmpty) _emptyDiary() else ..._mealGroups(),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: _addFood, icon: const Icon(Icons.add, color: green), label: const Text('Добавить продукт', style: TextStyle(color: ink, fontWeight: FontWeight.w800)), style: _outlineButton()),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: _addCustomFood, icon: const Icon(Icons.bookmark_add_outlined, color: green), label: const Text('Создать свой продукт', style: TextStyle(color: ink, fontWeight: FontWeight.w800)), style: _outlineButton()),
        ],
      );

  Widget _summaryCard() => _surfaceCard(Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${calories.round()} ккал', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: ink)), Text('из 1 900', style: const TextStyle(color: muted, fontWeight: FontWeight.w700))]),
        const SizedBox(height: 11),
        ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: (calories / 1900).clamp(0, 1), minHeight: 9, color: green, backgroundColor: mint)),
        const SizedBox(height: 14),
        Row(children: [Metric(label: 'Б', value: '${protein.round()} г'), Metric(label: 'Ж', value: '${fat.round()} г'), Metric(label: 'У', value: '${carbs.round()} г'), Metric(label: 'К', value: '${fiber.round()} г')]),
        const SizedBox(height: 10),
        Align(alignment: Alignment.centerLeft, child: Text('До целей: Б ${proteinToMin.round()}–${proteinToMax.round()} г · Ж до ${fatRemaining.round()} г · К ${fiberRemaining.round()} г', style: const TextStyle(color: muted, fontSize: 12))),
      ]));

  List<String> _mealNames() => diary.map((x) => x.meal).toSet().toList();

  List<Widget> _mealGroups() {
    const order = ['Завтрак', 'Обед', 'Ужин', 'Перекус'];
    final groups = <String, List<DiaryItem>>{};
    for (final item in diary) groups.putIfAbsent(item.meal, () => []).add(item);
    final keys = [...order.where(groups.containsKey), ...groups.keys.where((x) => !order.contains(x))];
    return keys.map((meal) {
      final items = groups[meal]!;
      final total = items.fold(0.0, (s, x) => s + x.kcal);
      return Padding(padding: const EdgeInsets.only(bottom: 10), child: _surfaceCard(Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(meal, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: ink)), Text('${total.round()} ккал', style: const TextStyle(color: muted, fontWeight: FontWeight.w800))]),
        const SizedBox(height: 5),
        ...items.map((x) => _diaryRow(x)),
      ])));
    }).toList();
  }

  Widget _diaryRow(DiaryItem item) => Dismissible(
        key: ValueKey(item.id),
        direction: DismissDirection.endToStart,
        background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 18), color: Colors.red.shade50, child: const Icon(Icons.delete_outline, color: Colors.red)),
        onDismissed: (_) { setState(() => diary.removeWhere((x) => x.id == item.id)); _persistDiary(); },
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(item.food.name, style: const TextStyle(fontWeight: FontWeight.w800, color: ink)),
          subtitle: Text('${_fmt(item.grams)} г · Б ${_fmt(item.protein)} · Ж ${_fmt(item.fat)} · У ${_fmt(item.carbs)} · К ${_fmt(item.fiber)} г', style: const TextStyle(color: muted, fontSize: 12)),
          trailing: Text('${item.kcal.round()} ккал', style: const TextStyle(fontWeight: FontWeight.w900, color: ink)),
          onTap: () => _editDiaryItem(item),
        ),
      );

  Widget _emptyDiary() => _surfaceCard(Column(children: [
        const Text('Дневник пока пуст', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink)),
        const SizedBox(height: 6),
        const Text('Добавь первый продукт. FitLife автоматически пересчитает калории, БЖУ и клетчатку.', textAlign: TextAlign.center, style: TextStyle(color: muted, height: 1.4)),
        const SizedBox(height: 14),
        FilledButton.icon(onPressed: _addFood, icon: const Icon(Icons.add), label: const Text('Добавить продукт'), style: FilledButton.styleFrom(backgroundColor: green)),
      ]));

  Widget _weightPage() => ListView(padding: const EdgeInsets.all(20), children: [
        _header('Вес', 'История и цель'),
        const SizedBox(height: 16),
        _surfaceCard(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${weight.toStringAsFixed(1).replaceAll('.', ',')} кг', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: ink)),
          const SizedBox(height: 5),
          const Text('Цель · 85 кг', style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 22),
          LinearProgressIndicator(value: ((104.2 - weight) / (104.2 - 85)).clamp(0, 1), minHeight: 10, color: green, backgroundColor: mint),
          const SizedBox(height: 10),
          const Text('Смотрим на устойчивый тренд, а не на скачок одного дня.', style: TextStyle(color: greenDark, fontWeight: FontWeight.w700)),
        ])),
        const SizedBox(height: 14),
        FilledButton.icon(onPressed: _addWeight, style: FilledButton.styleFrom(backgroundColor: green, minimumSize: const Size.fromHeight(52)), icon: const Icon(Icons.add), label: const Text('Добавить вес')),
      ]);

  Widget _progressPage() => ListView(padding: const EdgeInsets.all(20), children: [
        _header('Прогресс', 'Твои привычки'),
        const SizedBox(height: 16),
        _surfaceCard(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Главное — устойчивость', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: ink)),
          const SizedBox(height: 6),
          const Text('Один сложный день не отменяет прогресс.', style: TextStyle(color: muted)),
          const SizedBox(height: 20),
          ProgressLine(label: 'Калории', value: (calories / 1900).clamp(0, 1), text: '${((calories / 1900) * 100).round()}%'),
          ProgressLine(label: 'Белок', value: (protein / 170).clamp(0, 1), text: '${((protein / 170) * 100).round()}%'),
          ProgressLine(label: 'Клетчатка', value: (fiber / 30).clamp(0, 1), text: '${((fiber / 30) * 100).round()}%'),
          ProgressLine(label: 'Вода', value: (water / 2.5).clamp(0, 1), text: '${((water / 2.5) * 100).round()}%'),
        ])),
      ]);

  Widget _profilePage() => ListView(padding: const EdgeInsets.all(20), children: [
        _header('Профиль', 'Настройки FitLife'),
        const SizedBox(height: 16),
        _surfaceCard(const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Моя цель', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink)),
          SizedBox(height: 12),
          Text('Похудение · 85 кг', style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
          SizedBox(height: 18),
          Text('Дневная цель · 1 900 ккал', style: TextStyle(color: ink, fontWeight: FontWeight.w800)),
          SizedBox(height: 6),
          Text('Белок · 160–180 г · Жиры · 50–65 г · Клетчатка · 30 г', style: TextStyle(color: muted)),
        ])),
        const SizedBox(height: 12),
        _settingTile(Icons.restaurant_outlined, 'База продуктов', '${foods.length} продуктов доступно'),
        _settingTile(Icons.save_outlined, 'Локальное хранение', 'Дневник сохраняется на устройстве'),
      ]);

  Widget _header(String title, String subtitle) => Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: ink)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: muted, fontWeight: FontWeight.w600))])),
        IconButton(onPressed: () => setState(() => tab = 4), icon: const Icon(Icons.person_outline_rounded, color: ink)),
      ]);

  Widget _statCard(IconData icon, String label, String value, VoidCallback? onTap) => Expanded(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: _surfaceCard(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: greenDark), const SizedBox(height: 7), Text(label, style: const TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w700)), const SizedBox(height: 2), Text(value, style: const TextStyle(fontWeight: FontWeight.w900, color: ink))])));

  Widget _settingTile(IconData icon, String title, String subtitle) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _surfaceCard(ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundColor: mint, child: Icon(icon, color: greenDark)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: ink)), subtitle: Text(subtitle, style: const TextStyle(color: muted)))));

  Widget _surfaceCard(Widget child) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: line)), child: child);
  Widget _darkCard(Widget child) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: const Color(0xFF203129), borderRadius: BorderRadius.circular(22)), child: child);
  ButtonStyle _outlineButton() => OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: Colors.white, side: const BorderSide(color: line), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)));
  String _fmt(double n) => n.round().toString();

  Future<void> _addFood() async {
    String query = '';
    String selectedMeal = 'Ужин';
    FoodItem? selected;
    final grams = TextEditingController(text: '100');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: bg,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        final filtered = foods.where((f) => f.name.toLowerCase().contains(query.toLowerCase())).take(20).toList();
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: line, borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 14),
            const Text('Добавить продукт', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: ink)),
            const SizedBox(height: 12),
            TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Поиск продукта'), onChanged: (v) => setSheet(() => query = v)),
            const SizedBox(height: 8),
            SizedBox(height: 190, child: ListView(children: filtered.map((f) => ListTile(selected: selected?.id == f.id, selectedTileColor: mint, title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${f.kcal.round()} ккал · Б ${f.protein} г · К ${f.fiber} г / 100 г'), onTap: () => setSheet(() => selected = f))).toList())),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: grams, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Граммы'))),
              const SizedBox(width: 10),
              Expanded(child: DropdownButtonFormField<String>(value: selectedMeal, decoration: const InputDecoration(labelText: 'Приём'), items: const ['Завтрак', 'Обед', 'Ужин', 'Перекус'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setSheet(() => selectedMeal = v ?? selectedMeal))),
            ]),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: selected == null ? null : () { final g = double.tryParse(grams.text.replaceAll(',', '.')) ?? 100; if (g <= 0) return; setState(() => diary.add(DiaryItem(id: '${DateTime.now().microsecondsSinceEpoch}', meal: selectedMeal, food: selected!, grams: g, time: TimeOfDay.now().format(ctx)))); _persistDiary(); Navigator.pop(ctx); }, icon: const Icon(Icons.check), label: const Text('Добавить в дневник'), style: FilledButton.styleFrom(backgroundColor: green, minimumSize: const Size.fromHeight(52)))),
          ]),
        );
      }),
    );
  }

  Future<void> _editDiaryItem(DiaryItem item) async {
    final controller = TextEditingController(text: item.grams.toStringAsFixed(0));
    await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: Text(item.food.name), content: TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Граммы')), actions: [TextButton(onPressed: () { setState(() => diary.removeWhere((x) => x.id == item.id)); _persistDiary(); Navigator.pop(ctx); }, child: const Text('Удалить', style: TextStyle(color: Colors.red))), FilledButton(onPressed: () { final g = double.tryParse(controller.text.replaceAll(',', '.')); if (g == null || g <= 0) return; final i = diary.indexWhere((x) => x.id == item.id); setState(() => diary[i] = DiaryItem(id: item.id, meal: item.meal, food: item.food, grams: g, time: item.time)); _persistDiary(); Navigator.pop(ctx); }, child: const Text('Сохранить'))]);
  }

  Future<void> _addCustomFood() async {
    final name = TextEditingController();
    final kcal = TextEditingController();
    final proteinC = TextEditingController();
    final fatC = TextEditingController();
    final carbsC = TextEditingController();
    final fiberC = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Свой продукт'), content: SingleChildScrollView(child: Column(children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'Название')), const SizedBox(height: 8), _numField(kcal, 'Ккал / 100 г'), const SizedBox(height: 8), _numField(proteinC, 'Белок / 100 г'), const SizedBox(height: 8), _numField(fatC, 'Жиры / 100 г'), const SizedBox(height: 8), _numField(carbsC, 'Углеводы / 100 г'), const SizedBox(height: 8), _numField(fiberC, 'Клетчатка / 100 г') ])), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Сохранить'))]));
    if (ok != true || name.text.trim().isEmpty) return;
    final f = FoodItem('custom_${DateTime.now().microsecondsSinceEpoch}', name.text.trim(), double.tryParse(kcal.text.replaceAll(',', '.')) ?? 0, double.tryParse(proteinC.text.replaceAll(',', '.')) ?? 0, double.tryParse(fatC.text.replaceAll(',', '.')) ?? 0, double.tryParse(carbsC.text.replaceAll(',', '.')) ?? 0, double.tryParse(fiberC.text.replaceAll(',', '.')) ?? 0);
    setState(() => customFoods.add(f));
    await _persistCustomFoods();
  }

  Widget _numField(TextEditingController c, String label) => TextField(controller: c, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: label));

  Future<void> _addWater() async {
    setState(() => water = (water + .25).clamp(0, 5));
    await _saveDouble('water', water);
  }

  Future<void> _addWeight() async {
    final c = TextEditingController(text: weight.toStringAsFixed(1));
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Добавить вес'), content: TextField(controller: c, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(suffixText: 'кг')), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Сохранить'))]));
    if (ok != true) return;
    final value = double.tryParse(c.text.replaceAll(',', '.'));
    if (value == null || value < 30 || value > 300) return;
    setState(() => weight = value);
    await _saveDouble('weight', value);
  }
}

class FitLifeHome extends StatefulWidget {
  const FitLifeHome({super.key});
  @override
  State<FitLifeHome> createState() => _FitLifeHomeState();
}

class Metric extends StatelessWidget {
  final String label;
  final String value;
  const Metric({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(height: 2), Text(value, style: const TextStyle(color: ink, fontWeight: FontWeight.w900))]));
}

class ProgressLine extends StatelessWidget {
  final String label;
  final double value;
  final String text;
  const ProgressLine({super.key, required this.label, required this.value, required this.text});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 15), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: ink)), Text(text, style: const TextStyle(color: muted, fontWeight: FontWeight.w700))]), const SizedBox(height: 6), ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: value.clamp(0, 1), minHeight: 8, color: green, backgroundColor: mint))]));
}
