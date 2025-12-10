// lib/presentation/screens/hunter_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;

import '../../../infrastructure/commons/status.dart';
import '../../../../generated/locales.g.dart';
import '../controller/hunter_profile_controller.dart';
import '../models/view_models/proposal_profile_model.dart';


class HunterProfileScreen extends GetView<HunterProfileController> {
  const HunterProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('پروفایل شکارچی', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: GetX<HunterProfileController>(builder: (ctrl) {
        if (ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: ctrl.loadHunterProposals,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------- Filter tags (ChoiceChips) bound to controller ----------
                // outer Obx removed — inner chips already use Obx to react to controller changes
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChipBound('all', LocaleKeys.profile_page_filter_all.tr, Colors.grey.shade700),
                    _buildFilterChipBound('active', LocaleKeys.profile_page_filter_active.tr, Colors.blue.shade700),
                    _buildFilterChipBound('awaiting', LocaleKeys.profile_page_filter_awaiting.tr, Colors.orange.shade700),
                    _buildFilterChipBound('failed', LocaleKeys.profile_page_filter_failed.tr, Colors.red.shade700),
                    _buildFilterChipBound('confirmed', LocaleKeys.profile_page_filter_confirmed.tr, Colors.green.shade700),
                    _buildFilterChipBound('history', LocaleKeys.profile_page_filter_history.tr, Colors.grey.shade600),
                  ],
                ),

                const SizedBox(height: 12),

                // Show either all sections or only the selected filter section
                Builder(builder: (_) {
                  final key = controller.selectedFilter.value;
                  if (key == 'all') {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader('🎯 ${LocaleKeys.profile_page_filter_active.tr} (${controller.activeMissions.length})', Colors.blue.shade700),
                        const SizedBox(height: 10),
                        controller.activeMissions.isEmpty
                            ? _buildEmptyState(LocaleKeys.profile_page_no_active_missions.tr)
                            : _buildMissionList(controller.activeMissions, isHistory: false),

                        const SizedBox(height: 20),
                        _buildHeader('⏳ ${LocaleKeys.profile_page_filter_awaiting.tr} (${controller.awaitingApprovalCombined.length})', Colors.orange.shade700),
                        const SizedBox(height: 10),
                        controller.awaitingApprovalCombined.isEmpty
                            ? _buildEmptyState(LocaleKeys.profile_page_no_awaiting.tr)
                            : _buildMissionList(controller.awaitingApprovalCombined, isHistory: true),

                        const SizedBox(height: 20),
                        _buildHeader('❌ ${LocaleKeys.profile_page_filter_failed.tr} (${controller.failedRequestsCombined.length})', Colors.red.shade700),
                        const SizedBox(height: 10),
                        controller.failedRequestsCombined.isEmpty
                            ? _buildEmptyState(LocaleKeys.profile_page_no_failed.tr)
                            : _buildMissionList(controller.failedRequestsCombined, isHistory: false),

                        const SizedBox(height: 20),
                        _buildHeader('✅ ${LocaleKeys.profile_page_filter_confirmed.tr} (${controller.confirmedRequests.length})', Colors.green.shade700),
                        const SizedBox(height: 10),
                        controller.confirmedRequests.isEmpty
                            ? _buildEmptyState(LocaleKeys.profile_page_no_confirmed.tr)
                            : _buildMissionList(controller.confirmedRequests, isHistory: true),

                        const Divider(height: 40),

                        _buildHeader('📜 ${LocaleKeys.profile_page_filter_history.tr} (${controller.historyProposals.length})', Colors.grey.shade700),
                        const SizedBox(height: 10),
                        controller.historyProposals.isEmpty
                            ? _buildEmptyState(LocaleKeys.profile_page_no_history.tr)
                            : _buildMissionList(controller.historyProposals, isHistory: true),
                      ],
                    );
                  }

                  // single-section mode
                  switch (key) {
                    case 'active':
                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _buildHeader('🎯 ${LocaleKeys.profile_page_filter_active.tr} (${controller.activeMissions.length})', Colors.blue.shade700),
                        const SizedBox(height: 10),
                        controller.activeMissions.isEmpty ? _buildEmptyState(LocaleKeys.profile_page_no_active_missions.tr) : _buildMissionList(controller.activeMissions, isHistory: false),
                      ]);
                    case 'awaiting':
                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _buildHeader('⏳ ${LocaleKeys.profile_page_filter_awaiting.tr} (${controller.awaitingApprovalCombined.length})', Colors.orange.shade700),
                        const SizedBox(height: 10),
                        controller.awaitingApprovalCombined.isEmpty ? _buildEmptyState(LocaleKeys.profile_page_no_awaiting.tr) : _buildMissionList(controller.awaitingApprovalCombined, isHistory: true),
                      ]);
                    case 'failed':
                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _buildHeader('❌ ${LocaleKeys.profile_page_filter_failed.tr} (${controller.failedRequestsCombined.length})', Colors.red.shade700),
                        const SizedBox(height: 10),
                        controller.failedRequestsCombined.isEmpty ? _buildEmptyState(LocaleKeys.profile_page_no_failed.tr) : _buildMissionList(controller.failedRequestsCombined, isHistory: false),
                      ]);
                    case 'confirmed':
                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _buildHeader('✅ ${LocaleKeys.profile_page_filter_confirmed.tr} (${controller.confirmedRequests.length})', Colors.green.shade700),
                        const SizedBox(height: 10),
                        controller.confirmedRequests.isEmpty ? _buildEmptyState(LocaleKeys.profile_page_no_confirmed.tr) : _buildMissionList(controller.confirmedRequests, isHistory: true),
                      ]);
                    case 'history':
                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _buildHeader('📜 ${LocaleKeys.profile_page_filter_history.tr} (${controller.historyProposals.length})', Colors.grey.shade700),
                        const SizedBox(height: 10),
                        controller.historyProposals.isEmpty ? _buildEmptyState(LocaleKeys.profile_page_no_history.tr) : _buildMissionList(controller.historyProposals, isHistory: true),
                      ]);
                    default:
                      return const SizedBox.shrink();
                  }
                }),
              ],
            ),
          ),
        );
      }),
    );
  }

  // helper to build a single filter chip bound to controller.selectedFilter
  Widget _buildFilterChipBound(String key, String label, Color color) {
    return Obx(() => ChoiceChip(
          label: Text(label, style: TextStyle(color: controller.selectedFilter.value == key ? Colors.white : Colors.black)),
          selected: controller.selectedFilter.value == key,
          onSelected: (v) {
            if (v) {
              controller.applyFilterKey(key);
            }
          },
          backgroundColor: color.withAlpha((0.12 * 255).round()),
          selectedColor: color,
        ));
  }

  // ویجت هدر بخش‌ها
  Widget _buildHeader(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  // ویجت لیست پیشنهادات
  Widget _buildMissionList(List<ProposalProfileModel> proposals, {required bool isHistory}) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: proposals.length,
      itemBuilder: (context, index) {
        final proposal = proposals[index];
        // Use embedded mission title (repository now enriches proposals when possible).
        final missionTitle = proposal.mission?.title ?? 'عنوان نامشخص';

        return _buildProposalItem(proposal, missionTitle, isHistory);
      },
    );
  }

  // ویجت آیتم پیشنهادات
  Widget _buildProposalItem(ProposalProfileModel proposal, String title, bool isHistory) {
    // 💡 نمایش عنوان بر اساس وضعیت isCompleted
    String statusText;
    Color statusColor;
    // Prefer mission.status for clear UI if available
    final missionStatus = proposal.mission?.status;
    final isFailed = missionStatus == Status.failed;
    if (missionStatus != null) {
      if (missionStatus == Status.failed) {
        statusText = LocaleKeys.profile_page_status_failed.tr;
        statusColor = Colors.red;
      } else if (missionStatus == Status.pendingApproval) {
        statusText = LocaleKeys.profile_page_status_pending_approval.tr;
        statusColor = Colors.orange;
      } else if (missionStatus == Status.inProgress) {
        statusText = LocaleKeys.profile_page_status_in_progress.tr;
        statusColor = Colors.green;
      } else if (missionStatus == Status.completed) {
        statusText = LocaleKeys.profile_page_status_completed.tr;
        statusColor = Colors.blue;
      } else {
        // fall back to proposal flags
        if (proposal.isCompleted) {
          statusText = LocaleKeys.profile_page_status_pending_approval.tr;
          statusColor = Colors.orange;
        } else if (proposal.isAccepted && !isHistory) {
          statusText = LocaleKeys.profile_page_status_in_progress.tr;
          statusColor = Colors.green;
        } else {
          statusText = LocaleKeys.profile_page_status_rejected_or_pending.tr;
          statusColor = Colors.grey;
        }
      }
    } else {
      if (proposal.isCompleted) {
        statusText = LocaleKeys.profile_page_status_pending_approval.tr;
        statusColor = Colors.orange;
      } else if (proposal.isAccepted && !isHistory) {
        statusText = LocaleKeys.profile_page_status_in_progress.tr;
        statusColor = Colors.green;
      } else {
        statusText = LocaleKeys.profile_page_status_rejected_or_pending.tr;
        statusColor = Colors.grey;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('قیمت پیشنهادی: ${intl.NumberFormat('#,###').format(proposal.proposedPrice)} تومان'),
            Text('ارسال: ${intl.DateFormat('yyyy/MM/dd').format(proposal.createdAt)}'),
            const SizedBox(height: 4),
            Text(
              statusText,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        trailing: (isHistory || proposal.isCompleted || isFailed)
            ? null // برای تاریخچه یا ماموریت‌های منتظر تأیید، دکمه‌ای نیست
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // If proposal is not accepted, allow edit & delete
            if (!proposal.isAccepted) ...[
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.orange),
                tooltip: 'ویرایش پیشنهاد',
                onPressed: () => _showEditProposalDialog(proposal),
              ),
              IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                tooltip: 'حذف پیشنهاد',
                onPressed: () => _showDeleteProposalDialog(proposal),
              ),
            ],

            ElevatedButton(
              onPressed: () => _showCompletionDialog(proposal), // 🎯 فراخوانی دیالوگ
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: const Text('اعلام موفقیت'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _showFailureDialog(proposal),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('اعلام شکست'),
            ),
          ],
        ),
      ),
    );
  }

  // ویجت حالت خالی
  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Text(
          message,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _showCompletionDialog(ProposalProfileModel proposal) {
    Get.dialog(
      AlertDialog(
        title: const Text('اعلام موفقیت ماموریت', textAlign: TextAlign.center),
        content: Text(
          'آیا مطمئن هستید که ماموریت "${proposal.mission?.title ?? 'نامعلوم'}" با موفقیت تکمیل شده است؟\n\nپس از تأیید، درخواست برای کارفرما ارسال می‌شود.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('انصراف')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.requestCompletion(proposal); // 🎯 فراخوانی Controller
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('بله، اعلام موفقیت'),
          ),
        ],
      ),
    );
  }

  void _showFailureDialog(ProposalProfileModel proposal) {
    Get.dialog(
      AlertDialog(
        title: const Text('اعلام شکست ماموریت', textAlign: TextAlign.center),
        content: Text(
          'آیا مطمئن هستید که ماموریت "${proposal.mission?.title ?? 'نامعلوم'}" شکست خورده است و باید به کارفرما اعلام شود؟\n\nپس از تأیید کارفرما وضعیت ماموریت به "شکست خورده" تغییر خواهد کرد.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('انصراف')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.requestFailure(proposal);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('بله، اعلام شکست'),
          ),
        ],
      ),
    );
  }

  void _showEditProposalDialog(ProposalProfileModel proposal) {
    final priceCtrl = TextEditingController(text: proposal.proposedPrice.toString());
    final formKey = GlobalKey<FormState>();

    Get.dialog(AlertDialog(
      title: const Text('ویرایش قیمت پیشنهاد', textAlign: TextAlign.center),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: priceCtrl,
          keyboardType: TextInputType.number,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.attach_money), labelText: 'قیمت (تومان)'),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'قیمت را وارد کنید';
            final n = int.tryParse(v.replaceAll(',', ''));
            if (n == null || n <= 0) return 'قیمت معتبر نیست';
            return null;
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('انصراف')),
        ElevatedButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            final newPrice = int.parse(priceCtrl.text.replaceAll(',', ''));
            Get.back();
            await controller.editProposal(proposalId: proposal.id, newPrice: newPrice);
          },
          child: const Text('ذخیره'),
        )
      ],
    ));
  }

  void _showDeleteProposalDialog(ProposalProfileModel proposal) {
    Get.dialog(AlertDialog(
      title: const Text('حذف پیشنهاد', textAlign: TextAlign.center),
      content: const Text('آیا از حذف این پیشنهاد اطمینان دارید؟'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('انصراف')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () async {
            Get.back();
            await controller.deleteProposal(proposalId: proposal.id);
          },
          child: const Text('حذف'),
        ),
      ],
    ));
  }
}