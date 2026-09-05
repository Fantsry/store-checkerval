import 'package:get_it/get_it.dart';
import 'package:valorant_store_tracker/core/network/auth_interceptor.dart';
import 'package:valorant_store_tracker/core/network/dio_client.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/core/storage/secure_storage_service.dart';
import 'package:valorant_store_tracker/core/utils/connectivity_checker.dart';
import 'package:valorant_store_tracker/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:valorant_store_tracker/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:valorant_store_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:valorant_store_tracker/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:valorant_store_tracker/features/daily_store/data/datasources/riot_store_remote_datasource.dart';
import 'package:valorant_store_tracker/features/daily_store/data/datasources/valorant_api_remote_datasource.dart';
import 'package:valorant_store_tracker/features/daily_store/data/repositories/store_repository_impl.dart';
import 'package:valorant_store_tracker/features/daily_store/domain/repositories/store_repository.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_cubit.dart';
import 'package:valorant_store_tracker/features/notifications/data/notification_service.dart';
import 'package:valorant_store_tracker/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:valorant_store_tracker/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:valorant_store_tracker/features/profile/domain/repositories/profile_repository.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:valorant_store_tracker/features/wishlist/data/repositories/wishlist_repository_impl.dart';
import 'package:valorant_store_tracker/features/wishlist/domain/repositories/wishlist_repository.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupDI() async {
  // ─── Core Services & Storage ────────────────────────────────
  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(),
  );

  final localStore = LocalStoreService();
  await localStore.init();
  getIt.registerSingleton<LocalStoreService>(localStore);

  getIt.registerLazySingleton<ConnectivityChecker>(
    () => ConnectivityChecker(),
  );

  getIt.registerLazySingleton<NotificationService>(
    () => NotificationService(),
  );

  getIt.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(storage: getIt<SecureStorageService>()),
  );

  getIt.registerLazySingleton<DioClient>(
    () => DioClient(authInterceptor: getIt<AuthInterceptor>()),
  );

  // ─── Remote Data Sources ─────────────────────────────────────
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: getIt<DioClient>().dio),
  );

  getIt.registerLazySingleton<ValorantApiRemoteDataSource>(
    () => ValorantApiRemoteDataSourceImpl(dio: getIt<DioClient>().dio),
  );

  getIt.registerLazySingleton<RiotStoreRemoteDataSource>(
    () => RiotStoreRemoteDataSourceImpl(dio: getIt<DioClient>().dio),
  );

  getIt.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(dio: getIt<DioClient>().dio),
  );

  // ─── Repositories ───────────────────────────────────────────
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: getIt<AuthRemoteDataSource>(),
      storage: getIt<SecureStorageService>(),
    ),
  );

  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      remoteDataSource: getIt<ProfileRemoteDataSource>(),
      storage: getIt<SecureStorageService>(),
      localStore: getIt<LocalStoreService>(),
    ),
  );

  getIt.registerLazySingleton<StoreRepository>(
    () => StoreRepositoryImpl(
      riotRemoteDataSource: getIt<RiotStoreRemoteDataSource>(),
      valorantApiRemoteDataSource: getIt<ValorantApiRemoteDataSource>(),
      secureStorage: getIt<SecureStorageService>(),
      localStore: getIt<LocalStoreService>(),
    ),
  );

  getIt.registerLazySingleton<WishlistRepository>(
    () => WishlistRepositoryImpl(
      localStore: getIt<LocalStoreService>(),
      storeRepository: getIt<StoreRepository>(),
    ),
  );

  // ─── Cubits ─────────────────────────────────────────────────
  getIt.registerFactory<AuthCubit>(
    () => AuthCubit(authRepository: getIt<AuthRepository>()),
  );

  getIt.registerFactory<ProfileCubit>(
    () => ProfileCubit(profileRepository: getIt<ProfileRepository>()),
  );

  getIt.registerFactory<StoreCubit>(
    () => StoreCubit(storeRepository: getIt<StoreRepository>()),
  );

  getIt.registerFactory<WishlistCubit>(
    () => WishlistCubit(wishlistRepository: getIt<WishlistRepository>()),
  );
}
