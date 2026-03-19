import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shoothelper/shared/data/mappers/menu_tree_mapper.dart';
import 'package:shoothelper/shared/data/models/menu_tree_model.dart';
import 'package:shoothelper/shared/domain/entities/menu_tree.dart';

void main() {
  group('MenuTreeMapper', () {
    late MenuTreeModel model;

    setUpAll(() {
      final file = File('assets/packs/sony_a6700/menu_tree.json');
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      model = MenuTreeModel.fromJson(json);
    });

    test('maps MenuTreeModel to MenuTree correctly', () {
      final tree = MenuTreeMapper.toEntity(model);
      expect(tree.firmwareVersion, '3.0');
      expect(tree.root.length, 4);
    });

    test('maps menu item types correctly', () {
      final tree = MenuTreeMapper.toEntity(model);
      expect(tree.root[0].type, MenuItemType.tab);
      expect(tree.root[0].children!.first.type, MenuItemType.page);
    });

    test('findItemById works on mapped tree', () {
      final tree = MenuTreeMapper.toEntity(model);
      final item = tree.findItemById('focus_mode_item');
      expect(item, isNotNull);
      expect(item!.settingId, 'af_mode');
    });

    test('findBySetting works on mapped tree', () {
      final tree = MenuTreeMapper.toEntity(model);
      final item = tree.findBySetting('metering');
      expect(item, isNotNull);
      expect(item!.id, 'metering_mode_item');
    });

    test('maps labels in both languages', () {
      final tree = MenuTreeMapper.toEntity(model);
      final item = tree.findBySetting('af_mode');
      expect(item!.label('en'), 'Focus Mode');
      expect(item.label('fr'), 'Mode mise au point');
    });

    test('maps menu values with short labels', () {
      final tree = MenuTreeMapper.toEntity(model);
      final item = tree.findBySetting('af_mode');
      expect(item!.values, isNotEmpty);
      final afS = item.values!.firstWhere((v) => v.id == 'af-s');
      expect(afS.shortLabel('en'), 'AF-S');
      expect(afS.label('fr'), 'AF ponctuel');
    });
  });
}
