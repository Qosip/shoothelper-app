import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/shared/data/models/menu_tree_model.dart';

void main() {
  group('MenuTreeModel JSON parsing', () {
    late Map<String, dynamic> json;

    setUpAll(() {
      final file = File('assets/packs/sony_a6700/menu_tree.json');
      json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    });

    test('parses menu_tree.json without error', () {
      final model = MenuTreeModel.fromJson(json);
      expect(model.firmwareVersion, '3.0');
      expect(model.root, isNotEmpty);
    });

    test('has correct tab structure', () {
      final model = MenuTreeModel.fromJson(json);
      final tabs = model.root;
      expect(tabs.length, 4); // shooting, exposure_color, af_mf, setup
      expect(tabs[0].id, 'shooting');
      expect(tabs[0].type, 'tab');
      expect(tabs[0].labels['en'], 'Shooting');
      expect(tabs[0].labels['fr'], 'Prise de vue');
    });

    test('parses nested menu items with settings', () {
      final model = MenuTreeModel.fromJson(json);
      // Find AF tab → AF/MF page → focus_mode_item
      final afTab = model.root.firstWhere((t) => t.id == 'af_mf');
      final afPage = afTab.children!.first;
      final focusMode = afPage.children!.firstWhere((i) => i.settingId == 'af_mode');
      expect(focusMode.type, 'setting');
      expect(focusMode.values, isNotEmpty);
      expect(focusMode.values!.first.id, 'af-s');
      expect(focusMode.values!.first.labels['fr'], 'AF ponctuel');
    });

    test('parses menu values with short labels', () {
      final model = MenuTreeModel.fromJson(json);
      final afTab = model.root.firstWhere((t) => t.id == 'af_mf');
      final afPage = afTab.children!.first;
      final focusMode = afPage.children!.firstWhere((i) => i.settingId == 'af_mode');
      final afC = focusMode.values!.firstWhere((v) => v.id == 'af-c');
      expect(afC.shortLabels['en'], 'AF-C');
      expect(afC.labels['en'], 'Continuous AF');
    });
  });
}
