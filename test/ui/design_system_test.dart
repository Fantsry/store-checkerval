import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';
import 'package:valorant_store_tracker/ui/theme/app_theme.dart';
import 'package:valorant_store_tracker/ui/widgets/ascend_card.dart';
import 'package:valorant_store_tracker/ui/widgets/custom_tab_bar.dart';
import 'package:valorant_store_tracker/ui/widgets/empty_state_view.dart';
import 'package:valorant_store_tracker/ui/widgets/error_state_view.dart';
import 'package:valorant_store_tracker/ui/widgets/section_header.dart';
import 'package:valorant_store_tracker/ui/widgets/stat_box.dart';
import 'package:valorant_store_tracker/ui/widgets/stat_rail.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: DarkTheme.darkTheme,
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
  );
}

void main() {
  group('design tokens', () {
    test('uses Geist and tabular numerals', () {
      expect(AppTextStyles.bodyMedium().fontFamily, AppFonts.sans);
      expect(AppTextStyles.statValue().fontFamily, AppFonts.mono);
      expect(
        AppTextStyles.statValue().fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
      expect(AppColors.accent, const Color(0xFF48C878));
    });

    test('theme is flat and uses the new canvas', () {
      final theme = DarkTheme.darkTheme;
      expect(theme.scaffoldBackgroundColor, AppColors.background);
      expect(theme.cardTheme.elevation, 0);
      expect(theme.colorScheme.primary, AppColors.accent);
      expect(theme.textTheme.bodyMedium?.fontFamily, AppFonts.sans);
    });
  });

  group('design system widgets', () {
    testWidgets('DataPanel renders flat surface content', (tester) async {
      await tester.pumpWidget(_wrap(
        const DataPanel(
          child: Text('PANEL CONTENT'),
        ),
      ));

      expect(find.text('PANEL CONTENT'), findsOneWidget);
      final box = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.color, AppColors.surface);
      expect(decoration.boxShadow, isNull);
      expect(decoration.gradient, isNull);
      expect(decoration.borderRadius, BorderRadius.circular(10));
    });

    testWidgets('SectionHeader renders index, action, and subtitle',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        SectionHeader(
          index: '01',
          title: 'Match history',
          subtitle: 'Last 10 matches',
          actionLabel: 'View all',
          onActionTap: () => tapped = true,
        ),
      ));

      expect(find.text('01'), findsOneWidget);
      expect(find.text('MATCH HISTORY'), findsOneWidget);
      expect(find.text('Last 10 matches'), findsOneWidget);
      await tester.tap(find.text('VIEW ALL'));
      expect(tapped, isTrue);
    });

    testWidgets('CustomTabBar exposes selection without pills', (tester) async {
      var selected = 0;
      await tester.pumpWidget(_wrap(
        StatefulBuilder(
          builder: (context, setState) => CustomTabBar(
            tabs: const ['All', 'Competitive', 'Unrated'],
            selectedIndex: selected,
            onTabSelected: (index) => setState(() => selected = index),
          ),
        ),
      ));

      await tester.tap(find.text('COMPETITIVE'));
      await tester.pumpAndSettle();
      expect(selected, 1);
      expect(find.text('COMPETITIVE'), findsOneWidget);
    });

    testWidgets('StatBox and StatRail render compact metrics', (tester) async {
      await tester.pumpWidget(_wrap(
        Column(
          children: [
            const Row(
              children: [
                Expanded(
                  child: StatBox(
                    label: 'Win rate',
                    value: '54.2%',
                    subtitle: '13W / 11L',
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: StatBox(label: 'K/D', value: '1.24'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const StatRail(
              items: [
                StatRailItem(label: 'ACS', value: '228'),
                StatRailItem(label: 'HS', value: '31%'),
                StatRailItem(label: 'KAST', value: '74%'),
              ],
            ),
          ],
        ),
      ));

      expect(find.text('WIN RATE'), findsOneWidget);
      expect(find.text('54.2%'), findsOneWidget);
      expect(find.text('ACS'), findsOneWidget);
      expect(find.text('KAST'), findsOneWidget);
    });

    testWidgets('Empty and error states keep actions usable', (tester) async {
      var retried = false;
      await tester.pumpWidget(_wrap(
        Column(
          children: [
            EmptyStateView(
              icon: Icons.history_rounded,
              title: 'No matches',
              description: 'Nothing here yet.',
              buttonText: 'REFRESH',
              onButtonPressed: () {},
            ),
            ErrorStateView(
              message: 'Could not load data.',
              onRetry: () => retried = true,
            ),
          ],
        ),
      ));

      await tester.tap(find.text('RETRY'));
      expect(retried, isTrue);
      expect(find.text('NO DATA'), findsOneWidget);
      expect(find.text('ERROR'), findsOneWidget);
    });

    testWidgets('core widgets survive small screens and large text',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      await tester.pumpWidget(_wrap(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(
              index: '02',
              title: 'Collection overview',
              subtitle: 'Every owned skin, ranked by value',
              actionLabel: 'Details',
            ),
            const SizedBox(height: 16),
            const CustomTabBar(
              tabs: ['All', 'Exclusive', 'Premium', 'Deluxe'],
              selectedIndex: 0,
              onTabSelected: _noop,
            ),
            const SizedBox(height: 16),
            const StatRail(
              items: [
                StatRailItem(label: 'Account value', value: '12,450 VP'),
                StatRailItem(label: 'Skins', value: '128'),
              ],
            ),
            const SizedBox(height: 16),
            const StatBox(label: 'Win rate', value: '100%'),
          ],
        ),
      ));

      expect(tester.takeException(), isNull);
    });
  });
}

void _noop(int _) {}
