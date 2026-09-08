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
import 'package:valorant_store_tracker/features/notifications/presentation/cubit/store_alert_cubit.dart';
import 'package:valorant_store_tracker/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:valorant_store_tracker/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:valorant_store_tracker/features/profile/domain/repositories/profile_repository.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:valorant_store_tracker/features/career/data/datasources/career_remote_datasource.dart';
import 'package:valorant_store_tracker/features/career/data/repositories/career_repository_impl.dart';
import 'package:valorant_store_tracker/features/career/domain/repositories/career_repository.dart';
import 'package:valorant_store_tracker/features/career/presentation/cubit/career_cubit.dart';
import 'package:valorant_store_tracker/features/wishlist/data/repositories/wishlist_repository_impl.dart';
import 'package:valorant_store_tracker/features/wishlist/domain/repositories/wishlist_repository.dart';
import 'package:valorant_store_tracker/features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'package:valorant_store_tracker/features/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:valorant_store_tracker/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:valorant_store_tracker/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:valorant_store_tracker/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:valorant_store_tracker/features/battlepass/data/datasources/contracts_remote_datasource.dart';
import 'package:valorant_store_tracker/features/battlepass/data/repositories/battlepass_repository_impl.dart';
import 'package:valorant_store_tracker/features/battlepass/domain/repositories/battlepass_repository.dart';
import 'package:valorant_store_tracker/features/battlepass/presentation/cubit/battlepass_cubit.dart';
import 'package:valorant_store_tracker/features/live_match/data/datasources/live_match_remote_datasource.dart';
import 'package:valorant_store_tracker/features/live_match/data/repositories/live_match_repository_impl.dart';
import 'package:valorant_store_tracker/features/live_match/domain/repositories/live_match_repository.dart';
import 'package:valorant_store_tracker/features/live_match/presentation/cubit/live_match_cubit.dart';

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

  getIt.registerLazySingleton<CareerRemoteDataSource>(
    () => CareerRemoteDataSourceImpl(dio: getIt<DioClient>().dio),
  );

  getIt.registerLazySingleton<InventoryRemoteDataSource>(
    () => InventoryRemoteDataSourceImpl(dio: getIt<DioClient>().dio),
  );

  getIt.registerLazySingleton<ContractsRemoteDataSource>(
    () => ContractsRemoteDataSourceImpl(dio: getIt<DioClient>().dio),
  );

  getIt.registerLazySingleton<LiveMatchRemoteDataSource>(
    () => LiveMatchRemoteDataSourceImpl(dio: getIt<DioClient>().dio),
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

  getIt.registerLazySingleton<CareerRepository>(
    () => CareerRepositoryImpl(
      remoteDataSource: getIt<CareerRemoteDataSource>(),
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

  getIt.registerLazySingleton<InventoryRepository>(
    () => InventoryRepositoryImpl(
      remoteDataSource: getIt<InventoryRemoteDataSource>(),
      valorantApiDataSource: getIt<ValorantApiRemoteDataSource>(),
      storage: getIt<SecureStorageService>(),
      localStore: getIt<LocalStoreService>(),
    ),
  );

  getIt.registerLazySingleton<BattlepassRepository>(
    () => BattlepassRepositoryImpl(
      remoteDataSource: getIt<ContractsRemoteDataSource>(),
      storage: getIt<SecureStorageService>(),
      localStore: getIt<LocalStoreService>(),
    ),
  );

  getIt.registerLazySingleton<LiveMatchRepository>(
    () => LiveMatchRepositoryImpl(
      remoteDataSource: getIt<LiveMatchRemoteDataSource>(),
      careerDataSource: getIt<CareerRemoteDataSource>(),
      storage: getIt<SecureStorageService>(),
    ),
  );

  // ─── Cubits ─────────────────────────────────────────────────
  getIt.registerFactory<AuthCubit>(
    () => AuthCubit(authRepository: getIt<AuthRepository>()),
  );

  getIt.registerFactory<ProfileCubit>(
    () => ProfileCubit(profileRepository: getIt<ProfileRepository>()),
  );

  getIt.registerFactory<CareerCubit>(
    () => CareerCubit(careerRepository: getIt<CareerRepository>()),
  );

  getIt.registerFactory<StoreCubit>(
    () => StoreCubit(
      storeRepository: getIt<StoreRepository>(),
      notificationService: getIt<NotificationService>(),
      localStore: getIt<LocalStoreService>(),
    ),
  );

  getIt.registerFactory<WishlistCubit>(
    () => WishlistCubit(wishlistRepository: getIt<WishlistRepository>()),
  );

  getIt.registerFactory<StoreAlertCubit>(
    () => StoreAlertCubit(localStore: getIt<LocalStoreService>()),
  );

  getIt.registerFactory<InventoryCubit>(
    () => InventoryCubit(repository: getIt<InventoryRepository>()),
  );

  getIt.registerFactory<BattlepassCubit>(
    () => BattlepassCubit(repository: getIt<BattlepassRepository>()),
  );

  getIt.registerFactory<LiveMatchCubit>(
    () => LiveMatchCubit(repository: getIt<LiveMatchRepository>()),
  );
}
