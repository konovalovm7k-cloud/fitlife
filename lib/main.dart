
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const bg = Color(0xFF081018);
const card = Color(0xFF121C26);
const accent = Color(0xFF35E56B);

class Food {
  final String name; final int kcal; final double p,f,c;
  const Food(this.name,this.kcal,this.p,this.f,this.c);
}
const foods = [
  Food('Яйцо куриное',143,12.6,9.5,.7),
  Food('Куриная грудка',165,31,3.6,0),
  Food('Индейка, филе',135,29,1.6,0),
  Food('Ветчина из индейки',90,17,2,1),
  Food('Овсянка',370,13,6.5,62),
  Food('Творог 5%',121,17.2,5,1.8),
  Food('Рис варёный',130,2.7,.3,28.2),
  Food('Яблоко',52,.3,.2,13.8),
  Food('Банан',89,1.1,.3,22.8),
  Food('Красный перец',31,1,.3,6),
  Food('Айсберг',14,.9,.1,3),
  Food('Лосось',208,20.4,13.4,0),
];

void main()=>runApp(const FitLife());

class FitLife extends StatelessWidget{
 const FitLife({super.key});
 @override Widget build(BuildContext c)=>MaterialApp(
   debugShowCheckedModeBanner:false,title:'FitLife',
   theme:ThemeData(useMaterial3:true,scaffoldBackgroundColor:bg,
    colorScheme:ColorScheme.fromSeed(seedColor:accent,brightness:Brightness.dark)),
   home:const Shell());
}

class Shell extends StatefulWidget{const Shell({super.key});@override State<Shell> createState()=>_ShellState();}
class _ShellState extends State<Shell>{
 int tab=0; bool first=true;
 double weight=92.4,start=95,goal=85; int age=35,height=178;
 String sex='Мужской'; double activity=1.45;
 int kcal=1420,p=112,f=54,carb=128,water=1800;
 int kcalGoal=2000,pGoal=150,fGoal=67,cGoal=200;
 List<Map<String,dynamic>> meals=[]; List<Map<String,dynamic>> history=[];
 List<Map<String,dynamic>> recipes=[]; List<Map<String,dynamic>> customFoods=[];

 @override void initState(){super.initState();_load();}
 Future<void> _load() async{
  final s=await SharedPreferences.getInstance();
  setState((){
   first=s.getBool('onboard')??true; weight=s.getDouble('weight')??weight;
   start=s.getDouble('start')??start; goal=s.getDouble('goal')??goal;
   age=s.getInt('age')??age;height=s.getInt('height')??height;sex=s.getString('sex')??sex;
   activity=s.getDouble('activity')??activity;kcal=s.getInt('kcal')??kcal;p=s.getInt('p')??p;f=s.getInt('f')??f;carb=s.getInt('c')??carb;water=s.getInt('water')??water;
   final h=s.getString('history'); if(h!=null) history=List<Map<String,dynamic>>.from(jsonDecode(h));
   final m=s.getString('meals'); if(m!=null) meals=List<Map<String,dynamic>>.from(jsonDecode(m));
   final r=s.getString('recipes'); if(r!=null) recipes=List<Map<String,dynamic>>.from(jsonDecode(r));
   final cf=s.getString('custom'); if(cf!=null) customFoods=List<Map<String,dynamic>>.from(jsonDecode(cf));
  }); _calc();
 }
 Future<void> _save() async{
  final s=await SharedPreferences.getInstance();
  await s.setBool('onboard',first);await s.setDouble('weight',weight);await s.setDouble('start',start);await s.setDouble('goal',goal);
  await s.setInt('age',age);await s.setInt('height',height);await s.setString('sex',sex);await s.setDouble('activity',activity);
  await s.setInt('kcal',kcal);await s.setInt('p',p);await s.setInt('f',f);await s.setInt('c',carb);await s.setInt('water',water);
  await s.setString('history',jsonEncode(history));await s.setString('meals',jsonEncode(meals));await s.setString('recipes',jsonEncode(recipes));await s.setString('custom',jsonEncode(customFoods));
 }
 void _calc(){
  final bmr=sex=='Мужской'?10*weight+6.25*height-5*age+5:10*weight+6.25*height-5*age-161;
  final t=bmr*activity;
  setState(()=>kcalGoal=max(1200,(t-450).round()));
  pGoal=max(90,(weight*1.6).round()); fGoal=(kcalGoal*.30/9).round(); cGoal=max(80,((kcalGoal-pGoal*4-fGoal*9)/4).round());
 }
 void _finishOnboard(){
  setState(()=>first=false);_save();_profile(edit:true);
 }
 @override Widget build(BuildContext c){
  if(first)return Onboard(onDone:_finishOnboard);
  final pages=[_home(),_foodDiary(),_weight(),_stats(),_profile()];
  return Scaffold(body:SafeArea(child:pages[tab]),bottomNavigationBar:NavigationBar(
   backgroundColor:card,selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),
   destinations:const[
    NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'Главная'),
    NavigationDestination(icon:Icon(Icons.restaurant_outlined),selectedIcon:Icon(Icons.restaurant),label:'Питание'),
    NavigationDestination(icon:Icon(Icons.monitor_weight_outlined),selectedIcon:Icon(Icons.monitor_weight),label:'Вес'),
    NavigationDestination(icon:Icon(Icons.insights_outlined),selectedIcon:Icon(Icons.insights),label:'Статистика'),
    NavigationDestination(icon:Icon(Icons.person_outline),selectedIcon:Icon(Icons.person),label:'Профиль'),
  ]));
 }

 Widget _home(){
  final prog=((start-weight)/(start-goal)).clamp(0.0,1.0);
  return ListView(padding:const EdgeInsets.all(16),children:[
   Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
    Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Сегодня',style:TextStyle(fontSize:28,fontWeight:FontWeight.bold)),Text('30 авг. 2026',style:TextStyle(color:Colors.grey))]),
    IconButton(onPressed:()=>_profile(edit:true),icon:const Icon(Icons.settings))
   ]),
   const SizedBox(height:12),
   _card(Column(children:[
    Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[_metric('Текущий вес','${weight.toStringAsFixed(1)} кг'),Text('${(prog*100).round()}%',style:const TextStyle(fontSize:30,fontWeight:FontWeight.bold)),_metric('Цель','${goal.toStringAsFixed(1)} кг')]),
    const SizedBox(height:15),LinearProgressIndicator(value:prog,minHeight:8),const SizedBox(height:8),
    Text('Осталось ${(weight-goal).toStringAsFixed(1)} кг')
   ])),
   _nutritionCard(),
   Row(children:[
    Expanded(child:_tile('Вода','$water / 2500 мл',Icons.water_drop,()=>setState((){water=min(3000,water+250);_save();}))),
    const SizedBox(width:10),Expanded(child:_tile('Шаги','8 432 / 10 000',Icons.directions_walk,null))
   ]),
   _card(ListTile(leading:const Icon(Icons.auto_awesome),title:const Text('Цель рассчитана автоматически'),subtitle:Text('$kcalGoal ккал • Б $pGoal г • Ж $fGoal г • У $cGoal г'),trailing:const Icon(Icons.chevron_right))),
   const SizedBox(height:8),const Text('Быстрые действия',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
   Row(children:[
    Expanded(child:_action('Добавить еду',Icons.add_circle,_openFoods)),
    const SizedBox(width:8),Expanded(child:_action('Записать вес',Icons.monitor_weight,_addWeight)),
   ])
  ]);
 }
 Widget _nutritionCard()=>_card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
  const Text('Калории',style:TextStyle(fontSize:16)),Text('$kcal / $kcalGoal ккал',style:const TextStyle(fontSize:27,fontWeight:FontWeight.bold)),
  const SizedBox(height:8),LinearProgressIndicator(value:(kcal/kcalGoal).clamp(0,1),minHeight:8),const SizedBox(height:14),
  Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[_macro('Белки',p,pGoal),_macro('Жиры',f,fGoal),_macro('Углеводы',carb,cGoal)])
 ]));
 Widget _macro(String n,int v,int g)=>Column(children:[Text(n),Text('$v / $g г',style:const TextStyle(fontWeight:FontWeight.bold))]);
 Widget _metric(String a,String b)=>Column(children:[Text(a,style:TextStyle(color:Colors.grey.shade400)),Text(b,style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold))]);
 Widget _card(Widget child)=>Card(color:card,child:Padding(padding:const EdgeInsets.all(18),child:child));
 Widget _tile(String a,String b,IconData i,VoidCallback? f)=>Card(color:card,child:InkWell(onTap:f,child:Padding(padding:const EdgeInsets.all(15),child:Column(children:[Icon(i),const SizedBox(height:5),Text(a),Text(b,style:const TextStyle(fontWeight:FontWeight.bold))]))));
 Widget _action(String t,IconData i,VoidCallback f)=>FilledButton.tonalIcon(onPressed:f,icon:Icon(i),label:Text(t));

 Widget _foodDiary()=>ListView(padding:const EdgeInsets.all(16),children:[
  Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('Питание',style:TextStyle(fontSize:28,fontWeight:FontWeight.bold)),IconButton(onPressed:_openFoods,icon:const Icon(Icons.add_circle))]),
  _nutritionCard(),
  ...meals.map((m)=>_card(ListTile(leading:const Icon(Icons.restaurant),title:Text(m['name']),subtitle:Text('${m['grams']} г • Б ${m['p']} г • Ж ${m['f']} г • У ${m['c']} г'),trailing:Text('${m['kcal']} ккал')))),
  if(meals.isEmpty) const Padding(padding:EdgeInsets.all(30),child:Center(child:Text('Добавьте первый продукт')))
 ]);
 void _openFoods()=>showModalBottomSheet(context:context,isScrollControlled:true,builder:(_)=>StatefulBuilder(builder:(ctx,set)=>SizedBox(height:MediaQuery.of(ctx).size.height*.82,child:ListView(padding:const EdgeInsets.all(16),children:[
  const Text('Добавить продукт',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),
  const SizedBox(height:8),const Text('База КБЖУ на 100 г'),
  ...[...foods,...customFoods.map((x)=>Food(x['name'],x['kcal'],(x['p'] as num).toDouble(),(x['f'] as num).toDouble(),(x['c'] as num).toDouble()))].map((x)=>ListTile(title:Text(x.name),subtitle:Text('${x.kcal} ккал • Б ${x.p} • Ж ${x.f} • У ${x.c}'),trailing:IconButton(icon:const Icon(Icons.add_circle),onPressed:(){Navigator.pop(ctx);_addFood(x);}))),
  FilledButton.icon(onPressed:(){Navigator.pop(ctx);_customFood();},icon:const Icon(Icons.edit),label:const Text('Создать свой продукт')),
  OutlinedButton.icon(onPressed:(){Navigator.pop(ctx);_recipe();},icon:const Icon(Icons.menu_book),label:const Text('Создать рецепт'))
 ])));

 void _addFood(Food x){
  final g=TextEditingController(text:'100');
  showDialog(context:context,builder:(_)=>AlertDialog(title:Text(x.name),content:TextField(controller:g,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Граммы')),actions:[
   FilledButton(onPressed:(){final grams=double.tryParse(g.text)??100, q=grams/100;setState((){final kk=(x.kcal*q).round();kcal+=kk;p+=(x.p*q).round();f+=(x.f*q).round();carb+=(x.c*q).round();meals.add({'name':x.name,'grams':grams.round(),'kcal':kk,'p':(x.p*q).round(),'f':(x.f*q).round(),'c':(x.c*q).round()});});_save();Navigator.pop(context);},child:const Text('Добавить'))
  ]);
 }
 void _customFood(){
  final n=TextEditingController(),k=TextEditingController(),pp=TextEditingController(),ff=TextEditingController(),cc=TextEditingController();
  showDialog(context:context,builder:(_)=>AlertDialog(title:const Text('Свой продукт'),content:SingleChildScrollView(child:Column(children:[
   TextField(controller:n,decoration:const InputDecoration(labelText:'Название')),
   TextField(controller:k,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Ккал / 100 г')),
   TextField(controller:pp,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Белки')),
   TextField(controller:ff,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Жиры')),
   TextField(controller:cc,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Углеводы')),
  ])),actions:[FilledButton(onPressed:(){setState(()=>customFoods.add({'name':n.text,'kcal':int.tryParse(k.text)??0,'p':double.tryParse(pp.text)??0,'f':double.tryParse(ff.text)??0,'c':double.tryParse(cc.text)??0}));_save();Navigator.pop(context);},child:const Text('Сохранить'))]);
 }
 void _recipe(){
  final n=TextEditingController();
  showDialog(context:context,builder:(_)=>AlertDialog(title:const Text('Новый рецепт'),content:TextField(controller:n,decoration:const InputDecoration(labelText:'Название рецепта')),actions:[
   FilledButton(onPressed:(){setState(()=>recipes.add({'name':n.text.isEmpty?'Мой рецепт':n.text,'kcal':0}));_save();Navigator.pop(context);},child:const Text('Создать'))
  ]);
 }

 Widget _weight()=>ListView(padding:const EdgeInsets.all(16),children:[
  Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('Вес',style:TextStyle(fontSize:28,fontWeight:FontWeight.bold)),IconButton(onPressed:_addWeight,icon:const Icon(Icons.add_circle))]),
  _card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${weight.toStringAsFixed(1)} кг',style:const TextStyle(fontSize:32,fontWeight:FontWeight.bold)),Text('Цель ${goal.toStringAsFixed(1)} кг'),const SizedBox(height:15),SizedBox(height:250,child:Chart(history:history))])),
  ...history.reversed.map((x)=>ListTile(title:Text('${x['weight']} кг'),trailing:Text(x['date'])))
 ]);
 void _addWeight(){
  final c=TextEditingController(text:weight.toString());
  showDialog(context:context,builder:(_)=>AlertDialog(title:const Text('Записать вес'),content:TextField(controller:c,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(suffixText:'кг')),actions:[
   FilledButton(onPressed:(){final v=double.tryParse(c.text.replaceAll(',','.'));if(v!=null)setState((){weight=v;history.add({'date':'${DateTime.now().day}.${DateTime.now().month}','weight':v});});_calc();_save();Navigator.pop(context);},child:const Text('Сохранить'))
  ]);
 }

 Widget _stats()=>ListView(padding:const EdgeInsets.all(16),children:[
  const Text('Статистика',style:TextStyle(fontSize:28,fontWeight:FontWeight.bold)),
  _card(Column(children:[const Align(alignment:Alignment.centerLeft,child:Text('Динамика веса',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold))),const SizedBox(height:10),SizedBox(height:280,child:Chart(history:history))])),
  Row(children:[Expanded(child:_tile('Изменение','${(weight-start).toStringAsFixed(1)} кг',Icons.trending_down,null)),const SizedBox(width:10),Expanded(child:_tile('До цели','${(weight-goal).toStringAsFixed(1)} кг',Icons.flag,null))]),
  _card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Средние показатели',style:TextStyle(fontWeight:FontWeight.bold)),Text('Калории: $kcalGoal ккал/день'),Text('Белки: $pGoal г/день'),Text('Вода: 2500 мл/день')]))
 ]);

 Widget _profile()=>ListView(padding:const EdgeInsets.all(16),children:[
  const Text('Профиль',style:TextStyle(fontSize:28,fontWeight:FontWeight.bold)),
  _card(ListTile(leading:const Icon(Icons.person),title:Text(sex),subtitle:Text('$age лет • $height см'))),
  _card(ListTile(leading:const Icon(Icons.monitor_weight),title:Text('Вес ${weight.toStringAsFixed(1)} кг'),subtitle:Text('Цель ${goal.toStringAsFixed(1)} кг'))),
  _card(ListTile(leading:const Icon(Icons.local_fire_department),title:Text('$kcalGoal ккал/день'),subtitle:Text('Б $pGoal г • Ж $fGoal г • У $cGoal г'))),
  FilledButton.icon(onPressed:()=>_profile(edit:true),icon:const Icon(Icons.edit),label:const Text('Изменить данные')),
 ]);

 void _profile({bool edit=false}){
  final a=TextEditingController(text:'$age'),h=TextEditingController(text:'$height'),st=TextEditingController(text:'$start'),go=TextEditingController(text:'$goal');
  showDialog(context:context,builder:(_)=>AlertDialog(title:const Text('Профиль'),content:SingleChildScrollView(child:Column(children:[
   DropdownButtonFormField<String>(value:sex,items:const[DropdownMenuItem(value:'Мужской',child:Text('Мужской')),DropdownMenuItem(value:'Женский',child:Text('Женский'))],onChanged:(v)=>sex=v??sex,decoration:const InputDecoration(labelText:'Пол')),
   TextField(controller:a,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Возраст')),
   TextField(controller:h,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Рост, см')),
   TextField(controller:st,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Стартовый вес, кг')),
   TextField(controller:go,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Целевой вес, кг')),
   DropdownButton<double>(value:activity,isExpanded:true,items:const[
    DropdownMenuItem(value:1.2,child:Text('Минимальная активность')),DropdownMenuItem(value:1.375,child:Text('Лёгкая')),DropdownMenuItem(value:1.45,child:Text('Средняя')),DropdownMenuItem(value:1.55,child:Text('Высокая'))],onChanged:(v){if(v!=null)activity=v;})
  ])),actions:[FilledButton(onPressed:(){setState((){age=int.tryParse(a.text)??age;height=int.tryParse(h.text)??height;start=double.tryParse(st.text.replaceAll(',','.'))??start;goal=double.tryParse(go.text.replaceAll(',','.'))??goal;});_calc();_save();Navigator.pop(context);},child:const Text('Сохранить'))]);
 }
}

class Onboard extends StatelessWidget{
 final VoidCallback onDone;const Onboard({super.key,required this.onDone});
 @override Widget build(BuildContext c)=>Scaffold(body:Container(padding:const EdgeInsets.all(28),decoration:const BoxDecoration(gradient:LinearGradient(colors:[Color(0xFF0B1B22),bg],begin:Alignment.topCenter,end:Alignment.bottomCenter)),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
  const Icon(Icons.terrain,size:90,color:accent),const SizedBox(height:20),
  const Text('FitLife',style:TextStyle(fontSize:46,fontWeight:FontWeight.bold)),const SizedBox(height:8),
  const Text('Твой путь к лучшей форме',style:TextStyle(fontSize:18)),
  const SizedBox(height:45),
  const ListTile(leading:Icon(Icons.local_fire_department,color:accent),title:Text('Персональные калории'),subtitle:Text('Расчёт по твоим данным')),
  const ListTile(leading:Icon(Icons.restaurant,color:accent),title:Text('Удобный дневник питания'),subtitle:Text('КБЖУ и база продуктов')),
  const ListTile(leading:Icon(Icons.insights,color:accent),title:Text('Прогресс и статистика'),subtitle:Text('Следи за изменением веса')),
  const Spacer(),SizedBox(width:double.infinity,height:54,child:FilledButton(onPressed:onDone,child:const Text('Начать',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold))))
 ]));
}

class Chart extends StatelessWidget{
 final List<Map<String,dynamic>> history;const Chart({super.key,required this.history});
 @override Widget build(BuildContext c)=>CustomPaint(painter:_Painter(history,Theme.of(c).colorScheme.primary));
}
class _Painter extends CustomPainter{
 final List<Map<String,dynamic>> d;final Color color;_Painter(this.d,this.color);
 @override void paint(Canvas c,Size s){
  if(d.length<2)return;final v=d.map((e)=>(e['weight'] as num).toDouble()).toList(),mn=v.reduce(min)-.5,mx=v.reduce(max)+.5;
  final grid=Paint()..color=Colors.white12..strokeWidth=1, line=Paint()..color=color..strokeWidth=3..style=PaintingStyle.stroke;
  for(int i=0;i<5;i++){final y=s.height*i/4;c.drawLine(Offset(0,y),Offset(s.width,y),grid);}
  final path=Path();
  for(int i=0;i<v.length;i++){final x=s.width*i/(v.length-1),y=s.height-(v[i]-mn)/(mx-mn)*s.height;if(i==0)path.moveTo(x,y);else path.lineTo(x,y);c.drawCircle(Offset(x,y),4,Paint()..color=color);}
  c.drawPath(path,line);
 }
 @override bool shouldRepaint(covariant _Painter old)=>true;
}
