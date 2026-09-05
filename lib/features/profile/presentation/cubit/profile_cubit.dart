import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/features/profile/domain/repositories/profile_repository.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileCubit({required ProfileRepository profileRepository})
      : _profileRepository = profileRepository,
        super(const ProfileInitial());

  Future<void> loadProfile({bool forceRefresh = false}) async {
    final cached = await _profileRepository.getCachedProfile();
    final isStaleOrPlaceholder = cached != null &&
        (cached.gameName.isEmpty ||
            cached.gameName == cached.puuid.substring(0, 8) ||
            cached.cardWideArt == null ||
            cached.cardWideArt!.isEmpty);

    if (cached != null && !forceRefresh && !isStaleOrPlaceholder) {
      emit(ProfileLoaded(cached));
    } else {
      emit(ProfileLoading(cachedProfile: isStaleOrPlaceholder ? null : cached));
    }

    final result = await _profileRepository.getUserProfile(
      forceRefresh: forceRefresh || isStaleOrPlaceholder,
    );

    switch (result) {
      case Success(:final value):
        emit(ProfileLoaded(value));
      case Error(:final failure):
        if (cached != null && !isStaleOrPlaceholder) {
          emit(ProfileLoaded(cached));
        } else {
          emit(ProfileError(failure.message, cachedProfile: null));
        }
    }
  }

  Future<void> clearProfile() async {
    await _profileRepository.clearProfile();
    emit(const ProfileUnauthenticated());
  }

  void updateWithWallet({
    required int vp,
    required int rp,
    required int kc,
  }) {
    if (state is ProfileLoaded) {
      final current = (state as ProfileLoaded).profile;
      emit(
        ProfileLoaded(
          current.copyWith(
            valorantPoints: vp,
            radianitePoints: rp,
            kingdomCredits: kc,
          ),
        ),
      );
    }
  }
}
