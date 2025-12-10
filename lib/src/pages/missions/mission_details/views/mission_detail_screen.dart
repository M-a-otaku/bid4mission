import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../../generated/locales.g.dart';

import '../controller/mission_detail_controller.dart';

import '../../../../infrastructure/commons/status.dart';
import '../models/view_models/mission_model.dart';
import '../models/view_models/proposal_model.dart';

class MissionDetailScreen extends GetView<MissionDetailController> {
  const MissionDetailScreen({super.key});

  String _formatPrice(int price) {
    final formatter = intl.NumberFormat('#,###');
    return '${formatter.format(price)} تومان';
  }

  String _formatDate(DateTime date) {
    return intl.DateFormat('yyyy/MM/dd - HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.missions_page_detail_title.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor ?? colorScheme.primary,
        foregroundColor: theme.appBarTheme.foregroundColor ?? colorScheme.onPrimary,
        elevation: 4,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colorScheme.surfaceContainerLowest.withValues(alpha: 0.04), colorScheme.surface],
          ),
        ),
        child: Obx(() {
          if (controller.isLoading.value) {
            return Center(child: CircularProgressIndicator(color: colorScheme.primary));
          }

          final mission = controller.mission.value;
          final bids = controller.proposals;
          final bool isOpen = mission.status.isOpen;
          final bool inProgress = mission.status.isInProgress;

          return RefreshIndicator(
            onRefresh: () async => controller.loadMission(),
            color: colorScheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMissionDetailCard(context, mission),
                  const SizedBox(height: 30),
                  if (inProgress)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: _buildCancelButton(context, mission.chosenProposalId),
                    ),
                  const SizedBox(height: 30),
                  _buildBidsHeader(context, bids.length),
                  const SizedBox(height: 12),
                  bids.isEmpty
                      ? _buildEmptyState(context)
                      : Column(
                          children: bids.map((bid) {
                            final isSelected = bid.isAccepted;
                            final canSelect = isOpen;
                            return _buildBidItem(context, bid, isSelected, canSelect);
                          }).toList(),
                        ),
                  const SizedBox(height: 30),
                  // ...(true
                  //     ? [
                  //         _buildSelectedHunterMessage(),
                  //       ]
                  //     : <Widget>[]),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMissionDetailCard(BuildContext context, MissionModel mission) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    mission.title,
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.secondary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: mission.status.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: mission.status.color, width: 1),
                  ),
                  child: Text(('status_${statusToString(mission.status)}').tr,
                      style: TextStyle(
                          color: mission.status.color, fontWeight: FontWeight.w600)),
                )
              ],
            ),
            const SizedBox(height: 25),
            Text(mission.description, style: TextStyle(fontSize: 16.5, height: 1.6, color: colorScheme.onSurface)),
            const Divider(height: 40, thickness: 0.5),
            _buildInfoRow(context, Icons.category_outlined, LocaleKeys.missions_page_category_label.tr, mission.category),
            _buildInfoRow(context, Icons.account_balance_wallet, LocaleKeys.missions_page_budget_label.tr, _formatPrice(mission.budget)),
            _buildInfoRow(context, Icons.calendar_today, LocaleKeys.missions_page_deadline_label.tr, _formatDate(mission.deadline)),
            _buildInfoRow(context, Icons.person, LocaleKeys.missions_page_employer_label.tr, LocaleKeys.missions_page_employer_you.tr),
          ],
        ),
      ),
    );
  }

  Widget _buildBidsHeader(BuildContext context, int count) {
    final color = Theme.of(context).colorScheme.secondary;
    return Text(LocaleKeys.missions_page_bids_received.trParams({'count': count.toString()}), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color));
  }

  Widget _buildBidItem(BuildContext context, ProposalsModel bid, bool isSelected, bool canSelect) {
    // allow empty string in the map to fallback to a friendly default
    final resolvedName =
        (controller.usernames[bid.hunterId]?.trim().isNotEmpty == true)
            ? controller.usernames[bid.hunterId]!
            : LocaleKeys.missions_page_unknown_hunter.tr;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: isSelected ? 6 : 2,
        color: isSelected ? colorScheme.surface : theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isSelected ? BorderSide(color: colorScheme.primary, width: 2) : BorderSide.none,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          leading: CircleAvatar(
            radius: 30,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(resolvedName.isNotEmpty ? resolvedName.characters.first : '?',
                style: TextStyle(color: colorScheme.onPrimaryContainer, fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          title: Text(resolvedName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.onSurface)),
          subtitle: Text(LocaleKeys.missions_page_sent_label.trParams({'date': _formatDate(bid.createdAt)}), style: TextStyle(color: theme.dividerColor)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatPrice(bid.proposedPrice), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colorScheme.secondary)),
              if (isSelected) Text(LocaleKeys.missions_page_selected_label.tr, style: TextStyle(color: colorScheme.secondary, fontSize: 12)),
            ],
          ),
          onTap: canSelect && !isSelected ? () => _showSelectDialog(context, bid) : null,
          enabled: canSelect && !isSelected,
        ),
      ),
    );
  }

  // ویجت ردیف اطلاعات
  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.primary, size: 24),
          const SizedBox(width: 16),
          Text('$label:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface)),
          const SizedBox(width: 12),
          Expanded(child: Text(value, style: TextStyle(fontSize: 16, color: colorScheme.onSurface))),
        ],
      ),
    );
  }

  void _showSelectDialog(BuildContext context, ProposalsModel bid) {
    // ensure empty strings don't propagate to UI, use fallback
    final resolvedName =
        (controller.usernames[bid.hunterId]?.trim().isNotEmpty == true)
            ? controller.usernames[bid.hunterId]!
            : LocaleKeys.missions_page_unknown_hunter.tr;
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(LocaleKeys.missions_page_select_hunter_title.tr, textAlign: TextAlign.center),
      content: Text(LocaleKeys.missions_page_select_hunter_content.trParams({'name': resolvedName, 'price': _formatPrice(bid.proposedPrice)}), textAlign: TextAlign.center),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text(LocaleKeys.missions_page_select_no.tr)),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: () {
            Get.back();
            controller.selectHunter(selectedProposal: bid, hunterName: resolvedName);
          },
          child: Obx(() => controller.isSelecting.value
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onSecondary))
              : Text(LocaleKeys.missions_page_select_yes.tr, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSecondary))),
        ),
      ],
    ));
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            Text(LocaleKeys.missions_page_no_bids_line1.tr, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(LocaleKeys.missions_page_no_bids_line2.tr, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context, String? chosenProposalId) {
    if (chosenProposalId == null || chosenProposalId.isEmpty)
      return const SizedBox.shrink();

    return Center(
      child: Obx(() => ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: controller.isSelecting.value
                ? null
                : () => _showCancelDialog(context), // 🎯 فراخوانی دیالوگ
            icon: controller.isSelecting.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.cancel_outlined),
            label: Text(
              controller.isSelecting.value
                  ? LocaleKeys.missions_page_cancelling.tr
                  : LocaleKeys.missions_page_cancel_button_label.tr,
              style: const TextStyle(fontSize: 16),
            ),
          )),
    );
  }

  void _showCancelDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(LocaleKeys.missions_page_cancel_confirm_title.tr, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
        content: Text(
          LocaleKeys.missions_page_cancel_confirm_content.tr,
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text(LocaleKeys.missions_page_cancel_confirm_no.tr)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Get.back();
              controller.cancelHunterSelection(); // 🎯 فراخوانی متد Controller
            },
            child: Text(LocaleKeys.missions_page_cancel_confirm_yes.tr, style: TextStyle(fontSize: 16, color: colorScheme.onError)),
          ),
        ],
      ),
    );
  }
}
