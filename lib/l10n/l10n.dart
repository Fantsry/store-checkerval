import 'package:flutter/widgets.dart';
import 'package:valorant_store_tracker/l10n/generated/app_localizations.dart';

export 'package:valorant_store_tracker/l10n/generated/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
