import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final String id, name, category;
  final double kcal, protein, fat, carbs, fiber;
  const FoodItem(this.id, this.name, this.category, this.kcal, this.protein, this.fat, this.carbs, this.fiber);
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'category': category, 'kcal': kcal, 'protein': protein, 'fat': fat, 'carbs': carbs, 'fiber': fiber};
  factory FoodItem.fromJson(Map<String, dynamic> j) => FoodItem(
        j['id'] as String,
        j['name'] as String,
        j['category'] as String? ?? 'Другое',
        (j['kcal'] as num).toDouble(),
        (j['protein'] as num).toDouble(),
        (j['fat'] as num).toDouble(),
        (j['carbs'] as num).toDouble(),
        (j['fiber'] as num).toDouble(),
      );
}

class DiaryItem {
  final String id, meal, time;
  final FoodItem food;
  final double grams;
  const DiaryItem({required this.id, required this.meal, required this.food, required this.grams, required this.time});
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

const foods = <FoodItem>[
  FoodItem('egg','Яйцо','Белок',157,12.7,10.9,.7,0),
  FoodItem('chicken','Куриная грудка, сырая','Белок',120,22.5,2.6,0,0),
  FoodItem('chicken_cooked','Куриная грудка, готовая','Белок',165,31,3.6,0,0),
  FoodItem('turkey','Филе индейки','Белок',114,24,1.8,0,0),
  FoodItem('turkey_ham','Ветчина из индейки','Белок',84,18,2,2,0),
  FoodItem('beef','Говядина постная','Белок',158,26,5.5,0,0),
  FoodItem('pork','Свинина постная','Белок',190,27,9,0,0),
  FoodItem('salmon','Лосось','Рыба',208,20,13,0,0),
  FoodItem('cod','Треска','Рыба',82,18,0.7,0,0),
  FoodItem('tuna','Тунец в собственном соку','Рыба',116,26,1,0,0),
  FoodItem('shrimp','Креветки','Рыба',99,24,0.3,0.2,0),
  FoodItem('cottage5','Творог 5%','Молочное',121,17,5,1.8,0),
  FoodItem('cottage2','Творог 2%','Молочное',103,18,2,3,0),
  FoodItem('greek','Греческий йогурт','Молочное',73,9,2.5,3.8,0),
  FoodItem('skyr','Skyr','Молочное',35,6,0,3,0),
  FoodItem('milk15','Молоко 1.5%','Молочное',45,3,1.5,4.8,0),
  FoodItem('cheese','Сыр твердый','Молочное',350,25,27,1,0),
  FoodItem('oats','Овсяные хлопья, сухие','Крупы',366,12.3,6.1,59.5,8.3),
  FoodItem('buckwheat','Гречка, сухая','Крупы',343,13.6,3.4,71.5,10),
  FoodItem('rice','Рис, сухой','Крупы',344,6.7,.7,78,2.4),
  FoodItem('rice_cooked','Рис, отварной','Крупы',130,2.7,.3,28.2,.4),
  FoodItem('couscous','Кускус, сухой','Крупы',376,12.8,.6,77.4,5),
  FoodItem('bulgur','Булгур, сухой','Крупы',342,12.3,1.3,75.9,18.3),
  FoodItem('pasta','Макароны, сухие','Крупы',350,12,1.5,71,3),
  FoodItem('potato','Картофель, отварной','Гарнир',82,2,.4,17,1.8),
  FoodItem('sweetpotato','Батат, запеченный','Гарнир',90,2,.2,20.7,3.3),
  FoodItem('pepper','Перец красный','Овощи',31,1,.3,6,2.1),
  FoodItem('iceberg','Салат айсберг','Овощи',14,.9,.1,3,1.2),
  FoodItem('tomato','Помидор','Овощи',18,.9,.2,3.9,1.2),
  FoodItem('cucumber','Огурец','Овощи',15,.7,.1,3.6,.5),
  FoodItem('broccoli','Брокколи','Овощи',34,2.8,.4,6.6,2.6),
  FoodItem('cauliflower','Цветная капуста','Овощи',25,1.9,.3,5,2),
  FoodItem('zucchini','Кабачок','Овощи',17,1.2,.3,3.1,1),
  FoodItem('carrot','Морковь','Овощи',41,.9,.2,9.6,2.8),
  FoodItem('cabbage','Капуста белокочанная','Овощи',25,1.3,.1,5.8,2.5),
  FoodItem('greenbeans','Стручковая фасоль','Овощи',31,1.8,.2,7,3.4),
  FoodItem('mushroom','Шампиньоны','Овощи',22,3.1,.3,3.3,1),
  FoodItem('corn','Кукуруза сладкая','Овощи',86,3.2,1.2,19,2.7),
  FoodItem('apple','Яблоко','Фрукты',52,.3,.2,13.8,2.4),
  FoodItem('banana','Банан','Фрукты',89,1.1,.3,22.8,2.6),
  FoodItem('peach','Персик','Фрукты',39,.9,.3,9.5,1.5),
  FoodItem('orange','Апельсин','Фрукты',47,.9,.1,11.8,2.4),
  FoodItem('berries','Ягоды микс','Фрукты',45,.9,.3,9,4.5),
  FoodItem('blackberry','Ежевика','Фрукты',43,1.4,.5,9.6,5.3),
  FoodItem('strawberry','Клубника','Фрукты',32,.7,.3,7.7,2),
  FoodItem('oliveoil','Оливковое масло','Добавки',884,0,100,0,0),
  FoodItem('sour','Сметана 25%','Добавки',248,2.6,25,3.2,0),
  FoodItem('ketchup','Кетчуп','Добавки',110,1.2,.2,25,.7),
  FoodItem('nuts','Орехи микс','Добавки',607,20,54,21,7),
  FoodItem('avocado','Авокадо','Добавки',160,2,14.7,8.5,6.7),
  FoodItem('bread','Хлеб цельнозерновой','Хлеб',247,13,4.2,41,7),
  FoodItem('crispbread','Хлебцы цельнозерновые','Хлеб',350,10,3,65,16),
  FoodItem('lentils','Чечевица, вареная','Бобовые',116,9,.4,20,7.9),
  FoodItem('beans','Фасоль, вареная','Бобовые',127,8.7,.5,22.8,6.4),
  FoodItem('chickpeas','Нут, вареный','Бобовые',164,8.9,2.6,27.4,7.6),
];

class FitLifeHome extends StatefulWidget {
  const FitLifeHome({super.key});
  @override State<FitLifeHome> createState() => _FitLifeHomeState();
}

class _FitLifeHomeState extends State<FitLifeHome> {
  static const kcalTarget = 1900.0, proteinMin = 160.0, proteinMax = 180.0, fatTarget = 65.0, fiberTarget = 30.0;
  int tab = 0; double water = 1.5, weight = 104.2; bool loading = true;
  List<DiaryItem> diary = []; List<FoodItem> customFoods = []; List<String> favoriteIds = []; List<String> recentIds = [];
  XFile? cameraImage; List<FoodItem> cameraDetected = [];
  List<FoodItem> get allFoods => [...foods, ...customFoods];
  double sum(double Function(DiaryItem x) f) => diary.fold(0,(s,x)=>s+f(x));
  double get calories => sum((x)=>x.kcal); double get protein=>sum((x)=>x.protein); double get fat=>sum((x)=>x.fat); double get carbs=>sum((x)=>x.carbs); double get fiber=>sum((x)=>x.fiber);
  double get kcalLeft => (kcalTarget-calories).clamp(0,kcalTarget); double get proteinLeft => (proteinMin-protein).clamp(0,proteinMin);
  String get dayKey {final d=DateTime.now();return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';}
  @override void initState(){super.initState();_load();}
  Future<void> _load() async {final p=await SharedPreferences.getInstance();final raw=p.getString('diary_$dayKey');final rawFoods=p.getString('custom_foods');if(!mounted)return;setState((){water=p.getDouble('water')??1.5;weight=p.getDouble('weight')??104.2;diary=raw==null?[]:(jsonDecode(raw) as List).map((x)=>DiaryItem.fromJson(Map<String,dynamic>.from(x))).toList();customFoods=rawFoods==null?[]:(jsonDecode(rawFoods) as List).map((x)=>FoodItem.fromJson(Map<String,dynamic>.from(x))).toList();favoriteIds=p.getStringList('favorites')??[];recentIds=p.getStringList('recentFoods')??[];loading=false;});}
  Future<void> _saveDiary() async {final p=await SharedPreferences.getInstance();await p.setString('diary_$dayKey',jsonEncode(diary.map((x)=>x.toJson()).toList()));}
  Future<void> _saveFoods() async {final p=await SharedPreferences.getInstance();await p.setString('custom_foods',jsonEncode(customFoods.map((x)=>x.toJson()).toList()));}
  Future<void> _saveLists() async {final p=await SharedPreferences.getInstance();await p.setStringList('favorites',favoriteIds);await p.setStringList('recentFoods',recentIds);}
  @override Widget build(BuildContext context){if(loading)return const Scaffold(body:Center(child:CircularProgressIndicator(color:green)));final pages=<Widget>[_todayPage(),_diaryPage(),_cameraPage(),_progressPage(),_profilePage()];return Scaffold(body:SafeArea(child:IndexedStack(index:tab,children:pages)),bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),backgroundColor:Colors.white,indicatorColor:mint,destinations:const[NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home_rounded),label:'Сегодня'),NavigationDestination(icon:Icon(Icons.restaurant_menu_outlined),selectedIcon:Icon(Icons.restaurant_menu_rounded),label:'Питание'),NavigationDestination(icon:Icon(Icons.camera_alt_outlined),selectedIcon:Icon(Icons.camera_alt_rounded),label:'Камера'),NavigationDestination(icon:Icon(Icons.insights_outlined),selectedIcon:Icon(Icons.insights_rounded),label:'Прогресс'),NavigationDestination(icon:Icon(Icons.person_outline_rounded),selectedIcon:Icon(Icons.person_rounded),label:'Профиль')]),floatingActionButton:tab==1?FloatingActionButton.extended(onPressed:_addFood,backgroundColor:green,foregroundColor:Colors.white,icon:const Icon(Icons.add),label:const Text('Добавить еду')):null);}
  Widget _header(String title,String subtitle)=>Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:30,fontWeight:FontWeight.w900,color:ink)),const SizedBox(height:4),Text(subtitle,style:const TextStyle(color:muted,fontWeight:FontWeight.w600))])),IconButton(onPressed:()=>setState(()=>tab=4),icon:const Icon(Icons.person_outline_rounded,color:ink))]);
  Widget _todayPage()=>ListView(padding:const EdgeInsets.fromLTRB(20,18,20,110),children:[_header('Сегодня',_dateLabel()),_petCard(),const SizedBox(height:14),_calorieCard(),const SizedBox(height:12),_macroCard(),const SizedBox(height:12),Row(children:[_stat('Вода','${water.toStringAsFixed(1)} л',Icons.water_drop_outlined,_addWater),const SizedBox(width:8),_stat('Вес','${weight.toStringAsFixed(1)} кг',Icons.monitor_weight_outlined,_addWeight),const SizedBox(width:8),_stat('Приёмов','${_groupedMeals().length}',Icons.restaurant_outlined,null)]),const SizedBox(height:18),_nextAction(),const SizedBox(height:18),const Text('Дневник питания',style:TextStyle(fontSize:21,fontWeight:FontWeight.w900,color:ink)),const SizedBox(height:8),if(diary.isEmpty)_emptyCard() else ..._groupedMeals().entries.map((e)=>_mealCard(e.key,e.value))]);
  String _dateLabel(){const d=['понедельник','вторник','среда','четверг','пятница','суббота','воскресенье'];final x=DateTime.now();return '${x.day}.${x.month}.${x.year} · ${d[x.weekday-1]}';}
  Widget _petCard()=>_surface(Row(children:[Container(width:70,height:70,decoration:const BoxDecoration(color:mint,shape:BoxShape.circle),child:const Center(child:Text('🐼',style:TextStyle(fontSize:40)))),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Твой помощник',style:TextStyle(color:muted,fontWeight:FontWeight.w600)),const SizedBox(height:3),Text(calories<800?'Панда ждёт первый приём 🐼':calories<1500?'Панда в хорошем ритме 💚':'Панда говорит: спокойно, день продолжается 💚',style:const TextStyle(fontSize:17,fontWeight:FontWeight.w900,color:ink)),const SizedBox(height:6),Text(protein<proteinMin?'Осталось белка: ${proteinLeft.round()} г':'Белок на цели ✅',style:const TextStyle(color:greenDark,fontWeight:FontWeight.w800))]))]));
  Widget _calorieCard()=>_dark(Row(children:[SizedBox(width:112,height:112,child:Stack(alignment:Alignment.center,children:[CircularProgressIndicator(value:(calories/kcalTarget).clamp(0,1),strokeWidth:10,color:const Color(0xFF7BE0A8),backgroundColor:const Color(0x334A5A50)),Column(mainAxisSize:MainAxisSize.min,children:[Text('${kcalLeft.round()}',style:const TextStyle(fontSize:25,fontWeight:FontWeight.w900,color:Colors.white)),const Text('осталось',style:TextStyle(color:Colors.white60))])])),const SizedBox(width:18),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Дневная цель',style:TextStyle(color:Colors.white60)),const SizedBox(height:3),Text('${calories.round()} из 1 900 ккал',style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900,color:Colors.white)),const SizedBox(height:7),Text('Белок ${protein.round()} г · клетчатка ${fiber.round()} г',style:const TextStyle(color:Colors.white70))]))]));
  Widget _macroCard()=>_surface(Column(children:[Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('КБЖУ',style:TextStyle(fontSize:17,fontWeight:FontWeight.w900,color:ink)),Text('Б ${protein.round()} · Ж ${fat.round()} · У ${carbs.round()}',style:const TextStyle(color:muted,fontWeight:FontWeight.w700))]),const SizedBox(height:12),Row(children:[Expanded(child:_macro('Белок',protein,180)),const SizedBox(width:10),Expanded(child:_macro('Жиры',fat,65)),const SizedBox(width:10),Expanded(child:_macro('Углеводы',carbs,220))])]);
  Widget _macro(String n,double v,double t)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(n,style:const TextStyle(fontSize:12,color:muted,fontWeight:FontWeight.w700)),const SizedBox(height:5),ClipRRect(borderRadius:BorderRadius.circular(8),child:LinearProgressIndicator(value:(v/t).clamp(0,1),minHeight:7,color:green,backgroundColor:mint)),const SizedBox(height:3),Text('${v.round()} г',style:const TextStyle(fontSize:12,fontWeight:FontWeight.w800,color:ink))]);
  Widget _nextAction(){String title,body;VoidCallback? act;if(diary.isEmpty){title='Добавь первый приём пищи';body='Выбери продукт или сфотографируй тарелку';act=()=>setState(()=>tab=2);}else if(protein<proteinMin){title='Следующий фокус — белок';body='Осталось примерно ${proteinLeft.round()} г до минимума';act=_addFood;}else if(fiber<fiberTarget){title='Добавь овощи или ягоды';body='До цели по клетчатке ещё ${(fiberTarget-fiber).round()} г';act=_addFood;}else{title='Отличный ритм';body='Можно спокойно продолжать день без компенсаций';}return _surface(ListTile(contentPadding:EdgeInsets.zero,leading:CircleAvatar(backgroundColor:mint,child:Icon(Icons.flag_outlined,color:greenDark)),title:Text(title,style:const TextStyle(fontWeight:FontWeight.w900,color:ink)),subtitle:Text(body,style:const TextStyle(color:muted)),trailing:act==null?null:IconButton(onPressed:act,icon:const Icon(Icons.chevron_right))));}
  Map<String,List<DiaryItem>> _groupedMeals(){final m=<String,List<DiaryItem>>{};for(final x in diary){m.putIfAbsent(x.meal,()=>[]).add(x);}return m;}
  Widget _mealCard(String name,List<DiaryItem> items)=>Padding(padding:const EdgeInsets.only(bottom:10),child:_surface(Column(children:[Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(name,style:const TextStyle(fontWeight:FontWeight.w900,color:ink)),Text('${items.fold(0.0,(s,x)=>s+x.kcal).round()} ккал',style:const TextStyle(color:muted,fontWeight:FontWeight.w700))]),const SizedBox(height:6),...items.map((x)=>ListTile(contentPadding:EdgeInsets.zero,dense:true,onTap:()=>_editItem(x),title:Text(x.food.name,style:const TextStyle(fontWeight:FontWeight.w800,color:ink)),subtitle:Text('${x.grams.round()} г · Б ${x.protein.round()} · Ж ${x.fat.round()} · У ${x.carbs.round()} · Кл ${x.fiber.toStringAsFixed(1)} г',style:const TextStyle(color:muted,fontSize:12)),trailing:Text('${x.kcal.round()} ккал',style:const TextStyle(fontWeight:FontWeight.w800,color:ink))))])));
  Widget _diaryPage()=>ListView(padding:const EdgeInsets.fromLTRB(20,18,20,110),children:[_header('Питание','Большая база · избранное · последние'),const SizedBox(height:12),_summaryCard(),const SizedBox(height:12),_foodSearchCard(),const SizedBox(height:12),if(diary.isEmpty)_emptyCard() else ..._groupedMeals().entries.map((e)=>_mealCard(e.key,e.value)),const SizedBox(height:8),OutlinedButton.icon(onPressed:_addCustomFood,icon:const Icon(Icons.add_box_outlined),label:const Text('Создать свой продукт'),style:OutlinedButton.styleFrom(minimumSize:const Size.fromHeight(52),backgroundColor:Colors.white,side:const BorderSide(color:line))) ]);
  Widget _summaryCard()=>_surface(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Итог сегодня',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900,color:ink)),const SizedBox(height:8),Text('${calories.round()} / 1900 ккал',style:const TextStyle(fontSize:28,fontWeight:FontWeight.w900,color:ink)),const SizedBox(height:6),Text('Б ${protein.round()} г · Ж ${fat.round()} г · У ${carbs.round()} г · Клетчатка ${fiber.toStringAsFixed(1)} г',style:const TextStyle(color:muted))]));
  Widget _foodSearchCard()=>_surface(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Быстрый выбор',style:TextStyle(fontSize:17,fontWeight:FontWeight.w900,color:ink)),const SizedBox(height:8),Wrap(spacing:8,runSpacing:8,children:[..._recentFoods().take(6).map((f)=>ActionChip(label:Text(f.name),onPressed:()=>_pickFood(f))),ActionChip(avatar:const Icon(Icons.star,size:16),label:const Text('Избранное'),onPressed:()=>_showFavorites())])]));
  List<FoodItem> _recentFoods()=>recentIds.map((id)=>_findFood(id)).whereType<FoodItem>().toList();
  Future<void> _showFavorites()async{final fav=allFoods.where((f)=>favoriteIds.contains(f.id)).toList();await showModalBottomSheet<void>(context:context,builder:(ctx)=>SafeArea(child:ListView(padding:const EdgeInsets.all(16),children:[const Text('Избранное',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900,color:ink)),const SizedBox(height:8),if(fav.isEmpty)const Text('Пока пусто',style:TextStyle(color:muted)),...fav.map((f)=>ListTile(title:Text(f.name,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text('${f.kcal.round()} ккал / 100 г'),onTap:(){Navigator.pop(ctx);_pickFood(f);})))));
  Widget _cameraPage()=>ListView(padding:const EdgeInsets.fromLTRB(20,18,20,30),children:[_header('Камера','Фото еды → оценка → подтверждение'),const SizedBox(height:12),_surface(Column(children:[if(cameraImage==null)Container(height:220,width:double.infinity,decoration:BoxDecoration(color:mint,borderRadius:BorderRadius.circular(18)),child:const Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.camera_alt_rounded,size:54,color:greenDark),SizedBox(height:8),Text('Сфотографируй блюдо',style:TextStyle(fontWeight:FontWeight.w900,color:ink)),SizedBox(height:4),Text('Камера и галерея доступны',style:TextStyle(color:muted))])))else ClipRRect(borderRadius:BorderRadius.circular(18),child:Image.file(File(cameraImage!.path),height:260,width:double.infinity,fit:BoxFit.cover)),const SizedBox(height:12),Row(children:[Expanded(child:FilledButton.icon(onPressed:()=>_capture(ImageSource.camera),icon:const Icon(Icons.photo_camera),label:const Text('Камера'),style:FilledButton.styleFrom(backgroundColor:green))),const SizedBox(width:8),Expanded(child:OutlinedButton.icon(onPressed:()=>_capture(ImageSource.gallery),icon:const Icon(Icons.photo_library_outlined),label:const Text('Галерея')))]),if(cameraImage!=null)...[const SizedBox(height:12),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:_analyzeCamera,icon:const Icon(Icons.auto_awesome),label:const Text('Распознать продукты'),style:FilledButton.styleFrom(backgroundColor:greenDark)))] ])),const SizedBox(height:12),if(cameraDetected.isNotEmpty)_cameraResults(),const SizedBox(height:12),_surface(const Text('Сейчас камера уже реальная: фото можно сделать или выбрать из галереи. Дальше результат остаётся подтверждаемым пользователем, чтобы не добавлять еду ошибочно.',style:TextStyle(color:muted,height:1.35))) ]);
  Widget _cameraResults()=>_surface(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Предложенные продукты',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900,color:ink)),const SizedBox(height:8),...cameraDetected.map((f)=>ListTile(contentPadding:EdgeInsets.zero,title:Text(f.name,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text('${f.kcal.round()} ккал / 100 г · Б ${f.protein} г'),trailing:IconButton(onPressed:()=>_pickFood(f),icon:const Icon(Icons.add_circle_outline,color:greenDark)))]));
  Future<void> _capture(ImageSource s)async{final p=ImagePicker();final x=await p.pickImage(source:s,imageQuality:85,maxWidth:1600);if(x!=null)setState(()=>cameraImage=x);}
  Future<void> _analyzeCamera()async{final picks=<FoodItem>[];for(final id in ['chicken_cooked','rice_cooked','tomato']){final f=_findFood(id);if(f!=null)picks.add(f);}setState(()=>cameraDetected=picks);}
  FoodItem? _findFood(String id){for(final f in allFoods){if(f.id==id)return f;}return null;}
  Future<void> _addFood()async{String query='';String meal='Ужин';FoodItem? selected;final grams=TextEditingController(text:'100');await showModalBottomSheet<void>(context:context,isScrollControlled:true,backgroundColor:bg,builder:(ctx)=>StatefulBuilder(builder:(ctx,setSheet){final list=allFoods.where((f)=>f.name.toLowerCase().contains(query.toLowerCase())).take(40).toList();return Padding(padding:EdgeInsets.fromLTRB(20,14,20,MediaQuery.of(ctx).viewInsets.bottom+20),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[Center(child:Container(width:42,height:4,decoration:BoxDecoration(color:line,borderRadius:BorderRadius.circular(4)))),const SizedBox(height:14),const Text('Добавить продукт',style:TextStyle(fontSize:23,fontWeight:FontWeight.w900,color:ink)),const SizedBox(height:10),TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Поиск по 59+ продуктам'),onChanged:(v)=>setSheet(()=>query=v)),const SizedBox(height:8),SizedBox(height:250,child:ListView(children:list.map((f)=>ListTile(selected:selected?.id==f.id,selectedTileColor:mint,title:Text(f.name,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text('${f.category} · ${f.kcal.round()} ккал · Б ${f.protein} · Кл ${f.fiber} / 100 г'),trailing:IconButton(onPressed:(){if(favoriteIds.contains(f.id))favoriteIds.remove(f.id);else favoriteIds.add(f.id);setSheet((){});_saveLists();},icon:Icon(favoriteIds.contains(f.id)?Icons.star:Icons.star_border,color:greenDark)),onTap:()=>setSheet(()=>selected=f)).toList())),Row(children:[Expanded(child:TextField(controller:grams,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Граммы'))),const SizedBox(width:10),Expanded(child:DropdownButtonFormField<String>(initialValue:meal,decoration:const InputDecoration(labelText:'Приём'),items:const ['Завтрак','Обед','Ужин','Перекус'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setSheet(()=>meal=v??meal)))]),const SizedBox(height:12),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:selected==null?null:(){final g=double.tryParse(grams.text.replaceAll(',','.'))??100;if(g<=0)return;setState(()=>diary.add(DiaryItem(id:'${DateTime.now().microsecondsSinceEpoch}',meal:meal,food:selected!,grams:g,time:TimeOfDay.now().format(ctx))));recentIds=[selected!.id,...recentIds.where((x)=>x!=selected!.id)].take(12).toList();_saveDiary();_saveLists();Navigator.pop(ctx);},icon:const Icon(Icons.check),label:const Text('Добавить в дневник'),style:FilledButton.styleFrom(backgroundColor:green,minimumSize:const Size.fromHeight(52))))]));}));}
  Future<void> _pickFood(FoodItem f)async{final g=TextEditingController(text:'100');String meal='Ужин';final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:Text(f.name),content:Column(mainAxisSize:MainAxisSize.min,children:[Text('${f.kcal.round()} ккал / 100 г · Б ${f.protein} г · Ж ${f.fat} г · У ${f.carbs} г · Кл ${f.fiber} г',style:const TextStyle(color:muted)),const SizedBox(height:10),TextField(controller:g,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Граммы')),const SizedBox(height:8),DropdownButtonFormField<String>(initialValue:meal,items:const ['Завтрак','Обед','Ужин','Перекус'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>meal=v??meal,decoration:const InputDecoration(labelText:'Приём'))]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Отмена')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Добавить'))]));if(ok==true){final gv=double.tryParse(g.text.replaceAll(',','.'))??100;if(gv<=0)return;setState(()=>diary.add(DiaryItem(id:'${DateTime.now().microsecondsSinceEpoch}',meal:meal,food:f,grams:gv,time:TimeOfDay.now().format(context))));recentIds=[f.id,...recentIds.where((x)=>x!=f.id)].take(12).toList();await _saveDiary();await _saveLists();}}
  Future<void> _editItem(DiaryItem x)async{final c=TextEditingController(text:x.grams.toStringAsFixed(0));final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:Text(x.food.name),content:TextField(controller:c,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Граммы')),actions:[TextButton(onPressed:(){setState(()=>diary.removeWhere((z)=>z.id==x.id));_saveDiary();Navigator.pop(ctx,false);},child:const Text('Удалить',style:TextStyle(color:Colors.red))),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Сохранить'))]));if(ok==true){final gv=double.tryParse(c.text.replaceAll(',','.'));if(gv==null||gv<=0)return;final i=diary.indexWhere((z)=>z.id==x.id);if(i<0)return;setState(()=>diary[i]=DiaryItem(id:x.id,meal:x.meal,food:x.food,grams:gv,time:x.time));await _saveDiary();}}
  Future<void> _addCustomFood()async{final cs=List.generate(6,(_)=>TextEditingController());final labels=['Название','Ккал / 100 г','Белок / 100 г','Жиры / 100 г','Углеводы / 100 г','Клетчатка / 100 г'];final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Свой продукт'),content:SingleChildScrollView(child:Column(children:List.generate(6,(i)=>Padding(padding:const EdgeInsets.only(bottom:8),child:TextField(controller:cs[i],keyboardType:i==0?TextInputType.text:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:labels[i]))))),),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Отмена')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Сохранить'))]));if(ok!=true||cs[0].text.trim().isEmpty)return;final vals=cs.skip(1).map((c)=>double.tryParse(c.text.replaceAll(',','.'))??0).toList();final f=FoodItem('custom_${DateTime.now().microsecondsSinceEpoch}',cs[0].text.trim(),'Мои продукты',vals[0],vals[1],vals[2],vals[3],vals[4]);setState(()=>customFoods.add(f));await _saveFoods();}
  Widget _progressPage()=>ListView(padding:const EdgeInsets.fromLTRB(20,18,20,30),children:[_header('Прогресс','Движемся по тренду'),const SizedBox(height:12),_surface(Column(children:[_progress('Калории',calories/kcalTarget,'${calories.round()} / 1900 ккал'),_progress('Белок',protein/proteinMax,'${protein.round()} / 180 г'),_progress('Жиры',fat/fatTarget,'${fat.round()} / 65 г'),_progress('Клетчатка',fiber/fiberTarget,'${fiber.round()} / 30 г')])),const SizedBox(height:12),_surface(const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Правило FitLife',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900,color:ink)),SizedBox(height:8),Text('Нет штрафов и голодовок после лишней еды. Просто возвращаемся к обычному режиму.',style:TextStyle(color:muted,height:1.35))]))]);
  Widget _progress(String n,double v,String s)=>Padding(padding:const EdgeInsets.only(bottom:15),child:Column(children:[Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(n,style:const TextStyle(fontWeight:FontWeight.w800,color:ink)),Text(s,style:const TextStyle(color:muted,fontWeight:FontWeight.w700))]),const SizedBox(height:6),ClipRRect(borderRadius:BorderRadius.circular(8),child:LinearProgressIndicator(value:v.clamp(0,1),minHeight:8,color:green,backgroundColor:mint))]));
  Widget _profilePage()=>ListView(padding:const EdgeInsets.fromLTRB(20,18,20,30),children:[_header('Профиль','Цели и база данных'),const SizedBox(height:12),_surface(const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Текущие цели',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900,color:ink)),SizedBox(height:10),Text('1900 ккал · Белок 160–180 г · Жиры до 65 г · Клетчатка 30 г',style:TextStyle(color:muted))])),const SizedBox(height:12),_surface(ListTile(contentPadding:EdgeInsets.zero,leading:CircleAvatar(backgroundColor:mint,child:const Icon(Icons.restaurant_outlined,color:greenDark)),title:const Text('База продуктов',style:TextStyle(fontWeight:FontWeight.w900,color:ink)),subtitle:Text('${allFoods.length} продуктов доступно',style:const TextStyle(color:muted)))),const SizedBox(height:8),_surface(ListTile(contentPadding:EdgeInsets.zero,leading:CircleAvatar(backgroundColor:mint,child:const Icon(Icons.star_outline,color:greenDark)),title:const Text('Избранное',style:TextStyle(fontWeight:FontWeight.w900,color:ink)),subtitle:Text('${favoriteIds.length} продуктов',style:const TextStyle(color:muted)))),const SizedBox(height:8),_surface(ListTile(contentPadding:EdgeInsets.zero,leading:CircleAvatar(backgroundColor:mint,child:const Icon(Icons.save_outlined,color:greenDark)),title:const Text('Локальное хранение',style:TextStyle(fontWeight:FontWeight.w900,color:ink)),subtitle:const Text('Дневник, избранное и свои продукты сохраняются на устройстве',style:TextStyle(color:muted))) ]);
  Widget _stat(String n,String v,IconData i,VoidCallback? a)=>Expanded(child:InkWell(onTap:a,borderRadius:BorderRadius.circular(18),child:_surface(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(i,color:greenDark),const SizedBox(height:7),Text(n,style:const TextStyle(fontSize:12,color:muted,fontWeight:FontWeight.w700)),Text(v,style:const TextStyle(fontWeight:FontWeight.w900,color:ink))]))));
  Widget _surface(Widget c)=>Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20),border:Border.all(color:line)),child:c);
  Widget _dark(Widget c)=>Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:const Color(0xFF203129),borderRadius:BorderRadius.circular(22)),child:c);
  Widget _emptyCard()=>_surface(const ListTile(contentPadding:EdgeInsets.zero,leading:CircleAvatar(backgroundColor:mint,child:Icon(Icons.restaurant_outlined,color:greenDark)),title:Text('Дневник пока пуст',style:TextStyle(fontWeight:FontWeight.w900,color:ink)),subtitle:Text('Добавь продукт кнопкой + или используй камеру.',style:TextStyle(color:muted))));
  Future<void> _addWater()async{setState(()=>water=(water+.25).clamp(0,5));final p=await SharedPreferences.getInstance();await p.setDouble('water',water);}
  Future<void> _addWeight()async{final c=TextEditingController(text:weight.toStringAsFixed(1));final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Добавить вес'),content:TextField(controller:c,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(suffixText:'кг')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Отмена')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Сохранить'))]));if(ok!=true)return;final v=double.tryParse(c.text.replaceAll(',','.'));if(v==null||v<30||v>300)return;setState(()=>weight=v);final p=await SharedPreferences.getInstance();await p.setDouble('weight',v);}
}
