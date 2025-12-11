import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../../../bid4mission.dart';
import '../../../../../generated/locales.g.dart';
import '../../../../infrastructure/commons/local_storage_keys.dart';
import '../../../../infrastructure/commons/status.dart';
import '../../../../infrastructure/commons/role.dart';
import '../models/create_proposal_dto.dart';
import '../models/missions_model.dart';
import '../repositories/missions_list_repository.dart';
import '../../../../infrastructure/theme/theme_service.dart';
import '../../../../components/widgets/tag_input/repository/smart_category_service.dart';
import 'package:flutter/services.dart';
import '../../../../infrastructure/utils/thousands_separator_input_formatter.dart';

class MissionListController extends GetxController {
  final _repository = MissionListRepository();

  RxList<MissionsModel> missions = <MissionsModel>[].obs;
  RxBool isLoading = true.obs;
  RxString error = ''.obs;

  RxList<String> processingMissionIds = <String>[].obs;

  String userId = "0";
  Role? role;
  RxBool isUserLoaded = false.obs;

  Role get roleOrDefault => role ?? Role.hunter;

  final TextEditingController searchController = TextEditingController();
  RxString searchQuery = ''.obs;
  RxList<String> searchSuggestions = <String>[].obs;

  RxList<String> categories = <String>[].obs;
  RxList<String> selectedCategories = <String>[].obs;

  RxInt? minBudget = RxInt(0);
  RxInt? maxBudget = RxInt(0);

  RxList<String> selectedStatuses = <String>[].obs;

  RxInt globalMinBudget = 0.obs;
  RxInt globalMaxBudget = 1000.obs;

  RxBool isBudgetFilterEnabled = false.obs;

  RxString sortByDate = RxString('asc');

  Rx<ThemeMode> themeMode = Rx<ThemeMode>(ThemeMode.light);

  @override
  void onInit() {
    isLoading(true);
    _initController();
    super.onInit();
  }

  Future<void> _initController() async {
    try {
      await _loadUserFromStorage();

      themeMode.value = ThemeService.getThemeMode();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          Get.changeThemeMode(themeMode.value);
        } catch (_) {}
      });

      debounce(searchQuery, (_) {
        if (searchQuery.value.trim().length >= 2) {
          fetchMissions();
          _loadSearchSuggestions(searchQuery.value);
        } else if (searchQuery.value.trim().isEmpty) {
          searchSuggestions.clear();
          fetchMissions();
        }
      }, time: const Duration(milliseconds: 600));

      await fetchCategories();

      await loadGlobalBudgetRange();
      await fetchMissions();
    } catch (e) {
      isLoading.value = false;
      error.value = e.toString();
    }
  }

  Future<void> _loadUserFromStorage() async {
    await GetStorage.init();
    final storage = GetStorage();

    final dynamic storedUserId = storage.read(LocalStorageKeys.userId);
    userId = storedUserId == null ? '0' : storedUserId.toString();

    final dynamic storedRole = storage.read(LocalStorageKeys.role);
    if (storedRole != null) {
      final raw = storedRole.toString();

      role = parseRole(raw);
    }

    isUserLoaded.value = true;
  }

  Future<void> fetchCategories() async {
    try {
      final list = await _repository.getAllCategories();
      categories.value = list;
    } catch (_) {}
  }

  Future<void> _loadSearchSuggestions(String query) async {
    try {
      final result = await _repository
          .getMissions(userId, roleToString(roleOrDefault), search: query);
      result.fold((err) => null, (data) {
        final titles = data.map((m) => m.title).toSet().toList();
        searchSuggestions.value = titles;
      });
    } catch (_) {}
  }

  Future<void> fetchMissions({bool forceRefresh = false}) async {
    isLoading.value = true;
    error.value = '';

    final String? search =
        searchQuery.value.trim().isEmpty ? null : searchQuery.value.trim();
    final List<String>? cats =
        selectedCategories.isEmpty ? null : selectedCategories.toList();
    final int? minB = (minBudget?.value ?? 0) == 0 ? null : minBudget?.value;
    final int? maxB = (maxBudget?.value ?? 0) == 0 ? null : maxBudget?.value;
    final List<String>? statuses =
        selectedStatuses.isEmpty ? null : selectedStatuses.toList();
    final String? sort = sortByDate.value == '' ? null : sortByDate.value;

    final result = await _repository.getMissions(
        userId, roleToString(roleOrDefault),
        search: search,
        categories: cats,
        minBudget: minB,
        maxBudget: maxB,
        statuses: statuses,
        sortByDate: sort);

    result.fold(
      (err) => error.value = err,
      (data) => missions.value = data,
    );

    if (error.value.isNotEmpty) {
      try {
        Get.log('fetchMissions error: ${error.value}');
      } catch (_) {}
    } else {
      try {
        Get.log('fetchMissions success count=${missions.length}');
      } catch (_) {}
    }

    isLoading.value = false;
  }

  void setSearch(String value) {
    searchController.text = value;
    searchController.selection =
        TextSelection.fromPosition(TextPosition(offset: value.length));
    searchQuery.value = value;
    searchSuggestions.clear();
    fetchMissions();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    searchSuggestions.clear();
    fetchMissions();
  }

  void toggleCategory(String category) {
    if (selectedCategories.contains(category)) {
      selectedCategories.remove(category);
    } else {
      selectedCategories.add(category);
    }
    fetchMissions();
  }

  void setBudgetRange(int? min, int? max) {
    minBudget?.value = min ?? 0;
    maxBudget?.value = max ?? 0;
    fetchMissions();
  }

  void toggleStatus(String status) {
    if (selectedStatuses.contains(status)) {
      selectedStatuses.remove(status);
    } else {
      selectedStatuses.add(status);
    }
    fetchMissions();
  }

  void setSort(String sort) {
    sortByDate.value = sort;
    fetchMissions();
  }

  Future<void> toAddMission() async {
    final result = await Get.toNamed(RouteNames.addMissions);
    if (result != null) {
      missions.add(MissionsModel.fromJson(result));
      fetchMissions();
    }
  }

  Future<void> toEditMission({required String missionId}) async {
    final result = await Get.toNamed(RouteNames.editMissions,
        parameters: {"id": missionId});
    if (result != null || result != false) {
      fetchMissions();
    }
  }

  Future<void> toMissionDetails({required String missionId}) async {
    final result = await Get.toNamed(RouteNames.missionDetails,
        parameters: {"id": missionId});
    if (result != null || result != false) {
      fetchMissions();
    }
  }

  Future<void> toProfile({required String hunterId}) async {
    await Get.toNamed(RouteNames.profile, parameters: {"id": hunterId});
  }

  String fmtInt(int value) {
    final s = value.toString();
    return s.replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => ',');
  }

  String formatCurrency(dynamic b) {
    final intVal = int.tryParse(b?.toString() ?? '') ?? 0;
    return '${fmtInt(intVal)} ${LocaleKeys.currency_toman.tr}';
  }

  String displayStatus(Status status) {
    if (status == Status.pendingApproval) {
      if (roleOrDefault == Role.employer) return statusToString(status);
      return statusToString(Status.inProgress);
    }
    return statusToString(status);
  }

  List<String> availableStatuses() {
    if (roleOrDefault == Role.employer) {
      return [
        statusToString(Status.open),
        statusToString(Status.pendingApproval),
        statusToString(Status.completed),
        statusToString(Status.expired),
        statusToString(Status.inProgress),
      ];
    }
    return [
      statusToString(Status.open),
      statusToString(Status.inProgress),
      statusToString(Status.completed),
      statusToString(Status.expired),
    ];
  }

  Future<void> confirmMissionCompletion(
      {required MissionsModel mission}) async {
    if (!mission.status.isPendingApproval) return;

    if (processingMissionIds.contains(mission.id)) return;
    processingMissionIds.add(mission.id);
    Get.dialog(const Center(child: CircularProgressIndicator()),
        barrierDismissible: false);
    final result = await _repository.updateMissionStatus(
        missionId: mission.id, status: Status.completed);
    Get.back();

    result.fold((err) {
      Get.snackbar(LocaleKeys.common_error.tr, err,
          backgroundColor: Colors.red, colorText: Colors.white);
    }, (_) {
      final updated = missions.map((m) {
        if (m.id == mission.id) {
          return MissionsModel(
            id: m.id,
            title: m.title,
            description: m.description,
            category: m.category,
            budget: m.budget,
            deadline: m.deadline,
            status: Status.completed,
            employerId: m.employerId,
            chosenProposalId: m.chosenProposalId,
          );
        }
        return m;
      }).toList();
      missions.assignAll(updated);
      Get.snackbar(LocaleKeys.missions_page_confirm_done_title.tr,
          LocaleKeys.missions_page_confirm_done_message.tr,
          backgroundColor: Colors.green, colorText: Colors.white);
    });

    processingMissionIds.remove(mission.id);
  }

  Future<void> rejectMission({required MissionsModel mission}) async {
    if (!mission.status.isPendingApproval) return;

    if (processingMissionIds.contains(mission.id)) return;
    processingMissionIds.add(mission.id);
    Get.dialog(const Center(child: CircularProgressIndicator()),
        barrierDismissible: false);
    final result = await _repository.updateMissionStatus(
        missionId: mission.id, status: Status.failed);
    Get.back();

    result.fold((err) {
      Get.snackbar(LocaleKeys.common_error.tr, err,
          backgroundColor: Colors.red, colorText: Colors.white);
    }, (_) {
      final updated = missions.map((m) {
        if (m.id == mission.id) {
          return MissionsModel(
            id: m.id,
            title: m.title,
            description: m.description,
            category: m.category,
            budget: m.budget,
            deadline: m.deadline,
            status: Status.failed,
            employerId: m.employerId,
            chosenProposalId: m.chosenProposalId,
          );
        }
        return m;
      }).toList();
      missions.assignAll(updated);
      Get.snackbar(LocaleKeys.missions_page_reject_done_title.tr,
          LocaleKeys.missions_page_reject_done_message.tr,
          backgroundColor: Colors.orange, colorText: Colors.white);
    });

    processingMissionIds.remove(mission.id);
  }

  Future<void> deleteMission({required MissionsModel mission}) async {
    if (!mission.status.isOpen) return;

    if (processingMissionIds.contains(mission.id)) return;

    final confirm = await Get.dialog<bool>(AlertDialog(
      title: Text(LocaleKeys.missions_page_delete_confirm_title.tr),
      content: Text(LocaleKeys.missions_page_delete_confirm_content.tr),
      actions: [
        TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(LocaleKeys.missions_page_confirm_no.tr)),
        ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: Text(LocaleKeys.missions_page_confirm_yes.tr)),
      ],
    ));

    if (confirm != true) return;

    processingMissionIds.add(mission.id);
    Get.dialog(const Center(child: CircularProgressIndicator()),
        barrierDismissible: false);
    final res = await _repository.deleteMission(missionId: mission.id);
    Get.back();

    res.fold((err) {
      Get.snackbar(LocaleKeys.common_error.tr, err,
          backgroundColor: Colors.red, colorText: Colors.white);
    }, (_) {
      missions.removeWhere((m) => m.id == mission.id);
      Get.snackbar(LocaleKeys.missions_page_delete_success.tr,
          LocaleKeys.missions_page_delete_success.tr,
          backgroundColor: Colors.green, colorText: Colors.white);
    });

    processingMissionIds.remove(mission.id);
  }

  void showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(LocaleKeys.event_page_logout.tr),
          content: Text(LocaleKeys.event_page_logout_validate.tr),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(LocaleKeys.event_page_logout_no.tr),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                logout();
              },
              child: Text(LocaleKeys.event_page_logout_yes.tr),
            ),
          ],
        );
      },
    );
  }

  Future<void> logout() async {
    await Get.offAllNamed(RouteNames.login);
  }

  void onChangeLanguage() async {
    isLoading.value = true;

    final storage = GetStorage();
    String currentLocale =
        storage.read(LocalStorageKeys.languageLocale) ?? 'en';
    String newLocale = currentLocale == 'en' ? 'fa' : 'en';
    await storage.write(LocalStorageKeys.languageLocale, newLocale);
    Get.updateLocale(Locale(newLocale));
    isLoading.value = false;
    final primary = Get.theme.colorScheme.primary;
    Get.snackbar(
      LocaleKeys.missions_page_language_changed_title.tr,
      newLocale == 'fa'
          ? LocaleKeys.missions_page_language_changed_to_fa.tr
          : LocaleKeys.missions_page_language_changed_to_en.tr,
      backgroundColor: primary.withValues(alpha: 0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> submitBid({
    required String missionId,
    required MissionsModel mission,
  }) async {
    final check =
        await _repository.hasProposal(missionId: missionId, hunterId: userId);
    bool already = false;
    final existsError = <String?>[null];
    check.fold((err) {
      existsError[0] = err;
    }, (res) {
      already = res;
    });

    if (existsError[0] != null) {
      showDialog(
        context: Get.context!,
        builder: (ctx) => AlertDialog(
          title: Text(LocaleKeys.common_error.tr),
          content: Text(existsError[0]!),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(LocaleKeys.common_ok.tr))
          ],
        ),
      );
      return;
    }

    if (already) {
      showDialog(
        context: Get.context!,
        builder: (ctx) => AlertDialog(
          title: Text(LocaleKeys.missions_page_bid_already_title.tr),
          content: Text(LocaleKeys.missions_page_bid_already_message.tr),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(LocaleKeys.common_ok.tr))
          ],
        ),
      );
      return;
    }

    final priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(LocaleKeys.missions_page_bid_dialog_title.tr,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(mission.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(Get.context!).textTheme.bodyMedium?.color)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Form(
              key: formKey,
              child: TextFormField(
                controller: priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: false),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  ThousandsSeparatorInputFormatter(locale: 'en_US')
                ],
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: LocaleKeys.missions_page_bid_price_label.tr,
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return LocaleKeys.missions_page_bid_price_required.tr;
                  final digits = value.replaceAll(',', '');
                  if (int.tryParse(digits) == null)
                    return LocaleKeys.missions_page_bid_price_invalid.tr;
                  if (int.parse(digits) <= 0)
                    return LocaleKeys.missions_page_bid_price_positive.tr;
                  return null;
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(LocaleKeys.missions_page_budget_label.tr + ':',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              Text(formatCurrency(mission.budget),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 6),
            Text(LocaleKeys.missions_page_bid_explain.tr,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(), child: Text(LocaleKeys.common_cancel.tr)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              Get.dialog(const Center(child: CircularProgressIndicator()),
                  barrierDismissible: false);

              final price = int.parse(priceController.text.replaceAll(',', ''));
              final proposalDto = CreateProposalDto(
                  missionId: missionId, hunterId: userId, proposedPrice: price);

              isLoading.value = true;
              final result =
                  await _repository.createProposal(proposalDto: proposalDto);
              isLoading.value = false;

              Get.back();

              result.fold((error) {
                showDialog(
                    context: Get.context!,
                    builder: (ctx) => AlertDialog(
                            title: Text(LocaleKeys.common_error.tr),
                            content: Text(error),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: Text(LocaleKeys.common_ok.tr))
                            ]));
              }, (newProposal) {
                Get.back();
                showDialog(
                    context: Get.context!,
                    builder: (ctx) => AlertDialog(
                            title: Text(LocaleKeys.missions_page_bid_sent_title.tr),
                            content: Text(LocaleKeys.missions_page_bid_sent_message.tr),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: Text(LocaleKeys.common_ok.tr))
                            ]));
                fetchMissions();
              });
            },
            child: Text(LocaleKeys.missions_page_bid_submit_label.tr),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> toggleTheme() async {
    final newMode =
        themeMode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    themeMode.value = newMode;
    await ThemeService.setThemeMode(newMode);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        Get.changeThemeMode(newMode);

        Get.changeTheme(newMode == ThemeMode.dark
            ? ThemeService.darkTheme()
            : ThemeService.lightTheme());
      } catch (e) {}
    });
  }

  Future<void> loadGlobalBudgetRange() async {
    try {
      final res = await _repository.getBudgetRange();
      res.fold((err) {}, (map) {
        final min = map['min'] ?? 0;
        final max = map['max'] ?? 0;
        globalMinBudget.value = min;
        globalMaxBudget.value = max <= min ? min + 1 : max;
      });
    } catch (_) {}
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
