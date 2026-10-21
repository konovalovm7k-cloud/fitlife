import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/fitlife_theme.dart';
import 'photo_image.dart';
import 'photo_models.dart';
import 'photo_review_page.dart';
import 'photo_service.dart';
import 'photo_settings_page.dart';

class PhotoPage extends StatefulWidget {
  const PhotoPage({
    super.key,
    required this.day,
    required this.meal,
    required this.onManual,
    required this.onSave,
    this.store = const PhotoConnectionStore(),
    this.pickImage,
    this.createService,
  });
  final DateTime day;
  final String meal;
  final VoidCallback onManual;
  final Future<void> Function(PhotoMeal) onSave;
  final PhotoConnectionStore store;
  final Future<Uint8List?> Function(ImageSource)? pickImage;
  final PhotoService Function()? createService;
  @override
  State<PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  Uint8List? _photo;
  PhotoService? _service;
  bool _busy = false;
  String? _error;
  int _attempt = 0;
  @override
  void initState() {
    super.initState();
    if (widget.pickImage == null &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android) {
      _recoverPhoto();
    }
  }

  Future<void> _recoverPhoto() async {
    try {
      final lost = await ImagePicker().retrieveLostData();
      if (!mounted || lost.isEmpty) return;
      final files = lost.files;
      if (files != null && files.isNotEmpty) {
        final photo = await preparePhoto(await files.first.readAsBytes());
        if (mounted && _photo == null && !_busy) setState(() => _photo = photo);
      } else if (lost.exception != null) {
        setState(
          () => _error = 'Фото не восстановилось. Выберите его ещё раз.',
        );
      }
    } catch (_) {
      /* Recovery must never block diary startup. */
    }
  }

  @override
  void dispose() {
    _attempt++;
    _service?.close();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      Uint8List? bytes;
      if (widget.pickImage != null) {
        bytes = await widget.pickImage!(source);
      } else {
        final file = await ImagePicker().pickImage(
          source: source,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 90,
          requestFullMetadata: false,
        );
        if (file != null) {
          if (await file.length() > 15 * 1024 * 1024) {
            throw const PhotoFailure('Выберите фото до 15 МБ.');
          }
          bytes = await file.readAsBytes();
        }
      }
      if (bytes == null) return;
      final photo = await preparePhoto(bytes);
      if (mounted) setState(() => _photo = photo);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is PhotoFailure
              ? e.message
              : 'Не удалось открыть фото. Проверьте доступ к камере и галерее.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _settings() => Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => PhotoSettingsPage(store: widget.store)),
  );
  Future<void> _analyze() async {
    if (_busy || _photo == null) return;
    final day = widget.day;
    final meal = widget.meal;
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
        setState(
          () => _error =
              'Подключите сервер распознавания: нужны адрес и личный код доступа.',
        );
        return;
      }
      final consent = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Отправить фото на анализ?'),
          scrollable: true,
          content: Text(
            'Фото будет отправлено на ${connection.endpoint.host}, затем в Google Gemini. '
            'Метаданные и GPS удалены. На бесплатном тарифе Google может использовать фото для улучшения продуктов. '
            'Не отправляйте фото людей и документов. Результат приблизительный; перед сохранением его можно исправить.',
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
      final activeService = (widget.createService ?? PhotoService.new)();
      service = activeService;
      setState(() => _service = activeService);
      final result = await activeService.analyze(connection, _photo!);
      if (!mounted || attempt != _attempt) return;
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PhotoReviewPage(
            analysis: result,
            day: day,
            initialMeal: meal,
            onSave: widget.onSave,
          ),
        ),
      );
      if (saved == true && mounted) {
        setState(() => _photo = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Блюдо сохранено в дневник')),
        );
      }
    } catch (e) {
      if (mounted && attempt == _attempt) {
        setState(
          () => _error = e is PhotoFailure
              ? e.message
              : 'Не удалось открыть подключение. Проверьте настройки сервера.',
        );
      }
    } finally {
      service?.close();
      if (identical(_service, service)) _service = null;
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
          'Ожидание отменено. Запрос, уже принятый сервером, может расходовать лимит.';
    });
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
    children: [
      const Text(
        'Камера',
        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: ink),
      ),
      const SizedBox(height: 6),
      const Text('Фото блюда → подтверждение', style: TextStyle(color: muted)),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [mint, Color(0xfff2eddd)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            if (_photo != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.memory(
                  _photo!,
                  height: 210,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(24),
                child: Icon(
                  Icons.center_focus_strong,
                  size: 72,
                  color: greenDark,
                ),
              ),
            const SizedBox(height: 12),
            Text(
              _photo == null
                  ? 'Что сегодня на тарелке?'
                  : 'Фото готово к анализу',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Сфотографируйте блюдо сверху. FitLife предложит состав и порции, а вы уточните детали.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: _busy ? null : () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Камера'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Галерея'),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      if (_busy) ...[
        const LinearProgressIndicator(),
        const SizedBox(height: 8),
        const Text('Подготавливаем фото или ожидаем ответ…'),
        TextButton(
          onPressed: _service == null ? null : _cancel,
          child: const Text('Отменить ожидание'),
        ),
      ],
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      if (_photo != null)
        FilledButton.icon(
          key: const Key('photo-analyze'),
          onPressed: _busy ? null : _analyze,
          icon: const Icon(Icons.auto_awesome_outlined),
          label: const Text('Оценить калорийность'),
        ),
      TextButton.icon(
        onPressed: _busy ? null : _settings,
        icon: const Icon(Icons.cloud_outlined),
        label: const Text('Подключить сервер распознавания'),
      ),
      OutlinedButton.icon(
        onPressed: _busy ? null : widget.onManual,
        icon: const Icon(Icons.edit_note),
        label: const Text('Добавить продукты вручную'),
      ),
      const SizedBox(height: 12),
      const Text(
        'Распознавание требует интернета и доступа к общему серверу. '
        'Ручной дневник доступен офлайн.',
        style: TextStyle(color: muted),
      ),
    ],
  );
}
