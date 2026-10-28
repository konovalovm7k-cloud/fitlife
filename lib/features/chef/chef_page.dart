import 'package:flutter/material.dart';
import '../photo_analysis/photo_models.dart';
import '../photo_analysis/photo_review_page.dart';
import '../photo_analysis/photo_service.dart';
import '../photo_analysis/photo_settings_page.dart';
import 'chef_catalogue.dart';

class ChefPage extends StatefulWidget {
  const ChefPage({
    super.key,
    required this.day,
    required this.meal,
    required this.onSave,
    this.store = const PhotoConnectionStore(),
    this.createService,
    this.loadCatalogue = loadChefCatalogue,
  });
  final DateTime day;
  final String meal;
  final Future<void> Function(PhotoMeal) onSave;
  final PhotoConnectionStore store;
  final PhotoService Function()? createService;
  final Future<ChefCatalogue> Function() loadCatalogue;
  @override
  State<ChefPage> createState() => _ChefPageState();
}

class _ChefPageState extends State<ChefPage> {
  final _pantry = TextEditingController();
  PhotoService? _service;
  bool _busy = false;
  String? _error;
  int _attempt = 0;
  bool get _valid =>
      _pantry.text.trim().isNotEmpty && _pantry.text.trim().length <= 2000;
  @override
  void dispose() {
    _attempt++;
    _service?.close();
    _pantry.dispose();
    super.dispose();
  }

  Future<void> _suggest() async {
    if (_busy || !_valid) return;
    final text = _pantry.text.trim();
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
          'Подключение AI не настроено. Откройте настройки ниже или вернитесь к локальным идеям.',
        );
      }
      final catalogue = await Future<ChefCatalogue>.sync(
        widget.loadCatalogue,
      ).timeout(const Duration(seconds: 10));
      if (!mounted || attempt != _attempt) return;
      final consent = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Отправить список продуктов?'),
          scrollable: true,
          content: Text(
            'Список будет отправлен на ${connection.endpoint.host}, затем в Google Gemini. '
            'Вес, цели и остальной дневник автоматически не отправляются. В бесплатном режиме Google может использовать текст для улучшения продуктов. '
            'Не добавляйте личные или медицинские сведения. AI предложит сочетание и массу, состав возьмём из справочника. '
            'Перед записью вы проверите источники и порции. AI-сервис предназначен для пользователей 18+.',
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
      final analysis = await active.suggestMeal(connection, text, catalogue);
      if (!mounted || attempt != _attempt) return;
      if (analysis.items.isEmpty) {
        setState(
          () => _error =
              'Не нашлось подходящего сочетания. Уточните готовые продукты или выберите локальную идею.',
        );
        return;
      }
      final saved = await Navigator.push<bool>(
        context,
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
              : 'Не удалось подготовить идею. Список остался в форме; локальные идеи доступны без запроса.',
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
          'Ожидание отменено. Уже принятый сервером запрос может расходовать общий лимит.';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AI Chef')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Что есть под рукой?',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        const Text(
          'AI подберёт сочетание готовых к употреблению продуктов из проверенной подборки. Для риса, курицы и других готовых продуктов укажите уже приготовленную массу, если знаете.',
        ),
        const SizedBox(height: 16),
        Semantics(
          identifier: 'chef-pantry',
          child: TextField(
            key: const Key('chef-pantry'),
            controller: _pantry,
            enabled: !_busy,
            minLines: 3,
            maxLines: 6,
            maxLength: 2000,
            decoration: const InputDecoration(
              labelText: 'Список продуктов',
              alignLabelWithHint: true,
              hintText:
                  'Готовый рис басмати 150 г, курица 120 г, огурец и помидор',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const Text(
          'Подборка пока небольшая. Для остальных продуктов можно выбрать источник или ввести этикетку вручную при проверке блюда.',
        ),
        const SizedBox(height: 16),
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
          const Text(
            'Готовим предложение. Принятый сервером запрос расходует общий лимит AI.',
          ),
          TextButton(
            onPressed: _service == null ? null : _cancel,
            child: const Text('Отменить ожидание'),
          ),
        ],
        FilledButton.icon(
          key: const Key('chef-suggest'),
          onPressed: _busy || !_valid ? null : _suggest,
          icon: const Icon(Icons.auto_awesome_outlined),
          label: const Text('Подобрать с AI'),
        ),
        TextButton.icon(
          onPressed: _busy
              ? null
              : () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PhotoSettingsPage(store: widget.store),
                  ),
                ),
          icon: const Icon(Icons.cloud_outlined),
          label: const Text('Подключение AI'),
        ),
        OutlinedButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Вернуться к локальным идеям'),
        ),
        const SizedBox(height: 12),
        const Text(
          'Chef, камера и описание еды используют один лимит. Обычные локальные идеи не отправляют запросы.',
        ),
      ],
    ),
  );
}
