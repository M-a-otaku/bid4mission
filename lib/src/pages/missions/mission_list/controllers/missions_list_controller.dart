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
  // track mission ids currently being processed (to disable UI actions)
  RxList<String> processingMissionIds = <String>[].obs;

  String userId = "0";
  Role? role;
  RxBool isUserLoaded = false.obs;

  // fallback when role not yet loaded
  Role get roleOrDefault => role ?? Role.hunter;

  // search & filters
  final TextEditingController searchController = TextEditingController();
  RxString searchQuery = ''.obs;
  RxList<String> searchSuggestions = <String>[].obs;

  RxList<String> categories = <String>[].obs; // loaded from server
  RxList<String> selectedCategories = <String>[].obs;

  RxInt? minBudget = RxInt(0);
  RxInt? maxBudget = RxInt(0);

  RxList<String> selectedStatuses = <String>[].obs;

  // Global budget bounds (fetched from server) used to configure the filter slider
  RxInt globalMinBudget = 0.obs;
  RxInt globalMaxBudget = 1000.obs;
  // Whether the budget filter is enabled (affects apply behavior)
  RxBool isBudgetFilterEnabled = false.obs;

  // sort: 'asc'/'desc'/null
  RxString sortByDate = RxString('asc');

  // theme
  Rx<ThemeMode> themeMode = Rx<ThemeMode>(ThemeMode.light);

  @override
  void onInit() {
    // Start loading and do async initialization to avoid performing
    // navigation or widget rebuilds during the build phase (hot reload
    // / hot restart issue).
    isLoading(true);
    _initController();
    super.onInit();
  }

  // Async initializer: loads stored user/role, sets up debounce, theme and
  // fetches initial data. This avoids calling Get.offAllNamed during the
  // synchronous build phase which caused "setState() or markNeedsBuild() called during build".
  Future<void> _initController() async {
    try {
      await _loadUserFromStorage();

      // load theme mode from storage
      themeMode.value = ThemeService.getThemeMode();
      // Defer theme change until after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          Get.changeThemeMode(themeMode.value);
        } catch (_) {}
      });

      // Do NOT force navigation to login here. Hot reload / restart will
      // re-run onInit and if storage isn't immediately available this
      // caused forced navigation. Keep the current page; navigation should
      // happen only on explicit logout or when the app determines there's
      // no authenticated user elsewhere.

      // Debounce search: only trigger when user pauses typing
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
      // load global budget range from server (used by the filter slider)
      await loadGlobalBudgetRange();
      await fetchMissions();
    } catch (e) {
      // ensure loading flag is reset on error
      isLoading.value = false;
      error.value = e.toString();
    }
  }

  Future<void> _loadUserFromStorage() async {
    // Ensure GetStorage is initialized (idempotent). This avoids race conditions
    // where storage isn't ready during hot reload/hot restart.
    await GetStorage.init();
    final storage = GetStorage();
    // Safely read values from storage and provide defaults
    final dynamic storedUserId = storage.read(LocalStorageKeys.userId);
    userId = storedUserId == null ? '0' : storedUserId.toString();

    final dynamic storedRole = storage.read(LocalStorageKeys.role);
    if (storedRole != null) {
      final raw = storedRole.toString();
      // debug log stored role value
      try { Get.log('Stored role read from GetStorage: $raw'); } catch (_) {}
      role = parseRole(raw);
    }
    // mark that we've loaded stored user/role so UI can render based on it
    isUserLoaded.value = true;
  }

  Future<void> fetchCategories() async {
    try {
      final list = await SmartCategoryService.getAllCategories();
      categories.value = list;
    } catch (_) {
      // ignore, categories optional
    }
  }

  Future<void> _loadSearchSuggestions(String query) async {
    try {
      final result = await _repository.getMissions(userId, roleToString(roleOrDefault), search: query);
      result.fold((err) => null, (data) {
        final titles = data.map((m) => m.title).toSet().toList();
        searchSuggestions.value = titles;
      });
    } catch (_) {}
  }

  Future<void> fetchMissions({bool forceRefresh = false}) async {
    isLoading.value = true;
    error.value = '';

    final String? search = searchQuery.value.trim().isEmpty ? null : searchQuery.value.trim();
    final List<String>? cats = selectedCategories.isEmpty ? null : selectedCategories.toList();
    final int? minB = (minBudget?.value ?? 0) == 0 ? null : minBudget?.value;
    final int? maxB = (maxBudget?.value ?? 0) == 0 ? null : maxBudget?.value;
    final List<String>? statuses = selectedStatuses.isEmpty ? null : selectedStatuses.toList();
    final String? sort = sortByDate.value == '' ? null : sortByDate.value;

    try {
      Get.log('Fetching missions: userId=$userId role=${roleToString(roleOrDefault)} search=$search categories=$cats minB=$minB maxB=$maxB statuses=$statuses sort=$sort');
    } catch (_) {}

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
      try { Get.log('fetchMissions error: ${error.value}'); } catch(_){ }
    } else {
      try { Get.log('fetchMissions success count=${missions.length}'); } catch(_){ }
    }

    isLoading.value = false;
  }

  void setSearch(String value) {
    searchController.text = value;
    searchController.selection = TextSelection.fromPosition(TextPosition(offset: value.length));
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

  // --------------------- View helper logic ---------------------
  // Move small helper utilities here so views remain thin.
  String fmtInt(int value) {
    final s = value.toString();
    return s.replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => ',');
  }

  String formatCurrency(dynamic b) {
    final intVal = int.tryParse(b?.toString() ?? '') ?? 0;
    return '${fmtInt(intVal)} تومان';
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

  // Employer confirms mission completed (called when status == pendingApproval)
  Future<void> confirmMissionCompletion({required MissionsModel mission}) async {
    if (!mission.status.isPendingApproval) return;

    if (processingMissionIds.contains(mission.id)) return;
    processingMissionIds.add(mission.id);
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    final result = await _repository.updateMissionStatus(missionId: mission.id, status: Status.completed);
    Get.back();

    result.fold((err) {
      Get.snackbar('خطا', err, backgroundColor: Colors.red, colorText: Colors.white);
    }, (_) {
      // update local list
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
      Get.snackbar('تأیید شد', 'وضعیت ماموریت به "تکمیل‌شده" تغییر کرد', backgroundColor: Colors.green, colorText: Colors.white);
    });
    // ensure removal from processing regardless of result
    processingMissionIds.remove(mission.id);
  }

  // Employer rejects hunter's completion request and marks mission as failed
  Future<void> rejectMission({required MissionsModel mission}) async {
    if (!mission.status.isPendingApproval) return;

    if (processingMissionIds.contains(mission.id)) return;
    processingMissionIds.add(mission.id);
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    final result = await _repository.updateMissionStatus(missionId: mission.id, status: Status.failed);
    Get.back();

    result.fold((err) {
      Get.snackbar('خطا', err, backgroundColor: Colors.red, colorText: Colors.white);
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
      Get.snackbar('انجام شد', 'ماموریت به عنوان "شکست‌خورده" علامت‌گذاری شد', backgroundColor: Colors.orange, colorText: Colors.white);
    });
    // ensure removal from processing regardless of result
    processingMissionIds.remove(mission.id);
  }

  /// Delete an open mission (only allowed for employer who owns it)
  Future<void> deleteMission({required MissionsModel mission}) async {
    // Only allow deletion of open missions
    if (!mission.status.isOpen) return;

    // prevent duplicate clicks
    if (processingMissionIds.contains(mission.id)) return;

    final confirm = await Get.dialog<bool>(AlertDialog(
      title: Text(LocaleKeys.missions_page_mission_not_requestable_title.tr),
      content: Text('آیا از حذف این ماموریت اطمینان دارید؟'),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: Text(LocaleKeys.missions_page_confirm_no.tr)),
        ElevatedButton(onPressed: () => Get.back(result: true), child: Text(LocaleKeys.missions_page_confirm_yes.tr)),
      ],
    ));

    if (confirm != true) return;

    processingMissionIds.add(mission.id);
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    final res = await _repository.deleteMission(missionId: mission.id);
    Get.back();

    res.fold((err) {
      Get.snackbar('خطا', err, backgroundColor: Colors.red, colorText: Colors.white);
    }, (_) {
      // remove mission locally
      missions.removeWhere((m) => m.id == mission.id);
      Get.snackbar('حذف شد', 'ماموریت با موفقیت حذف شد', backgroundColor: Colors.green, colorText: Colors.white);
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
        storage.read(LocalStorageKeys.languageLocale) ?? 'fa';
    String newLocale = currentLocale == 'fa' ? 'en' : 'fa';
    await storage.write(LocalStorageKeys.languageLocale, newLocale);
    Get.updateLocale(Locale(newLocale));
    isLoading.value = false;
    final primary = Get.theme.colorScheme.primary;
    Get.snackbar(
      'تغییر زبان',
      newLocale == 'fa' ? 'زبان به فارسی تغییر کرد' : 'Language changed to English',
      backgroundColor: primary.withValues(alpha: 0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> submitBid({
    required String missionId,
    required MissionsModel mission,
  }) async {
    // First, check whether this hunter already submitted a proposal for this mission
    final check = await _repository.hasProposal(missionId: missionId, hunterId: userId);
    bool already = false;
    final existsError = <String?>[null];
    check.fold((err) {
      existsError[0] = err;
    }, (res) {
      already = res;
    });

    if (existsError[0] != null) {
      // Show a simple dialog with the error and abort
      showDialog(
        context: Get.context!,
        builder: (ctx) => AlertDialog(
          title: const Text('خطا'),
          content: Text(existsError[0]!),
          actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('باشه'))],
        ),
      );
      return;
    }

    if (already) {
      // Inform user that they've already submitted a proposal
      showDialog(
        context: Get.context!,
        builder: (ctx) => AlertDialog(
          title: const Text('درخواست قبلی'),
          content: const Text('شما قبلاً برای این ماموریت درخواست ارسال کرده‌اید.'),
          actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('باشه'))],
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
            Text('ارسال درخواست برای ماموریت', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(mission.title, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Theme.of(Get.context!).textTheme.bodyMedium?.color)),
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
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsSeparatorInputFormatter(locale: 'en_US')],
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'قیمت پیشنهادی (تومان)',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'قیمت را وارد کنید';
                  final digits = value.replaceAll(',', '');
                  if (int.tryParse(digits) == null) return 'عدد معتبر نیست';
                  if (int.parse(digits) <= 0) return 'قیمت باید بیشتر از صفر باشد';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('بودجه کارفرما:', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              Text(formatCurrency(mission.budget), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 6),
            Text('قیمت پیشنهادی خود را وارد کنید و سپس ارسال را بزنید.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('انصراف')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              // show progress overlay while keeping the submit dialog open underneath
              Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

              final price = int.parse(priceController.text.replaceAll(',', ''));
              final proposalDto = CreateProposalDto(missionId: missionId, hunterId: userId, proposedPrice: price);

              isLoading.value = true;
              final result = await _repository.createProposal(proposalDto: proposalDto);
              isLoading.value = false;

              // close progress indicator
              Get.back();

              result.fold((error) {
                // show error dialog
                showDialog(context: Get.context!, builder: (ctx) => AlertDialog(title: const Text('خطا'), content: Text(error), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('باشه'))]));
              }, (newProposal) {
                // success: close submit dialog and show success confirmation
                Get.back(); // close submit dialog
                showDialog(context: Get.context!, builder: (ctx) => AlertDialog(title: const Text('موفقیت‌آمیز'), content: const Text('درخواست شما با موفقیت ارسال شد.'), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('باشه'))]));
                fetchMissions();
              });
            },
            child: const Text('ارسال درخواست'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> toggleTheme() async {
    final newMode = themeMode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    themeMode.value = newMode;
    await ThemeService.setThemeMode(newMode);
    // Ensure the app's GetMaterialApp actually applies the new ThemeData.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        Get.changeThemeMode(newMode);
        // Also force-update the ThemeData itself to avoid cases where only partial
        // theme properties update. This guarantees floatingActionButtonTheme (and others)
        // are replaced immediately.
        Get.changeTheme(newMode == ThemeMode.dark ? ThemeService.darkTheme() : ThemeService.lightTheme());
      } catch (e) {
        // ignore - we avoid crashing the app on theme change issues
      }
    });
  }

  Future<void> loadGlobalBudgetRange() async {
    try {
      final res = await _repository.getBudgetRange();
      res.fold((err) {
        // ignore silently, keep defaults
      }, (map) {
        final min = map['min'] ?? 0;
        final max = map['max'] ?? 0;
        globalMinBudget.value = min;
        globalMaxBudget.value = max <= min ? min + 1 : max;
      });
    } catch (_) {
      // ignore
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
