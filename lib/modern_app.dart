import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitLife',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(seedColor: green),
      ),
      home: const FitLifeHome(),
    );
  }
}

class FitLifeHome extends StatefulWidget {
  const FitLifeHome({super.key});

  @override
  State<FitLifeHome> createState() => _FitLifeHomeState();
}

class _FitLifeHomeState extends State<FitLifeHome> {
  int tab = 0;
  double water = 1.5;

  final meals = const <Meal>[
    Meal(
      name: 'Завтрак',
      time: '08:30',
      kcal: 420,
      foods: <String>[
        'Яйца · 3 шт.',
        'Ветчина из индейки · 120 г',
        'Яблоко · 100 г',
      ],
    ),
    Meal(
      name: 'Обед',
      time: '13:10',
      kcal: 610,
      foods: <String>[
        'Куриная грудка · 250 г',
        'Гречка · 70 г',
        'Овощи · 150 г',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _today(),
      _diary(),
      _weight(),
      _progress(),
      _profile(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        backgroundColor: Colors.white,
        indicatorColor: mint,
        onDestinationSelected: (index) => setState(() => tab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Сегодня',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu_rounded),
            label: 'Питание',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_weight_outlined),
            selectedIcon: Icon(Icons.monitor_weight_rounded),
            label: 'Вес',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Прогресс',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Профиль',
          ),
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

  Widget _today() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
      children: <Widget>[
        _header('Сегодня', '6 сентября · воскресенье'),
        const SizedBox(height: 16),
        _dateStrip(),
        const SizedBox(height: 16),
        _calorieCard(),
        const SizedBox(height: 14),
        _macroCard(),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            _statCard(
              Icons.water_drop_outlined,
              'Вода',
              '${water.toStringAsFixed(1)} л',
              () => setState(() => water = (water + 0.25).clamp(0, 3)),
            ),
            const SizedBox(width: 10),
            _statCard(Icons.monitor_weight_outlined, 'Вес', '104,2 кг', null),
            const SizedBox(width: 10),
            _statCard(Icons.directions_walk_outlined, 'Шаги', '2 840', null),
          ],
        ),
        const SizedBox(height: 22),
        const Text(
          'Дневник питания',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: ink),
        ),
        const SizedBox(height: 4),
        ...meals.map(_mealCard),
      ],
    );
  }

  Widget _diary() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
      children: <Widget>[
        _header('Питание', 'Сегодня · 6 сентября'),
        const SizedBox(height: 16),
        _surfaceCard(
          Column(
            children: <Widget>[
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('1 247 ккал', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: ink)),
                  Text('из 1 900', style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                child: const LinearProgressIndicator(
                  value: 0.656,
                  minHeight: 9,
                  color: green,
                  backgroundColor: mint,
                ),
              ),
              const SizedBox(height: 14),
              const Row(
                children: <Widget>[
                  Metric(label: 'Б', value: '126 г'),
                  Metric(label: 'Ж', value: '48 г'),
                  Metric(label: 'У', value: '105 г'),
                  Metric(label: 'К', value: '21 г'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...meals.map(_mealCard),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _addFood,
          icon: const Icon(Icons.add, color: green),
          label: const Text(
            'Добавить приём пищи',
            style: TextStyle(color: ink, fontWeight: FontWeight.w800),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            backgroundColor: Colors.white,
            side: const BorderSide(color: line),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
        const SizedBox(height: 12),
        _surfaceCard(
          const Row(
            children: <Widget>[
              Icon(Icons.auto_awesome, color: green),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Совет FitLife\nБелка осталось немного — хороший ужин поможет закрыть цель.',
                  style: TextStyle(color: ink, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _weight() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        _header('Вес', 'История и цель'),
        const SizedBox(height: 16),
        _surfaceCard(
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('104,2 кг', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: ink)),
              SizedBox(height: 5),
              Text('Цель · 85 кг', style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
              SizedBox(height: 22),
              LinearProgressIndicator(value: 0.23, minHeight: 10, color: green, backgroundColor: mint),
              SizedBox(height: 10),
              Text('Прогресс к цели · 23%', style: TextStyle(color: greenDark, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _surfaceCard(
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Динамика веса', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink)),
              SizedBox(height: 22),
              Text('104,2 ───╮\n        ╰──╮\n           ╰──── 85 кг', style: TextStyle(fontSize: 18, height: 1.6, fontWeight: FontWeight.w800, color: ink)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _addWeight,
          style: FilledButton.styleFrom(backgroundColor: green, minimumSize: const Size.fromHeight(52)),
          icon: const Icon(Icons.add),
          label: const Text('Добавить вес'),
        ),
      ],
    );
  }

  Widget _progress() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        _header('Прогресс', 'Твоя динамика'),
        const SizedBox(height: 16),
        _surfaceCard(
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('За последние 30 дней', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink)),
              SizedBox(height: 18),
              Text('🔥 Отличный темп', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: greenDark)),
              SizedBox(height: 6),
              Text('Продолжай придерживаться плана.', style: TextStyle(color: muted)),
              SizedBox(height: 20),
              ProgressLine(label: 'Цель по калориям', value: 0.82, text: '82%'),
              ProgressLine(label: 'Белок', value: 0.74, text: '74%'),
              ProgressLine(label: 'Вода', value: 0.60, text: '60%'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _profile() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        _header('Профиль', 'Настройки FitLife'),
        const SizedBox(height: 16),
        _surfaceCard(
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Моя цель', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink)),
              SizedBox(height: 12),
              Text('Похудение · 85 кг', style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
              SizedBox(height: 18),
              Text('Дневная цель · 1 900 ккал', style: TextStyle(color: ink, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _settingTile(Icons.person_outline, 'Личные данные', 'Возраст, рост, пол'),
        _settingTile(Icons.flag_outlined, 'Цели', 'Вес и темп похудения'),
        _settingTile(Icons.notifications_none_rounded, 'Напоминания', 'Вода и питание'),
      ],
    );
  }

  Widget _header(String title, String subtitle) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: ink)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: muted, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        IconButton(
          onPressed: () => setState(() => tab = 4),
          icon: const Icon(Icons.person_outline_rounded, color: ink),
        ),
      ],
    );
  }

  Widget _dateStrip() {
    const days = <String>['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];
    const numbers = <String>['31', '1', '2', '3', '4', '5', '6'];

    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final active = index == days.length - 1;
          return Container(
            width: 52,
            decoration: BoxDecoration(
              color: active ? green : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: active ? green : line),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(days[index], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: active ? Colors.white70 : muted)),
                Text(numbers[index], style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: active ? Colors.white : ink)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _calorieCard() {
    return _darkCard(
      Row(
        children: <Widget>[
          SizedBox(
            width: 118,
            height: 118,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                const SizedBox(
                  width: 118,
                  height: 118,
                  child: CircularProgressIndicator(
                    value: 0.656,
                    strokeWidth: 10,
                    color: Color(0xFF7BE0A8),
                    backgroundColor: Color(0x334A5A50),
                  ),
                ),
                const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('1 247', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: Colors.white)),
                    Text('ккал', style: TextStyle(color: Colors.white60)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Дневная цель', style: TextStyle(color: Colors.white60)),
                SizedBox(height: 4),
                Text('1 900 ккал', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                SizedBox(height: 12),
                Text('653', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: Color(0xFF7BE0A8))),
                Text('осталось сегодня', style: TextStyle(color: Colors.white60)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroCard() {
    return _surfaceCard(
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Баланс макросов', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink)),
          SizedBox(height: 14),
          MacroBar(label: 'Белки', value: '126 / 170 г', progress: 0.74, color: green),
          MacroBar(label: 'Жиры', value: '48 / 60 г', progress: 0.80, color: Color(0xFFE2A53D)),
          MacroBar(label: 'Углеводы', value: '105 / 180 г', progress: 0.58, color: Color(0xFF718DDA)),
          SizedBox(height: 10),
          Row(
            children: <Widget>[
              Icon(Icons.eco_outlined, size: 19, color: green),
              SizedBox(width: 7),
              Text('Клетчатка', style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
              Spacer(),
              Text('21 / 30 г', style: TextStyle(fontWeight: FontWeight.w900, color: ink)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String title, String value, VoidCallback? onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: _surfaceCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, color: green),
              const SizedBox(height: 7),
              Text(title, style: const TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.w700)),
              Text(value, style: const TextStyle(fontSize: 15, color: ink, fontWeight: FontWeight.w900)),
            ],
          ),
          padding: const EdgeInsets.all(14),
        ),
      ),
    );
  }

  Widget _mealCard(Meal meal) {
    final breakfast = meal.name == 'Завтрак';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: _surfaceCard(
        Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: mint, borderRadius: BorderRadius.circular(14)),
                  child: Icon(breakfast ? Icons.free_breakfast_outlined : Icons.lunch_dining_outlined, color: greenDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(meal.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: ink)),
                      Text(meal.time, style: const TextStyle(fontSize: 11, color: muted)),
                    ],
                  ),
                ),
                Text('${meal.kcal} ккал', style: const TextStyle(fontWeight: FontWeight.w900, color: greenDark)),
              ],
            ),
            const SizedBox(height: 10),
            ...meal.foods.map(
              (food) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.circle, size: 5, color: muted),
                    const SizedBox(width: 8),
                    Expanded(child: Text(food, style: const TextStyle(color: muted, fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _surfaceCard(Widget child, {EdgeInsets padding = const EdgeInsets.all(18)}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: line),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x10000000), blurRadius: 14, offset: Offset(0, 5)),
        ],
      ),
      child: child,
    );
  }

  Widget _darkCard(Widget child) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }

  Widget _settingTile(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _surfaceCard(
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: mint,
            foregroundColor: greenDark,
            child: Icon(icon),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: ink)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }

  void _addFood() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('Добавить еду', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
                const SizedBox(height: 18),
                ListTile(
                  leading: const Icon(Icons.search, color: green),
                  title: const Text('Найти продукт'),
                  onTap: () => Navigator.pop(sheetContext),
                ),
                ListTile(
                  leading: const Icon(Icons.qr_code_scanner, color: green),
                  title: const Text('Сканировать штрихкод'),
                  onTap: () => Navigator.pop(sheetContext),
                ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: green),
                  title: const Text('Создать свой продукт'),
                  onTap: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addWeight() {
    final controller = TextEditingController(text: '104.2');
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Добавить вес'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Вес, кг'),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Отмена')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Сохранить')),
          ],
        );
      },
    ).then((_) => controller.dispose());
  }
}

class Meal {
  const Meal({required this.name, required this.time, required this.kcal, required this.foods});

  final String name;
  final String time;
  final int kcal;
  final List<String> foods;
}

class Metric extends StatelessWidget {
  const Metric({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: const TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 15, color: ink, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class MacroBar extends StatelessWidget {
  const MacroBar({super.key, required this.label, required this.value, required this.progress, required this.color});

  final String label;
  final String value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(label, style: const TextStyle(color: muted, fontWeight: FontWeight.w700)),
              Text(value, style: const TextStyle(color: ink, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: progress, minHeight: 7, color: color, backgroundColor: line),
          ),
        ],
      ),
    );
  }
}

class ProgressLine extends StatelessWidget {
  const ProgressLine({super.key, required this.label, required this.value, required this.text});

  final String label;
  final double value;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: muted)),
              Text(text, style: const TextStyle(fontWeight: FontWeight.w900, color: ink)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: value, minHeight: 8, color: green, backgroundColor: mint),
          ),
        ],
      ),
    );
  }
}
