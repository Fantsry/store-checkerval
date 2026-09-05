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
        final isStaleOrPlaceholder = cached.gameName.isEmpty ||
            cached.gameName == cached.puuid.substring(0, 8) ||
            cached.cardWideArt == null ||
            cached.cardWideArt!.isEmpty;
        if (!isStaleOrPlaceholder) {
          // Trigger background refresh silently
          _fetchAndCacheFreshProfile().ignore();
          return Result.success(cached);
        }
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

      // If storage doesn't have gameName, fetch from UserInfo endpoint
      if (gameName.isEmpty) {
        try {
          final accessToken = await _storage.getAccessToken();
          if (accessToken != null && accessToken.isNotEmpty) {
            final userInfo = await _remoteDataSource.fetchUserInfo(accessToken);
            final acct = userInfo['acct'] as Map?;
            final fName = acct?['game_name']?.toString();
            final fTag = acct?['tag_line']?.toString();
            if (fName != null && fName.isNotEmpty) {
              gameName = fName;
              tagLine = fTag ?? tagLine;
              await _storage.setGameName(gameName);
              await _storage.setTagLine(tagLine);
            }
          }
        } catch (_) {}
      }

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
      final rawCardUuid = (identityMap['PlayerCardID'] ??
              identityMap['playerCardId'] ??
              identityMap['PlayerCardId'] ??
              identityMap['playercard_id'])
          ?.toString();
      final titleUuid = (identityMap['PlayerTitleID'] ??
              identityMap['playerTitleId'] ??
              identityMap['PlayerTitleId'] ??
              identityMap['playertitle_id'])
          ?.toString();
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

      // 4. Fetch Card Metadata from Valorant-API (with default fallback to Valorant Card)
      final effectiveCardUuid = (rawCardUuid != null &&
              rawCardUuid.isNotEmpty &&
              rawCardUuid != '00000000-0000-0000-0000-000000000000')
          ? rawCardUuid
          : '9fb348bc-41a0-91ad-8a3e-818035c4e561';

      var cardData = await _remoteDataSource.fetchPlayerCardDetails(effectiveCardUuid);
      if (cardData == null && effectiveCardUuid != '9fb348bc-41a0-91ad-8a3e-818035c4e561') {
        cardData = await _remoteDataSource.fetchPlayerCardDetails('9fb348bc-41a0-91ad-8a3e-818035c4e561');
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

      final finalGameName = gameName.isNotEmpty ? gameName : (puuid.length > 8 ? puuid.substring(0, 8) : 'Agent');

      final profile = UserProfile(
        puuid: puuid,
        gameName: finalGameName,
        tagLine: tagLine,
        accountLevel: accountLevel,
        accountXp: accountXp,
        cardUuid: cardData?['uuid'] as String? ?? effectiveCardUuid,
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
