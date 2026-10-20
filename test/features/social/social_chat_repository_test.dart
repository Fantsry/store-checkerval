import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/features/career/data/datasources/career_remote_datasource.dart';
import 'package:valorant_store_tracker/features/career/domain/repositories/career_repository.dart';
import 'package:valorant_store_tracker/features/live_match/data/datasources/live_match_remote_datasource.dart';
import 'package:valorant_store_tracker/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:valorant_store_tracker/features/social/data/datasources/riot_chat_remote_datasource.dart';
import 'package:valorant_store_tracker/features/social/data/repositories/social_repository_impl.dart';
import 'package:valorant_store_tracker/features/social/domain/entities/chat_message.dart';
import 'package:valorant_store_tracker/features/social/domain/entities/friend_entity.dart';

class MockLiveMatchRemoteDataSource extends Mock
    implements LiveMatchRemoteDataSource {}

class MockCareerRemoteDataSource extends Mock
    implements CareerRemoteDataSource {}

class MockProfileRemoteDataSource extends Mock
    implements ProfileRemoteDataSource {}

class MockCareerRepository extends Mock implements CareerRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockLocalStoreService extends Mock implements LocalStoreService {}

class MockRiotChatRemoteDataSource extends Mock
    implements RiotChatRemoteDataSource {}

void main() {
  late MockLiveMatchRemoteDataSource liveDataSource;
  late MockCareerRemoteDataSource careerDataSource;
  late MockProfileRemoteDataSource profileDataSource;
  late MockCareerRepository careerRepository;
  late MockSecureStorageService storage;
  late MockLocalStoreService localStore;
  late MockRiotChatRemoteDataSource chatDataSource;
  late SocialRepositoryImpl repository;

  const friendPuuid = 'friend-puuid';
  const friendJid = 'friend-puuid@eu1.pvp.net';
  final timestamp = DateTime.utc(2026, 10, 20, 8, 7, 33);

  setUpAll(() {
    registerFallbackValue(
      ChatMessageEntity(
        id: 'fallback',
        body: 'fallback',
        timestamp: DateTime.utc(2026),
        isMine: false,
      ),
    );
  });

  setUp(() {
    liveDataSource = MockLiveMatchRemoteDataSource();
    careerDataSource = MockCareerRemoteDataSource();
    profileDataSource = MockProfileRemoteDataSource();
    careerRepository = MockCareerRepository();
    storage = MockSecureStorageService();
    localStore = MockLocalStoreService();
    chatDataSource = MockRiotChatRemoteDataSource();

    repository = SocialRepositoryImpl(
      liveDataSource: liveDataSource,
      careerDataSource: careerDataSource,
      profileDataSource: profileDataSource,
      careerRepository: careerRepository,
      storage: storage,
      localStore: localStore,
      chatDataSource: chatDataSource,
    );

    when(() => storage.getAccessToken()).thenAnswer((_) async => 'access-token');
    when(() => storage.getEntitlementsToken())
        .thenAnswer((_) async => 'entitlement-token');
    when(() => storage.getPuuid()).thenAnswer((_) async => 'self-puuid');
    when(() => localStore.getSavedFriendJson(friendPuuid)).thenAnswer(
      (_) async => jsonEncode(
        FriendEntity(
          puuid: friendPuuid,
          gameName: 'Friend',
          xmppJid: friendJid,
          lastUpdated: timestamp,
        ).toJson(),
      ),
    );
    when(() => localStore.getChatMessages(friendPuuid))
        .thenAnswer((_) async => []);
    when(() => localStore.saveChatMessage(any(), any()))
        .thenAnswer((_) async {});
    when(() => localStore.saveFriendJson(any(), any())).thenAnswer((_) async {
      return;
    });
  });

  test('sendChatMessage sends to the roster JID and persists the message',
      () async {
    when(
      () => chatDataSource.sendChatMessage(
        accessToken: any(named: 'accessToken'),
        entitlementToken: any(named: 'entitlementToken'),
        recipientJid: any(named: 'recipientJid'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => RiotChatSendResult.success(
        messageId: 'server-message-1',
        messages: const [],
      ),
    );

    final result = await repository.sendChatMessage(
      puuid: friendPuuid,
      body: 'halo',
    );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.body, 'halo');
    expect(result.valueOrNull!.isMine, isTrue);
    expect(result.valueOrNull!.status, ChatMessageStatus.sent);

    verify(
      () => chatDataSource.sendChatMessage(
        accessToken: 'access-token',
        entitlementToken: 'entitlement-token',
        recipientJid: friendJid,
        body: 'halo',
      ),
    ).called(1);

    final savedMessage = verify(
      () => localStore.saveChatMessage(friendPuuid, captureAny()),
    ).captured.single as ChatMessageEntity;
    expect(savedMessage.body, 'halo');
    expect(savedMessage.isMine, isTrue);

    final savedFriend = verify(
      () => localStore.saveFriendJson(friendPuuid, captureAny()),
    ).captured.single as String;
    final decodedFriend = FriendEntity.fromJson(
      jsonDecode(savedFriend) as Map<String, dynamic>,
    );
    expect(decodedFriend.lastChatMessage, 'halo');
  });

  test('sendChatMessage rejects an empty body before contacting XMPP',
      () async {
    final result = await repository.sendChatMessage(
      puuid: friendPuuid,
      body: '   ',
    );

    expect(result.isFailure, isTrue);
    verifyNever(
      () => chatDataSource.sendChatMessage(
        accessToken: any(named: 'accessToken'),
        entitlementToken: any(named: 'entitlementToken'),
        recipientJid: any(named: 'recipientJid'),
        body: any(named: 'body'),
      ),
    );
  });

  test('sendChatMessage fails when the user has no access token', () async {
    when(() => storage.getAccessToken()).thenAnswer((_) async => null);

    final result = await repository.sendChatMessage(
      puuid: friendPuuid,
      body: 'halo',
    );

    expect(result.isFailure, isTrue);
    verifyNever(
      () => chatDataSource.sendChatMessage(
        accessToken: any(named: 'accessToken'),
        entitlementToken: any(named: 'entitlementToken'),
        recipientJid: any(named: 'recipientJid'),
        body: any(named: 'body'),
      ),
    );
  });

  test('sendChatMessage reports an XMPP rejection without persisting', () async {
    when(
      () => chatDataSource.sendChatMessage(
        accessToken: any(named: 'accessToken'),
        entitlementToken: any(named: 'entitlementToken'),
        recipientJid: any(named: 'recipientJid'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => RiotChatSendResult.failure('Pesan ditolak server'),
    );

    final result = await repository.sendChatMessage(
      puuid: friendPuuid,
      body: 'halo',
    );

    expect(result.isFailure, isTrue);
    verifyNever(() => localStore.saveChatMessage(any(), any()));
  });

  test('getChatMessages returns locally stored history', () async {
    final stored = [
      ChatMessageEntity(
        id: 'm1',
        body: 'pagi',
        timestamp: timestamp,
        isMine: false,
      ),
    ];
    when(() => localStore.getChatMessages(friendPuuid))
        .thenAnswer((_) async => stored);

    final result = await repository.getChatMessages(friendPuuid);

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, stored);
  });
}
