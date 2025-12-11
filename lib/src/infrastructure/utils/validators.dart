import 'package:get/get.dart';
import '../../../generated/locales.g.dart';

String? validateRequired(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return LocaleKeys.validate_required.tr;
  return null;
}

String? validateUsername(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return LocaleKeys.login_page_validate_username.tr;
  final persianRegex = RegExp(r"[\u0600-\u06FF\uFB50-\uFDFF\uFE70-\uFEFF]");
  if (persianRegex.hasMatch(v)) return LocaleKeys.login_page_validate_username_no_persian.tr;
  return null;
}

String? validatePasswordCommon(String? value, {String? serverError}) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return LocaleKeys.login_page_validate_password.tr;
  final persianRegex = RegExp(r"[\u0600-\u06FF\uFB50-\uFDFF\uFE70-\uFEFF]");
  if (persianRegex.hasMatch(v)) return LocaleKeys.login_page_validate_password_no_persian.tr;
  if (v.length < 8) return LocaleKeys.login_page_validate_password_min.tr;
  if (serverError != null && serverError.isNotEmpty) return serverError;
  return null;
}

String? validateRepeatPassword(String? value, String password, {String? serverError}) {
  final base = validatePasswordCommon(value, serverError: serverError);
  if (base != null) return base;
  if ((value ?? '') != password) return LocaleKeys.register_page_password_not_match.tr;
  return null;
}

String? validateTitle(String? value) {
  if (value == null || value.trim().isEmpty) return LocaleKeys.missions_page_validate_title_required.tr;
  if (value.trim().length < 5) return LocaleKeys.missions_page_validate_title_min.tr;
  return null;
}

String? validateDescription(String? value) {
  if (value == null || value.trim().isEmpty) return LocaleKeys.missions_page_validate_description_required.tr;
  if (value.trim().length < 20) return LocaleKeys.missions_page_validate_description_min.tr;
  return null;
}

String? validateBudget(String? value) {
  if (value == null || value.isEmpty) return LocaleKeys.missions_page_validate_budget_required.tr;
  final budget = int.tryParse(value.replaceAll(',', ''));
  if (budget == null || budget < 100000) return LocaleKeys.missions_page_validate_budget_min.tr;
  return null;
}


