import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valorant_store_tracker/features/live_match/domain/entities/live_match_data.dart';
import 'package:valorant_store_tracker/features/live_match/domain/repositories/live_match_repository.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/cubit/live_match_cubit.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/cubit/live_match_state.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/pages/live_match_page.dart';
import 'package:valorant_store_tracker/ui/theme/app_theme.dart';

class _MockLiveMatchRepository extends Mock implements LiveMatchRepository {}

class _StubLiveMatchCubit extends LiveMatchCubit {
  _StubLiveMatchCubit() : super(repository: _MockLiveMatchRepository());

  final List<bool> silentCalls = [];

  @override
  Future<void> scanLiveMatch({bool silent = false}) async {
    silentCalls.add(silent);
  }

  void seed(LiveMatchState state) => emit(state);
}

void main() {
  testWidgets('refresh uses a silent scan when match data is already loaded',
      (tester) async {
    final cubit = _StubLiveMatchCubit()
      ..seed(
        const LiveMatchLoaded(
          matchData: LiveMatchData(phase: LiveMatchPhase.inLobby),
        ),
      );

    await tester.pumpWidget(
      BlocProvider<LiveMatchCubit>.value(
        value: cubit,
        child: MaterialApp(
          theme: DarkTheme.darkTheme,
          home: const LiveMatchPage(),
        ),
      ),
    );
    await tester.pump();
    cubit.silentCalls.clear();

    await tester.tap(find.byTooltip('Scan now'));
    await tester.pump();

    expect(cubit.silentCalls, [true]);
    await cubit.close();
  });
}
