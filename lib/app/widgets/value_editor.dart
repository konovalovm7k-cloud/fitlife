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
  });

  final String title;
  final List<NumberFieldSpec> fields;
  final String? initialName;
  final bool allowDelete;
  final String saveLabel;
  final String? Function(List<double>)? validate;

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

  void _save() {
    if (!_form.currentState!.validate()) return;
    final values = _controllers.map((field) => _parse(field.text)!).toList();
    final error = widget.validate?.call(values);
    setState(() => _error = error);
    if (error != null) return;
    Navigator.pop(
      context,
      ValueEditResult(values: values, name: _name.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
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
          onPressed: () =>
              Navigator.pop(context, const ValueEditResult(deleted: true)),
          child: const Text('Удалить'),
        ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Отмена'),
      ),
      FilledButton(onPressed: _save, child: Text(widget.saveLabel)),
    ],
  );
}
