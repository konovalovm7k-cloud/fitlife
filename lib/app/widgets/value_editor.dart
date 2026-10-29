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

class ChoiceFieldSpec {
  const ChoiceFieldSpec(this.label, this.value, this.options);
  final String label;
  final String value;
  final List<String> options;
}

class ValueEditResult {
  const ValueEditResult({
    this.values = const [],
    this.name,
    this.choice,
    this.deleted = false,
  });
  final List<double> values;
  final String? name;
  final String? choice;
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
    this.summaryBuilder,
    this.detailsBuilder,
    this.choice,
  });

  final String title;
  final List<NumberFieldSpec> fields;
  final String? initialName;
  final bool allowDelete;
  final String saveLabel;
  final String? Function(List<double>)? validate;
  final Future<void> Function(ValueEditResult)? onSave;
  final String? Function(List<double>)? summaryBuilder;
  final Widget Function(List<double> values, bool saving)? detailsBuilder;
  final ChoiceFieldSpec? choice;

  @override
  State<ValueEditorDialog> createState() => _ValueEditorDialogState();
}

class _ValueEditorDialogState extends State<ValueEditorDialog> {
  final _form = GlobalKey<FormState>();
  late final _controllers = widget.fields
      .map((field) => TextEditingController(text: field.value.toString()))
      .toList();
  late final _name = TextEditingController(text: widget.initialName);
  late String? _choice = widget.choice?.value;
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

  List<double>? get _validValues {
    final values = <double>[];
    for (var i = 0; i < _controllers.length; i++) {
      final value = _parse(_controllers[i].text);
      final spec = widget.fields[i];
      if (value == null ||
          !value.isFinite ||
          value < spec.min ||
          value > spec.max) {
        return null;
      }
      values.add(value);
    }
    return values;
  }

  String? get _summaryText {
    final values = _validValues;
    return values == null ? null : widget.summaryBuilder?.call(values);
  }

  Widget? get _detailsWidget {
    if (widget.detailsBuilder == null) return null;
    final values = _validValues;
    return values == null ? null : widget.detailsBuilder!(values, _saving);
  }

  void _save() {
    if (_saving) return;
    if (!_form.currentState!.validate()) return;
    final values = _controllers.map((field) => _parse(field.text)!).toList();
    final error = widget.validate?.call(values);
    setState(() => _error = error);
    if (error != null) return;
    _submit(
      ValueEditResult(values: values, name: _name.text.trim(), choice: _choice),
    );
  }

  Future<void> _submit(ValueEditResult result) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave?.call(result);
      if (mounted) Navigator.pop(context, result);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Не удалось сохранить. Проверь свободное место и повтори.';
      });
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
                controller: _name,
                readOnly: _saving,
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
              Semantics(
                identifier: 'value-editor-number-$i',
                child: TextFormField(
                  controller: _controllers[i],
                  readOnly: _saving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: widget.fields[i].label,
                  ),
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
                  onChanged:
                      widget.summaryBuilder == null &&
                          widget.detailsBuilder == null
                      ? null
                      : (_) => setState(() => _error = null),
                ),
              ),
              if (i < widget.fields.length - 1) const SizedBox(height: 12),
            ],
            if (widget.choice case final choice?) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _choice,
                isExpanded: true,
                decoration: InputDecoration(labelText: choice.label),
                items: choice.options
                    .map(
                      (option) =>
                          DropdownMenuItem(value: option, child: Text(option)),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _choice = value),
                validator: (value) =>
                    choice.options.contains(value) ? null : 'Выберите значение',
              ),
            ],
            if (_summaryText case final summary?) ...[
              const SizedBox(height: 12),
              Text(summary),
            ],
            if (_detailsWidget case final details?) ...[
              const SizedBox(height: 12),
              details,
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
