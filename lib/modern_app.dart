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
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FitLife',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: bg,
          colorScheme: ColorScheme.fromSeed(seedColor: green),
          fontFamily: 'Roboto',
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

  final meals = const [
    Meal('Завтрак', '08:30', 420, ['Яйца · 3 шт.', 'Ветчина из индейки · 120 г', 'Яблоко · 100 г']),
    Meal('Обед', '13:10', 610, ['Куриная грудка · 250 г', 'Гречка · 70 г', 'Овощи · 150 г']),
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
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Сегодня'),
          NavigationDestination(icon: Icon(Icons.restaurant_menu_outlined), selectedIcon: Icon(Icons.restaurant_menu_rounded), label: 'Питание'),
          NavigationDestination(icon: Icon(Icons.monitor_weight_outlined), selectedIcon: Icon(Icons.monitor_weight_rounded), label: 'Вес'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights_rounded), label: 'Прогресс'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Профиль'),
        ],
      ),
      floatingActionButton: (tab == 0 || tab == 1)
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
          _header('Сегодня', '6 сентября · воскресенье'),
          const SizedBox(height: 14),
          _dates(),
          const SizedBox(height: 16),
          _calories(),
          const SizedBox(height: 14),
          _macros(),
          const SizedBox(height: 12),
          Row(children: [
            _stat(Icons.water_drop_outlined, 'Вода', '${water.toStringAsFixed(1)} л', () => setState(() => water = (water + .25).clamp(0, 3))),
            const SizedBox(width: 10),
            _stat(Icons.monitor_weight_outlined, 'Вес', '104,2 кг', null),
            const SizedBox(width: 10),
            _stat(Icons.directions_walk_outlined, 'Шаги', '2 840', null),
          ]),
          const SizedBox(height: 20),
          const Text('Дневник питания', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: ink)),
          const SizedBox(height: 4),
          ...meals.map(_meal),
        ],
      );

  Widget _diary() => ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
        children: [
          _header('Питание', 'Сегодня · 6 сентября'),
          const SizedBox(height: 16),
          _card(Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
              Text('1 247 ккал', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: ink)),
              Text('из 1 900', style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 12),
            ClipRRect(borderRadius: BorderRadius.circular(8), child: const LinearProgressIndicator(value: .656, minHeight: 9, color: green, backgroundColor: mint)),
            const SizedBox(height: 14),
            const Row(children: [Metric('Б', '126 г'), Metric('Ж', '48 г'), Metric('У', '105 г'), Metric('К', '21 г')]),
          ])),
          const SizedBox(height: 10),
          ...meals.map(_meal),
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
          const SizedBox(height: 12),
          _card(const Row(children: [
            Icon(Icons.auto_awesome, color: green),
            SizedBox(width: 10),
            Expanded(child: Text('Совет FitLife\nБелка осталось немного — хороший ужин поможет закрыть цель.', style: TextStyle(color: ink, fontWeight: FontWeight.w700))),
          ])),
        ],
      );

  Widget _weight() => ListView(padding: const EdgeInsets.all(20), children: [
        _header('Вес', 'История и цель'),
        const SizedBox(height: 16),
        _card(const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('104,2 кг', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: ink)),
          SizedBox(height: 5),
          Text('Цель · 85 кг', style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
          SizedBox(height: 22),
          LinearProgressIndicator(value: .23, minHeight: 10, color: green, backgroundColor: mint),
          SizedBox(height: 10),
          Text('Прогресс к цели · 23%', style: TextStyle(color: greenDark, fontWeight: FontWeight.w800)),
        ])),
        const SizedBox(height: 14),
        _card(const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Динамика веса', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink)),
          SizedBox(height: 22),
          Text('104,2 ───╮\n        ╰──╮\n           ╰──── 85 кг', style: TextStyle(fontSize: 18, height: 1.6, fontWeight: FontWeight.w800, color: ink)),
        ])),
      ]);

  Widget _progress() => ListView(padding: const EdgeInsets.all(20), children: [
        _header('Прогресс', 'Твоя динамика'),
        const SizedBox(height: 16),
        _card(const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('За последние 30 дней', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink)),
          SizedBox(height: 18),
          Text('🔥 Отличный темп', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: greenDark)),
          SizedBox(height: 6),
          Text('Продолжай придерживаться плана.', style: TextStyle(color: muted)),
        ])),
      ]);

  Widget _profile() => ListView(padding: const EdgeInsets.all(20), children: [
        _header('Профиль', 'Настройки FitLife'),
        const SizedBox(height: 16),
        _card(const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Моя цель', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink)),
          SizedBox(height: 12),
          Text('Похудение · 85 кг', style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
          SizedBox(height: 18),
          Text('Дневная цель · 1 900 ккал', style: TextStyle(color: ink, fontWeight: FontWeight.w800)),
        ])),
      ]);

  Widget _header(String title, String subtitle) => Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: ink)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: muted, fontWeight: FontWeight.w600)),
        ])),
        IconButton(onPressed: () => setState(() => tab = 4), icon: const Icon(Icons.person_outline_rounded, color: ink)),
      ]);

  Widget _dates() => SizedBox(
        height: 70,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 7,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final active = i == 6;
            final days = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];
            final numbers = ['31', '1', '2', '3', '4', '5', '6'];
            return Container(
              width: 52,
              decoration: BoxDecoration(color: active ? green : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: active ? green : line)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(days[i], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: active ? Colors.white70 : muted)),
                Text(numbers[i], style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: active ? Colors.white : ink)),
              ]),
            );
          },
        ),
      );

  Widget _calories() => _card(Row(children: [
        SizedBox(width: 120, height: 120, child: Stack(alignment: Alignment.center, children: [
          const SizedBox(width: 120, height: 120, child: CircularProgressIndicator(value: .656, strokeWidth: 10, color: Color(0xFF7BE0A8), backgroundColor: Color(0x334A5A50))),
          const Column(mainAxisSize: MainAxisSize.min, children: [Text('1 247', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: Colors.white)), Text('ккал', style: TextStyle(color: Colors.white60))]),
        ])),
        const SizedBox(width: 18),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Дневная цель', style: TextStyle(color: Colors.white60)),
          SizedBox(height: 4),
          Text('1 900 ккал', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          SizedBox(height: 12),
          Text('653', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: Color(0xFF7BE0A8))),
          Text('осталось сегодня', style: TextStyle(color: Colors.white60)),
        ])),
      ], dark: true);

  Widget _macros() => _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Баланс макросов', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink)),
        const SizedBox(height: 14),
        const Row(children: [Bar('Белки', '126 / 170 г', .74, green), Bar('Жиры', '48 / 60 г', .80, Color(0xFFE2A53D)), Bar('Углеводы', '105 / 180 г', .58, Color(0xFF718DDA))]),
        const SizedBox(height: 14),
        const Row(children: [Icon(Icons.eco_outlined, size: 19, color: green), SizedBox(width: 7), Text('Клетчатка', style: TextStyle(color: muted, fontWeight: FontWeight.w700)), Spacer(), Text('21 / 30 г', style: TextStyle(fontWeight: FontWeight.w900, color: ink))]),
      ]);

  Widget _stat(IconData icon, String title, String value, VoidCallback? onTap) => Expanded(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: green), const SizedBox(height: 7), Text(title, style: const TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.w700)), Text(value, style: const TextStyle(fontSize: 15, color: ink, fontWeight: FontWeight.w900))])));

  Widget _meal(Meal m) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: _card(Column(children: [
        Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: mint, borderRadius: BorderRadius.circular(14)), child: Icon(m.name == 'Завтрак' ? Icons.free_breakfast_outlined : Icons.lunch_dining_outlined, color: greenDark)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(m.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: ink)), Text(m.time, style: const TextStyle(fontSize: 11, color: muted))])),
          Text('${m.kcal} ккал', style: const TextStyle(fontWeight: FontWeight.w900, color: greenDark)),
        ]),
        const SizedBox(height: 10),
        ...m.foods.map((f) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [const Icon(Icons.circle, size: 5, color: muted), const SizedBox(width: 8), Text(f, style: const TextStyle(color: muted, fontWeight: FontWeight.w600))]))),
      ])));

  Widget _card(Widget child, {bool dark = false}) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: dark ? ink : Colors.white, borderRadius: BorderRadius.circular(24), border: dark ? null : Border.all(color: line), boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 14, offset: Offset(0, 5))]), child: child);

  void _addFood() => showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (_) => SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Добавить еду', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
        const SizedBox(height: 18),
        ListTile(leading: const Icon(Icons.search, color: green), title: const Text('Найти продукт'), onTap: () => Navigator.pop(context)),
        ListTile(leading: const Icon(Icons.qr_code_scanner, color: green), title: const Text('Сканировать штрихкод'), onTap: () => Navigator.pop(context)),
        ListTile(leading: const Icon(Icons.edit_outlined, color: green), title: const Text('Создать свой продукт'), onTap: () => Navigator.pop(context)),
      ]))));
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
  const Metric(this.label, this.value, {super.key});
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [Text(value, style: const TextStyle(fontWeight: FontWeight.w900, color: ink)), Text(label, style: const TextStyle(fontSize: 10, color: muted))]));
}

class Bar extends StatelessWidget {
  final String name;
  final String value;
  final double progress;
  final Color color;
  const Bar(this.name, this.value, this.progress, this.color, {super.key});
  @override
  Widget build(BuildContext context) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 9), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.w700)), const SizedBox(height: 6), ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: progress, minHeight: 7, color: color, backgroundColor: line)), const SizedBox(height: 5), Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: ink))])));
}
