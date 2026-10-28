import 'package:flutter/material.dart';
import '../../core/models/diary_item.dart';
import '../../data/repositories/diary_repository.dart';
import 'hunger_observation.dart';
import 'satiety_estimate.dart';

const foodSinceLabels = {
  FoodSinceMeal.no: 'Нет',
  FoodSinceMeal.yes: 'Да',
  FoodSinceMeal.unknown: 'Не помню / не хочу уточнять',
};
String observationTime(DateTime value) {
  final d = value.toLocal();
  return '${d.day}.${d.month.toString().padLeft(2, '0')}.${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class HungerEntryPage extends StatefulWidget {
  const HungerEntryPage({
    super.key,
    required this.repository,
    required this.items,
    required this.meal,
    required this.day,
    this.structure,
    this.existing,
    this.clock,
  });
  final HungerRepository repository;
  final List<DiaryItem> items;
  final String meal;
  final DateTime day;
  final FoodStructure? structure;
  final HungerObservation? existing;
  final DateTime Function()? clock;
  @override
  State<HungerEntryPage> createState() => _HungerEntryPageState();
}

class _HungerEntryPageState extends State<HungerEntryPage> {
  late final _id = widget.existing?.id ?? newDiaryEntryId();
  late TimeOfDay? _mealTime = widget.existing == null
      ? null
      : TimeOfDay.fromDateTime(widget.existing!.mealAt.toLocal());
  late int? _level = widget.existing?.level;
  late FoodSinceMeal? _since = widget.existing?.foodSince;
  DateTime? _observedAt;
  bool _saving = false;
  String? _error;
  DateTime get _now => (widget.clock ?? DateTime.now)();

  Future<void> _save() async {
    if (_saving || _mealTime == null || _level == null || _since == null) {
      return;
    }
    final mealAt = DateTime(
      widget.day.year,
      widget.day.month,
      widget.day.day,
      _mealTime!.hour,
      _mealTime!.minute,
    );
    final observedAt = widget.existing?.observedAt ?? _observedAt!;
    if (!mealAt.isBefore(observedAt)) {
      setState(
        () => _error =
            'Укажите время еды раньше момента наблюдения. '
            'Можно вернуться к записи позже.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.save(
        HungerObservation(
          id: _id,
          meal: widget.meal,
          mealAt: mealAt,
          observedAt: observedAt,
          level: _level!,
          foodSince: _since!,
          items: widget.items,
          structure: widget.structure,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Не удалось сохранить наблюдение. Ваши поля остались на экране; попробуйте ещё раз.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.existing == null ? 'Отметить голод' : 'Исправить наблюдение',
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Добровольное наблюдение. Можно пропустить. '
          'FitLife сохраняет запись на устройстве и не отправляет её в AI. '
          'Оценка не влияет на цели, награды и питомца.',
        ),
        const SizedBox(height: 16),
        Text(
          '${widget.meal} · ${widget.day.day}.${widget.day.month}.${widget.day.year}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(widget.items.map((i) => i.food.name).join(', ')),
        const SizedBox(height: 12),
        OutlinedButton(
          key: const Key('hunger-meal-time'),
          onPressed: _saving
              ? null
              : () async {
                  final time = await showTimePicker(
                    context: context,
                    initialEntryMode: TimePickerEntryMode.input,
                    initialTime: _mealTime ?? TimeOfDay.fromDateTime(_now),
                  );
                  if (mounted && time != null) setState(() => _mealTime = time);
                },
          child: Text(
            _mealTime == null
                ? 'Когда закончили есть?'
                : 'Закончили есть: ${_mealTime!.format(context)}',
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.existing == null
              ? 'Какой голод вы чувствуете сейчас?'
              : 'Какой голод был в момент записи?',
        ),
        Wrap(
          spacing: 8,
          children: List.generate(
            5,
            (i) => ChoiceChip(
              label: Text(hungerLabels[i]),
              selected: _level == i + 1,
              onSelected: _saving
                  ? null
                  : (_) => setState(() {
                      _level = i + 1;
                      _observedAt = _now;
                    }),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('После этого приёма пищи ещё что-нибудь ели?'),
        Wrap(
          spacing: 8,
          children: foodSinceLabels.entries
              .map(
                (e) => ChoiceChip(
                  label: Text(e.value),
                  selected: _since == e.key,
                  onSelected: _saving
                      ? null
                      : (_) => setState(() => _since = e.key),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        if (widget.existing != null)
          Text(
            'Момент наблюдения: ${observationTime(widget.existing!.observedAt)}. '
            'При исправлении он сохраняется.',
          ),
        const Text(
          'Это личная отметка для будущей персонализации. '
          'Время между едой и записью — фактический интервал, а не прогноз сытости. '
          'Если голодны, можно поесть.',
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('hunger-save'),
          onPressed:
              !_saving && _mealTime != null && _level != null && _since != null
              ? _save
              : null,
          child: Text(_saving ? 'Сохраняем…' : 'Сохранить наблюдение'),
        ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Пропустить'),
        ),
      ],
    ),
  );
}

class HungerHistoryPage extends StatefulWidget {
  const HungerHistoryPage({super.key, required this.repository});
  final HungerRepository repository;
  @override
  State<HungerHistoryPage> createState() => _HungerHistoryPageState();
}

class _HungerHistoryPageState extends State<HungerHistoryPage> {
  late Future<List<HungerObservation>> _data = _load();
  bool _busy = false;
  String? _error;
  Future<List<HungerObservation>> _load() {
    final data = widget.repository.load().timeout(const Duration(seconds: 15));
    // Retry can fail before the next frame attaches FutureBuilder. Observe
    // errors immediately while retaining the original future/error for its UI.
    data.ignore();
    return data;
  }
  void _reload() {
    final data = _load();
    setState(() {
      _data = data;
    });
  }

  Future<void> _delete({HungerObservation? item}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          item == null ? 'Удалить все наблюдения?' : 'Удалить наблюдение?',
        ),
        content: const Text(
          'Оценки голода будут удалены. Записи еды сохранятся.',
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
    if (!mounted || confirmed != true) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (item == null) {
        await widget.repository.clear();
      } else {
        await widget.repository.delete(item.id);
      }
      if (mounted) _reload();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Не удалось удалить. Попробуйте ещё раз.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Наблюдения голода'),
      actions: [
        IconButton(
          tooltip: 'Удалить все наблюдения',
          onPressed: _busy ? null : () => _delete(),
          icon: const Icon(Icons.delete_sweep_outlined),
        ),
      ],
    ),
    body: FutureBuilder<List<HungerObservation>>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Не удалось прочитать наблюдения. Исходные данные сохранены. '
                    'Можно повторить чтение или удалить все наблюдения кнопкой вверху.',
                  ),
                  if (_error != null) Text(_error!),
                  TextButton(
                    onPressed: _reload,
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Личные отметки сохраняются на устройстве. Пока они не меняют '
              'формулу и не позволяют предсказать часы сытости. Любую запись можно исправить или удалить.',
            ),
            if (_error != null) Text(_error!),
            if (records.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Наблюдений пока нет. Откройте «Умную сытость» нужного приёма пищи '
                  'и отметьте голод спустя время, когда вам удобно.',
                ),
              ),
            for (final item in records)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${item.meal} · ${observationTime(item.mealAt)}'),
                      Text(
                        hungerLabels[item.level - 1],
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Отмечено: ${observationTime(item.observedAt)} · через ${item.elapsed.inMinutes} мин',
                      ),
                      Text('Ели после: ${foodSinceLabels[item.foodSince]}'),
                      Text(item.items.map((i) => i.food.name).join(', ')),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () async {
                                    final saved = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => HungerEntryPage(
                                          repository: widget.repository,
                                          items: item.items,
                                          meal: item.meal,
                                          day: item.mealAt.toLocal(),
                                          existing: item,
                                          structure: item.structure,
                                        ),
                                      ),
                                    );
                                    if (mounted && saved == true) {
                                      _reload();
                                    }
                                  },
                            child: const Text('Исправить'),
                          ),
                          TextButton(
                            onPressed: _busy ? null : () => _delete(item: item),
                            child: const Text('Удалить запись'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
