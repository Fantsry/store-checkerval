import 'package:flutter/material.dart';

/// Performance rating calculator — assigns a grade (S+, S, A, B, C, D) based
/// on ACS, K/D ratio, and headshot percentage. Mimics Tracker.gg-style grades.
class PerformanceRating {
  final String grade;
  final Color color;
  final Color backgroundColor;

  const PerformanceRating._({
    required this.grade,
    required this.color,
    required this.backgroundColor,
  });

  /// Calculate performance grade based on key match stats.
  ///
  /// Scoring system (max 100 pts):
  ///   - ACS (0–40 pts): 0→0, 150→20, 250→35, 350+→40
  ///   - K/D (0–40 pts): 0→0, 1.0→20, 1.5→30, 2.0+→40
  ///   - HS% (0–20 pts): 0→0, 15→8, 25→14, 35+→20
  static PerformanceRating calculate({
    required int acs,
    required double kdRatio,
    required int headshotPct,
  }) {
    // ACS score (out of 40)
    double acsScore;
    if (acs >= 350) {
      acsScore = 40;
    } else if (acs >= 250) {
      acsScore = 35 + (acs - 250) / 100 * 5;
    } else if (acs >= 150) {
      acsScore = 20 + (acs - 150) / 100 * 15;
    } else {
      acsScore = acs / 150 * 20;
    }

    // K/D score (out of 40)
    double kdScore;
    if (kdRatio >= 2.0) {
      kdScore = 40;
    } else if (kdRatio >= 1.5) {
      kdScore = 30 + (kdRatio - 1.5) / 0.5 * 10;
    } else if (kdRatio >= 1.0) {
      kdScore = 20 + (kdRatio - 1.0) / 0.5 * 10;
    } else {
      kdScore = kdRatio / 1.0 * 20;
    }

    // Headshot score (out of 20)
    double hsScore;
    if (headshotPct >= 35) {
      hsScore = 20;
    } else if (headshotPct >= 25) {
      hsScore = 14 + (headshotPct - 25) / 10 * 6;
    } else if (headshotPct >= 15) {
      hsScore = 8 + (headshotPct - 15) / 10 * 6;
    } else {
      hsScore = headshotPct / 15 * 8;
    }

    final totalScore = acsScore + kdScore + hsScore;

    if (totalScore >= 85) {
      return const PerformanceRating._(
        grade: 'S+',
        color: Color(0xFFFFD700),
        backgroundColor: Color(0x30FFD700),
      );
    } else if (totalScore >= 72) {
      return const PerformanceRating._(
        grade: 'S',
        color: Color(0xFFFFA500),
        backgroundColor: Color(0x28FFA500),
      );
    } else if (totalScore >= 58) {
      return const PerformanceRating._(
        grade: 'A',
        color: Color(0xFF00C4A8),
        backgroundColor: Color(0x2500C4A8),
      );
    } else if (totalScore >= 42) {
      return const PerformanceRating._(
        grade: 'B',
        color: Color(0xFF4FC3F7),
        backgroundColor: Color(0x224FC3F7),
      );
    } else if (totalScore >= 25) {
      return const PerformanceRating._(
        grade: 'C',
        color: Color(0xFFB0BEC5),
        backgroundColor: Color(0x20B0BEC5),
      );
    } else {
      return const PerformanceRating._(
        grade: 'D',
        color: Color(0xFFFF5252),
        backgroundColor: Color(0x22FF5252),
      );
    }
  }
}
