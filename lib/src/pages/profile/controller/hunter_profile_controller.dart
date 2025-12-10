import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../infrastructure/commons/status.dart';
import '../../missions/edit_mission/models/mission_model.dart' as edit_mission_model;
import '../models/dto/update_proposal_dto.dart';
import '../models/view_models/proposal_profile_model.dart';
import '../repository/hunter_proposal_repository.dart';

class HunterProfileController extends GetxController {
  final String hunterId;

  HunterProfileController({required this.hunterId});

  final HunterProposalRepository _repository = HunterProposalRepository();

  var isLoading = false.obs;
  var proposals = <ProposalProfileModel>[].obs;
  // Locally tracked proposal states to keep UI consistent until server reflects changes
  final RxSet<String> _locallyPendingApproval = <String>{}.obs; // proposal ids marked as pending by hunter
  final RxSet<String> _locallyFailedProposals = <String>{}.obs; // proposal ids marked as failure by hunter
  // cached categorized lists to ensure mutual exclusivity (recomputed on proposals changes)
  List<ProposalProfileModel> _cachedConfirmed = [];
  List<ProposalProfileModel> _cachedFailed = [];
  List<ProposalProfileModel> _cachedAwaiting = [];
  List<ProposalProfileModel> _cachedActive = [];
  List<ProposalProfileModel> _cachedHistory = [];
  // currently selected filter key (stored in controller so it survives widget rebuilds)
  final RxString selectedFilter = 'all'.obs;

  // Return plain Lists computed from the reactive `proposals` list.
  // We compute mutually-exclusive lists by priority to avoid duplicates across sections:
  // priority: confirmed -> failed -> awaiting -> active -> history
  // Expose cached lists (read-only) to the view
  List<ProposalProfileModel> get confirmedRequests => List.unmodifiable(_cachedConfirmed);
  List<ProposalProfileModel> get failedRequestsCombined => List.unmodifiable(_cachedFailed);
  List<ProposalProfileModel> get awaitingApprovalCombined => List.unmodifiable(_cachedAwaiting);
  List<ProposalProfileModel> get activeMissions => List.unmodifiable(_cachedActive);
  List<ProposalProfileModel> get historyProposals => List.unmodifiable(_cachedHistory);

  @override
  void onInit() {
    super.onInit();
    loadHunterProposals();
    // recompute categories whenever proposals change
    ever(proposals, (_) => _recomputeCategories());
  }

  /// Apply a named filter key from the UI (ChoiceChips) and fetch appropriate proposals.
  Future<void> applyFilterKey(String key) async {
    selectedFilter.value = key;
    switch (key) {
      case 'active':
        await loadHunterProposalsFiltered(isAccepted: true, isCompleted: false);
        break;
      case 'awaiting':
        // fetch all and rely on controller's awaitingApprovalCombined to select pending approvals
        await loadHunterProposals();
        break;
      case 'failed':
        // fetch all and let the view use failedRequests getter to display only failed items
        await loadHunterProposals();
        break;
      case 'confirmed':
        await loadHunterProposalsFiltered(isAccepted: true, isCompleted: true);
        break;
      case 'history':
        await loadHunterProposals();
        break;
      case 'all':
      default:
        await loadHunterProposals();
        break;
    }
  }

  /// Load proposals with optional server-side filter flags.
  Future<void> loadHunterProposalsFiltered({bool? isAccepted, bool? isCompleted}) async {
    isLoading(true);
    final result = await _repository.getAllHunterProposals(
      hunterId: hunterId,
      isAccepted: isAccepted,
      isCompleted: isCompleted,
    );

    result.fold(
      (error) {
        Get.snackbar('خطا', error, backgroundColor: Colors.red, colorText: Colors.white);
      },
      (fetchedProposals) {
        // assign and normalize statuses locally
        var normalized = _normalizeProposals(fetchedProposals);
        // reconcile and clear local overlays where server already applied the change
        _reconcileLocalFlags(normalized);
        // overlay remaining local state (if user recently marked completion/failure but server not updated yet)
        normalized = _applyLocalFlags(normalized);
        proposals.assignAll(normalized);
        // persist any needed status changes (accepted proposals whose deadline passed)
        _autoFailExpiredAcceptedProposals(normalized);
      },
    );

    isLoading(false);
  }

  Future<void> loadHunterProposals() async {
    isLoading(true);
    final result = await _repository.getAllHunterProposals(hunterId: hunterId);

    result.fold(
      (error) {
        Get.snackbar('خطا', error, backgroundColor: Colors.red, colorText: Colors.white);
      },
      (fetchedProposals) {
        var normalized = _normalizeProposals(fetchedProposals);
        _reconcileLocalFlags(normalized);
        normalized = _applyLocalFlags(normalized);
        proposals.assignAll(normalized);
        // ensure server reflects expired accepted proposals
        _autoFailExpiredAcceptedProposals(normalized);
      },
    );

    isLoading(false);
  }

  /// Normalize proposals after loading: if a proposal is accepted and its mission deadline passed,
  /// mark the mission status as failed locally so the UI reflects a failed request.
  List<ProposalProfileModel> _normalizeProposals(List<ProposalProfileModel> list) {
    final now = DateTime.now();
    return list.map((p) {
      // If server already marked this mission as pending approval, treat proposal as completed locally
      try {
        if (p.mission != null && p.mission!.status == Status.pendingApproval) {
          try {
            Get.log('[HunterProfileController] Normalizing: proposal ${p.id} -> mission pendingApproval');
          } catch (_) {}
          return p.copyWith(isCompleted: true);
        }
      } catch (_) {}

      // If accepted but deadline passed, show mission as failed locally
      try {
        if (p.isAccepted && p.mission != null) {
          final m = p.mission!;
          if (m.deadline.isBefore(now) && m.status != Status.failed) {
            final updatedMission = edit_mission_model.MissionModel(
              id: m.id,
              title: m.title,
              description: m.description,
              category: m.category,
              budget: m.budget,
              deadline: m.deadline,
              status: Status.failed,
              employerId: m.employerId,
            );
            return p.copyWith(mission: updatedMission);
          }
        }
      } catch (_) {}

      return p;
    }).toList();
  }

  /// For any proposal that is accepted and whose mission deadline passed,
  /// persist mission.status = failed on server and update local list.
  Future<void> _autoFailExpiredAcceptedProposals(List<ProposalProfileModel> list) async {
    final now = DateTime.now();
    final List<String> toUpdate = [];
    for (final p in list) {
      try {
        if (p.isAccepted && p.mission != null) {
          final m = p.mission!;
          if (m.deadline.isBefore(now) && m.status != Status.failed) {
            toUpdate.add(m.id);
          }
        }
      } catch (_) {}
    }

    if (toUpdate.isEmpty) return;

    for (final missionId in toUpdate) {
      final res = await _repository.requestMissionFailure(missionId: missionId);
      res.fold((err) {
        try {
          Get.log('Failed to auto-mark mission $missionId as failed: $err');
        } catch (_) {}
      }, (_) {
        // update local proposals referencing this mission
        final updated = proposals.map((p) {
          if (p.mission != null && p.mission!.id == missionId) {
            final m = p.mission!;
            final updatedMission = edit_mission_model.MissionModel(
              id: m.id,
              title: m.title,
              description: m.description,
              category: m.category,
              budget: m.budget,
              deadline: m.deadline,
              status: Status.failed,
              employerId: m.employerId,
            );
            return p.copyWith(mission: updatedMission);
          }
          return p;
        }).toList();
        proposals.assignAll(updated);
      });
    }
  }

  // =======================================================
  // متد اعلام اتمام و موفقیت
  // =======================================================
  Future<void> requestCompletion(ProposalProfileModel proposal) async {
    if (!proposal.isAccepted || proposal.isCompleted) return;

    Get.dialog(const Center(child: CircularProgressIndicator()));

    final result = await _repository.requestMissionCompletion(
      missionId: proposal.missionId,
    );

    Get.back(); // بستن دیالوگ لودینگ

    result.fold(
      (error) {
        Get.snackbar('خطا', 'اعلام اتمام ماموریت ناموفق بود: $error', backgroundColor: Colors.red, colorText: Colors.white);
      },
      (_) async {
        // remember locally so UI hides actions immediately and across refresh
        _locallyPendingApproval.add(proposal.id);
        _updateLocalMissionStatusToPending(proposal.id);
        // refresh from server to get authoritative state, but preserve local overlays
        await loadHunterProposals();

        Get.snackbar(
          'درخواست ارسال شد',
          'درخواست اتمام ماموریت ارسال شد و در انتظار تأیید کارفرما است.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      },
    );
  }

  // ===================== اعلام شکست =====================
  Future<void> requestFailure(ProposalProfileModel proposal) async {
    // If already completed/failed/awaiting, nothing to do
    if (proposal.isCompleted || (proposal.mission?.status != null && proposal.mission!.status == Status.failed)) return;

    Get.dialog(const Center(child: CircularProgressIndicator()));

    final result = await _repository.requestMissionFailure(
      missionId: proposal.missionId,
    );

    Get.back(); // close loading

    result.fold((error) {
      Get.snackbar('خطا', 'اعلام شکست ماموریت ناموفق بود: $error', backgroundColor: Colors.red, colorText: Colors.white);
    }, (_) async {
      // remember locally
      _locallyFailedProposals.add(proposal.id);
      _updateLocalMissionStatusToFailure(proposal.id);
      // refresh from server to get authoritative state
      await loadHunterProposals();

      Get.snackbar(
        'درخواست ارسال شد',
        'درخواست اعلام شکست ماموریت ارسال شد و در انتظار تأیید کارفرما است.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    });
  }

  void _updateLocalMissionStatusToPending(String proposalId) {
    final updatedList = proposals.map((p) {
      if (p.id == proposalId) {
        if (p.mission != null) {
          final m = p.mission!;
          final updatedMission = edit_mission_model.MissionModel(
            id: m.id,
            title: m.title,
            description: m.description,
            category: m.category,
            budget: m.budget,
            deadline: m.deadline,
            status: Status.pendingApproval,
            employerId: m.employerId,
          );
          // mark proposal as completed (hunter signaled completion) so UI hides action buttons
          return p.copyWith(mission: updatedMission, isCompleted: true);
        }
      }
      return p;
    }).toList();

    proposals.assignAll(updatedList);
  }

  void _updateLocalMissionStatusToFailure(String proposalId) {
    final updatedList = proposals.map((p) {
      if (p.id == proposalId) {
        if (p.mission != null) {
          final m = p.mission!;
          final updatedMission = edit_mission_model.MissionModel(
            id: m.id,
            title: m.title,
            description: m.description,
            category: m.category,
            budget: m.budget,
            deadline: m.deadline,
            status: Status.failed,
            employerId: m.employerId,
          );
          // mark proposal as completed/handled so actions are hidden
          return p.copyWith(mission: updatedMission, isCompleted: true);
        }
      }
      return p;
    }).toList();

    proposals.assignAll(updatedList);
  }

  // ================== Edit & Delete proposals (for non-accepted proposals) ==================
  Future<void> editProposal({required String proposalId, required int newPrice}) async {
    final idx = proposals.indexWhere((p) => p.id == proposalId);
    if (idx == -1) return;
    final proposal = proposals[idx];
    if (proposal.isAccepted) return; // cannot edit an accepted proposal

    Get.dialog(const Center(child: CircularProgressIndicator()));
    final dto = UpdateProposalDto(proposedPrice: newPrice);
    final result = await _repository.updateProposal(proposalId: proposalId, dto: dto);
    Get.back();

    result.fold((err) {
      Get.snackbar('خطا', err, backgroundColor: Colors.red, colorText: Colors.white);
    }, (_) {
      final updated = proposals.map((p) {
        if (p.id == proposalId) return p.copyWith(proposedPrice: newPrice);
        return p;
      }).toList();
      proposals.assignAll(updated);
      Get.snackbar('موفقیت', 'قیمت پیشنهاد به‌روزرسانی شد', backgroundColor: Colors.green, colorText: Colors.white);
    });
  }

  Future<void> deleteProposal({required String proposalId}) async {
    final idx = proposals.indexWhere((p) => p.id == proposalId);
    if (idx == -1) return;
    final proposal = proposals[idx];
    if (proposal.isAccepted) return; // cannot delete an accepted proposal

    Get.dialog(const Center(child: CircularProgressIndicator()));
    final result = await _repository.deleteProposal(proposalId: proposalId);
    Get.back();

    result.fold((err) {
      Get.snackbar('خطا', err, backgroundColor: Colors.red, colorText: Colors.white);
    }, (_) {
      proposals.removeWhere((p) => p.id == proposalId);
      Get.snackbar('موفقیت', 'پیشنهاد حذف شد', backgroundColor: Colors.green, colorText: Colors.white);
    });
  }

  // insert helper to apply local flags
  List<ProposalProfileModel> _applyLocalFlags(List<ProposalProfileModel> list) {
    return list.map((p) {
      if (_locallyPendingApproval.contains(p.id)) {
        // ensure it's marked completed locally and mission pendingApproval
        final m = p.mission;
        final updatedMission = m != null
            ? edit_mission_model.MissionModel(id: m.id, title: m.title, description: m.description, category: m.category, budget: m.budget, deadline: m.deadline, status: Status.pendingApproval, employerId: m.employerId)
            : null;
        return p.copyWith(mission: updatedMission, isCompleted: true);
      }
      if (_locallyFailedProposals.contains(p.id)) {
        final m = p.mission;
        final updatedMission = m != null
            ? edit_mission_model.MissionModel(id: m.id, title: m.title, description: m.description, category: m.category, budget: m.budget, deadline: m.deadline, status: Status.failed, employerId: m.employerId)
            : null;
        return p.copyWith(mission: updatedMission, isCompleted: true);
      }
      return p;
    }).toList();
  }

  /// Remove recovered ids from local overlay sets when server state shows the change was applied.
  void _reconcileLocalFlags(List<ProposalProfileModel> list) {
    // remove pendingApproval flags if server shows p.isCompleted==true and mission.status==pendingApproval
    final pendingToRemove = <String>[];
    final failedToRemove = <String>[];
    for (final p in list) {
      try {
        if (_locallyPendingApproval.contains(p.id)) {
          if (p.mission != null) {
            final s = p.mission!.status;
            // remove local pending if server shows pendingApproval (applied) or already completed/failed
            if (s == Status.pendingApproval || s == Status.completed || s == Status.failed) {
              pendingToRemove.add(p.id);
            }
          }
        }

        if (_locallyFailedProposals.contains(p.id)) {
          if (p.mission != null && p.mission!.status == Status.failed) {
            failedToRemove.add(p.id);
          }
        }
      } catch (_) {}
    }

    if (pendingToRemove.isNotEmpty) _locallyPendingApproval.removeAll(pendingToRemove);
    if (failedToRemove.isNotEmpty) _locallyFailedProposals.removeAll(failedToRemove);
  }

  // Recompute categorized lists in a single pass to guarantee mutual exclusivity
  void _recomputeCategories() {
    final confirmed = <ProposalProfileModel>[];
    final failed = <ProposalProfileModel>[];
    final awaiting = <ProposalProfileModel>[];
    final active = <ProposalProfileModel>[];
    final history = <ProposalProfileModel>[];

    for (final p in proposals) {
      final missionStatus = p.mission?.status;

      // Debug log: show key fields before decision
      try {
        Get.log('[HunterProfileController] Categorizing proposal=${p.id} missionStatus=${missionStatus?.toString() ?? 'null'} isAccepted=${p.isAccepted} isCompleted=${p.isCompleted}');
      } catch (_) {}

      // confirmed if server says completed AND this proposal was the chosen/accepted one
      if (missionStatus != null && missionStatus == Status.completed && p.isAccepted) {
        try {
          Get.log('[HunterProfileController] -> confirmed: ${p.id}');
        } catch (_) {}
        confirmed.add(p);
        continue;
      }

      // failed if server says failed or locally flagged failed
      if ((missionStatus != null && missionStatus == Status.failed) || _locallyFailedProposals.contains(p.id)) {
        try {
          Get.log('[HunterProfileController] -> failed: ${p.id}');
        } catch (_) {}
        failed.add(p);
        continue;
      }

      // awaiting if server says pendingApproval and this proposal was accepted OR locally pending
      if (((missionStatus != null && missionStatus == Status.pendingApproval) && p.isAccepted) || _locallyPendingApproval.contains(p.id)) {
        try {
          Get.log('[HunterProfileController] -> awaiting: ${p.id} (serverPending=${missionStatus == Status.pendingApproval}, localPending=${_locallyPendingApproval.contains(p.id)})');
        } catch (_) {}
        awaiting.add(p);
        continue;
      }

      // active: accepted and not completed and not in prior categories
      if (p.isAccepted && !p.isCompleted) {
        // if mission status indicates active (not failed/expired/completed/pending)
        if (missionStatus == null || !(missionStatus.isFailed || missionStatus.isExpired || missionStatus.isCompleted || missionStatus.isPendingApproval)) {
          try {
            Get.log('[HunterProfileController] -> active: ${p.id}');
          } catch (_) {}
          active.add(p);
          continue;
        }
      }

      // otherwise history
      try {
        Get.log('[HunterProfileController] -> history: ${p.id}');
      } catch (_) {}
      history.add(p);
    }

    _cachedConfirmed = confirmed;
    _cachedFailed = failed;
    _cachedAwaiting = awaiting;
    _cachedActive = active;
    _cachedHistory = history;
  }

}
