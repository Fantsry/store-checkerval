import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/core/utils/valorant_card_assets.dart';
import 'package:valorant_store_tracker/features/profile/domain/repositories/profile_repository.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _profileRepository;
  Future<void>? _loadInFlight;

  ProfileCubit({required ProfileRepository profileRepository})
      : _profileRepository = profileRepository,
        super(const ProfileInitial());

  Future<void> loadProfile({bool forceRefresh = false}) {
    final inFlight = _loadInFlight;
    if (inFlight != null) return inFlight;

    final future = _loadProfile(forceRefresh: forceRefresh);
    _loadInFlight = future;
    return future.whenComplete(() {
      if (identical(_loadInFlight, future)) _loadInFlight = null;
    });
  }

  Future<void> _loadProfile({required bool forceRefresh}) async {
    final cached = await _profileRepository.getCachedProfile();
    final isDefaultBanner = cached != null &&
        (ValorantCardAssets.isDefaultCard(cached.cardUuid) ||
            cached.cardName?.toLowerCase() == 'valorant card' ||
            (cached.cardWideArt != null &&
                cached.cardWideArt!.toLowerCase().contains(
                      ValorantCardAssets.defaultCardUuid,
                    )));

    final isStaleOrPlaceholder = cached != null &&
        (cached.gameName.isEmpty ||
            cached.gameName == cached.puuid.substring(0, 8) ||
            cached.cardWideArt == null ||
            cached.cardWideArt!.isEmpty ||
            isDefaultBanner);

    if (cached != null && !forceRefresh && !isStaleOrPlaceholder) {
      emit(ProfileLoaded(cached));
    } else {
      emit(ProfileLoading(cachedProfile: isStaleOrPlaceholder ? null : cached));
    }

    final result = await _profileRepository.getUserProfile(
      forceRefresh: true,
    );

    switch (result) {
      case Success(:final value):
        final current = state;
        if (current is ProfileLoaded && current.profile == value) return;
        emit(ProfileLoaded(value));
      case Error(:final failure):
        if (cached != null && !isStaleOrPlaceholder) {
          if (state is! ProfileLoaded) emit(ProfileLoaded(cached));
        } else {
          emit(ProfileError(failure.message, cachedProfile: null));
        }
    }
  }

  Future<void> clearProfile() async {
    await _profileRepository.clearProfile();
    emit(const ProfileUnauthenticated());
  }

  void reset() => emit(const ProfileInitial());

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
            walletAvailable: true,
          ),
        ),
      );
    }
  }
}
