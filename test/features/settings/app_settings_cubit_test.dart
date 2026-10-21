import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/features/settings/presentation/cubit/app_settings_cubit.dart';

class _FakeLocalStore extends LocalStoreService {
  String? locale;
  int setCalls = 0;

  @override
  Future<String?> getLocale() async => locale;

  @override
  Future<void> setLocale(String? localeCode) async {
    locale = localeCode;
    setCalls++;
  }
}

void main() {
  group('AppSettingsCubit', () {
    test('loads the persisted locale', () async {
      final store = _FakeLocalStore()..locale = 'id';
      final cubit = AppSettingsCubit(store);

      await cubit.load();

      expect(cubit.state.isLoaded, isTrue);
      expect(cubit.state.locale, const Locale('id'));
    });

    test('persists and clears the locale', () async {
      final store = _FakeLocalStore();
      final cubit = AppSettingsCubit(store);

      await cubit.setLocale('en');
      expect(store.locale, 'en');
      expect(cubit.state.locale, const Locale('en'));

      await cubit.setLocale(null);
      expect(store.locale, isNull);
      expect(cubit.state.locale, isNull);
    });
  });
}
