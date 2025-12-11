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
  
  final RxSet<String> _locallyPendingApproval = <String>{}.obs; 
  final RxSet<String> _locallyFailedProposals = <String>{}.obs; 
  
  List<ProposalProfileModel> _cachedConfirmed = [];
  List<ProposalProfileModel> _cachedFailed = [];
  List<ProposalProfileModel> _cachedAwaiting = [];
  List<ProposalProfileModel> _cachedActive = [];
  List<ProposalProfileModel> _cachedHistory = [];
  
  final RxString selectedFilter = 'all'.obs;

  
  
  
  
  List<ProposalProfileModel> get confirmedRequests => List.unmodifiable(_cachedConfirmed);
  List<ProposalProfileModel> get failedRequestsCombined => List.unmodifiable(_cachedFailed);
  List<ProposalProfileModel> get awaitingApprovalCombined => List.unmodifiable(_cachedAwaiting);
  List<ProposalProfileModel> get activeMissions => List.unmodifiable(_cachedActive);
  List<ProposalProfileModel> get historyProposals => List.unmodifiable(_cachedHistory);

  @override
  void onInit() {
    super.onInit();
    loadHunterProposals();
    
    ever(proposals, (_) => _recomputeCategories());
  }

  
  Future<void> applyFilterKey(String key) async {
    selectedFilter.value = key;
    switch (key) {
      case 'active':
        await loadHunterProposalsFiltered(isAccepted: true, isCompleted: false);
        break;
      case 'awaiting':
        
        await loadHunterProposals();
        break;
      case 'failed':
        
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

  
  Future<void> loadHunterProposalsFiltered({bool? isAccepted, bool? isCompleted}) async {
    isLoading(true);
    final result = await _repository.getAllHunterProposals(
      hunterId: hunterId,
      isAccepted: isAccepted,
      isCompleted: isCompleted,
    );

    result.fold(
      (error) {
        Get.snackbar('Ø®Ø·Ø§', error, backgroundColor: Colors.red, colorText: Colors.white);
      },
      (fetchedProposals) {
        
        var normalized = _normalizeProposals(fetchedProposals);
        
        _reconcileLocalFlags(normalized);
        
        normalized = _applyLocalFlags(normalized);
        proposals.assignAll(normalized);
        
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
        Get.snackbar('Ø®Ø·Ø§', error, backgroundColor: Colors.red, colorText: Colors.white);
      },
      (fetchedProposals) {
        var normalized = _normalizeProposals(fetchedProposals);
        _reconcileLocalFlags(normalized);
        normalized = _applyLocalFlags(normalized);
        proposals.assignAll(normalized);
        
        _autoFailExpiredAcceptedProposals(normalized);
      },
    );

    isLoading(false);
  }

  
  
  List<ProposalProfileModel> _normalizeProposals(List<ProposalProfileModel> list) {
    final now = DateTime.now();
    return list.map((p) {
      
      try {
        if (p.mission != null && p.mission!.status == Status.pendingApproval) {
          try {
            Get.log('[HunterProfileController] Normalizing: proposal ${p.id} -> mission pendingApproval');
          } catch (_) {}
          return p.copyWith(isCompleted: true);
        }
      } catch (_) {}

      
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

  
  
  
  Future<void> requestCompletion(ProposalProfileModel proposal) async {
    if (!proposal.isAccepted || proposal.isCompleted) return;

    Get.dialog(const Center(child: CircularProgressIndicator()));

    final result = await _repository.requestMissionCompletion(
      missionId: proposal.missionId,
    );

    Get.back(); 

    result.fold(
      (error) {
        Get.snackbar('Ø®Ø·Ø§', 'Ø§Ø¹Ù„Ø§Ù… Ø§ØªÙ…Ø§Ù… Ù…Ø§Ù…ÙˆØ±ÛŒØª Ù†Ø§Ù…ÙˆÙÙ‚ Ø¨ÙˆØ¯: $error', backgroundColor: Colors.red, colorText: Colors.white);
      },
      (_) async {
        
        _locallyPendingApproval.add(proposal.id);
        _updateLocalMissionStatusToPending(proposal.id);
        
        await loadHunterProposals();

        Get.snackbar(
          'Ø¯Ø±Ø®ÙˆØ§Ø³Øª Ø§Ø±Ø³Ø§Ù„ Ø´Ø¯',
          'Ø¯Ø±Ø®ÙˆØ§Ø³Øª Ø§ØªÙ…Ø§Ù… Ù…Ø§Ù…ÙˆØ±ÛŒØª Ø§Ø±Ø³Ø§Ù„ Ø´Ø¯ Ùˆ Ø¯Ø± Ø§Ù†ØªØ¸Ø§Ø± ØªØ£ÛŒÛŒØ¯ Ú©Ø§Ø±ÙØ±Ù…Ø§ Ø§Ø³Øª.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      },
    );
  }

  
  Future<void> requestFailure(ProposalProfileModel proposal) async {
    
    if (proposal.isCompleted || (proposal.mission?.status != null && proposal.mission!.status == Status.failed)) return;

    Get.dialog(const Center(child: CircularProgressIndicator()));

    final result = await _repository.requestMissionFailure(
      missionId: proposal.missionId,
    );

    Get.back(); 

    result.fold((error) {
      Get.snackbar('Ø®Ø·Ø§', 'Ø§Ø¹Ù„Ø§Ù… Ø´Ú©Ø³Øª Ù…Ø§Ù…ÙˆØ±ÛŒØª Ù†Ø§Ù…ÙˆÙÙ‚ Ø¨ÙˆØ¯: $error', backgroundColor: Colors.red, colorText: Colors.white);
    }, (_) async {
      
      _locallyFailedProposals.add(proposal.id);
      _updateLocalMissionStatusToFailure(proposal.id);
      
      await loadHunterProposals();

      Get.snackbar(
        'Ø¯Ø±Ø®ÙˆØ§Ø³Øª Ø§Ø±Ø³Ø§Ù„ Ø´Ø¯',
        'Ø¯Ø±Ø®ÙˆØ§Ø³Øª Ø§Ø¹Ù„Ø§Ù… Ø´Ú©Ø³Øª Ù…Ø§Ù…ÙˆØ±ÛŒØª Ø§Ø±Ø³Ø§Ù„ Ø´Ø¯ Ùˆ Ø¯Ø± Ø§Ù†ØªØ¸Ø§Ø± ØªØ£ÛŒÛŒØ¯ Ú©Ø§Ø±ÙØ±Ù…Ø§ Ø§Ø³Øª.',
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
          
          return p.copyWith(mission: updatedMission, isCompleted: true);
        }
      }
      return p;
    }).toList();

    proposals.assignAll(updatedList);
  }

  
  Future<void> editProposal({required String proposalId, required int newPrice}) async {
    final idx = proposals.indexWhere((p) => p.id == proposalId);
    if (idx == -1) return;
    final proposal = proposals[idx];
    if (proposal.isAccepted) return; 

    Get.dialog(const Center(child: CircularProgressIndicator()));
    final dto = UpdateProposalDto(proposedPrice: newPrice);
    final result = await _repository.updateProposal(proposalId: proposalId, dto: dto);
    Get.back();

    result.fold((err) {
      Get.snackbar('Ø®Ø·Ø§', err, backgroundColor: Colors.red, colorText: Colors.white);
    }, (_) {
      final updated = proposals.map((p) {
        if (p.id == proposalId) return p.copyWith(proposedPrice: newPrice);
        return p;
      }).toList();
      proposals.assignAll(updated);
      Get.snackbar('Ù…ÙˆÙÙ‚ÛŒØª', 'Ù‚ÛŒÙ…Øª Ù¾ÛŒØ´Ù†Ù‡Ø§Ø¯ Ø¨Ù‡â€ŒØ±ÙˆØ²Ø±Ø³Ø§Ù†ÛŒ Ø´Ø¯', backgroundColor: Colors.green, colorText: Colors.white);
    });
  }

  Future<void> deleteProposal({required String proposalId}) async {
    final idx = proposals.indexWhere((p) => p.id == proposalId);
    if (idx == -1) return;
    final proposal = proposals[idx];
    if (proposal.isAccepted) return; 

    Get.dialog(const Center(child: CircularProgressIndicator()));
    final result = await _repository.deleteProposal(proposalId: proposalId);
    Get.back();

    result.fold((err) {
      Get.snackbar('Ø®Ø·Ø§', err, backgroundColor: Colors.red, colorText: Colors.white);
    }, (_) {
      proposals.removeWhere((p) => p.id == proposalId);
      Get.snackbar('Ù…ÙˆÙÙ‚ÛŒØª', 'Ù¾ÛŒØ´Ù†Ù‡Ø§Ø¯ Ø­Ø°Ù Ø´Ø¯', backgroundColor: Colors.green, colorText: Colors.white);
    });
  }

  
  List<ProposalProfileModel> _applyLocalFlags(List<ProposalProfileModel> list) {
    return list.map((p) {
      if (_locallyPendingApproval.contains(p.id)) {
        
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

  
  void _reconcileLocalFlags(List<ProposalProfileModel> list) {
    
    final pendingToRemove = <String>[];
    final failedToRemove = <String>[];
    for (final p in list) {
      try {
        if (_locallyPendingApproval.contains(p.id)) {
          if (p.mission != null) {
            final s = p.mission!.status;
            
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

  
  void _recomputeCategories() {
    final confirmed = <ProposalProfileModel>[];
    final failed = <ProposalProfileModel>[];
    final awaiting = <ProposalProfileModel>[];
    final active = <ProposalProfileModel>[];
    final history = <ProposalProfileModel>[];

    for (final p in proposals) {
      final missionStatus = p.mission?.status;

      
      try {
        Get.log('[HunterProfileController] Categorizing proposal=${p.id} missionStatus=${missionStatus?.toString() ?? 'null'} isAccepted=${p.isAccepted} isCompleted=${p.isCompleted}');
      } catch (_) {}

      
      if (missionStatus != null && missionStatus == Status.completed && p.isAccepted) {
        try {
          Get.log('[HunterProfileController] -> confirmed: ${p.id}');
        } catch (_) {}
        confirmed.add(p);
        continue;
      }

      
      if ((missionStatus != null && missionStatus == Status.failed) || _locallyFailedProposals.contains(p.id)) {
        try {
          Get.log('[HunterProfileController] -> failed: ${p.id}');
        } catch (_) {}
        failed.add(p);
        continue;
      }

      
      if (((missionStatus != null && missionStatus == Status.pendingApproval) && p.isAccepted) || _locallyPendingApproval.contains(p.id)) {
        try {
          Get.log('[HunterProfileController] -> awaiting: ${p.id} (serverPending=${missionStatus == Status.pendingApproval}, localPending=${_locallyPendingApproval.contains(p.id)})');
        } catch (_) {}
        awaiting.add(p);
        continue;
      }

      
      if (p.isAccepted && !p.isCompleted) {
        
        if (missionStatus == null || !(missionStatus.isFailed || missionStatus.isExpired || missionStatus.isCompleted || missionStatus.isPendingApproval)) {
          try {
            Get.log('[HunterProfileController] -> active: ${p.id}');
          } catch (_) {}
          active.add(p);
          continue;
        }
      }

      
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


