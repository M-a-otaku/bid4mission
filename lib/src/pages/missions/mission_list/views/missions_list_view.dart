import 'dart:math' as math;
import '../../../../infrastructure/commons/status.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import '../../../../../generated/locales.g.dart';
import '../../../../infrastructure/commons/role.dart';
import '../controllers/missions_list_controller.dart';

class MissionListView extends GetView<MissionListController> {
  const MissionListView({super.key});

  @override
  Widget build(BuildContext context) {
    // Use theme values inside build so changes are applied
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: _appBar(context),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
              child: CircularProgressIndicator(color: colorScheme.primary));
        }

        if (!controller.isUserLoaded.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.fetchMissions,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.searchController,
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          prefixIcon:
                              Icon(Icons.search, color: colorScheme.primary),
                          hintText: LocaleKeys.missions_page_search_hint.tr,
                          // use reactive searchQuery so Obx rebuilds when user types
                          suffixIcon: controller.searchQuery.value.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear,
                                      color: theme.iconTheme.color),
                                  onPressed: controller.clearSearch,
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: theme.inputDecorationTheme.fillColor ??
                              colorScheme.surfaceContainerLowest
                                  .withValues(alpha: 0.04),
                        ),
                        onChanged: (v) => controller.searchQuery.value = v,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon:
                          Icon(Icons.filter_list, color: theme.iconTheme.color),
                      onPressed: () => _openFilterSheet(context),
                    ),
                  ],
                ),
              ),
              // mission list area: show empty state here but keep search bar above
              Expanded(
                child: controller.missions.isEmpty
                    ? SingleChildScrollView(
                        // allow pull-to-refresh even when there are no items
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(
                              child: Text(
                            LocaleKeys.missions_page_empty.tr,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textWidthBasis: TextWidthBasis.parent,
                            style: theme.textTheme.titleMedium,
                          )),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: controller.missions.length,
                        itemBuilder: (context, index) {
                          final mission = controller.missions[index];
                          final cat = mission.category.toString().trim();

                          return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              elevation: 6,
                              color: theme.cardColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () {
                                  // Hunter should be able to open the submit-bid dialog when mission is open
                                  if (controller.roleOrDefault == Role.hunter) {
                                    if (mission.status.isOpen) {
                                      controller.submitBid(
                                          missionId: mission.id,
                                          mission: mission);
                                    } else {
                                      Get.snackbar(
                                          LocaleKeys
                                              .missions_page_mission_not_requestable_title
                                              .tr,
                                          LocaleKeys
                                              .missions_page_mission_not_requestable
                                              .tr);
                                    }
                                  } else {
                                    // Employers and others navigate to details
                                    controller.toMissionDetails(
                                        missionId: mission.id);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // leading avatar / icon
                                          Container(
                                            width: 56,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(Icons.work_outline,
                                                color:
                                                    theme.colorScheme.primary,
                                                size: 28),
                                          ),
                                          const SizedBox(width: 12),
                                          // main content
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(mission.title,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: theme.textTheme
                                                              .titleMedium
                                                              ?.copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800)),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Chip(
                                                      label: Text(
                                                          // displayStatus returns token; show localized label
                                                          ('status_${statusToString(mission.status)}')
                                                              .tr,
                                                          style: theme.textTheme
                                                              .labelSmall
                                                              ?.copyWith(
                                                                  color: mission
                                                                      .status
                                                                      .color)),
                                                      backgroundColor: mission
                                                          .status.color
                                                          .withValues(
                                                              alpha: 0.12),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(mission.description,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: theme
                                                        .textTheme.bodyMedium),
                                                const SizedBox(height: 12),
                                                Row(
                                                  children: [
                                                    if (cat.isNotEmpty)
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 10,
                                                                vertical: 6),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              theme.cardColor,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(18),
                                                          border: Border.all(
                                                              color: theme
                                                                  .dividerColor
                                                                  .withValues(
                                                                      alpha:
                                                                          0.08)),
                                                        ),
                                                        child: Row(children: [
                                                          Icon(
                                                              Icons
                                                                  .label_outline,
                                                              size: 14,
                                                              color: theme
                                                                  .iconTheme
                                                                  .color),
                                                          const SizedBox(
                                                              width: 6),
                                                          Text(cat,
                                                              style: theme
                                                                  .textTheme
                                                                  .bodySmall)
                                                        ]),
                                                      ),
                                                    const SizedBox(width: 10),
                                                    Text(
                                                        controller
                                                            .formatCurrency(
                                                                mission.budget),
                                                        style: theme
                                                            .textTheme.bodySmall
                                                            ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700)),
                                                    const Spacer(),
                                                    Row(children: [
                                                      Icon(Icons.calendar_today,
                                                          size: 14,
                                                          color: theme
                                                              .iconTheme.color),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                          mission.deadline
                                                              .toString()
                                                              .substring(0, 10),
                                                          style: theme.textTheme
                                                              .bodySmall)
                                                    ]),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // edit icon stays in the top-right as a quick action
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (controller.roleOrDefault ==
                                                      Role.employer &&
                                                  mission.employerId ==
                                                      controller.userId &&
                                                  mission.status.isOpen)
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(Icons.edit,
                                                          color: colorScheme
                                                              .tertiary),
                                                      onPressed: () =>
                                                          controller
                                                              .toEditMission(
                                                                  missionId:
                                                                      mission
                                                                          .id),
                                                    ),
                                                    // delete action
                                                    Obx(() {
                                                      final processing = controller
                                                          .processingMissionIds
                                                          .contains(mission.id);
                                                      return IconButton(
                                                        icon: processing
                                                            ? SizedBox(
                                                                width: 20,
                                                                height: 20,
                                                                child: CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2))
                                                            : Icon(
                                                                Icons
                                                                    .delete_outline,
                                                                color: Colors
                                                                    .redAccent),
                                                        onPressed: processing
                                                            ? null
                                                            : () => controller
                                                                .deleteMission(
                                                                    mission:
                                                                        mission),
                                                      );
                                                    }),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      // Prominent confirm/reject button bar for pendingApproval
                                      if (controller.roleOrDefault ==
                                              Role.employer &&
                                          mission.employerId ==
                                              controller.userId &&
                                          mission.status.isPendingApproval)
                                        Obx(() {
                                          final processing = controller
                                              .processingMissionIds
                                              .contains(mission.id);
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(top: 10),
                                            child: processing
                                                ? Center(
                                                    child: SizedBox(
                                                      height: 34,
                                                      width: 34,
                                                      child:
                                                          CircularProgressIndicator(
                                                              strokeWidth: 2),
                                                    ),
                                                  )
                                                : Row(
                                                    children: [
                                                      Expanded(
                                                        child:
                                                            ElevatedButton.icon(
                                                          onPressed: () {
                                                            showDialog(
                                                              context: context,
                                                              builder: (ctx) =>
                                                                  AlertDialog(
                                                                title: Text(
                                                                    LocaleKeys
                                                                        .missions_page_confirm_complete_title
                                                                        .tr),
                                                                content: Text(
                                                                    LocaleKeys
                                                                        .missions_page_confirm_complete_content
                                                                        .trParams({
                                                                  'title':
                                                                      mission
                                                                          .title
                                                                })),
                                                                actions: [
                                                                  TextButton(
                                                                      onPressed: () =>
                                                                          Navigator.of(ctx)
                                                                              .pop(),
                                                                      child: Text(LocaleKeys
                                                                          .missions_page_confirm_no
                                                                          .tr)),
                                                                  ElevatedButton(
                                                                    onPressed:
                                                                        () {
                                                                      Navigator.of(
                                                                              ctx)
                                                                          .pop();
                                                                      controller.confirmMissionCompletion(
                                                                          mission:
                                                                              mission);
                                                                    },
                                                                    style: ElevatedButton.styleFrom(
                                                                        backgroundColor:
                                                                            Colors
                                                                                .green,
                                                                        foregroundColor:
                                                                            Colors.white),
                                                                    child: Text(
                                                                        LocaleKeys
                                                                            .missions_page_confirm_yes
                                                                            .tr),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          },
                                                          icon: const Icon(Icons
                                                              .check_circle),
                                                          label: Text(LocaleKeys
                                                              .missions_page_confirm_yes
                                                              .tr),
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                Colors.green,
                                                            foregroundColor:
                                                                Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child:
                                                            ElevatedButton.icon(
                                                          onPressed: () {
                                                            showDialog(
                                                              context: context,
                                                              builder: (ctx) =>
                                                                  AlertDialog(
                                                                title: Text(
                                                                    LocaleKeys
                                                                        .missions_page_reject_title
                                                                        .tr),
                                                                content: Text(
                                                                    LocaleKeys
                                                                        .missions_page_reject_content
                                                                        .trParams({
                                                                  'title':
                                                                      mission
                                                                          .title
                                                                })),
                                                                actions: [
                                                                  TextButton(
                                                                      onPressed: () =>
                                                                          Navigator.of(ctx)
                                                                              .pop(),
                                                                      child: Text(LocaleKeys
                                                                          .missions_page_confirm_no
                                                                          .tr)),
                                                                  ElevatedButton(
                                                                    onPressed:
                                                                        () {
                                                                      Navigator.of(
                                                                              ctx)
                                                                          .pop();
                                                                      controller.rejectMission(
                                                                          mission:
                                                                              mission);
                                                                    },
                                                                    style: ElevatedButton.styleFrom(
                                                                        backgroundColor:
                                                                            Colors
                                                                                .redAccent,
                                                                        foregroundColor:
                                                                            Colors.white),
                                                                    child: Text(
                                                                        LocaleKeys
                                                                            .missions_page_reject_yes
                                                                            .tr),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          },
                                                          icon: const Icon(
                                                              Icons.cancel),
                                                          label: Text(LocaleKeys
                                                              .missions_page_reject_yes
                                                              .tr),
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                Colors
                                                                    .redAccent,
                                                            foregroundColor:
                                                                Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                          );
                                        }),
                                    ],
                                  ),
                                ),
                              ));
                        },
                      ),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: Obx(() {
        // keep reactive reads so this Obx updates when user/role/theme change
        final _loaded = controller.isUserLoaded.value;
        final role = controller.roleOrDefault;
        // read themeMode to ensure rebuild when controller toggles theme (optional)
        final _ = controller.themeMode.value;

        return (_loaded && role == Role.employer)
            ? FloatingActionButton.extended(
                onPressed: controller.toAddMission,
                icon: const Icon(Icons.add_task),
                label: Text(LocaleKeys.missions_page_new_mission.tr,
                    style: theme.textTheme.labelLarge),
              )
            : const SizedBox.shrink();
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  AppBar _appBar(BuildContext context) {
    final appBarTheme = Theme.of(context).appBarTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = appBarTheme.backgroundColor ?? colorScheme.primary;
    final fgColor = appBarTheme.foregroundColor ?? colorScheme.onPrimary;
    final iconColor = appBarTheme.iconTheme?.color ?? fgColor;
    final titleStyle = appBarTheme.titleTextStyle ??
        TextStyle(color: fgColor, fontSize: 20, fontWeight: FontWeight.bold);

    return AppBar(
      backgroundColor: bgColor,
      centerTitle: true,
      title: Text(
        LocaleKeys.missions_page_missions_list_title.tr,
        style: titleStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        textAlign: TextAlign.center,
      ),
      leading: IconButton(
        icon: const Icon(Icons.logout),
        hoverColor: const Color.fromRGBO(107, 91, 60, 0.3),
        tooltip: LocaleKeys.event_page_logout_press.tr,
        color: iconColor,
        onPressed: () => controller.showLogoutDialog(context),
      ),
      actions: [
        Obx(() {
          // build actions reactively so role & theme changes update UI immediately
          final List<Widget> acts = [];
          acts.add(IconButton(
            icon: Icon(
              Icons.language_outlined,
              color: iconColor,
              size: 24,
            ),
            hoverColor: const Color.fromRGBO(107, 91, 60, 0.3),
            tooltip: LocaleKeys.event_page_change_language.tr,
            onPressed: controller.onChangeLanguage,
          ));

          acts.add(IconButton(
            icon: Icon(
              controller.themeMode.value == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
              color: iconColor,
              size: 24,
            ),
            hoverColor: const Color.fromRGBO(107, 91, 60, 0.3),
            tooltip: controller.themeMode.value == ThemeMode.dark
                ? 'Switch to light'
                : 'Switch to dark',
            onPressed: controller.toggleTheme,
          ));

          if (controller.roleOrDefault == Role.hunter)
            acts.add(IconButton(
              icon: Icon(
                Icons.person,
                color: iconColor,
                size: 24,
              ),
              hoverColor: const Color.fromRGBO(107, 91, 60, 0.3),
              onPressed: () =>
                  controller.toProfile(hunterId: controller.userId),
            ));

          return Row(mainAxisSize: MainAxisSize.min, children: acts);
        }),
      ],
    );
  }

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        // use global min/max budget provided by controller (fetched from server)
        final int minAvailable = controller.globalMinBudget.value;
        final int maxAvailable =
            controller.globalMaxBudget.value <= minAvailable
                ? minAvailable + 1
                : controller.globalMaxBudget.value;

        // temp local state (captured by inner StatefulBuilder so values persist)
        final tempSelectedCategories =
            Set<String>.from(controller.selectedCategories);
        final tempSelectedStatuses =
            Set<String>.from(controller.selectedStatuses);
        // budget enable toggle: whether budget filter is active
        bool tempBudgetEnabled = controller.isBudgetFilterEnabled.value;
        int tempMin = controller.minBudget?.value == null ||
                controller.minBudget!.value == 0
            ? minAvailable
            : controller.minBudget!.value;
        int tempMax = controller.maxBudget?.value == null ||
                controller.maxBudget!.value == 0
            ? maxAvailable
            : controller.maxBudget!.value;
        String tempSort = controller.sortByDate.value;

        // Normalize
        tempMin = (tempMin.clamp(minAvailable, maxAvailable) as num).toInt();
        tempMax = (tempMax.clamp(minAvailable, maxAvailable) as num).toInt();
        if (tempMin > tempMax) {
          final t = tempMin;
          tempMin = tempMax;
          tempMax = t;
        }

        RangeValues tempRange =
            RangeValues(tempMin.toDouble(), tempMax.toDouble());

        return StatefulBuilder(builder: (ctx, setState) {
          return Padding(
            padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16.0,
                top: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(LocaleKeys.missions_page_filters_title.tr,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                // categories
                Obx(() {
                  if (controller.categories.isEmpty)
                    return const SizedBox.shrink();
                  final themeLocal = Theme.of(ctx);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(LocaleKeys.missions_page_categories_label.tr,
                          style: themeLocal.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: controller.categories.map((c) {
                          final selected = tempSelectedCategories.contains(c);
                          return FilterChip(
                            label: Text(
                              c,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textWidthBasis: TextWidthBasis.parent,
                              strutStyle:
                                  const StrutStyle(forceStrutHeight: true),
                            ),
                            selected: selected,
                            onSelected: (_) {
                              setState(() {
                                if (selected)
                                  tempSelectedCategories.remove(c);
                                else
                                  tempSelectedCategories.add(c);
                              });
                            },
                            selectedColor: themeLocal.colorScheme.primary,
                            backgroundColor: themeLocal.cardColor,
                            labelStyle: TextStyle(
                                color: selected
                                    ? themeLocal.colorScheme.onPrimary
                                    : themeLocal.colorScheme.onSurface),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 12),
                // budget range (RangeSlider) + enable toggle
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title:
                          Text(LocaleKeys.missions_page_apply_price_filter.tr),
                      value: tempBudgetEnabled,
                      onChanged: (v) => setState(() => tempBudgetEnabled = v),
                    ),
                    Builder(builder: (ctx) {
                      final effectiveMin =
                          math.min(minAvailable, maxAvailable).toDouble();
                      final effectiveMax =
                          math.max(minAvailable, maxAvailable).toDouble();
                      double start =
                          tempRange.start.clamp(effectiveMin, effectiveMax);
                      double end =
                          tempRange.end.clamp(effectiveMin, effectiveMax);
                      if (start > end) {
                        final t = start;
                        start = end;
                        end = t;
                      }
                      final displayedRange = RangeValues(start, end);
                      final int rawDivisionsLocal =
                          (effectiveMax - effectiveMin).round();
                      final int safeDivisions = rawDivisionsLocal <= 0
                          ? 1
                          : (rawDivisionsLocal > 1000
                              ? 1000
                              : rawDivisionsLocal);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(LocaleKeys.missions_page_price_range_label
                              .trParams({
                            'min': displayedRange.start.toInt().toString(),
                            'max': displayedRange.end.toInt().toString()
                          })),
                          RangeSlider(
                            min: effectiveMin,
                            max: effectiveMax,
                            values: displayedRange,
                            divisions: safeDivisions,
                            labels: RangeLabels(
                                '${displayedRange.start.toInt()}',
                                '${displayedRange.end.toInt()}'),
                            onChanged: tempBudgetEnabled
                                ? (r) {
                                    setState(() {
                                      final s = r.start
                                          .clamp(effectiveMin, effectiveMax);
                                      final e = r.end
                                          .clamp(effectiveMin, effectiveMax);
                                      tempRange = RangeValues(s, e);
                                    });
                                  }
                                : null,
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 12),
                // statuses
                Wrap(
                  spacing: 8,
                  children: controller.availableStatuses().map((s) {
                    final selected = tempSelectedStatuses.contains(s);
                    return FilterChip(
                      label: Text(('status_$s').tr),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          if (selected)
                            tempSelectedStatuses.remove(s);
                          else
                            tempSelectedStatuses.add(s);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // sort
                Row(
                  children: [
                    Text(LocaleKeys.missions_page_sort_label.tr),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: tempSort,
                      items: [
                        DropdownMenuItem(
                            value: 'asc',
                            child:
                                Text(LocaleKeys.missions_page_sort_oldest.tr)),
                        DropdownMenuItem(
                            value: 'desc',
                            child:
                                Text(LocaleKeys.missions_page_sort_newest.tr)),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => tempSort = v);
                      },
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Clear applied filters (left)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          controller.selectedCategories.clear();
                          controller.selectedStatuses.clear();
                          controller.isBudgetFilterEnabled.value = false;
                          controller.setBudgetRange(null, null);
                          controller.setSort('asc');
                          controller.fetchMissions();
                          Navigator.of(ctx).pop();
                        },
                        child: Text(LocaleKeys.missions_page_clear_filters.tr),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Apply button (right)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final appliedMin = tempRange.start.toInt();
                          final appliedMax = tempRange.end.toInt();
                          controller.selectedCategories
                              .assignAll(tempSelectedCategories.toList());
                          controller.selectedStatuses
                              .assignAll(tempSelectedStatuses.toList());
                          // apply budget filter only if enabled
                          controller.isBudgetFilterEnabled.value =
                              tempBudgetEnabled;
                          if (tempBudgetEnabled) {
                            controller.setBudgetRange(appliedMin, appliedMax);
                          } else {
                            controller.setBudgetRange(null, null);
                          }
                          controller.setSort(tempSort);
                          controller.fetchMissions();
                          Navigator.of(ctx).pop();
                        },
                        child: Text(LocaleKeys.missions_page_apply_filters.tr),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        });
      },
    );
  }
}
