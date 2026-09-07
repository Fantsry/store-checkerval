import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/features/career/domain/repositories/career_repository.dart';
import 'package:valorant_store_tracker/features/career/presentation/cubit/career_state.dart';

class CareerCubit extends Cubit<CareerState> {
  final CareerRepository _careerRepository;

  CareerCubit({required CareerRepository careerRepository})
      : _careerRepository = careerRepository,
        super(const CareerInitial());

  Future<void> loadCareer({bool forceRefresh = false}) async {
    final (currentOverview, currentFilter) = switch (state) {
      CareerLoaded(:final overview, :final selectedQueueFilter) =>
        (overview, selectedQueueFilter),
      CareerLoading(:final cachedOverview) => (cachedOverview, 'all'),
      CareerError(:final cachedOverview) => (cachedOverview, 'all'),
      _ => (null, 'all'),
    };

    emit(CareerLoading(cachedOverview: currentOverview));

    final result = await _careerRepository.getCareerOverview(
      forceRefresh: forceRefresh,
    );

    switch (result) {
      case Success(:final value):
        emit(CareerLoaded(
          overview: value,
          selectedQueueFilter: currentFilter,
        ));
      case Error(:final failure):
        if (currentOverview != null) {
          emit(CareerLoaded(
            overview: currentOverview,
            selectedQueueFilter: currentFilter,
          ));
        } else {
          emit(CareerError(failure.message, cachedOverview: null));
        }
    }
  }

  void filterQueue(String queue) {
    if (state is CareerLoaded) {
      final loaded = state as CareerLoaded;
      emit(loaded.copyWith(selectedQueueFilter: queue));
    }
  }

  Future<void> refresh() => loadCareer(forceRefresh: true);
}
