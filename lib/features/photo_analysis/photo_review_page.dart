import 'package:flutter/material.dart';
import '../../app/fitlife_theme.dart';
import '../../app/widgets/value_editor.dart';
import '../../core/models/nutrition_profile.dart';
import 'photo_models.dart';

class PhotoReviewPage extends StatefulWidget {
  const PhotoReviewPage({
    super.key,
    required this.analysis,
    required this.day,
    required this.initialMeal,
    required this.onSave,
  });
  final PhotoAnalysis analysis;
  final DateTime day;
  final String initialMeal;
  final Future<void> Function(PhotoMeal) onSave;
  @override
  State<PhotoReviewPage> createState() => _PhotoReviewPageState();
}

class _PhotoReviewPageState extends State<PhotoReviewPage> {
  late final _items = [...widget.analysis.items];
  late String _meal = widget.initialMeal;
  bool _saving = false;
  String? _error;
  Future<void> _edit(int? index) async {
    final item = index == null ? null : _items[index];
    final p =
        item?.nutrition ??
        const NutritionProfile(kcal: 0, protein: 0, fat: 0, carbs: 0, fiber: 0);
    final result = await showDialog<ValueEditResult>(
      context: context,
      builder: (_) => ValueEditorDialog(
        title: 'Продукт и порция',
        initialName: item?.name ?? '',
        allowDelete: item != null,
        fields: [
          NumberFieldSpec(
            'Вес порции, г',
            item?.grams ?? 100,
            min: 1,
            max: 3000,
          ),
          NumberFieldSpec('Ккал на 100 г', p.kcal, max: 1000),
          NumberFieldSpec('Белки на 100 г', p.protein, max: 100),
          NumberFieldSpec('Жиры на 100 г', p.fat, max: 100),
          NumberFieldSpec('Углеводы на 100 г', p.carbs, max: 100),
          NumberFieldSpec('Клетчатка на 100 г', p.fiber, max: 100),
        ],
        validate: (v) => v[2] + v[3] + v[4] > 105
            ? 'Проверьте КБЖУ: сумма превышает 100 г.'
            : null,
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      if (result.deleted) {
        _items.removeAt(index!);
        return;
      }
      final v = result.values;
      final updated = PhotoFood(
        name: result.name!,
        grams: v[0],
        nutrition: NutritionProfile(
          kcal: v[1],
          protein: v[2],
          fat: v[3],
          carbs: v[4],
          fiber: v[5],
        ),
        confidence: item?.confidence ?? 'low',
      );
      if (index == null) {
        _items.add(updated);
      } else {
        _items[index] = updated;
      }
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_saving || _items.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
        PhotoMeal(
          id: widget.analysis.requestId,
          day: widget.day,
          meal: _meal,
          items: List.unmodifiable(_items),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Не удалось сохранить в дневник. '
              'Ваши правки остались на этом экране. Нажмите ещё раз.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kcal = _items.fold(0.0, (sum, f) => sum + f.calories);
    double total(double Function(NutritionProfile) get) =>
        _items.fold(0.0, (sum, f) => sum + get(f.nutrition) * f.grams / 100);
    final date =
        '${widget.day.day.toString().padLeft(2, '0')}.${widget.day.month.toString().padLeft(2, '0')}.${widget.day.year}';
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('Проверьте блюдо')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: greenDark,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ОЦЕНКА ПО ФОТО',
                    style: TextStyle(color: Colors.white70, letterSpacing: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '≈ ${kcal.round()} ккал',
                    key: const Key('photo-total'),
                    style: const TextStyle(
                      fontSize: 34,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Б ${total((p) => p.protein).round()} · Ж ${total((p) => p.fat).round()} · '
                    'У ${total((p) => p.carbs).round()} г',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Запись за $date',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Уточните вес и состав. Масло, соусы и скрытые ингредиенты могут '
              'изменить калорийность. Все значения приблизительные.',
            ),
            for (final warning in widget.analysis.warnings)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('• $warning'),
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _meal,
              decoration: const InputDecoration(labelText: 'Приём пищи'),
              items: photoMeals
                  .map(
                    (meal) => DropdownMenuItem(value: meal, child: Text(meal)),
                  )
                  .toList(),
              onChanged: _saving ? null : (v) => setState(() => _meal = v!),
            ),
            const SizedBox(height: 16),
            if (_items.isEmpty)
              const Text(
                'Продуктов пока нет. Добавьте вручную или вернитесь к фото.',
              ),
            for (var i = 0; i < _items.length; i++)
              Card(
                child: ListTile(
                  onTap: _saving ? null : () => _edit(i),
                  title: Text(_items[i].name),
                  subtitle: Text(
                    '${_items[i].grams.round()} г · ≈ ${_items[i].calories.round()} ккал\n'
                    'Уверенность: ${switch (_items[i].confidence) {
                      'high' => 'высокая',
                      'medium' => 'средняя',
                      _ => 'низкая',
                    }}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.edit_outlined),
                ),
              ),
            OutlinedButton.icon(
              onPressed: _saving || _items.length >= 12
                  ? null
                  : () => _edit(null),
              icon: const Icon(Icons.add),
              label: const Text('Добавить ингредиент'),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            FilledButton.icon(
              key: const Key('photo-save'),
              onPressed: _saving || _items.isEmpty ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_saving ? 'Сохраняем…' : 'Подтвердить и сохранить'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
