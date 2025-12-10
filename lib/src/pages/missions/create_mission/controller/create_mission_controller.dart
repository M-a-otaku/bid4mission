import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../../infrastructure/commons/local_storage_keys.dart';
import '../../../../infrastructure/commons/role.dart';
import '../models/create_mission_dto.dart';
import '../repository/create_mission_repository.dart';
import '../../../../../generated/locales.g.dart';

class CreateMissionController extends GetxController {
  final CreateMissionRepository _repository = CreateMissionRepository();

  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final budgetController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();

  RxString selectedCategory = ''.obs;
  Rx<DateTime?> selectedDeadline = Rx<DateTime?>(null);
  RxBool isLoading = false.obs;

  late String employerId;
  late Role role;

  @override
  void onInit() {
    _loadUserFromStorage();
    // keep text controller in sync with selectedCategory
    ever(selectedCategory, (String? v) {
      final text = v ?? '';
      if (categoryController.text != text) categoryController.text = text;
    });
    super.onInit();
  }

  void _loadUserFromStorage() {
    final storage = GetStorage();
    final dynamic storedUserId = storage.read(LocalStorageKeys.userId);
    employerId = storedUserId == null ? '0' : storedUserId.toString();

    final dynamic storedRole = storage.read(LocalStorageKeys.role);
    role = parseRole(storedRole?.toString());
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

  Future<void> pickDeadline() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: Get.context!,
      initialDate: now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );

    if (pickedDate == null) return; // user cancelled date selection

    // now pick time in a loop until a valid (future) time is chosen or user cancels
    while (true) {
      final initialTime = TimeOfDay.fromDateTime(now.add(const Duration(hours: 1)));
      final pickedTime = await showTimePicker(
        context: Get.context!,
        initialTime: initialTime,
      );

      if (pickedTime == null) {
        // user cancelled time selection -> abort entire pick
        return;
      }

      final combined = DateTime(pickedDate.year, pickedDate.month, pickedDate.day,
          pickedTime.hour, pickedTime.minute);

      if (combined.isBefore(now.add(const Duration(minutes: 1)))) {
        // chosen datetime is in the past or too close to now; show message and let user pick time again
        Get.snackbar('زمان نامعتبر', 'مهلت باید بعد از زمان فعلی باشد', backgroundColor: Colors.orange.shade100);
        // continue loop to let user pick another time
        continue;
      }

      // valid
      selectedDeadline.value = combined;
      return;
    }
  }

  Future<void> submitMission() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedDeadline.value == null) {
      Get.snackbar(LocaleKeys.missions_page_error_deadline_required.tr, LocaleKeys.missions_page_error_deadline_required.tr);
      return;
    }

    // Ensure category is provided (prevent sending empty string to server)
    if (selectedCategory.value.trim().isEmpty) {
      Get.snackbar(LocaleKeys.missions_page_error_category_required.tr, LocaleKeys.missions_page_error_category_required.tr);
      return;
    }

    isLoading.value = true;

    final dto = CreateMissionDto(
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      category: selectedCategory.value,
      budget: int.parse(budgetController.text.replaceAll(',', '')),
      deadline: selectedDeadline.value!,
      employerId: employerId,
    );

    final result = await _repository.addMission(dto: dto);

    isLoading.value = false;

    result.fold(
      (error) =>
          Get.snackbar(LocaleKeys.missions_page_error_create_mission.trParams({'error': error}), LocaleKeys.missions_page_error_create_mission.trParams({'error': error}), backgroundColor: Colors.red.shade100),
      (result) {
        Get.back(result: result);
        Get.snackbar(LocaleKeys.missions_page_success_mission_created.tr, LocaleKeys.missions_page_success_mission_created.tr,
            backgroundColor: Colors.green.shade100);
      },
    );
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    budgetController.dispose();
    categoryController.dispose();
    super.onClose();
  }
}
