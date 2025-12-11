import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';

import '../models/dto/update_mission_dto.dart';
import '../models/dto/update_proposal_dto.dart';
import '../models/view_models/mission_model.dart';
import '../models/view_models/proposal_model.dart';
import '../repository/mission_detail_repository.dart';
import '../../../../infrastructure/commons/status.dart';

class MissionDetailController extends GetxController {
  final MissionDetailRepository _repository = MissionDetailRepository();

  final String missionId;

  MissionDetailController({required this.missionId});

  var isLoading = false.obs;
  var isSelecting = false.obs;
  late Rx<MissionModel> mission;
  final proposals = <ProposalsModel>[].obs;

  
  final RxMap<String, String> usernames = <String, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadMission();
  }

  void loadMission() async {
    isLoading(true);

    final result = await _repository.getMissionById(missionId: missionId);

    result.fold(
      (error) {
        Get.snackbar('Ø®Ø·Ø§', error,
            backgroundColor: Colors.red, colorText: Colors.white);
        Get.back();
      },
      (fetchedMission) {
        mission = fetchedMission.obs;
        fetchProposals();
      },
    );

    isLoading(false);
  }

  Future<void> fetchProposals() async {
    isLoading(true);

    final result = await _repository.getBidsForMission(missionId: missionId);

    result.fold(
      (error) {
        Get.snackbar('Ø®Ø·Ø§', error,
            backgroundColor: Colors.red, colorText: Colors.white);
      },
      (fetchedBids) async {
        proposals.assignAll(fetchedBids);

        
        final hunterIds = fetchedBids
            .map((b) => b.hunterId)
            .toSet()
            .toList();

        
        final toFetch = hunterIds.where((id) => !usernames.containsKey(id)).toList();

        if (toFetch.isNotEmpty) {
          
          String fixEncoding(String input) {
            if (input.isEmpty) return '';
            
            if (RegExp(r'[ÃƒÃ‚Ã™Ã˜]').hasMatch(input)) {
              try {
                final bytes = latin1.encode(input);
                final fixed = utf8.decode(bytes);
                return fixed;
              } catch (_) {
                return input;
              }
            }
            return input;
          }

          final futures = toFetch.map((id) async {
            final res = await _repository.getUsernameById(hunterId: id);
            String name = '';
            res.fold((err) => name = '', (n) => name = n);
            name = fixEncoding(name).trim();
            
            
            print('[MissionDetail] username for $id => "$name"');
            return MapEntry(id, name);
          }).toList();

          final entries = await Future.wait(futures);
          usernames.addAll(Map.fromEntries(entries));
        }
      },
    );

    isLoading(false);
  }

  Future<void> selectHunter(
      {required ProposalsModel selectedProposal,required String hunterName}) async {
    if (!mission.value.status.isOpen) return;

    isSelecting(true);

    final proposalUpdateDto = UpdateProposalDto(isAccepted: true);
    final missionUpdateDto = UpdateMissionDto(
      status: statusToString(Status.inProgress),
      chosenProposalId: selectedProposal.id,
    );

    final result = await _repository.selectHunter(
      missionId: mission.value.id,
      proposalId: selectedProposal.id,
      proposalDto: proposalUpdateDto,
      missionDto: missionUpdateDto,
    );

    result.fold(
      (error) {
        Get.snackbar('Ø®Ø·Ø§', 'Ø§Ù†ØªØ®Ø§Ø¨ Ø´Ú©Ø§Ø±Ú†ÛŒ Ù†Ø§Ù…ÙˆÙÙ‚ Ø¨ÙˆØ¯: $error',
            backgroundColor: Colors.red, colorText: Colors.white);
      },
      (_) {
        _updateLocalMissionStatus(selectedProposal.id);

        _updateLocalProposals(selectedProposal.id);

        Get.snackbar(
          'Ù…ÙˆÙÙ‚ÛŒØªâ€ŒØ¢Ù…ÛŒØ²',
          'Ø´Ú©Ø§Ø±Ú†ÛŒ $hunterName Ø¨Ø§ Ù…ÙˆÙÙ‚ÛŒØª Ø§Ù†ØªØ®Ø§Ø¨ Ø´Ø¯ Ùˆ Ù…Ø§Ù…ÙˆØ±ÛŒØª Ø¢ØºØ§Ø² Ø´Ø¯',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      },
    );

    isSelecting(false);
  }

  void _updateLocalMissionStatus(String chosenProposalId) {
    final updatedMission = mission.value.copyWith(
      status: Status.inProgress,
      chosenProposalId: chosenProposalId,
    );
    mission.value = updatedMission;
  }

  void _updateLocalProposals(String acceptedProposalId) {
    final updatedList = proposals.map((proposal) {
      if (proposal.id == acceptedProposalId) {
        return proposal.copyWith(isAccepted: true);
      }
      return proposal;
    }).toList();

    proposals.assignAll(updatedList);
  }


  Future<void> cancelHunterSelection() async {
    if (!mission.value.status.isInProgress) return;

    final currentProposalId = mission.value.chosenProposalId;
    if (currentProposalId == null || currentProposalId.isEmpty) {
      Get.snackbar('Ø®Ø·Ø§', 'Ù¾ÛŒØ´Ù†Ù‡Ø§Ø¯ Ø§Ù†ØªØ®Ø§Ø¨ Ø´Ø¯Ù‡â€ŒØ§ÛŒ Ø¨Ø±Ø§ÛŒ Ù„ØºÙˆ ÛŒØ§ÙØª Ù†Ø´Ø¯.', backgroundColor: Colors.yellow, colorText: Colors.black);
      return;
    }

    isSelecting(true);

    final proposalUpdateDto = UpdateProposalDto(isAccepted: false);
    final missionUpdateDto = UpdateMissionDto(
      status: statusToString(Status.open),
      chosenProposalId: '',
    );

    final result = await _repository.cancelHunterSelection(
      missionId: mission.value.id,
      proposalId: currentProposalId,
      proposalDto: proposalUpdateDto,
      missionDto: missionUpdateDto,
    );

    result.fold(
          (error) {
        
        Get.snackbar('Ø®Ø·Ø§', 'Ù„ØºÙˆ Ø§Ù†ØªØ®Ø§Ø¨ Ø´Ú©Ø§Ø±Ú†ÛŒ Ù†Ø§Ù…ÙˆÙÙ‚ Ø¨ÙˆØ¯: $error',
            backgroundColor: Colors.red, colorText: Colors.white);
      },
          (_) {
            _cancelLocalMissionStatus(null);
            _cancelLocalProposals(null, currentProposalId);

        Get.snackbar(
          'Ù…ÙˆÙÙ‚ÛŒØªâ€ŒØ¢Ù…ÛŒØ²',
          'Ø§Ù†ØªØ®Ø§Ø¨ Ø´Ú©Ø§Ø±Ú†ÛŒ Ø¨Ø§ Ù…ÙˆÙÙ‚ÛŒØª Ù„ØºÙˆ Ø´Ø¯. Ù…Ø§Ù…ÙˆØ±ÛŒØª Ø§Ú©Ù†ÙˆÙ† Ø¨Ø§Ø² Ø§Ø³Øª.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      },
    );

    isSelecting(false);
  }

  void _cancelLocalMissionStatus(String? chosenProposalId) {
    mission.value = mission.value.copyWith(
      status: chosenProposalId == null ? Status.open : Status.inProgress,
      chosenProposalId: chosenProposalId,
    );
  }

  void _cancelLocalProposals(String? acceptedProposalId, [String? canceledProposalId]) {
    final updatedList = proposals.map((proposal) {
      if (canceledProposalId != null && proposal.id == canceledProposalId) {
        return proposal.copyWith(isAccepted: false);
      }
      if (acceptedProposalId != null && proposal.id == acceptedProposalId) {
        return proposal.copyWith(isAccepted: true);
      }
      return proposal;
    }).toList();

    proposals.assignAll(updatedList);
  }
}


