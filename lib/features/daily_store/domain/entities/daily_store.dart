import 'package:equatable/equatable.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/entities/skin_item.dart';

class UserWallet extends Equatable {
  final int valorantPoints;
  final int radianitePoints;

  const UserWallet({
    this.valorantPoints = 0,
    this.radianitePoints = 0,
  });

  Map<String, dynamic> toJson() => {
        'valorantPoints': valorantPoints,
        'radianitePoints': radianitePoints,
      };

  factory UserWallet.fromJson(Map<String, dynamic> json) => UserWallet(
        valorantPoints: json['valorantPoints'] as int? ?? 0,
        radianitePoints: json['radianitePoints'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [valorantPoints, radianitePoints];
}

class FeaturedBundle extends Equatable {
  final String uuid;
  final String displayName;
  final String? displayIcon;
  final int price;
  final int remainingDurationSeconds;
  final List<SkinItem> items;

  const FeaturedBundle({
    required this.uuid,
    required this.displayName,
    this.displayIcon,
    this.price = 0,
    this.remainingDurationSeconds = 0,
    this.items = const [],
  });

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'displayName': displayName,
        'displayIcon': displayIcon,
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
        price,
        remainingDurationSeconds,
        items,
      ];
}

class DailyStore extends Equatable {
  final List<SkinItem> featuredOffers;
  final int remainingDurationSeconds;
  final FeaturedBundle? bundle;
  final DateTime lastFetched;

  const DailyStore({
    required this.featuredOffers,
    required this.remainingDurationSeconds,
    this.bundle,
    required this.lastFetched,
  });

  Map<String, dynamic> toJson() => {
        'featuredOffers': featuredOffers.map((o) => o.toJson()).toList(),
        'remainingDurationSeconds': remainingDurationSeconds,
        'bundle': bundle?.toJson(),
        'lastFetched': lastFetched.toIso8601String(),
      };

  factory DailyStore.fromJson(Map<String, dynamic> json) {
    final offers = (json['featuredOffers'] as List<dynamic>? ?? [])
        .map((e) => SkinItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return DailyStore(
      featuredOffers: offers,
      remainingDurationSeconds: json['remainingDurationSeconds'] as int? ?? 0,
      bundle: json['bundle'] != null
          ? FeaturedBundle.fromJson(json['bundle'] as Map<String, dynamic>)
          : null,
      lastFetched: json['lastFetched'] != null
          ? DateTime.tryParse(json['lastFetched'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        featuredOffers,
        remainingDurationSeconds,
        bundle,
        lastFetched,
      ];
}
