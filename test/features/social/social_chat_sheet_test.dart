import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/core/error/failures.dart';
import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/features/social/domain/entities/chat_message.dart';
import 'package:valorant_store_tracker/features/social/domain/entities/friend_entity.dart';
import 'package:valorant_store_tracker/features/social/domain/repositories/social_repository.dart';
import 'package:valorant_store_tracker/features/social/presentation/cubit/social_cubit.dart';
import 'package:valorant_store_tracker/features/social/presentation/widgets/social_chat_sheet.dart';

class MockSocialRepository extends Mock implements SocialRepository {}

void main() {
  late MockSocialRepository repository;
  late SocialCubit cubit;

  final friend = FriendEntity(
    puuid: 'friend-puuid',
    gameName: 'Friend',
    tagLine: 'EUW',
    lastUpdated: DateTime(2026, 10, 20, 8),
  );

  setUp(() {
    repository = MockSocialRepository();
    cubit = SocialCubit(socialRepository: repository);
  });

  tearDown(() async {
    await cubit.close();
  });

  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: SocialChatSheet(friend: friend),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows an empty state and sends a real chat message',
      (tester) async {
    when(() => repository.getChatMessages('friend-puuid'))
        .thenAnswer((_) async => const Result.success([]));

    final sent = ChatMessageEntity(
      id: 'server-message-1',
      body: 'halo',
      timestamp: DateTime(2026, 10, 20, 8, 5),
      isMine: true,
      status: ChatMessageStatus.sent,
    );
    when(
      () => repository.sendChatMessage(
        puuid: 'friend-puuid',
        body: 'halo',
      ),
    ).thenAnswer((_) async => Result.success(sent));

    await pumpSheet(tester);

    expect(find.text('Mulai percakapan dengan Friend'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'halo');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(find.text('halo'), findsOneWidget);
    expect(find.text('Terkirim'), findsOneWidget);
    expect(find.text('Mulai percakapan dengan Friend'), findsNothing);
    verify(
      () => repository.sendChatMessage(
        puuid: 'friend-puuid',
        body: 'halo',
      ),
    ).called(1);
  });

  testWidgets('marks a failed message and retries it', (tester) async {
    when(() => repository.getChatMessages('friend-puuid'))
        .thenAnswer((_) async => const Result.success([]));
    when(
      () => repository.sendChatMessage(
        puuid: 'friend-puuid',
        body: 'halo',
      ),
    ).thenAnswer(
      (_) async => const Result.failure(
        ServerFailure(message: 'Server menolak pesan'),
      ),
    );

    await pumpSheet(tester);

    await tester.enterText(find.byType(TextField), 'halo');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Gagal dikirim · Coba lagi'), findsOneWidget);
    expect(find.text('Server menolak pesan'), findsOneWidget);

    final retried = ChatMessageEntity(
      id: 'server-message-2',
      body: 'halo',
      timestamp: DateTime(2026, 10, 20, 8, 6),
      isMine: true,
      status: ChatMessageStatus.sent,
    );
    when(
      () => repository.sendChatMessage(
        puuid: 'friend-puuid',
        body: 'halo',
      ),
    ).thenAnswer((_) async => Result.success(retried));

    await tester.tap(find.text('Gagal dikirim · Coba lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Terkirim'), findsOneWidget);
    expect(find.text('Gagal dikirim · Coba lagi'), findsNothing);
  });
}
