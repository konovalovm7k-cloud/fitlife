import 'package:flutter/material.dart';
import '../../app/fitlife_theme.dart';
import '../../data/repositories/diary_repository.dart';
import 'saved_meal_editor.dart';
import 'saved_meals.dart';

String mealDate(DateTime day) =>
    '${day.day}.${day.month.toString().padLeft(2, '0')}.${day.year}';

class SavedMealsPage extends StatefulWidget {
  const SavedMealsPage({
    super.key,
    required this.repository,
    required this.day,
    required this.initialMeal,
  });
  final SavedMealsRepository repository;
  final DateTime day;
  final String initialMeal;
  @override
  State<SavedMealsPage> createState() => _SavedMealsPageState();
}

class _SavedMealsPageState extends State<SavedMealsPage> {
  bool _previous = false;
  String _query = '';
  late Future<({List<SavedMeal> meals, bool recovered})> _data = _load();
  Future<({List<SavedMeal> meals, bool recovered})> _load() =>
      (_previous
              ? widget.repository.previousDay(widget.day)
              : widget.repository.load())
          .timeout(const Duration(seconds: 15));
  void _reload() => setState(() => _data = _load());

  Future<void> _add(SavedMeal recipe) async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _MealPortionPage(
          recipe: recipe,
          repository: widget.repository,
          day: widget.day,
          initialMeal: _previous && mealNames.contains(recipe.name)
              ? recipe.name
              : widget.initialMeal,
        ),
      ),
    );
    if (mounted && added == true) Navigator.pop(context, true);
  }

  Future<void> _edit(SavedMeal recipe) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SavedMealEditor(initial: recipe, repository: widget.repository),
      ),
    );
    if (mounted && changed == true) _reload();
  }

  Future<void> _delete(SavedMeal recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить «${recipe.name}»?'),
        content: const Text(
          'Блюдо исчезнет из библиотеки. Записи в дневнике сохранятся.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository
          .delete(recipe.id)
          .timeout(const Duration(seconds: 15));
      if (mounted) _reload();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось удалить блюдо. Повторите попытку.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Мои блюда')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Добавим в дневник за ${mealDate(widget.day)}',
                style: const TextStyle(color: muted),
              ),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Мои блюда'),
                    icon: Icon(Icons.bookmarks_outlined),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Повторить'),
                    icon: Icon(Icons.history),
                  ),
                ],
                selected: {_previous},
                onSelectionChanged: (v) => setState(() {
                  _previous = v.single;
                  _data = _load();
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Найти блюдо',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (s) =>
                    setState(() => _query = s.trim().toLowerCase()),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<({List<SavedMeal> meals, bool recovered})>(
            future: _data,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Не удалось прочитать блюда.'),
                      TextButton(
                        onPressed: _reload,
                        child: const Text('Повторить загрузку'),
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data!;
              final meals = data.meals
                  .where((m) => m.name.toLowerCase().contains(_query))
                  .toList();
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                children: [
                  if (_previous)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Приёмы пищи за ${mealDate(DateTime(widget.day.year, widget.day.month, widget.day.day - 1))}. Выберите один и проверьте порцию.',
                      ),
                    ),
                  if (data.recovered)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Часть записей повреждена. Исходные данные сохранены для восстановления.',
                      ),
                    ),
                  if (meals.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.restaurant_menu,
                            size: 52,
                            color: green,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _query.isNotEmpty
                                ? 'Ничего не найдено'
                                : _previous
                                ? 'За этот день нет записей'
                                : 'Ваши привычные блюда — здесь',
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          if (!_previous && _query.isEmpty)
                            const Text(
                              'Откройте приём пищи в дневнике и нажмите значок закладки. Сохраните состав один раз и используйте снова.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: muted),
                            ),
                        ],
                      ),
                    ),
                  for (final recipe in meals)
                    Card(
                      color: Colors.white,
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    recipe.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                if (!_previous)
                                  PopupMenuButton<String>(
                                    tooltip: 'Действия с блюдом',
                                    onSelected: (v) => v == 'edit'
                                        ? _edit(recipe)
                                        : _delete(recipe),
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Изменить состав'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Удалить блюдо'),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            Text(
                              '${recipe.total((i) => i.kcal).round()} ккал · ${recipe.total((i) => i.grams).toStringAsFixed(0)} г на порцию',
                              style: const TextStyle(
                                color: greenDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              recipe.items.map((i) => i.food.name).join(' · '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: muted),
                            ),
                            if (recipe.estimated)
                              const Text(
                                'Содержит AI-оценку',
                                style: TextStyle(color: muted, fontSize: 12),
                              ),
                            const SizedBox(height: 14),
                            FilledButton.tonalIcon(
                              onPressed: () => _add(recipe),
                              icon: const Icon(Icons.add),
                              label: const Text('Выбрать порцию'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _MealPortionPage extends StatefulWidget {
  const _MealPortionPage({
    required this.recipe,
    required this.repository,
    required this.day,
    required this.initialMeal,
  });
  final SavedMeal recipe;
  final SavedMealsRepository repository;
  final DateTime day;
  final String initialMeal;
  @override
  State<_MealPortionPage> createState() => _MealPortionPageState();
}

class _MealPortionPageState extends State<_MealPortionPage> {
  final _form = GlobalKey<FormState>();
  final _portions = TextEditingController(text: '1');
  final _operation = newDiaryEntryId();
  late String _meal = widget.initialMeal;
  late final _time = TimeOfDay.now().format(context);
  bool _saving = false;
  String? _error;
  double? get _count => double.tryParse(_portions.text.replaceAll(',', '.'));
  bool get _valid =>
      _count != null && _count!.isFinite && _count! >= 0.1 && _count! <= 20;
  @override
  void dispose() {
    _portions.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository
          .add(
            recipe: widget.recipe,
            day: widget.day,
            meal: _meal,
            portions: _count!,
            operationId: _operation,
            time: _time,
          )
          .timeout(const Duration(seconds: 15));
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Не удалось подтвердить сохранение. Повторите попытку — дубля не будет.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _valid ? _count! : 0.0;
    final recipe = widget.recipe;
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('Порция блюда')),
        body: Form(
          key: _form,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              Text(
                recipe.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Дневник за ${mealDate(widget.day)}',
                style: const TextStyle(color: muted),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: mint,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(recipe.total((i) => i.kcal) * count).round()} ккал',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: greenDark,
                      ),
                    ),
                    Text(
                      'Б ${(recipe.total((i) => i.protein) * count).toStringAsFixed(1)} г · Ж ${(recipe.total((i) => i.fat) * count).toStringAsFixed(1)} г · У ${(recipe.total((i) => i.carbs) * count).toStringAsFixed(1)} г',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _portions,
                enabled: !_saving,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Количество порций',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (_) => _valid ? null : 'Введите число от 0,1 до 20',
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final value in ['0.5', '1', '1.5', '2'])
                    ChoiceChip(
                      label: Text('$value×'),
                      selected: _count == double.parse(value),
                      onSelected: _saving
                          ? null
                          : (_) => setState(() => _portions.text = value),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _meal,
                decoration: const InputDecoration(labelText: 'Приём пищи'),
                items: [
                  for (final meal in mealNames)
                    DropdownMenuItem(value: meal, child: Text(meal)),
                ],
                onChanged: _saving ? null : (v) => setState(() => _meal = v!),
              ),
              const SizedBox(height: 20),
              for (final item in recipe.items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.food.name),
                  subtitle: Text(
                    '${(item.grams * count / recipe.servings).toStringAsFixed(1)} г · ${(item.kcal * count / recipe.servings).round()} ккал',
                  ),
                ),
              if (recipe.estimated)
                const Text(
                  'Приблизительные AI-значения сохранены. Проверьте состав и порцию.',
                  style: TextStyle(color: muted),
                ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check),
                label: Text(
                  _saving ? 'Сохраняем...' : 'Добавить блюдо в дневник',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
