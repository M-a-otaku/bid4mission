import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../../generated/locales.g.dart';

import '../models/edit_mission_dto.dart';
import '../models/mission_model.dart';
import '../repository/edit_mission_repository.dart';
import '../../../../infrastructure/utils/validators.dart' as validators;

class EditMissionController extends GetxController {
  final EditMissionRepository _repository = EditMissionRepository();

  final String missionId;

  EditMissionController({required this.missionId});

  final formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController budgetController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  RxString selectedCategory = ''.obs;
  Rx<DateTime?> selectedDeadline = Rx<DateTime?>(null);
  RxBool isLoading = true.obs;
  Rx<MissionModel?> mission = Rx<MissionModel?>(null);
  RxBool budgetFormatted = false.obs;

  @override
  void onInit() {
    _bindCategory();
    super.onInit();
    loadMission(missionId);
  }

  void _bindCategory() {
    
    ever(selectedCategory, (String? v) {
      final text = v ?? '';
      if (categoryController.text != text) categoryController.text = text;
    });
  }

  Future<void> loadMission(String missionId) async {
    isLoading.value = true;

    final result = await _repository.getMissionById(missionId: missionId);

    result.fold(
      (error) {
        isLoading.value = false;
        
        Get.snackbar(LocaleKeys.error_error.tr, LocaleKeys.missions_page_error_update_mission.trParams({'error': error}), backgroundColor: Colors.red.shade100);
        Get.back();
      },
      (fetchedMission) {
        mission.value = fetchedMission;
        isLoading.value = false;
        titleController.text = fetchedMission.title;
        descriptionController.text = fetchedMission.description;
        
        try {
          final formatted = intl.NumberFormat.decimalPattern('en_US').format(fetchedMission.budget);
          try { Get.log('EditMissionController: setting formatted budget -> $formatted'); } catch (_) { print('EditMissionController: setting formatted budget -> $formatted'); }
          budgetController.value = TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
          budgetFormatted.value = true;
        } catch (_) {
          final plain = fetchedMission.budget.toString();
          try { Get.log('EditMissionController: setting plain budget -> $plain'); } catch (_) { print('EditMissionController: setting plain budget -> $plain'); }
          budgetController.value = TextEditingValue(text: plain, selection: TextSelection.collapsed(offset: plain.length));
          budgetFormatted.value = true;
        }
        selectedCategory.value = fetchedMission.category;
        categoryController.text = fetchedMission.category;
        selectedDeadline.value = fetchedMission.deadline;
      },
    );
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

  Future<void> submitEdit() async {
    if (!formKey.currentState!.validate()) return;

    if (selectedCategory.value.trim().isEmpty) {
      Get.snackbar('Ø®Ø·Ø§', 'Ø¯Ø³ØªÙ‡â€ŒØ¨Ù†Ø¯ÛŒ Ø±Ø§ Ø§Ù†ØªØ®Ø§Ø¨ ÛŒØ§ ÙˆØ§Ø±Ø¯ Ú©Ù†ÛŒØ¯');
      return;
    }

    isLoading.value = true;

    final dto = EditMissionDto(
      id: missionId,
      
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      category: selectedCategory.value,
      budget: int.parse(budgetController.text.replaceAll(',', '')),
      deadline: selectedDeadline.value ?? DateTime.now(),
    );

    final result =
        await _repository.editMission(dto: dto, missionId: missionId);

    isLoading.value = false;

    result.fold(
      (error) => Get.snackbar(LocaleKeys.error_error.tr, LocaleKeys.missions_page_error_update_mission.trParams({'error': error}), backgroundColor: Colors.red.shade100),
      (updatedMission) {
        Get.back(result: updatedMission);
      },
    );
  }

  Future<void> pickDeadline(BuildContext context) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );

    final timeOfDay = pickedTime ?? TimeOfDay.fromDateTime(now);

    final combined = DateTime(pickedDate.year, pickedDate.month, pickedDate.day,
        timeOfDay.hour, timeOfDay.minute);

    selectedDeadline.value = combined;
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


