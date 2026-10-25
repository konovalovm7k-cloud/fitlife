import 'package:flutter/material.dart';
import '../../app/fitlife_theme.dart';
import '../../app/widgets/value_editor.dart';
import '../../core/models/diary_item.dart';
import 'saved_meals.dart';

class SavedMealEditor extends StatefulWidget {
  const SavedMealEditor({
    super.key,
    required this.initial,
    required this.repository,
  });
  final SavedMeal initial;
  final SavedMealsRepository repository;
  @override
  State<SavedMealEditor> createState() => _SavedMealEditorState();
}

class _SavedMealEditorState extends State<SavedMealEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial.name);
  late final _servings = TextEditingController(
    text: widget.initial.servings.toString(),
  );
  late final _items = widget.initial.items.toList();
  bool _saving = false;
  String? _error;
  double? get _count => double.tryParse(_servings.text.replaceAll(',', '.'));
  @override
  void dispose() {
    _name.dispose();
    _servings.dispose();
    super.dispose();
  }

  Future<void> _edit(int index) async {
    final item = _items[index];
    final result = await showDialog<ValueEditResult>(
      context: context,
      builder: (_) => ValueEditorDialog(
        title: item.food.name,
        allowDelete: _items.length > 1,
        fields: [
          NumberFieldSpec(
            'Граммы в составе',
            item.grams,
            min: 0.1,
            max: 100000,
          ),
        ],
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      if (result.deleted) {
        _items.removeAt(index);
      } else {
        _items[index] = DiaryItem(
          id: item.id,
          meal: item.meal,
          food: item.food,
          grams: result.values.single,
          time: item.time,
        );
      }
    });
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository
          .save(
            SavedMeal(
              id: widget.initial.id,
              name: _name.text.trim(),
              items: _items,
              servings: _count!,
            ),
          )
          .timeout(const Duration(seconds: 15));
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Не удалось сохранить. Состав остался здесь — повторите попытку.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _count;
    final kcal = count != null && count.isFinite && count >= 0.1 && count <= 100
        ? _items.fold(0.0, (sum, item) => sum + item.kcal) / count
        : null;
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('Сохранить блюдо')),
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
              const Text(
                'Знакомый вкус — в пару касаний',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Сохраним продукты и их вес. При добавлении в дневник можно выбрать часть порции.',
                style: TextStyle(color: muted),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _name,
                enabled: !_saving,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Название блюда'),
                validator: (s) =>
                    s == null || s.trim().isEmpty ? 'Введите название' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _servings,
                enabled: !_saving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Порций во всём составе',
                  helperText: 'Например, 2 — если приготовили на двоих',
                ),
                validator: (_) =>
                    _count == null ||
                        !_count!.isFinite ||
                        _count! < 0.1 ||
                        _count! > 100
                    ? 'Введите число от 0,1 до 100'
                    : null,
              ),
              const SizedBox(height: 24),
              Text(
                kcal == null
                    ? 'Состав блюда'
                    : '${kcal.round()} ккал на порцию',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: greenDark,
                ),
              ),
              if (widget.initial.estimated)
                const Text(
                  'Содержит приблизительную AI-оценку',
                  style: TextStyle(color: muted),
                ),
              for (var i = 0; i < _items.length; i++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_items[i].food.name),
                  subtitle: Text(
                    '${_items[i].grams.toStringAsFixed(1)} г · ${_items[i].kcal.round()} ккал',
                  ),
                  trailing: IconButton(
                    tooltip: 'Изменить ингредиент',
                    onPressed: _saving ? null : () => _edit(i),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ),
              const Text(
                'Изменения блюда не меняют уже записанные приёмы пищи.',
                style: TextStyle(color: muted),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: Text(_saving ? 'Сохраняем...' : 'Сохранить в мои блюда'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
