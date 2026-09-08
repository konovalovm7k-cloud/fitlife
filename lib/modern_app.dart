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
        ),
        home: const FitLifeHome(),
      );
}

class FitLifeHome extends StatefulWidget {
  const FitLifeHome({super.key});
  @override
  State<FitLifeHome> createState() => _FitLifeHomeState();
}

class _FitLifeHomeState extends State<FitLifeHome> {
  int tab = 0;
  double water = 1.5;
  double weight = 104.2;
  int eaten = 1247;
  int protein = 126;
  int fiber = 21;

  final meals = const <Meal>[
    Meal('Завтрак', '08:30', 420, ['Яйца · 3 шт.', 'Ветчина из индейки · 120 г', 'Яблоко · 100 г']),
    Meal('Обед', '13:10', 610, ['Куриная грудка · 250 г', 'Гречка · 70 г', 'Овощи · 150 г']),
  ];

  int get remaining => (1900 - eaten).clamp(0, 1900);
  int get proteinRemaining => (180 - protein).clamp(0, 180);
  int get fiberRemaining => (30 - fiber).clamp(0, 30);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      water = p.getDouble('water') ?? 1.5;
      weight = p.getDouble('weight') ?? 104.2;
    });
  }

  Future<void> _save(String key, double value) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[_today(), _diary(), _weightPage(), _progress(), _profile()];
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
            _statCard(Icons.water_drop_outlined, 'Вода', '${water.toStringAsFixed(2)} л', _addWater),
            const SizedBox(width: 8),
            _statCard(Icons.monitor_weight_outlined, 'Вес', '${weight.toStringAsFixed(1).replaceAll('.', ',')} кг', _addWeight),
            const SizedBox(width: 8),
            _statCard(Icons.directions_walk_outlined, 'Шаги', '2 840', null),
          ]),
          const SizedBox(height: 20),
          _nextAction(),
          const SizedBox(height: 20),
          const Text('Дневник питания', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: ink)),
          const SizedBox(height: 6),
          ...meals.map(_mealCard),
        ],
      );

  String _dateLabel() {
    const days = ['понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота', 'воскресенье'];
    final d = DateTime.now();
    return '${d.day}.${d.month}.${d.year} · ${days[d.weekday - 1]}';
  }

  Widget _petCard() => _surfaceCard(
        Row(children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: mint, shape: BoxShape.circle),
            child: const Center(child: Text('🐼', style: TextStyle(fontSize: 42))),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Твой помощник', style: TextStyle(color: muted, fontWeight: FontWeight.w600)),
              SizedBox(height: 3),
              Text('Панда на хорошем ходу 💚', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: ink)),
              SizedBox(height: 7),
              Text('Уровень 4 · 680 / 1 000 XP', style: TextStyle(color: greenDark, fontWeight: FontWeight.w800)),
            ]),
          ),
        ]),
      );

  Widget _nextAction() {
    final text = proteinRemaining > 0
        ? 'Добери ещё $proteinRemaining г белка'
        : fiberRemaining > 0
            ? 'Добавь ещё $fiberRemaining г клетчатки'
            : 'Цель на сегодня почти закрыта';
    final sub = remaining > 0
        ? 'AI Chef сможет подобрать ужин под остаток $remaining ккал.'
        : 'Сегодня не нужно ничего компенсировать — просто продолжай обычный режим.';
    return _surfaceCard(
      Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(color: mint, shape: BoxShape.circle),
          child: const Icon(Icons.auto_awesome, color: greenDark),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Следующий шаг', style: TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(text, style: const TextStyle(fontWeight: FontWeight.w900, color: ink)),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(color: muted, fontSize: 12)),
          ]),
        ),
        IconButton(onPressed: _showChefHint, icon: const Icon(Icons.chevron_right_rounded, color: greenDark)),
      ]),
    );
  }

  Widget _diary() => ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
        children: [
          _header('Питание', 'Сегодня'),
          const SizedBox(height: 16),
          _surfaceCard(Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('$eaten ккал', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: ink)),
              const Text('из 1 900', style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: (eaten / 1900).clamp(0, 1), minHeight: 9, color: green, backgroundColor: mint),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Metric(label: 'Б', value: '$protein г'),
              const Metric(label: 'Ж', value: '48 г'),
              const Metric(label: 'У', value: '105 г'),
              Metric(label: 'К', value: '$fiber г'),
            ]),
          ])),
          const SizedBox(height: 10),
          ...meals.map(_mealCard),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addFood,
            icon: const Icon(Icons.add, color: green),
            label: const Text('Добавить приём пищи', style: TextStyle(color: ink, fontWeight: FontWeight.w800)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: Colors.white,
              side: const BorderSide(color: line),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ],
      );

  Widget _weightPage() => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _header('Вес', 'История и цель'),
          const SizedBox(height: 16),
          _surfaceCard(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${weight.toStringAsFixed(1).replaceAll('.', ',')} кг', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: ink)),
            const SizedBox(height: 5),
            const Text('Цель · 85 кг', style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 22),
            LinearProgressIndicator(value: ((104.2 - weight) / (104.2 - 85)).clamp(0, 1), minHeight: 10, color: green, backgroundColor: mint),
            const SizedBox(height: 10),
            const Text('Двигаемся к цели постепенно и без резких ограничений.', style: TextStyle(color: greenDark, fontWeight: FontWeight.w700)),
          ])),
          const SizedBox(height: 14),
          _surfaceCard(const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Устойчивая динамика', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink)),
            SizedBox(height: 8),
            Text('FitLife будет ориентироваться на тренд, а не на скачки веса за один день.', style: TextStyle(color: muted, height: 1.4)),
          ])),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _addWeight,
            style: FilledButton.styleFrom(backgroundColor: green, minimumSize: const Size.fromHeight(52)),
            icon: const Icon(Icons.add),
            label: const Text('Добавить вес'),
          ),
        ],
      );

  Widget _progress() => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _header('Прогресс', 'Твои привычки'),
          const SizedBox(height: 16),
          _surfaceCard(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Главное — устойчивость', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: ink)),
            const SizedBox(height: 6),
            const Text('Один сложный день не отменяет прогресс.', style: TextStyle(color: muted)),
            const SizedBox(height: 20),
            const ProgressLine(label: 'Цель по калориям', value: .82, text: '82%'),
            ProgressLine(label: 'Белок', value: 126 / 180, text: '${((126 / 180) * 100).round()}%'),
            ProgressLine(label: 'Клетчатка', value: 21 / 30, text: '${((21 / 30) * 100).round()}%'),
            ProgressLine(label: 'Вода', value: .6, text: '60%'),
          ])),
        ],
      );

  Widget _profile() => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _header('Профиль', 'Настройки FitLife'),
          const SizedBox(height: 16),
          _surfaceCard(const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Моя цель', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink)),
            SizedBox(height: 12),
            Text('Похудение · 85 кг', style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
            SizedBox(height: 18),
            Text('Дневная цель · 1 900 ккал', style: TextStyle(color: ink, fontWeight: FontWeight.w800)),
            SizedBox(height: 6),
            Text('Белок · 160–180 г · Клетчатка · 30 г', style: TextStyle(color: muted)),
          ])),
          const SizedBox(height: 12),
          _settingTile(Icons.person_outline, 'Личные данные', 'Возраст, рост, пол'),
          _settingTile(Icons.flag_outlined, 'Цели', 'Вес и темп похудения'),
          _settingTile(Icons.notifications_none_rounded, 'Напоминания', 'Вода и питание'),
        ],
      );

  Widget _header(String title, String subtitle) => Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: ink)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: muted, fontWeight: FontWeight.w600)),
          ]),
        ),
        IconButton(onPressed: () => setState(() => tab = 4), icon: const Icon(Icons.person_outline_rounded, color: ink)),
      ]);

  Widget _calorieCard() => _darkCard(
        Row(children: [
          SizedBox(
            width: 112,
            height: 112,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(value: (eaten / 1900).clamp(0, 1), strokeWidth: 10, color: const Color(0xFF7BE0A8), backgroundColor: const Color(0x334A5A50)),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('$remaining', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Colors.white)),
                const Text('осталось', style: TextStyle(color: Colors.white60)),
              ]),
            ]),
          ),
          const SizedBox(width: 18),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Дневная цель', style: TextStyle(color: Colors.white60)),
            const SizedBox(height: 4),
            const Text('1 900 ккал', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 10),
            Text('$eaten ккал съедено', style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 3),
            const Text('без наказаний и компенсаций', style: TextStyle(color: Colors.white60, fontSize: 12)),
          ])),
        ]),
      );

  Widget _macroCard() => _surfaceCard(Column(children: [
        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Баланс БЖУ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: ink)),
          Text('цель · белок 160–180 г', style: TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 14),
        MacroBar(label: 'Белок', value: 126, max: 180, suffix: 'г'),
        const MacroBar(label: 'Жиры', value: 48, max: 65, suffix: 'г'),
        const MacroBar(label: 'Углеводы', value: 105, max: 220, suffix: 'г'),
        MacroBar(label: 'Клетчатка', value: 21, max: 30, suffix: 'г'),
      ]));

  Widget _statCard(IconData icon, String title, String value, VoidCallback? action) => Expanded(
        child: InkWell(
          onTap: action,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: line)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, size: 20, color: greenDark),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontSize: 11, color: muted)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: ink)),
            ]),
          ),
        ),
      );

  Widget _mealCard(Meal meal) => Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: line)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 42, height: 42, decoration: const BoxDecoration(color: mint, shape: BoxShape.circle), child: const Icon(Icons.restaurant_rounded, color: greenDark)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(meal.name, style: const TextStyle(fontWeight: FontWeight.w900, color: ink)),
              Text('${meal.kcal} ккал', style: const TextStyle(fontWeight: FontWeight.w900, color: greenDark)),
            ]),
            const SizedBox(height: 4),
            Text('${meal.time} · ${meal.foods.join(', ')}', style: const TextStyle(fontSize: 12, color: muted, height: 1.35)),
          ])),
        ]),
      );

  Widget _surfaceCard(Widget child) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: line)),
        child: child,
      );

  Widget _darkCard(Widget child) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: const Color(0xFF20352B), borderRadius: BorderRadius.circular(22)),
        child: child,
      );

  Widget _settingTile(IconData icon, String title, String subtitle) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: line)),
        child: Row(children: [
          Icon(icon, color: greenDark),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: ink)),
            Text(subtitle, style: const TextStyle(color: muted, fontSize: 12)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: muted),
        ]),
      );

  Future<void> _addWater() async {
    final next = (water + .25).clamp(0, 3).toDouble();
    setState(() => water = next);
    await _save('water', next);
  }

  void _addFood() => showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Align(alignment: Alignment.centerLeft, child: Text('Добавить еду', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: ink))),
              const SizedBox(height: 14),
              _actionTile(Icons.camera_alt_outlined, 'Фото еды', 'AI оценит блюдо и попросит подтвердить важное'),
              _actionTile(Icons.search, 'Поиск продукта', 'Найти продукт и указать граммы'),
              _actionTile(Icons.flash_on_outlined, 'Быстрый ввод', 'Добавить калории и БЖУ вручную'),
              _actionTile(Icons.auto_awesome, 'AI Chef', 'Подобрать следующий приём пищи под остаток'),
            ]),
          ),
        ),
      );

  Widget _actionTile(IconData icon, String title, String subtitle) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(width: 46, height: 46, decoration: const BoxDecoration(color: mint, shape: BoxShape.circle), child: Icon(icon, color: greenDark)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: ink)),
        subtitle: Text(subtitle, style: const TextStyle(color: muted, fontSize: 12)),
        onTap: () => Navigator.pop(context),
      );

  void _addWeight() {
    final controller = TextEditingController(text: weight.toStringAsFixed(1));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Добавить вес'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Вес, кг', suffixText: 'кг'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text.replaceAll(',', '.'));
              if (value == null || value < 30 || value > 300) return;
              setState(() => weight = value);
              _save('weight', value);
              Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showChefHint() => showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (_) => const SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AI Chef', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: ink)),
              SizedBox(height: 8),
              Text('В следующей версии здесь появится подбор блюд по остаткам калорий и БЖУ, продуктам дома и способу приготовления.', style: TextStyle(color: muted, height: 1.45)),
              SizedBox(height: 14),
              Text('Приоритет: аэрогриль → запекание → варка → пар. Без лишнего масла.', style: TextStyle(fontWeight: FontWeight.w800, color: greenDark)),
            ]),
          ),
        ),
      );
}

class Meal {
  final String name;
  final String time;
  final int kcal;
  final List<String> foods;
  const Meal(this.name, this.time, this.kcal, this.foods);
}

class Metric extends StatelessWidget {
  final String label;
  final String value;
  const Metric({required this.label, required this.value, super.key});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(label, style: const TextStyle(fontSize: 12, color: muted)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, color: ink)),
        ]),
      );
}

class MacroBar extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final String suffix;
  const MacroBar({required this.label, required this.value, required this.max, required this.suffix, super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          SizedBox(width: 82, child: Text(label, style: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w700))),
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: (value / max).clamp(0, 1), minHeight: 8, color: green, backgroundColor: mint))),
          const SizedBox(width: 10),
          SizedBox(width: 48, child: Text('$value$suffix', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w900, color: ink, fontSize: 12))),
        ]),
      );
}

class ProgressLine extends StatelessWidget {
  final String label;
  final double value;
  final String text;
  const ProgressLine({required this.label, required this.value, required this.text, super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: ink)), Text(text, style: const TextStyle(fontWeight: FontWeight.w900, color: greenDark))]),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: value.clamp(0, 1), minHeight: 8, color: green, backgroundColor: mint)),
        ]),
      );
}
