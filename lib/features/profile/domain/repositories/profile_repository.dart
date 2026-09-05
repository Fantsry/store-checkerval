import 'package:valorant_store_tracker/core/error/result.dart';
import 'package:valorant_store_tracker/features/profile/domain/entities/user_profile.dart';

abstract class ProfileRepository {
  /// Fetches the user's current profile, equipped card, level, and wallet.
  Future<Result<UserProfile>> getUserProfile({bool forceRefresh = false});

  /// Retrieves the cached profile for instant offline/startup display.
  Future<UserProfile?> getCachedProfile();

  /// Clears profile cache on sign out.
  Future<void> clearProfile();
}
