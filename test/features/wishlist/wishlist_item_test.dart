import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';
import 'package:valorant_store_tracker/features/wishlist/domain/entities/wishlist_item.dart';

void main() {
  group('WishlistItem Entity', () {
    const skin = SkinItem(
      uuid: 'skin-101',
      displayName: 'Reaver Vandal',
      weaponName: 'Vandal',
      cost: 1775,
      tierName: 'Premium',
    );

    test('WishlistItem.fromSkinItem converts accurately', () {
      final wishlistItem = WishlistItem.fromSkinItem(skin);

      expect(wishlistItem.uuid, 'skin-101');
      expect(wishlistItem.displayName, 'Reaver Vandal');
      expect(wishlistItem.weaponName, 'Vandal');
      expect(wishlistItem.cost, 1775);
      expect(wishlistItem.tierName, 'Premium');
    });

    test('WishlistItem toJson and fromJson preserves data', () {
      final item = WishlistItem(
        uuid: 'uuid-1',
        displayName: 'Ion Phantom',
        weaponName: 'Phantom',
        cost: 1775,
        addedAt: DateTime(2026, 9, 5, 10, 0),
      );

      final json = item.toJson();
      final restored = WishlistItem.fromJson(json);

      expect(restored.uuid, 'uuid-1');
      expect(restored.displayName, 'Ion Phantom');
      expect(restored.cost, 1775);
    });

    test('toSkinItem converts back to SkinItem', () {
      final item = WishlistItem(
        uuid: 'uuid-1',
        displayName: 'Ion Phantom',
        weaponName: 'Phantom',
        cost: 1775,
        addedAt: DateTime(2026, 9, 5),
      );

      final skinItem = item.toSkinItem();
      expect(skinItem.uuid, 'uuid-1');
      expect(skinItem.displayName, 'Ion Phantom');
    });
  });
}
