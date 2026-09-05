import 'package:valorant_store_tracker/core/error/failures.dart';
import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:valorant_store_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:valorant_store_tracker/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;
  final SecureStorageService _storage;
  final LocalStoreService _localStore;

  ProfileRepositoryImpl({
    required ProfileRemoteDataSource remoteDataSource,
    required SecureStorageService storage,
    required LocalStoreService localStore,
  })  : _remoteDataSource = remoteDataSource,
        _storage = storage,
        _localStore = localStore;

  @override
  Future<UserProfile?> getCachedProfile() => _localStore.getCachedProfile();

  @override
  Future<void> clearProfile() async {
    await _localStore.clearCachedProfile();
  }

  @override
  Future<Result<UserProfile>> getUserProfile({bool forceRefresh = false}) async {
    // 1. Return cached profile immediately if available and not forced
    if (!forceRefresh) {
      final cached = await _localStore.getCachedProfile();
      if (cached != null) {
        // Trigger background refresh silently
        _fetchAndCacheFreshProfile().ignore();
        return Result.success(cached);
      }
    }

    return _fetchAndCacheFreshProfile();
  }

  Future<Result<UserProfile>> _fetchAndCacheFreshProfile() async {
    try {
      final puuid = await _storage.getPuuid();
      final shard = await _storage.getShard() ?? 'ap';
      final region = await _storage.getRegion() ?? 'ap';

      if (puuid == null || puuid.isEmpty) {
        return const Result.failure(
          AuthFailure(message: 'No active Riot session. Please sign in.'),
        );
      }

      // Read fallback names from storage
      var gameName = await _storage.getGameName() ?? '';
      var tagLine = await _storage.getTagLine() ?? '';

      // 1. Fetch In-Game Name via Name-Service
      var resolvedShard = shard;
      final nameRes = await _remoteDataSource.fetchPlayerName(
        shard: resolvedShard,
        puuid: puuid,
      );
      final fetchedName = nameRes['gameName'] ?? '';
      final fetchedTag = nameRes['tagLine'] ?? '';
      if (fetchedName.isNotEmpty) {
        gameName = fetchedName;
        tagLine = fetchedTag;
        await _storage.setGameName(gameName);
        await _storage.setTagLine(tagLine);
      }

      if (nameRes['resolvedShard'] != null &&
          nameRes['resolvedShard']!.isNotEmpty &&
          nameRes['resolvedShard'] != resolvedShard) {
        resolvedShard = nameRes['resolvedShard']!;
        await _storage.setShard(resolvedShard);
      }

      // 2. Fetch Player Identity (Loadout / Equipped Player Card)
      final identityRes = await _remoteDataSource.fetchPlayerIdentity(
        shard: resolvedShard,
        puuid: puuid,
      );
      if (identityRes['resolvedShard'] != null &&
          identityRes['resolvedShard'] != resolvedShard) {
        resolvedShard = identityRes['resolvedShard'] as String;
        await _storage.setShard(resolvedShard);
      }
      final identityMap =
          identityRes['identity'] as Map<String, dynamic>? ?? {};
      final cardUuid = identityMap['PlayerCardID'] as String?;
      final titleUuid = identityMap['PlayerTitleID'] as String?;
      var accountLevel = (identityMap['AccountLevel'] as num?)?.toInt() ?? 1;

      // 3. Fetch Account XP for detailed level
      var accountXp = 0;
      final xpData = await _remoteDataSource.fetchAccountXp(
        shard: resolvedShard,
        puuid: puuid,
      );
      if (xpData['resolvedShard'] != null &&
          xpData['resolvedShard'] != resolvedShard) {
        resolvedShard = xpData['resolvedShard'] as String;
        await _storage.setShard(resolvedShard);
      }
      final progress = xpData['Progress'] as Map<String, dynamic>?;
      if (progress != null) {
        accountLevel = (progress['Level'] as num?)?.toInt() ?? accountLevel;
        accountXp = (progress['XP'] as num?)?.toInt() ?? 0;
      }

      // 4. Fetch Card Metadata from Valorant-API
      Map<String, dynamic>? cardData;
      if (cardUuid != null && cardUuid.isNotEmpty) {
        cardData = await _remoteDataSource.fetchPlayerCardDetails(cardUuid);
      }

      // 5. Fetch Title Text from Valorant-API
      String? titleText;
      if (titleUuid != null && titleUuid.isNotEmpty) {
        titleText = await _remoteDataSource.fetchPlayerTitleText(titleUuid);
      }

      // 6. Fetch Wallet Balances (VP, RP, KC)
      final wallet = await _remoteDataSource.fetchWallet(
        shard: resolvedShard,
        puuid: puuid,
      );

      final profile = UserProfile(
        puuid: puuid,
        gameName: gameName.isNotEmpty ? gameName : puuid.substring(0, 8),
        tagLine: tagLine,
        accountLevel: accountLevel,
        accountXp: accountXp,
        cardUuid: cardUuid,
        cardName: cardData?['displayName'] as String?,
        cardSmallArt: cardData?['smallArt'] as String?,
        cardWideArt: cardData?['wideArt'] as String?,
        cardLargeArt: cardData?['largeArt'] as String?,
        titleUuid: titleUuid,
        titleText: titleText,
        region: region,
        shard: resolvedShard,
        valorantPoints: wallet['vp'] ?? 0,
        radianitePoints: wallet['rp'] ?? 0,
        kingdomCredits: wallet['kc'] ?? 0,
      );

      // Save to offline storage
      await _localStore.saveCachedProfile(profile);

      return Result.success(profile);
    } catch (e) {
      // If network fails, return cached profile if present
      final cached = await _localStore.getCachedProfile();
      if (cached != null) {
        return Result.success(cached);
      }

      return Result.failure(
        ServerFailure(message: 'Failed to load player profile: $e'),
      );
    }
  }
}
