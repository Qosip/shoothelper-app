import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../shared/domain/entities/optical_filter.dart';
import '../../../../shared/presentation/providers/filter_providers.dart';
import '../../../../shared/presentation/theme/app_colors.dart';
import '../../../../shared/presentation/theme/app_spacing.dart';
import '../../../../shared/presentation/theme/app_typography.dart';

/// Bottom sheet for managing user's optical filters.
class FilterManagementSheet extends ConsumerStatefulWidget {
  const FilterManagementSheet({super.key});

  @override
  ConsumerState<FilterManagementSheet> createState() =>
      _FilterManagementSheetState();
}

class _FilterManagementSheetState
    extends ConsumerState<FilterManagementSheet> {
  String _selectedType = 'nd';
  int _ndStops = 6;
  int _ndVarMin = 2;
  int _ndVarMax = 5;
  int _diameterMm = 67;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkDivider
                      : AppColors.lightDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            Text('AJOUTER UN FILTRE', style: AppTypography.overline),
            const SizedBox(height: AppSpacing.md),

            // Filter type selector
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                _typeChip('nd', 'ND', isDark),
                _typeChip('nd_variable', 'ND Variable', isDark),
                _typeChip('cpl', 'CPL', isDark),
                _typeChip('uv', 'UV', isDark),
              ],
            ),
            const SizedBox(height: AppSpacing.base),

            // Type-specific fields
            if (_selectedType == 'nd') ...[
              Text('Densité (stops)', style: AppTypography.caption),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [1, 2, 3, 4, 5, 6, 7, 8, 10]
                    .map((s) => ChoiceChip(
                          label: Text('$s'),
                          selected: _ndStops == s,
                          onSelected: (_) => setState(() => _ndStops = s),
                        ))
                    .toList(),
              ),
            ],
            if (_selectedType == 'nd_variable') ...[
              Text('Plage (stops)', style: AppTypography.caption),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text('Min: $_ndVarMin', style: AppTypography.body),
                  Expanded(
                    child: Slider(
                      min: 1,
                      max: 5,
                      divisions: 4,
                      value: _ndVarMin.toDouble(),
                      onChanged: (v) =>
                          setState(() => _ndVarMin = v.round()),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text('Max: $_ndVarMax', style: AppTypography.body),
                  Expanded(
                    child: Slider(
                      min: 3,
                      max: 10,
                      divisions: 7,
                      value: _ndVarMax.toDouble(),
                      onChanged: (v) =>
                          setState(() => _ndVarMax = v.round()),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: AppSpacing.md),
            Text('Diamètre (mm)', style: AppTypography.caption),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [46, 49, 52, 55, 58, 62, 67, 72, 77, 82]
                  .map((d) => ChoiceChip(
                        label: Text('$d'),
                        selected: _diameterMm == d,
                        onSelected: (_) =>
                            setState(() => _diameterMm = d),
                      ))
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.xl),

            FilledButton(
              onPressed: () => _addFilter(context),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: AppColors.blueOptique,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.plus, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Ajouter',
                      style: AppTypography.title
                          .copyWith(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String type, String label, bool isDark) {
    final selected = _selectedType == type;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _selectedType = type),
    );
  }

  void _addFilter(BuildContext context) {
    final id =
        '${_selectedType}_${_diameterMm}_${DateTime.now().millisecondsSinceEpoch}';
    final OpticalFilter filter;

    switch (_selectedType) {
      case 'nd':
        final ndValue = _ndPower(_ndStops);
        filter = NdFilter(
          id: id,
          name: 'ND$ndValue',
          stops: _ndStops,
          filterDiameterMm: _diameterMm,
        );
      case 'nd_variable':
        filter = NdVariableFilter(
          id: id,
          name: 'ND Variable $_ndVarMin-$_ndVarMax',
          minStops: _ndVarMin,
          maxStops: _ndVarMax,
          filterDiameterMm: _diameterMm,
        );
      case 'cpl':
        filter = CplFilter(
          id: id,
          name: 'CPL ${_diameterMm}mm',
          lightLoss: 1.5,
          filterDiameterMm: _diameterMm,
        );
      case 'uv':
        filter = UvFilter(
          id: id,
          name: 'UV ${_diameterMm}mm',
          filterDiameterMm: _diameterMm,
        );
      default:
        return;
    }

    ref.read(filterStoreProvider).addFilter(filter);
    ref.invalidate(userFiltersProvider);
    Navigator.pop(context);
  }

  int _ndPower(int stops) {
    // ND2=1stop, ND4=2, ND8=3, etc.
    int v = 1;
    for (int i = 0; i < stops; i++) {
      v *= 2;
    }
    return v;
  }
}
