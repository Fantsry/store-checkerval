import 'package:equatable/equatable.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/career_overview.dart';
import 'package:valorant_store_tracker/features/career/domain/entities/match_summary.dart';

sealed class CareerState extends Equatable {
  const CareerState();

  @override
  List<Object?> get props => [];
}

class CareerInitial extends CareerState {
  const CareerInitial();
}

class CareerLoading extends CareerState {
  final CareerOverview? cachedOverview;

  const CareerLoading({this.cachedOverview});

  @override
  List<Object?> get props => [cachedOverview];
}

class CareerLoaded extends CareerState {
  final CareerOverview overview;
  final String selectedQueueFilter;

  const CareerLoaded({
    required this.overview,
    this.selectedQueueFilter = 'all',
  });

  List<MatchSummary> get filteredMatches {
    if (selectedQueueFilter == 'all') {
      return overview.matches;
    }
    return overview.matches.where((m) {
      final q = m.queueId.toLowerCase();
      if (selectedQueueFilter == 'competitive') {
        return q == 'competitive';
      }
      if (selectedQueueFilter == 'unrated') {
        return q == 'unrated';
      }
      if (selectedQueueFilter == 'deathmatch') {
        return q == 'deathmatch';
      }
      if (selectedQueueFilter == 'spikerush') {
        return q == 'spikerush';
      }
      return true;
    }).toList();
  }

  CareerLoaded copyWith({
    CareerOverview? overview,
    String? selectedQueueFilter,
  }) {
    return CareerLoaded(
      overview: overview ?? this.overview,
      selectedQueueFilter: selectedQueueFilter ?? this.selectedQueueFilter,
    );
  }

  @override
  List<Object?> get props => [overview, selectedQueueFilter];
}

class CareerError extends CareerState {
  final String message;
  final CareerOverview? cachedOverview;

  const CareerError(this.message, {this.cachedOverview});

  @override
  List<Object?> get props => [message, cachedOverview];
}
