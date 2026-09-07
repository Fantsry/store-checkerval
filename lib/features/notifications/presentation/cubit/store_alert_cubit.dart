import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:valorant_store_tracker/core/storage/local_store_service.dart';
import 'package:valorant_store_tracker/features/notifications/domain/entities/store_alert_rule.dart';
import 'package:valorant_store_tracker/features/notifications/presentation/cubit/store_alert_state.dart';

class StoreAlertCubit extends Cubit<StoreAlertState> {
  final LocalStoreService _localStore;

  StoreAlertCubit({required LocalStoreService localStore})
      : _localStore = localStore,
        super(const StoreAlertInitial());

  Future<void> loadRules() async {
    emit(const StoreAlertLoading());
    try {
      final rules = await _localStore.getAlertRules();
      emit(StoreAlertLoaded(rules: rules));
    } catch (e) {
      emit(StoreAlertError('Gagal memuat aturan alert: $e'));
    }
  }

  Future<void> toggleRule(String id, bool isEnabled) async {
    await _localStore.toggleAlertRule(id, isEnabled);
    await loadRules();
  }

  Future<void> addRule(StoreAlertRule rule) async {
    await _localStore.saveAlertRule(rule);
    await loadRules();
  }

  Future<void> deleteRule(String id) async {
    await _localStore.deleteAlertRule(id);
    await loadRules();
  }
}
