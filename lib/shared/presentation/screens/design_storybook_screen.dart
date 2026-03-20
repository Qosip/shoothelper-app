import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/shoot_chip.dart';
import '../widgets/setting_card.dart';
import '../widgets/summary_header.dart';
import '../widgets/confidence_badge.dart';
import '../widgets/nav_step_card.dart';
import '../widgets/section_divider.dart';
import '../widgets/expand_toggle.dart';
import '../widgets/gear_badge.dart';
import '../widgets/compromise_banner.dart';
import '../widgets/bottom_sticky_bar.dart';

/// Debug screen showing all V2 design system components.
class DesignStorybookScreen extends StatefulWidget {
  const DesignStorybookScreen({super.key});

  @override
  State<DesignStorybookScreen> createState() => _DesignStorybookScreenState();
}

class _DesignStorybookScreenState extends State<DesignStorybookScreen> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Design Storybook')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.base,
              AppSpacing.base,
              AppSpacing.base,
              100,
            ),
            children: [
              // ── Typography ──
              _SectionTitle('TYPOGRAPHIE'),
              Text('Display 28pt Bold', style: AppTypography.display),
              Text('Headline 22pt SemiBold', style: AppTypography.headline),
              Text('Title 17pt SemiBold', style: AppTypography.title),
              Text('Body 15pt Regular', style: AppTypography.body),
              Text('Caption 13pt Regular', style: AppTypography.caption),
              Text('OVERLINE 11PT MEDIUM', style: AppTypography.overline),
              Text('Mono 13pt — Menu > AF/MF', style: AppTypography.mono),
              Text('Value 17pt Bold — f/2.8  1/125  ISO 400',
                  style: AppTypography.value),

              const SizedBox(height: AppSpacing.xl),

              // ── Colors ──
              _SectionTitle('COULEURS'),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _ColorSwatch('Blue Optique', AppColors.blueOptique),
                  _ColorSwatch('Success', AppColors.success),
                  _ColorSwatch('Warning', AppColors.warning),
                  _ColorSwatch('Critical', AppColors.critical),
                  _ColorSwatch('Info', AppColors.info),
                  _ColorSwatch('EV Low', AppColors.evLow),
                  _ColorSwatch('EV Med', AppColors.evMedium),
                  _ColorSwatch('EV High', AppColors.evHigh),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── ShootChip ──
              _SectionTitle('SHOOT CHIP'),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ShootChip(label: 'Portrait', icon: LucideIcons.user),
                  ShootChip(
                    label: 'Paysage',
                    icon: LucideIcons.mountain,
                    state: ShootChipState.selected,
                  ),
                  ShootChip(
                    label: 'Street',
                    icon: LucideIcons.building2,
                    state: ShootChipState.suggested,
                  ),
                  ShootChip(
                    label: 'Disabled',
                    state: ShootChipState.disabled,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── ConfidenceBadge ──
              _SectionTitle('CONFIDENCE BADGE'),
              const Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ConfidenceBadge(level: ConfidenceLevel.high),
                  ConfidenceBadge(level: ConfidenceLevel.medium),
                  ConfidenceBadge(level: ConfidenceLevel.low),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── SummaryHeader ──
              _SectionTitle('SUMMARY HEADER'),
              const SummaryHeader(
                aperture: 'f/2.8',
                shutterSpeed: '1/125',
                iso: '400',
                exposureMode: 'A',
                confidence: ConfidenceLevel.high,
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── SettingCard ──
              _SectionTitle('SETTING CARD'),
              SettingCard(
                settingName: 'Ouverture',
                explanation: 'Grande ouverture pour le bokeh',
                valueDisplay: 'f/2.8',
                icon: LucideIcons.aperture,
                onTap: () {},
              ),
              const SizedBox(height: AppSpacing.sm),
              SettingCard(
                settingName: 'ISO',
                explanation: 'Monté pour compenser la vitesse',
                valueDisplay: '1600',
                icon: LucideIcons.gauge,
                variant: SettingCardVariant.compromised,
                onTap: () {},
              ),
              const SizedBox(height: AppSpacing.sm),
              SettingCard(
                settingName: 'Stabilisation',
                explanation: 'Override utilisateur',
                valueDisplay: 'OFF',
                icon: LucideIcons.move,
                variant: SettingCardVariant.overridden,
                onTap: () {},
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── CompromiseBanner ──
              _SectionTitle('COMPROMISE BANNER'),
              const CompromiseBanner(
                text: 'ISO monté à 1600 pour maintenir la vitesse.',
                severity: CompromiseSeverity.warning,
              ),
              const SizedBox(height: AppSpacing.sm),
              const CompromiseBanner(
                text: 'Vitesse insuffisante — risque de flou de bougé.',
                severity: CompromiseSeverity.critical,
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── GearBadge ──
              _SectionTitle('GEAR BADGE'),
              GearBadge(
                bodyName: 'A6700',
                lensName: 'Sigma 18-50 f/2.8',
                onTap: () {},
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── SectionDivider ──
              _SectionTitle('SECTION DIVIDER'),
              const SectionDivider(),
              const SectionDivider(label: 'RÉGLAGES AVANCÉS'),

              const SizedBox(height: AppSpacing.xl),

              // ── ExpandToggle ──
              _SectionTitle('EXPAND TOGGLE'),
              ExpandToggle(
                label: 'Affiner davantage',
                isExpanded: _expanded,
                badgeCount: 3,
                onTap: () => setState(() => _expanded = !_expanded),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Container(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface1 : AppColors.lightSurface2,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  ),
                  child: Text('Contenu déplié', style: AppTypography.body),
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── NavStepCard ──
              _SectionTitle('NAV STEP CARD'),
              const NavStepCard(stepNumber: 1, text: 'Menu principal'),
              const NavStepCard(stepNumber: 2, text: 'AF/MF'),
              const NavStepCard(
                stepNumber: 3,
                text: 'Mode mise au point → AF-C',
                isLast: true,
              ),
            ],
          ),

          // ── BottomStickyBar ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomStickyBar(
              child: FilledButton(
                onPressed: () {},
                child: const Text('Calculer les réglages'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md, top: AppSpacing.sm),
      child: Text(
        text,
        style: AppTypography.overline.copyWith(color: AppColors.blueOptique),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final String label;
  final Color color;
  const _ColorSwatch(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}
