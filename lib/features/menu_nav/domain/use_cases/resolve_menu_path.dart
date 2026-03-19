import '../../../../shared/domain/entities/menu_tree.dart';
import '../../../../shared/domain/entities/nav_path.dart';
import '../../../../shared/domain/entities/settings_result.dart';

/// Resolved menu navigation display data.
class MenuNavDisplay {
  final String header;
  final String subheader;
  final DialSection? dialSection;
  final QuickAccessSection? quickAccessSection;
  final FullMenuSection? fullMenuSection;
  final List<TipDisplay> tips;

  const MenuNavDisplay({
    required this.header,
    required this.subheader,
    this.dialSection,
    this.quickAccessSection,
    this.fullMenuSection,
    this.tips = const [],
  });
}

class DialSection {
  final String title;
  final String instruction;

  const DialSection({required this.title, required this.instruction});
}

class QuickAccessSection {
  final String title;
  final List<String> steps;

  const QuickAccessSection({required this.title, required this.steps});
}

class FullMenuSection {
  final String title;
  final String pressMenuLabel;
  final List<MenuNavStep> steps;

  const FullMenuSection({
    required this.title,
    required this.pressMenuLabel,
    required this.steps,
  });
}

class MenuNavStep {
  final int stepNumber;
  final int totalSteps;
  final String label;
  final String? detail;

  const MenuNavStep({
    required this.stepNumber,
    required this.totalSteps,
    required this.label,
    this.detail,
  });
}

class TipDisplay {
  final String text;

  const TipDisplay({required this.text});
}

/// Resolves a setting recommendation into a localized menu navigation display.
class ResolveMenuPath {
  const ResolveMenuPath();

  MenuNavDisplay? resolve({
    required String settingId,
    required SettingRecommendation setting,
    required SettingNavPath? navPath,
    required MenuTree menuTree,
    required String bodyName,
    required String lang,
  }) {
    if (navPath == null) return null;

    // Header: "Mode AF → AF-C"
    final menuItem = menuTree.findBySetting(settingId);
    final settingLabel = menuItem?.label(lang) ?? settingId;

    // Resolve value label from menu tree
    String valueLabel = setting.valueDisplay;
    if (menuItem != null && menuItem.values != null) {
      final valueId = _normalizeValueId(setting.value);
      for (final v in menuItem.values!) {
        if (v.id == valueId) {
          valueLabel =
              '${v.shortLabel(lang)} (${v.label(lang)})';
          break;
        }
      }
    }

    final header = '$settingLabel → $valueLabel';
    final subheader = '$bodyName · Menus en ${_langName(lang)}';

    // Dial access
    DialSection? dialSection;
    if (navPath.hasDialAccess) {
      dialSection = DialSection(
        title: 'Méthode rapide (molette)',
        instruction: navPath.dialAccess!.label(lang),
      );
    }

    // Quick access (Fn menu)
    QuickAccessSection? quickAccessSection;
    if (navPath.hasQuickAccess) {
      quickAccessSection = QuickAccessSection(
        title: 'Méthode rapide (Fn)',
        steps: navPath.quickAccess!.steps
            .map((s) => s.label(lang))
            .toList(),
      );
    }

    // Full menu path
    FullMenuSection? fullMenuSection;
    if (navPath.hasMenuPath) {
      final steps = <MenuNavStep>[];
      final path = navPath.menuPath!;

      for (var i = 0; i < path.length; i++) {
        final item = menuTree.findItemById(path[i]);
        final label = item?.label(lang) ?? path[i];
        steps.add(MenuNavStep(
          stepNumber: i + 1,
          totalSteps: path.length,
          label: label,
        ));
      }

      fullMenuSection = FullMenuSection(
        title: 'Via le menu',
        pressMenuLabel: 'Appuie sur MENU',
        steps: steps,
      );
    }

    // Tips
    final tips = navPath.tips
        .map((t) => TipDisplay(text: t.label(lang)))
        .toList();

    return MenuNavDisplay(
      header: header,
      subheader: subheader,
      dialSection: dialSection,
      quickAccessSection: quickAccessSection,
      fullMenuSection: fullMenuSection,
      tips: tips,
    );
  }

  String _normalizeValueId(dynamic value) {
    if (value is Enum) {
      return value.name
          .replaceAllMapped(
              RegExp(r'[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}')
          .replaceFirst(RegExp(r'^_'), '');
    }
    return value.toString().toLowerCase().replaceAll(' ', '-');
  }

  String _langName(String lang) => switch (lang) {
        'fr' => 'Français',
        'en' => 'English',
        'de' => 'Deutsch',
        'ja' => '日本語',
        _ => lang,
      };
}
