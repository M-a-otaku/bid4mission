import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../../infrastructure/commons/local_storage_keys.dart';
import '../../../../infrastructure/commons/role.dart';
import '../models/create_mission_dto.dart';
import '../repository/create_mission_repository.dart';
import '../../../../../generated/locales.g.dart';
import '../../../../infrastructure/utils/validators.dart' as validators;

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
    return validators.validateTitle(value);
  }

  String? validateDescription(String? value) {
    return validators.validateDescription(value);
  }

  String? validateBudget(String? value) {
    return validators.validateBudget(value);
  }

  Future<void> pickDeadline() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: Get.context!,
      initialDate: now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );

    if (pickedDate == null) return; 

    
    while (true) {
      final initialTime = TimeOfDay.fromDateTime(now.add(const Duration(hours: 1)));
      final pickedTime = await showTimePicker(
        context: Get.context!,
        initialTime: initialTime,
      );

      if (pickedTime == null) {
        
        return;
      }

      final combined = DateTime(pickedDate.year, pickedDate.month, pickedDate.day,
          pickedTime.hour, pickedTime.minute);

      if (combined.isBefore(now.add(const Duration(minutes: 1)))) {
        
        Get.snackbar('Ø²Ù…Ø§Ù† Ù†Ø§Ù…Ø¹ØªØ¨Ø±', 'Ù…Ù‡Ù„Øª Ø¨Ø§ÛŒØ¯ Ø¨Ø¹Ø¯ Ø§Ø² Ø²Ù…Ø§Ù† ÙØ¹Ù„ÛŒ Ø¨Ø§Ø´Ø¯', backgroundColor: Colors.orange.shade100);
        
        continue;
      }

      
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


