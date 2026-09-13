import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_store_tracker/features/career/presentation/widgets/performance_rating_utils.dart';

void main() {
  group('PerformanceRating.calculate Tests', () {
    test('calculates S+ grade for god-tier performance', () {
      final rating = PerformanceRating.calculate(
        acs: 360,
        kdRatio: 2.2,
        headshotPct: 38,
      );
      expect(rating.grade, 'S+');
    });

    test('calculates S grade for strong carry performance', () {
      final rating = PerformanceRating.calculate(
        acs: 280,
        kdRatio: 1.6,
        headshotPct: 28,
      );
      expect(rating.grade, 'S');
    });

    test('calculates A grade for solid winning game', () {
      final rating = PerformanceRating.calculate(
        acs: 220,
        kdRatio: 1.2,
        headshotPct: 20,
      );
      expect(rating.grade, 'A');
    });

    test('calculates B grade for average game', () {
      final rating = PerformanceRating.calculate(
        acs: 170,
        kdRatio: 0.95,
        headshotPct: 16,
      );
      expect(rating.grade, 'B');
    });

    test('calculates C grade for below average game', () {
      final rating = PerformanceRating.calculate(
        acs: 120,
        kdRatio: 0.7,
        headshotPct: 10,
      );
      expect(rating.grade, 'C');
    });

    test('calculates D grade for rough game', () {
      final rating = PerformanceRating.calculate(
        acs: 60,
        kdRatio: 0.3,
        headshotPct: 5,
      );
      expect(rating.grade, 'D');
    });
  });
}
