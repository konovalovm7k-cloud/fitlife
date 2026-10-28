import 'package:flutter/material.dart';
import 'learning_pages.dart';
import 'nutrition_lessons.dart';

/// A voluntary next topic from existing local marks, independent of food intake,
/// selected diary date, rewards and companion state. No extra stored progress.
class TodayLearningStep extends StatefulWidget {
  const TodayLearningStep({
    super.key,
    required this.repository,
    required this.onOpenDiary,
    this.revision = 0,
  });
  final LearningRepository repository;
  final VoidCallback onOpenDiary;
  final int revision;

  @override
  State<TodayLearningStep> createState() => _TodayLearningStepState();
}

class _TodayLearningStepState extends State<TodayLearningStep> {
  late Future<LearningProgress> _data = _load();
  bool _opening = false;

  Future<LearningProgress> _load() {
    final future = Future<LearningProgress>.sync(
      widget.repository.load,
    ).timeout(const Duration(seconds: 15));
    future.ignore();
    return future;
  }

  void _reload() {
    setState(() {
      _data = _load();
    });
  }

  @override
  void didUpdateWidget(covariant TodayLearningStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.repository != oldWidget.repository ||
        widget.revision != oldWidget.revision) {
      _data = _load();
    }
  }

  Future<void> _open(Widget page) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    } finally {
      if (mounted) {
        setState(() {
          _opening = false;
          _data = _load();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Один небольшой шаг',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      FutureBuilder<LearningProgress>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Не удалось прочитать отметки уроков. Дневник доступен.',
                ),
                TextButton(
                  onPressed: _reload,
                  child: const Text('Повторить загрузку шага'),
                ),
              ],
            );
          }
          if (!snapshot.hasData) {
            return const Text('Загружаем отметки уроков…');
          }
          final progress = snapshot.data!;
          final next = nutritionLessons
              .where((lesson) => !progress.completed.contains(lesson.id))
              .firstOrNull;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Понятно: ${progress.count} из ${nutritionLessons.length}'),
              if (progress.recovered)
                const Text(
                  'Часть отметок восстановлена. Исходная копия сохранена.',
                ),
              const SizedBox(height: 8),
              if (next == null)
                const Text(
                  'Все темы отмечены как понятные. Можно вернуться к любой '
                  'из них, когда будет удобно.',
                )
              else ...[
                Text(
                  next.title,
                  key: const Key('today-learning-topic'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(next.task),
                TextButton.icon(
                  key: const Key('today-open-task'),
                  onPressed: _opening
                      ? null
                      : () => _open(
                          LessonPage(
                            lesson: next,
                            repository: widget.repository,
                            onOpenDiary: widget.onOpenDiary,
                          ),
                        ),
                  icon: const Icon(Icons.lightbulb_outline),
                  label: const Text('Открыть задание'),
                ),
              ],
              const Text(
                'Шаг можно отложить. Отметки не оценивают ваш рацион.',
              ),
            ],
          );
        },
      ),
      TextButton.icon(
        onPressed: _opening
            ? null
            : () => _open(
                LearningPage(
                  repository: widget.repository,
                  onOpenDiary: widget.onOpenDiary,
                ),
              ),
        icon: const Icon(Icons.menu_book_outlined),
        label: const Text('Открыть короткие уроки'),
      ),
    ],
  );
}
