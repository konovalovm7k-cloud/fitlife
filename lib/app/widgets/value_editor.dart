import 'package:flutter/material.dart';

class NumberFieldSpec {
  const NumberFieldSpec(
    this.label,
    this.value, {
    this.min = 0,
    this.max = 10000,
  });
  final String label;
  final double value;
  final double min;
  final double max;
}

class ValueEditResult {
  const ValueEditResult({
    this.values = const [],
    this.name,
    this.deleted = false,
  });
  final List<double> values;
  final String? name;
  final bool deleted;
}

class ValueEditorDialog extends StatefulWidget {
  const ValueEditorDialog({
    super.key,
    required this.title,
    required this.fields,
    this.initialName,
    this.allowDelete = false,
    this.validate,
    this.saveLabel = 'Сохранить',
    this.onSave,
  });

  final String title;
  final List<NumberFieldSpec> fields;
  final String? initialName;
  final bool allowDelete;
  final String saveLabel;
  final String? Function(List<double>)? validate;
  final Future<void> Function(ValueEditResult)? onSave;

  @override
  State<ValueEditorDialog> createState() => _ValueEditorDialogState();
}

class _ValueEditorDialogState extends State<ValueEditorDialog> {
  final _form = GlobalKey<FormState>();
  late final _controllers = widget.fields
      .map((field) => TextEditingController(text: field.value.toString()))
      .toList();
  late final _name = TextEditingController(text: widget.initialName);
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    _name.dispose();
    super.dispose();
  }

  double? _parse(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    if (_saving) return;
    if (!_form.currentState!.validate()) return;
    final values = _controllers.map((field) => _parse(field.text)!).toList();
    final error = widget.validate?.call(values);
    setState(() => _error = error);
    if (error != null) return;
    await _submit(ValueEditResult(values: values, name: _name.text.trim()));
  }

  Future<void> _submit(ValueEditResult result) async {
    if (_saving) return;
    if (widget.onSave == null) {
      Navigator.pop(context, result);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave!(result).timeout(const Duration(seconds: 15));
      if (mounted) Navigator.pop(context, result);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Не удалось сохранить. Введённые данные остались здесь. Повторите попытку.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: Text(widget.title),
      scrollable: true,
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.initialName != null) ...[
              TextFormField(
                enabled: !_saving,
                controller: _name,
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Название'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Укажи название'
                    : null,
              ),
              const SizedBox(height: 12),
            ],
            for (var i = 0; i < widget.fields.length; i++) ...[
              TextFormField(
                enabled: !_saving,
                controller: _controllers[i],
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(labelText: widget.fields[i].label),
                validator: (text) {
                  final value = _parse(text ?? '');
                  final spec = widget.fields[i];
                  return value == null ||
                          !value.isFinite ||
                          value < spec.min ||
                          value > spec.max
                      ? 'Введи число от ${spec.min} до ${spec.max}'
                      : null;
                },
                onFieldSubmitted: (_) =>
                    i == widget.fields.length - 1 ? _save() : null,
              ),
              if (i < widget.fields.length - 1) const SizedBox(height: 12),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (widget.allowDelete)
          TextButton(
            onPressed: _saving
                ? null
                : () => _submit(const ValueEditResult(deleted: true)),
            child: const Text('Удалить'),
          ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Сохраняем...' : widget.saveLabel),
        ),
      ],
    ),
  );
}
