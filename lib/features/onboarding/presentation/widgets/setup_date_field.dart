import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SetupDateField extends StatelessWidget {
  const SetupDateField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.errorText,
    super.key,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey('$label-${value?.millisecondsSinceEpoch}'),
      initialValue: value == null ? '' : DateFormat.yMMMd().format(value!),
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today_outlined),
        suffixIcon: const Icon(Icons.expand_more_rounded),
        errorText: errorText,
      ),
      onTap: () async {
        FocusScope.of(context).unfocus();
        final today = DateUtils.dateOnly(DateTime.now());
        final selected = await showDatePicker(
          context: context,
          initialDate: value ?? today,
          firstDate: DateTime(today.year - 5),
          lastDate: DateTime(today.year + 10, 12, 31),
          helpText: 'Select $label',
        );
        if (selected != null) onChanged(DateUtils.dateOnly(selected));
      },
    );
  }
}
