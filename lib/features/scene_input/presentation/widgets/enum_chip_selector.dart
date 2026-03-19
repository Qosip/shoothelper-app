import 'package:flutter/material.dart';

/// A row of filter chips for selecting an enum value.
class EnumChipSelector<T extends Enum> extends StatelessWidget {
  final String label;
  final List<T> values;
  final T? selected;
  final ValueChanged<T> onSelected;
  final String Function(T) displayName;

  const EnumChipSelector({
    super.key,
    required this.label,
    required this.values,
    required this.selected,
    required this.onSelected,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: values.map((v) {
            final isSelected = v == selected;
            return FilterChip(
              label: Text(displayName(v)),
              selected: isSelected,
              onSelected: (_) => onSelected(v),
            );
          }).toList(),
        ),
      ],
    );
  }
}
