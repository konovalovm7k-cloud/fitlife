import 'package:flutter/material.dart';
import 'photo_service.dart';

class PhotoSettingsPage extends StatefulWidget {
  const PhotoSettingsPage({
    super.key,
    this.store = const PhotoConnectionStore(),
  });
  final PhotoConnectionStore store;
  @override
  State<PhotoSettingsPage> createState() => _PhotoSettingsPageState();
}

class _PhotoSettingsPageState extends State<PhotoSettingsPage> {
  final _address = TextEditingController();
  final _token = TextEditingController();
  final _form = GlobalKey<FormState>();
  PhotoConnection? _existing;
  bool _busy = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _read();
  }

  Future<void> _read() async {
    try {
      final existing = await widget.store.read();
      if (!mounted) return;
      _existing = existing;
      _address.text = existing?.address ?? '';
    } catch (_) {
      if (mounted) {
        _error =
            'Не удалось прочитать подключение. Можно удалить его и настроить заново.';
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  void dispose() {
    _address.dispose();
    _token.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final connection = PhotoConnection(
        _address.text,
        _token.text.trim().isEmpty ? _existing!.token : _token.text.trim(),
      );
      await widget.store.write(connection);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Не удалось сохранить подключение. Повторите попытку.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clear() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.store.clear();
      _existing = null;
      _address.clear();
      _token.clear();
    } catch (_) {
      if (mounted) {
        _error = 'Не удалось удалить подключение. Повторите попытку.';
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Распознавание по фото')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(Icons.cloud_outlined, size: 56),
        const SizedBox(height: 16),
        Text(
          'Подключение к FitLife',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          widget.store.hasAutomaticConnection
              ? 'Ваша персональная сборка подключается автоматически. Ключ Google остаётся только на сервере. Ниже дополнительные настройки.'
              : 'Получите адрес сервера и личный код у владельца FitLife. '
                    'Один сервер обслуживает нескольких пользователей. Код хранится защищённо на телефоне.',
        ),
        const SizedBox(height: 20),
        if (_busy) const LinearProgressIndicator(),
        Form(
          key: _form,
          child: Column(
            children: [
              Semantics(
                label: 'Адрес сервера HTTPS',
                child: TextFormField(
                  controller: _address,
                  enabled: !_busy,
                  autocorrect: false,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Адрес сервера HTTPS',
                    hintText: 'https://fitlife-photo.example.workers.dev',
                  ),
                  validator: (v) {
                    try {
                      PhotoConnection.parseAddress(v ?? '');
                      return null;
                    } on FormatException catch (e) {
                      return e.message;
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: 'Личный код доступа',
                child: TextFormField(
                  controller: _token,
                  enabled: !_busy,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: 'Личный код доступа',
                    helperText: _existing == null
                        ? 'Код выдаёт владелец сервера'
                        : 'Оставьте пустым, чтобы сохранить текущий код',
                  ),
                  validator: (v) {
                    if ((v ?? '').trim().isEmpty && _existing != null) {
                      try {
                        if (PhotoConnection.parseAddress(
                              _address.text,
                            ).origin ==
                            _existing!.address) {
                          return null;
                        }
                      } on FormatException {
                        /* Address field shows its own error. */
                      }
                      return 'Для другого сервера нужен новый код';
                    }
                    return RegExp(
                          r'^[A-Za-z0-9_-]{43}$',
                        ).hasMatch((v ?? '').trim())
                        ? null
                        : 'Нужен код из 43 символов';
                  },
                ),
              ),
            ],
          ),
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
        FilledButton(
          onPressed: _busy ? null : _save,
          child: const Text('Сохранить подключение'),
        ),
        TextButton(
          onPressed: _busy ? null : _clear,
          child: const Text('Удалить подключение'),
        ),
        if (widget.store.hasAutomaticConnection)
          TextButton.icon(
            onPressed: _busy
                ? null
                : () async {
                    setState(() {
                      _busy = true;
                      _error = null;
                    });
                    try {
                      await widget.store.restoreAutomatic();
                      await _read();
                    } catch (_) {
                      if (mounted) {
                        setState(() {
                          _busy = false;
                          _error =
                              'Не удалось восстановить подключение. Повторите позже.';
                        });
                      }
                    }
                  },
            icon: const Icon(Icons.restart_alt),
            label: const Text('Восстановить автоподключение'),
          ),
        const SizedBox(height: 12),
        const Text(
          'Владелец: инструкция запуска находится в server/SETUP_RU.md репозитория FitLife. '
          'Ключ Google вводится только в настройках сервера.',
        ),
      ],
    ),
  );
}
