import 'package:flutter/material.dart';
import '../../app/fitlife_theme.dart';
import 'photo_models.dart';
import 'label_meal.dart';
import 'photo_review_page.dart';
import 'photo_service.dart';
import 'photo_settings_page.dart';

class TextMealPage extends StatefulWidget {
  const TextMealPage({
    super.key,
    required this.day,
    required this.meal,
    required this.onSave,
    this.store = const PhotoConnectionStore(),
    this.createService,
  });
  final DateTime day;
  final String meal;
  final Future<void> Function(PhotoMeal) onSave;
  final PhotoConnectionStore store;
  final PhotoService Function()? createService;

  @override
  State<TextMealPage> createState() => _TextMealPageState();
}

class _TextMealPageState extends State<TextMealPage> {
  final _description = TextEditingController();
  PhotoService? _service;
  bool _busy = false;
  String? _error;
  int _attempt = 0;

  @override
  void dispose() {
    _attempt++;
    _service?.close();
    _description.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    if (_busy || _description.text.trim().isEmpty) return;
    final description = _description.text.trim();
    final attempt = ++_attempt;
    PhotoService? service;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final connection = await widget.store.read();
      if (!mounted || attempt != _attempt) return;
      if (connection == null) {
        throw const PhotoFailure(
          'Не настроено подключение. Откройте настройки распознавания ниже.',
        );
      }
      final consent = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Отправить описание на анализ?'),
          scrollable: true,
          content: Text(
            'Введённое описание еды будет отправлено на ${connection.endpoint.host}, затем в Google Gemini. '
            'Остальной дневник не отправляется. На бесплатном тарифе Google может использовать текст для улучшения продуктов. '
            'Не указывайте личные или медицинские сведения. AI предложит продукты и порции. Источник состава вы выберете сами перед сохранением.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Отправить'),
            ),
          ],
        ),
      );
      if (consent != true || !mounted || attempt != _attempt) return;
      final active = (widget.createService ?? PhotoService.new)();
      service = active;
      setState(() => _service = active);
      final analysis = await active.analyzeText(connection, description);
      if (!mounted || attempt != _attempt) return;
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PhotoReviewPage(
            analysis: analysis,
            day: widget.day,
            initialMeal: widget.meal,
            onSave: widget.onSave,
          ),
        ),
      );
      if (saved == true && mounted && attempt == _attempt) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted && attempt == _attempt) {
        setState(
          () => _error = error is PhotoFailure
              ? error.message
              : 'Не удалось подготовить запись. Попробуйте позже.',
        );
      }
    } finally {
      service?.close();
      if (identical(service, _service)) _service = null;
      if (mounted && attempt == _attempt) setState(() => _busy = false);
    }
  }

  void _cancel() {
    _attempt++;
    _service?.close();
    _service = null;
    setState(() {
      _busy = false;
      _error =
          'Ожидание отменено. Уже принятый сервером запрос может расходовать лимит.';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Описать еду')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [mint, Color(0xfff2eddd)]),
            borderRadius: BorderRadius.circular(26),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.edit_note_rounded, color: greenDark, size: 40),
              SizedBox(height: 14),
              Text(
                'Просто расскажите,\nчто вы ели.',
                style: TextStyle(
                  fontSize: 28,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'FitLife предложит продукты и порции. Вы проверите результат и решите, что сохранить.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          key: const Key('meal-description'),
          controller: _description,
          enabled: !_busy,
          minLines: 4,
          maxLines: 6,
          maxLength: 2000,
          decoration: const InputDecoration(
            labelText: 'Что было в вашем приёме пищи?',
            alignLabelWithHint: true,
            hintText: 'Омлет из двух яиц, хлеб 40 г и кофе без сахара',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const Text(
          'Укажите вес и способ приготовления, если знаете. Неизвестные порции будут отмечены как приблизительные.',
          style: TextStyle(color: muted, fontSize: 12),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final example in [
              'Яблоко 180 г',
              'Рис варёный 150 г, курица 120 г',
              'Омлет из двух яиц',
            ])
              ActionChip(
                label: Text(example),
                backgroundColor: Colors.white,
                side: const BorderSide(color: line),
                labelStyle: const TextStyle(color: greenDark),
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _description.text = example;
                        _description.selection = TextSelection.collapsed(
                          offset: example.length,
                        );
                      }),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (_busy) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          const Text('Подготавливаем оценку…'),
          TextButton(
            onPressed: _service == null ? null : _cancel,
            child: const Text('Отменить ожидание'),
          ),
        ],
        FilledButton.icon(
          key: const Key('text-analyze'),
          onPressed: _busy || _description.text.trim().isEmpty
              ? null
              : _analyze,
          icon: const Icon(Icons.auto_awesome_outlined),
          label: const Text('Разобрать описание'),
        ),
        TextButton.icon(
          onPressed: _busy
              ? null
              : () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => PhotoSettingsPage(store: widget.store),
                  ),
                ),
          icon: const Icon(Icons.cloud_outlined),
          label: const Text('Настройки распознавания'),
        ),
        OutlinedButton.icon(
          onPressed: _busy
              ? null
              : () => openLabelMeal(
                  context,
                  day: widget.day,
                  meal: widget.meal,
                  onSave: widget.onSave,
                ),
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('Ввести состав с этикетки'),
        ),
        const Text(
          'Описание и фото используют общий лимит распознаваний. Без интернета можно добавить продукты вручную.',
          style: TextStyle(color: muted, fontSize: 12),
        ),
      ],
    ),
  );
}
