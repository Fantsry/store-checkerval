import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_store_tracker/core/utils/competitive_rank_helper.dart';

void main() {
  const activeActId = 'act-current';
  const oldActId = 'act-old';
  final now = DateTime.utc(2026, 10, 20, 12);

  List<Map<String, dynamic>> seasons() => [
        {
          'uuid': oldActId,
          'displayName': 'ACT V',
          'type': 'EAresSeasonType::Act',
          'startTime': '2026-06-24T00:00:00Z',
          'endTime': '2026-10-14T00:00:00Z',
        },
        {
          'uuid': activeActId,
          'displayName': 'ACT VI',
          'type': 'EAresSeasonType::Act',
          'startTime': '2026-10-14T00:00:00Z',
          'endTime': '2027-01-06T00:00:00Z',
        },
        {
          'uuid': 'episode',
          'displayName': 'EPISODE',
          'type': 'EAresSeasonType::Episode',
          'startTime': '2026-01-01T00:00:00Z',
          'endTime': '2027-01-06T00:00:00Z',
        },
      ];

  group('resolveActiveAct', () {
    test('selects the act containing now, ignoring episodes', () {
      final act = CompetitiveRankHelper.resolveActiveAct(seasons(), now: now);

      expect(act?.id, activeActId);
      expect(act?.displayName, 'ACT VI');
    });

    test('returns null between acts instead of guessing', () {
      final act = CompetitiveRankHelper.resolveActiveAct(
        seasons(),
        now: DateTime.utc(2027, 2, 1),
      );

      expect(act, isNull);
    });
  });

  group('resolveCurrentRank', () {
    Map<String, dynamic> mmrWithSeasonal(Map<String, dynamic> entry) => {
          'QueueSkills': {
            'competitive': {
              'SeasonalInfoBySeasonID': {activeActId: entry},
            },
          },
        };

    test('reads tier and rating from the active act seasonal entry', () {
      final snapshot = CompetitiveRankHelper.resolveCurrentRank(
        mmr: mmrWithSeasonal({
          'CompetitiveTier': 18,
          'RankedRating': 42,
          'GamesNeededForRating': 0,
        }),
        activeSeasonId: activeActId,
      );

      expect(snapshot.tier, 18);
      expect(snapshot.rating, 42);
      expect(snapshot.isRanked, isTrue);
      expect(snapshot.isPlacement, isFalse);
    });

    test('matches seasonal info keys case-insensitively', () {
      final snapshot = CompetitiveRankHelper.resolveCurrentRank(
        mmr: {
          'QueueSkills': {
            'competitive': {
              'SeasonalInfoBySeasonID': {
                activeActId.toUpperCase(): {
                  'CompetitiveTier': 17,
                  'RankedRating': 21,
                },
              },
            },
          },
        },
        activeSeasonId: activeActId,
      );

      expect(snapshot.tier, 17);
      expect(snapshot.rating, 21);
      expect(snapshot.isRanked, isTrue);
    });

    test('keeps a real 0 RR instead of treating it as unknown', () {
      final snapshot = CompetitiveRankHelper.resolveCurrentRank(
        mmr: mmrWithSeasonal({
          'CompetitiveTier': 15,
          'RankedRating': 0,
        }),
        activeSeasonId: activeActId,
      );

      expect(snapshot.rating, 0);
      expect(snapshot.isRanked, isTrue);
    });

    test('detects a placement account', () {
      final snapshot = CompetitiveRankHelper.resolveCurrentRank(
        mmr: mmrWithSeasonal({
          'CompetitiveTier': 0,
          'RankedRating': 0,
          'GamesNeededForRating': 3,
        }),
        activeSeasonId: activeActId,
      );

      expect(snapshot.isPlacement, isTrue);
      expect(snapshot.gamesNeededForRating, 3);
      expect(snapshot.isRanked, isFalse);
    });

    test('does not fall back to the previous act when current act is empty',
        () {
      final snapshot = CompetitiveRankHelper.resolveCurrentRank(
        mmr: {
          'QueueSkills': {
            'competitive': {
              'Tier': 20,
              'RankedRating': 88,
              'SeasonalInfoBySeasonID': {
                oldActId: {'CompetitiveTier': 20, 'RankedRating': 88},
              },
            },
          },
          'LatestCompetitiveUpdate': {
            'SeasonID': oldActId,
            'TierAfterUpdate': 20,
            'RankedRatingAfterUpdate': 88,
          },
        },
        activeSeasonId: activeActId,
        competitiveUpdates: [
          {
            'SeasonID': oldActId,
            'TierAfterUpdate': 20,
            'RankedRatingAfterUpdate': 88,
            'MatchStartTime': 1000,
          },
        ],
      );

      expect(snapshot.tier, 0);
      expect(snapshot.rating, 0);
      expect(snapshot.isRanked, isFalse);
      expect(snapshot.seasonId, activeActId);
    });

    test('uses the newest update only when it belongs to the active act', () {
      final snapshot = CompetitiveRankHelper.resolveCurrentRank(
        mmr: const {'QueueSkills': {'competitive': {}}},
        activeSeasonId: activeActId,
        competitiveUpdates: [
          {
            'SeasonID': oldActId,
            'TierAfterUpdate': 20,
            'RankedRatingAfterUpdate': 80,
            'MatchStartTime': 2000,
          },
          {
            'SeasonID': activeActId,
            'TierAfterUpdate': 16,
            'RankedRatingAfterUpdate': 30,
            'MatchStartTime': 1000,
          },
        ],
      );

      expect(snapshot.tier, 16);
      expect(snapshot.rating, 30);
      expect(snapshot.isRanked, isTrue);
    });

    test('matches competitive update season ids case-insensitively', () {
      final snapshot = CompetitiveRankHelper.resolveCurrentRank(
        mmr: const {'QueueSkills': {'competitive': {}}},
        activeSeasonId: activeActId,
        competitiveUpdates: [
          {
            'SeasonID': activeActId.toUpperCase(),
            'TierAfterUpdate': 14,
            'RankedRatingAfterUpdate': 12,
            'MatchStartTime': 1000,
          },
        ],
      );

      expect(snapshot.tier, 14);
      expect(snapshot.rating, 12);
      expect(snapshot.hasCurrentActData, isTrue);
    });
  });

  group('rrEarnedFromUpdate', () {
    test('preserves an official 0 RR delta', () {
      final delta = CompetitiveRankHelper.rrEarnedFromUpdate({
        'RankedRatingEarned': 0,
        'RankedRatingBeforeUpdate': 40,
        'RankedRatingAfterUpdate': 40,
      });

      expect(delta, 0);
    });

    test('computes the delta across a tier boundary', () {
      final delta = CompetitiveRankHelper.rrEarnedFromUpdate({
        'TierBeforeUpdate': 15,
        'TierAfterUpdate': 16,
        'RankedRatingBeforeUpdate': 90,
        'RankedRatingAfterUpdate': 10,
      });

      expect(delta, 20);
    });
  });
}
