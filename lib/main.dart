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
  Food('Овсянка', 370, 13, 6.5, 62),
  Food('Творог 5%', 121, 17.2, 5, 1.8),
  Food('Рис варёный', 130, 2.7, 0.3, 28.2),
  Food('Яблоко', 52, 0.3, 0.2, 13.8),
  Food('Банан', 89, 1.1, 0.3, 22.8),
  Food('Красный перец', 31, 1, 0.3, 6),
  Food('Лосось', 208, 20.4, 13.4, 0),
];

void main() => runApp(const FitLife());

class FitLife extends StatelessWidget {
  const FitLife({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'FitLife',
    theme: ThemeData(useMaterial3: true, brightness: Brightness.dark, scaffoldBackgroundColor: bg, colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark)),
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
  bool loading = true;
  bool onboard = true;
  double weight = 92.4, start = 92.4, goal = 85;
  int age = 35, height = 178, water = 0;
  String sex = 'Мужской';
  double activity = 1.45;
  int kcalGoal = 2000, pGoal = 150, fGoal = 67, cGoal = 200;
  String dayKey = '';
  List<Map<String, dynamic>> meals = [], history = [], customFoods = [];

  String get todayKey { final d = DateTime.now(); return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}'; }

  int get kcal => meals.fold(0, (s, x) => s + ((x['kcal'] as num?)?.round() ?? 0));
  int get protein => meals.fold(0, (s, x) => s + ((x['p'] as num?)?.round() ?? 0));
  int get fat => meals.fold(0, (s, x) => s + ((x['f'] as num?)?.round() ?? 0));
  int get carbs => meals.fold(0, (s, x) => s + ((x['c'] as num?)?.round() ?? 0));

  @override
  void initState() { super.initState(); _load(); }

  List<Map<String, dynamic>> _decode(String? s) {
    if (s == null || s.isEmpty) return [];
    try { return List<Map<String, dynamic>>.from(jsonDecode(s)); } catch (_) { return []; }
  }

  Future<void> _load() async {
    final s = await SharedPreferences.getInstance();
    onboard = s.getBool('onboard') ?? true;
    weight = s.getDouble('weight') ?? weight; start = s.getDouble('start') ?? weight; goal = s.getDouble('goal') ?? goal;
    age = s.getInt('age') ?? age; height = s.getInt('height') ?? height; sex = s.getString('sex') ?? sex; activity = s.getDouble('activity') ?? activity;
    water = s.getInt('water') ?? 0; history = _decode(s.getString('history')); customFoods = _decode(s.getString('custom'));
    dayKey = s.getString('dayKey') ?? todayKey; meals = dayKey == todayKey ? _decode(s.getString('meals')) : [];
    dayKey = todayKey; _calc();
    if (mounted) setState(() => loading = false);
    await _save();
  }

  void _calc() {
    final bmr = sex == 'Мужской' ? 10 * weight + 6.25 * height - 5 * age + 5 : 10 * weight + 6.25 * height - 5 * age - 161;
    kcalGoal = math.max(1200, (bmr * activity - 450).round());
    pGoal = math.max(90, (weight * 1.6).round());
    fGoal = math.max(35, (kcalGoal * .30 / 9).round());
    cGoal = math.max(80, ((kcalGoal - pGoal * 4 - fGoal * 9) / 4).round());
  }

  Future<void> _save() async {
    final s = await SharedPreferences.getInstance();
    await s.setBool('onboard', onboard); await s.setDouble('weight', weight); await s.setDouble('start', start); await s.setDouble('goal', goal);
    await s.setInt('age', age); await s.setInt('height', height); await s.setString('sex', sex); await s.setDouble('activity', activity); await s.setInt('water', water);
    await s.setString('dayKey', dayKey); await s.setString('meals', jsonEncode(meals)); await s.setString('history', jsonEncode(history)); await s.setString('custom', jsonEncode(customFoods));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (onboard) return Scaffold(body: SafeArea(child: Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.monitor_weight, size: 80, color: accent), const SizedBox(height: 16), const Text('FitLife', style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12), const Text('Умный дневник похудения', style: TextStyle(fontSize: 20)), const SizedBox(height: 30),
      SizedBox(width: double.infinity, child: FilledButton(onPressed: () async { await _profile(); if (mounted) setState(() => onboard = false); await _save(); }, child: const Text('Начать'))),
    ]))));
    final pages = [_home(), _food(), _weightPage(), _stats(), _profilePage()];
    return Scaffold(body: SafeArea(child: pages[tab]), bottomNavigationBar: NavigationBar(backgroundColor: card, selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), destinations: const [
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Главная'),
      NavigationDestination(icon: Icon(Icons.restaurant_outlined), selectedIcon: Icon(Icons.restaurant), label: 'Питание'),
      NavigationDestination(icon: Icon(Icons.monitor_weight_outlined), selectedIcon: Icon(Icons.monitor_weight), label: 'Вес'),
      NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Статистика'),
      NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Профиль'),
    ]));
  }

  Widget _card(Widget child) => Card(color: card, child: Padding(padding: const EdgeInsets.all(16), child: child));
  Widget _home() { final progress = start == goal ? 1.0 : ((start - weight) / (start - goal)).clamp(0.0, 1.0); return ListView(padding: const EdgeInsets.all(16), children: [
    Text('Сегодня', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 12),
    _card(Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${weight.toStringAsFixed(1)} кг'), Text('Цель ${goal.toStringAsFixed(1)} кг')]), const SizedBox(height: 12), LinearProgressIndicator(value: progress, minHeight: 8), const SizedBox(height: 8), Text('${(progress * 100).round()}% пути к цели')])),
    _nutrition(), Row(children: [Expanded(child: _quick('Вода', '$water / 2500 мл', Icons.water_drop, () { setState(() => water = math.min(3000, water + 250)); _save(); })), const SizedBox(width: 10), Expanded(child: _quick('Вес', 'Записать', Icons.monitor_weight, _addWeight))]),
    _card(ListTile(leading: const Icon(Icons.auto_awesome), title: const Text('Авторасчёт'), subtitle: Text('$kcalGoal ккал • Б $pGoal г • Ж $fGoal г • У $cGoal г'))),
  ]); }

  Widget _nutrition() => _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Калории'), Text('$kcal / $kcalGoal ккал', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)), const SizedBox(height: 8), LinearProgressIndicator(value: (kcal / math.max(1, kcalGoal)).clamp(0.0, 1.0), minHeight: 8), const SizedBox(height: 12), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Б $protein/$pGoal г'), Text('Ж $fat/$fGoal г'), Text('У $carbs/$cGoal г')])]));
  Widget _quick(String a, String b, IconData i, VoidCallback f) => Card(color: card, child: InkWell(onTap: f, child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [Icon(i), Text(a), Text(b, style: const TextStyle(fontWeight: FontWeight.bold))]))));

  Widget _food() => ListView(padding: const EdgeInsets.all(16), children: [Text('Питание', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)), _nutrition(), ...meals.asMap().entries.map((e) => _card(ListTile(title: Text(e.value['name']), subtitle: Text('${e.value['grams']} г'), trailing: Text('${e.value['kcal']} ккал'), onLongPress: () { setState(() => meals.removeAt(e.key)); _save(); }))), FilledButton.icon(onPressed: _addFoodDialog, icon: const Icon(Icons.add), label: const Text('Добавить продукт'))]);

  Future<void> _addFoodDialog() async { final q = TextEditingController(); final grams = TextEditingController(text: '100'); await showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, set) { final all = [...foods, ...customFoods.map((x) => Food(x['name'], (x['kcal'] as num).round(), (x['p'] as num).toDouble(), (x['f'] as num).toDouble(), (x['c'] as num).toDouble()))]; final shown = all.where((x) => x.name.toLowerCase().contains(q.text.toLowerCase())).toList(); return AlertDialog(title: const Text('Добавить продукт'), content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: q, onChanged: (_) => set(() {}), decoration: const InputDecoration(labelText: 'Поиск')), TextField(controller: grams, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Граммы')), SizedBox(height: 280, child: ListView(children: shown.map((x) => ListTile(title: Text(x.name), subtitle: Text('${x.kcal} ккал / 100 г'), onTap: () { final g = double.tryParse(grams.text.replaceAll(',', '.')) ?? 100; final k = g / 100; setState(() => meals.add({'name': x.name, 'grams': g.round(), 'kcal': (x.kcal*k).round(), 'p': (x.p*k).round(), 'f': (x.f*k).round(), 'c': (x.c*k).round()})); Navigator.pop(ctx); _save(); })).toList()))])))); }); }

  Widget _weightPage() => ListView(padding: const EdgeInsets.all(16), children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Вес', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)), IconButton(onPressed: _addWeight, icon: const Icon(Icons.add_circle))]), _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${weight.toStringAsFixed(1)} кг', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)), Text('Цель ${goal.toStringAsFixed(1)} кг'), const SizedBox(height: 16), SizedBox(height: 220, child: history.length < 2 ? const Center(child: Text('Добавьте минимум 2 измерения')) : CustomPaint(painter: ChartPainter(history.map((e) => (e['weight'] as num).toDouble()).toList())))])), ...history.reversed.map((x) => ListTile(title: Text('${x['weight']} кг'), trailing: Text(x['date'])))]);

  Future<void> _addWeight() async { final c = TextEditingController(text: weight.toStringAsFixed(1)); final v = await showDialog<double>(context: context, builder: (ctx) => AlertDialog(title: const Text('Записать вес'), content: TextField(controller: c, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'кг')), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')), FilledButton(onPressed: () => Navigator.pop(ctx, double.tryParse(c.text.replaceAll(',', '.'))), child: const Text('Сохранить'))])); if (v == null || v <= 0) return; final d = DateTime.now(); setState(() { weight = v; history.add({'weight': v, 'date': '${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year}'}); if (history.length > 90) history.removeAt(0); _calc(); }); await _save(); }

  Widget _stats() => ListView(padding: const EdgeInsets.all(16), children: [Text('Статистика', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)), _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Прогресс веса'), const SizedBox(height: 12), Text('${start.toStringAsFixed(1)} → ${weight.toStringAsFixed(1)} → ${goal.toStringAsFixed(1)} кг'), const SizedBox(height: 12), SizedBox(height: 220, child: history.length < 2 ? const Center(child: Text('Нужно минимум 2 измерения')) : CustomPaint(painter: ChartPainter(history.map((e) => (e['weight'] as num).toDouble()).toList())))])), _card(Text('Сегодня: $kcal ккал • Б $protein г • Ж $fat г • У $carbs г'))]);

  Widget _profilePage() => ListView(padding: const EdgeInsets.all(16), children: [Text('Профиль', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)), _card(Column(children: [ListTile(title: const Text('Пол'), trailing: Text(sex)), ListTile(title: const Text('Возраст'), trailing: Text('$age лет')), ListTile(title: const Text('Рост'), trailing: Text('$height см')), ListTile(title: const Text('Вес'), trailing: Text('${weight.toStringAsFixed(1)} кг')), ListTile(title: const Text('Цель'), trailing: Text('${goal.toStringAsFixed(1)} кг')), ListTile(title: const Text('Активность'), trailing: Text(_activityName())), FilledButton.icon(onPressed: _profile, icon: const Icon(Icons.edit), label: const Text('Изменить'))]))]);

  String _activityName() => {1.2:'Минимальная',1.375:'Низкая',1.45:'Умеренная',1.65:'Высокая',1.8:'Очень высокая'}[activity] ?? 'Умеренная';

  Future<void> _profile() async { final w = TextEditingController(text: weight.toStringAsFixed(1)); final g = TextEditingController(text: goal.toStringAsFixed(1)); final h = TextEditingController(text: height.toString()); final a = TextEditingController(text: age.toString()); String sx = sex; double act = activity; final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx,set) => AlertDialog(title: const Text('Профиль'), content: SingleChildScrollView(child: Column(children: [DropdownButtonFormField<String>(value:sx, items: const [DropdownMenuItem(value:'Мужской',child:Text('Мужской')),DropdownMenuItem(value:'Женский',child:Text('Женский'))], onChanged:(v)=>set(()=>sx=v??sx), decoration:const InputDecoration(labelText:'Пол')), TextField(controller:a,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Возраст')), TextField(controller:h,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Рост, см')), TextField(controller:w,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Вес, кг')), TextField(controller:g,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Цель, кг')), DropdownButtonFormField<double>(value:act,items:const [DropdownMenuItem(value:1.2,child:Text('Минимальная')),DropdownMenuItem(value:1.375,child:Text('Низкая')),DropdownMenuItem(value:1.45,child:Text('Умеренная')),DropdownMenuItem(value:1.65,child:Text('Высокая')),DropdownMenuItem(value:1.8,child:Text('Очень высокая'))],onChanged:(v)=>set(()=>act=v??act),decoration:const InputDecoration(labelText:'Активность'))])), actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Отмена')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Сохранить'))] ))); if(ok!=true)return; final nw=double.tryParse(w.text.replaceAll(',','.')); final ng=double.tryParse(g.text.replaceAll(',','.')); final na=int.tryParse(a.text); final nh=int.tryParse(h.text); if(nw==null||ng==null||na==null||nh==null||nw<=0||ng<=0||na<12||nh<100)return; setState(()=>{weight=nw;goal=ng;age=na;height=nh;sex=sx;activity=act;if(start<=0)start=nw;_calc();}); await _save(); }
}

class ChartPainter extends CustomPainter {
  final List<double> values;
  ChartPainter(this.values);
  @override
  void paint(Canvas canvas, Size size) { if(values.length<2)return; final minV=values.reduce(math.min), maxV=values.reduce(math.max); final range=math.max(.5,maxV-minV); final paint=Paint()..color=accent..strokeWidth=3..style=PaintingStyle.stroke; final path=Path(); for(var i=0;i<values.length;i++){final x=i*size.width/(values.length-1);final y=size.height-10-((values[i]-minV)/range)*(size.height-20);if(i==0)path.moveTo(x,y);else path.lineTo(x,y);canvas.drawCircle(Offset(x,y),4,Paint()..color=accent);} canvas.drawPath(path,paint); }
  @override
  bool shouldRepaint(covariant ChartPainter oldDelegate)=>oldDelegate.values!=values;
}
