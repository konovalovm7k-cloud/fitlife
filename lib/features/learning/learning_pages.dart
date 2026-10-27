import 'package:flutter/material.dart';
import '../../app/nutrition_goal_format.dart';
import '../../app/portion_format.dart';
import 'nutrition_lessons.dart';

class LearningPage extends StatefulWidget {
  const LearningPage({super.key, required this.repository, this.onOpenDiary});
  final LearningRepository repository;
  final VoidCallback? onOpenDiary;
  @override
  State<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends State<LearningPage> {
  late Future<LearningProgress> _data = _load();
  Future<LearningProgress> _load() {
    final data = widget.repository.load().timeout(const Duration(seconds: 15));
    data.ignore(); // FutureBuilder may attach on the frame after a fast retry.
    return data;
  }

  void _reload() {
    final data = _load();
    setState(() {
      _data = data;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Короткие уроки')),
    body: FutureBuilder<LearningProgress>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Не удалось загрузить отметки уроков.'),
                TextButton(onPressed: _reload, child: const Text('Повторить')),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final progress = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Один небольшой шаг, когда вам удобно. Уроки и задания '
              'работают без интернета; можно вернуться к любой теме.',
            ),
            const SizedBox(height: 12),
            Text(
              'Понятно: ${progress.count} из ${nutritionLessons.length}',
              key: const Key('learning-progress'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (progress.recovered)
              const Text(
                'Часть отметок повреждена. '
                'Доступные отметки восстановлены, исходная копия сохранена.',
              ),
            const SizedBox(height: 12),
            for (final lesson in nutritionLessons)
              Card(
                child: ListTile(
                  key: Key(lesson.id),
                  title: Text(lesson.title),
                  subtitle: Text(
                    progress.completed.contains(lesson.id)
                        ? 'Отмечено как понятное'
                        : 'Короткий урок и небольшое задание',
                  ),
                  trailing: Icon(
                    progress.completed.contains(lesson.id)
                        ? Icons.check_circle_outline
                        : Icons.chevron_right,
                  ),
                  onTap: () async {
                    await Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LessonPage(
                          lesson: lesson,
                          repository: widget.repository,
                          initiallyCompleted: progress.completed.contains(
                            lesson.id,
                          ),
                          onOpenDiary: widget.onOpenDiary,
                        ),
                      ),
                    );
                    if (mounted) _reload();
                  },
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'Отметки уроков не оценивают ваш рацион и не меняют цели '
              'питания, награды или состояние питомца.',
            ),
          ],
        );
      },
    ),
  );
}

class LessonPage extends StatefulWidget {
  const LessonPage({
    super.key,
    required this.lesson,
    required this.repository,
    this.initiallyCompleted = false,
    this.onOpenDiary,
  });
  final NutritionLesson lesson;
  final LearningRepository repository;
  final bool initiallyCompleted;
  final VoidCallback? onOpenDiary;
  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  late bool _completed = widget.initiallyCompleted;
  bool _saving = false;
  String? _error;
  double _servings = 1;
  Future<void> _mark() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final target = !_completed;
    try {
      await widget.repository.mark(widget.lesson.id, target);
      if (mounted) setState(() => _completed = target);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Не удалось сохранить отметку. Попробуйте ещё раз.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final portion = teachingPortion(227 * _servings);
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.lesson.title)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final text in widget.lesson.paragraphs)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(text),
              ),
            if (widget.lesson.id == 'portions_v1') ...[
              Wrap(
                spacing: 8,
                children: [
                  for (final value in [.5, 1.0, 2.0])
                    ChoiceChip(
                      label: Text(
                        value == .5
                            ? '½ порции'
                            : value == 1
                            ? '1 порция'
                            : '2 порции',
                      ),
                      selected: _servings == value,
                      onSelected: _saving
                          ? null
                          : (_) => setState(() => _servings = value),
                    ),
                ],
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Учебный пример · не добавляется в дневник'),
                      Text(
                        '${formatFoodGrams(227 * _servings)} г · ${portion.kcal.round()} ккал',
                        key: const Key('teaching-portion'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Б ${formatNutritionGoal(portion.protein)} г · '
                        'Ж ${formatNutritionGoal(portion.fat)} г · У ${formatNutritionGoal(portion.carbs)} г',
                      ),
                      Text('Клетчатка ${formatNutritionGoal(portion.fiber)} г'),
                      const Text(
                        'Основа пересчёта для FitLife: 123,35 ккал на 100 г '
                        '(округлено для отображения).',
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Попробуйте, если удобно',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(widget.lesson.task),
            if (widget.onOpenDiary != null)
              TextButton.icon(
                key: const Key('lesson-open-diary'),
                onPressed: _saving ? null : widget.onOpenDiary,
                icon: const Icon(Icons.restaurant_outlined),
                label: const Text('Открыть дневник'),
              ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            FilledButton(
              key: const Key('lesson-mark'),
              onPressed: _saving ? null : _mark,
              child: Text(
                _saving
                    ? 'Сохраняем…'
                    : _completed
                    ? 'Отменить отметку'
                    : 'Понятно, отметить',
              ),
            ),
            const SizedBox(height: 20),
            const Text('Источники · проверены 27.10.2026'),
            for (final source in widget.lesson.sources)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: SelectableText('${source.title}\n${source.url}'),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
