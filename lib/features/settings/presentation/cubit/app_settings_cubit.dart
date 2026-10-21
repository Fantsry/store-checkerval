import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';

class AppSettingsState extends Equatable {
  const AppSettingsState({
    this.locale,
    this.isLoaded = false,
  });

  final Locale? locale;
  final bool isLoaded;

  AppSettingsState copyWith({
    Locale? locale,
    bool? isLoaded,
    bool clearLocale = false,
  }) {
    return AppSettingsState(
      locale: clearLocale ? null : (locale ?? this.locale),
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  @override
  List<Object?> get props => [locale, isLoaded];
}

class AppSettingsCubit extends Cubit<AppSettingsState> {
  AppSettingsCubit(this._localStore) : super(const AppSettingsState());

  final LocalStoreService _localStore;

  Future<void> load() async {
    final code = await _localStore.getLocale();
    emit(
      AppSettingsState(
        locale: _parseLocale(code),
        isLoaded: true,
      ),
    );
  }

  Future<void> setLocale(String? code) async {
    await _localStore.setLocale(code);
    emit(
      state.copyWith(
        locale: _parseLocale(code),
        isLoaded: true,
        clearLocale: code == null || code.isEmpty,
      ),
    );
  }

  Locale? _parseLocale(String? code) {
    if (code == null || code.isEmpty) return null;
    return Locale(code);
  }
}
