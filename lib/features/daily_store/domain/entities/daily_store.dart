import 'package:equatable/equatable.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';

class UserWallet extends Equatable {
  final int valorantPoints;
  final int radianitePoints;
  final int kingdomCredits;

  const UserWallet({
    this.valorantPoints = 0,
    this.radianitePoints = 0,
    this.kingdomCredits = 0,
  });

  Map<String, dynamic> toJson() => {
        'valorantPoints': valorantPoints,
        'radianitePoints': radianitePoints,
        'kingdomCredits': kingdomCredits,
      };

  factory UserWallet.fromJson(Map<String, dynamic> json) => UserWallet(
        valorantPoints: json['valorantPoints'] as int? ?? 0,
        radianitePoints: json['radianitePoints'] as int? ?? 0,
        kingdomCredits: json['kingdomCredits'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [valorantPoints, radianitePoints, kingdomCredits];
}

class FeaturedBundle extends Equatable {
  final String uuid;
  final String displayName;
  final String? displayIcon;
  final String? displayIcon2; // wide landscape promo banner
  final String? verticalPromoImage; // portrait promo poster
  final int price;
  final int remainingDurationSeconds;
  final List<SkinItem> items;

  const FeaturedBundle({
    required this.uuid,
    required this.displayName,
    this.displayIcon,
    this.displayIcon2,
    this.verticalPromoImage,
    this.price = 0,
    this.remainingDurationSeconds = 0,
    this.items = const [],
  });

  /// High quality banner art URL (wide banner preferred, fallback to vertical or displayIcon)
  String? get bannerImageUrl =>
      displayIcon2 ?? verticalPromoImage ?? displayIcon;

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'displayName': displayName,
        'displayIcon': displayIcon,
        'displayIcon2': displayIcon2,
        'verticalPromoImage': verticalPromoImage,
        'price': price,
        'remainingDurationSeconds': remainingDurationSeconds,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory FeaturedBundle.fromJson(Map<String, dynamic> json) {
    final itemsData = json['items'] as List<dynamic>? ?? [];
    return FeaturedBundle(
      uuid: json['uuid'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      displayIcon: json['displayIcon'] as String?,
      displayIcon2: json['displayIcon2'] as String?,
      verticalPromoImage: json['verticalPromoImage'] as String?,
      price: json['price'] as int? ?? 0,
      remainingDurationSeconds: json['remainingDurationSeconds'] as int? ?? 0,
      items: itemsData
          .map((i) => SkinItem.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        uuid,
        displayName,
        displayIcon,
        displayIcon2,
        verticalPromoImage,
        price,
        remainingDurationSeconds,
        items,
      ];
}

class NightMarketItem extends Equatable {
  final SkinItem skin;
  final int originalCost;
  final int discountPercent;
  final int discountedCost;
  final bool isSeen;

  const NightMarketItem({
    required this.skin,
    required this.originalCost,
    required this.discountPercent,
    required this.discountedCost,
    this.isSeen = true,
  });

  Map<String, dynamic> toJson() => {
        'skin': skin.toJson(),
        'originalCost': originalCost,
        'discountPercent': discountPercent,
        'discountedCost': discountedCost,
        'isSeen': isSeen,
      };

  factory NightMarketItem.fromJson(Map<String, dynamic> json) =>
      NightMarketItem(
        skin: SkinItem.fromJson(json['skin'] as Map<String, dynamic>),
        originalCost: json['originalCost'] as int? ?? 0,
        discountPercent: json['discountPercent'] as int? ?? 0,
        discountedCost: json['discountedCost'] as int? ?? 0,
        isSeen: json['isSeen'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [
        skin,
        originalCost,
        discountPercent,
        discountedCost,
        isSeen,
      ];
}

class NightMarket extends Equatable {
  final List<NightMarketItem> offers;
  final int remainingDurationSeconds;

  const NightMarket({
    required this.offers,
    required this.remainingDurationSeconds,
  });

  Map<String, dynamic> toJson() => {
        'offers': offers.map((o) => o.toJson()).toList(),
        'remainingDurationSeconds': remainingDurationSeconds,
      };

  factory NightMarket.fromJson(Map<String, dynamic> json) {
    final list = (json['offers'] as List<dynamic>? ?? [])
        .map((e) => NightMarketItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return NightMarket(
      offers: list,
      remainingDurationSeconds:
          json['remainingDurationSeconds'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [offers, remainingDurationSeconds];
}

class AccessoryStoreItem extends Equatable {
  final String uuid;
  final String displayName;
  final String? displayIcon;
  final String itemType; // Buddy, Spray, Card, Title
  final int kcCost;
  final int remainingDurationSeconds;

  const AccessoryStoreItem({
    required this.uuid,
    required this.displayName,
    this.displayIcon,
    this.itemType = 'Accessory',
    this.kcCost = 4000,
    this.remainingDurationSeconds = 0,
  });

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'displayName': displayName,
        'displayIcon': displayIcon,
        'itemType': itemType,
        'kcCost': kcCost,
        'remainingDurationSeconds': remainingDurationSeconds,
      };

  factory AccessoryStoreItem.fromJson(Map<String, dynamic> json) =>
      AccessoryStoreItem(
        uuid: json['uuid'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        displayIcon: json['displayIcon'] as String?,
        itemType: json['itemType'] as String? ?? 'Accessory',
        kcCost: json['kcCost'] as int? ?? 4000,
        remainingDurationSeconds:
            json['remainingDurationSeconds'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [
        uuid,
        displayName,
        displayIcon,
        itemType,
        kcCost,
        remainingDurationSeconds,
      ];
}

class DailyStore extends Equatable {
  final List<SkinItem> featuredOffers;
  final int remainingDurationSeconds;
  final List<FeaturedBundle> bundles;
  final NightMarket? nightMarket;
  final List<AccessoryStoreItem> accessoryOffers;
  final DateTime lastFetched;

  const DailyStore({
    required this.featuredOffers,
    required this.remainingDurationSeconds,
    this.bundles = const [],
    FeaturedBundle? bundle,
    this.nightMarket,
    this.accessoryOffers = const [],
    required this.lastFetched,
  }) : _bundle = bundle;

  final FeaturedBundle? _bundle;

  /// Primary featured bundle (or first bundle in bundles list)
  FeaturedBundle? get bundle =>
      _bundle ?? (bundles.isNotEmpty ? bundles.first : null);

  Map<String, dynamic> toJson() => {
        'featuredOffers': featuredOffers.map((o) => o.toJson()).toList(),
        'remainingDurationSeconds': remainingDurationSeconds,
        'bundles': bundles.map((b) => b.toJson()).toList(),
        'bundle': bundle?.toJson(),
        'nightMarket': nightMarket?.toJson(),
        'accessoryOffers': accessoryOffers.map((a) => a.toJson()).toList(),
        'lastFetched': lastFetched.toIso8601String(),
      };

  factory DailyStore.fromJson(Map<String, dynamic> json) {
    final offers = (json['featuredOffers'] as List<dynamic>? ?? [])
        .map((e) => SkinItem.fromJson(e as Map<String, dynamic>))
        .toList();

    final bundlesList = (json['bundles'] as List<dynamic>? ?? [])
        .map((b) => FeaturedBundle.fromJson(b as Map<String, dynamic>))
        .toList();

    FeaturedBundle? singleBundle;
    if (json['bundle'] != null) {
      singleBundle =
          FeaturedBundle.fromJson(json['bundle'] as Map<String, dynamic>);
    } else if (bundlesList.isNotEmpty) {
      singleBundle = bundlesList.first;
    }

    NightMarket? nm;
    if (json['nightMarket'] != null) {
      nm = NightMarket.fromJson(json['nightMarket'] as Map<String, dynamic>);
    }

    final accessories = (json['accessoryOffers'] as List<dynamic>? ?? [])
        .map((a) => AccessoryStoreItem.fromJson(a as Map<String, dynamic>))
        .toList();

    return DailyStore(
      featuredOffers: offers,
      remainingDurationSeconds: json['remainingDurationSeconds'] as int? ?? 0,
      bundles: bundlesList,
      bundle: singleBundle,
      nightMarket: nm,
      accessoryOffers: accessories,
      lastFetched: json['lastFetched'] != null
          ? DateTime.tryParse(json['lastFetched'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        featuredOffers,
        remainingDurationSeconds,
        bundles,
        bundle,
        nightMarket,
        accessoryOffers,
        lastFetched,
      ];
}
