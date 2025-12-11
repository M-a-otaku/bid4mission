import 'package:either_dart/either.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../infrastructure/commons/url_repository.dart';
import '../../../infrastructure/commons/status.dart';
import '../models/view_models/proposal_profile_model.dart';
import '../models/dto/update_proposal_dto.dart';
import '../../missions/edit_mission/models/mission_model.dart' as EditMissionModel;

class HunterProposalRepository {
  

  Future<Either<String, List<ProposalProfileModel>>> getAllHunterProposals({
    required String hunterId,
    bool? isAccepted,
    bool? isCompleted,
  }) async {
    try {
      
      final base = UrlRepository.getBidsForHunterId(hunterId: hunterId);
      final qp = Map<String, String>.from(base.queryParameters);
      if (isAccepted != null) qp['isAccepted'] = isAccepted.toString();
      if (isCompleted != null) qp['isCompleted'] = isCompleted.toString();

      final url = base.replace(queryParameters: qp);

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList =
            json.decode(utf8.decode(response.bodyBytes));

        final List<ProposalProfileModel> bids = jsonList
            .map((item) => ProposalProfileModel.fromJson(item))
            .toList();

        
        final Map<String, EditMissionModel.MissionModel> fetchedMissions = {};
        final List<Future<void>> fetchers = [];

        for (final p in bids) {
          if (p.mission == null && !fetchedMissions.containsKey(p.missionId)) {
            
            fetchers.add(http.get(UrlRepository.getMissionById(missionId: p.missionId)).then((resp) {
              if (resp.statusCode == 200) {
                try {
                  final body = utf8.decode(resp.bodyBytes);
                  final Map<String, dynamic> data = json.decode(body);
                  final m = EditMissionModel.MissionModel.fromJson(json: data);
                  fetchedMissions[p.missionId] = m;
                } catch (_) {
                  
                }
              }
            }).catchError((_) {
              
            }));
          }
        }

        if (fetchers.isNotEmpty) {
          await Future.wait(fetchers);
        }

        
        final List<ProposalProfileModel> enriched = bids.map((p) {
          final m = fetchedMissions[p.missionId];
          if (m != null) {
            return p.copyWith(mission: m);
          }
          return p;
        }).toList();

        return Right(enriched);
      } else {
        return Left('Ø®Ø·Ø§ Ø¯Ø± Ø¯Ø±ÛŒØ§ÙØª Ù¾ÛŒØ´Ù†Ù‡Ø§Ø¯Ø§Øª Ø´Ú©Ø§Ø±Ú†ÛŒ: ${response.statusCode}');
      }
    } catch (e) {
      return Left('Ø®Ø·Ø§ÛŒ Ø´Ø¨Ú©Ù‡ ÛŒØ§ Ø³Ø±ÙˆØ±: ${e.toString()}');
    }
  }
  Future<Either<String, bool>> requestMissionCompletion({
    required String missionId,
  }) async {
    try {
      final url = UrlRepository.getMissionById(missionId: missionId);
      final body = jsonEncode({'status': statusToString(Status.pendingApproval)});
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        return const Right(true);
      } else {
        return Left('Ø®Ø·Ø§ Ø¯Ø± Ø§Ø¹Ù„Ø§Ù… Ø§ØªÙ…Ø§Ù… Ù…Ø§Ù…ÙˆØ±ÛŒØª: ${response.statusCode}');
      }
    } catch (e) {
      return Left('Ø®Ø·Ø§ÛŒ Ø´Ø¨Ú©Ù‡ Ø¯Ø± Ø§Ø¹Ù„Ø§Ù… Ø§ØªÙ…Ø§Ù…: ${e.toString()}');
    }
  }

  Future<Either<String, bool>> requestMissionFailure({
    required String missionId,
  }) async {
    try {
      final url = UrlRepository.getMissionById(missionId: missionId);
      final body = jsonEncode({'status': statusToString(Status.failed)});
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        return const Right(true);
      } else {
        return Left('Ø®Ø·Ø§ Ø¯Ø± Ø§Ø¹Ù„Ø§Ù… Ø´Ú©Ø³Øª Ù…Ø§Ù…ÙˆØ±ÛŒØª: ${response.statusCode}');
      }
    } catch (e) {
      return Left('Ø®Ø·Ø§ÛŒ Ø´Ø¨Ú©Ù‡ Ø¯Ø± Ø§Ø¹Ù„Ø§Ù… Ø´Ú©Ø³Øª: ${e.toString()}');
    }
  }

  
  Future<Either<String, bool>> updateProposal({required String proposalId, required UpdateProposalDto dto}) async {
    try {
      final url = UrlRepository.getProposalById(proposalId: proposalId);
      final body = jsonEncode(dto.toJson());
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        return const Right(true);
      } else {
        return Left('Ø®Ø·Ø§ Ø¯Ø± Ø¨Ù‡â€ŒØ±ÙˆØ²Ø±Ø³Ø§Ù†ÛŒ Ù¾ÛŒØ´Ù†Ù‡Ø§Ø¯: ${response.statusCode}');
      }
    } catch (e) {
      return Left('Ø®Ø·Ø§ÛŒ Ø´Ø¨Ú©Ù‡ Ø¯Ø± Ø¨Ù‡â€ŒØ±ÙˆØ²Ø±Ø³Ø§Ù†ÛŒ Ù¾ÛŒØ´Ù†Ù‡Ø§Ø¯: ${e.toString()}');
    }
  }

  
  Future<Either<String, bool>> deleteProposal({required String proposalId}) async {
    try {
      final url = UrlRepository.getProposalById(proposalId: proposalId);
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return const Right(true);
      } else {
        return Left('Ø®Ø·Ø§ Ø¯Ø± Ø­Ø°Ù Ù¾ÛŒØ´Ù†Ù‡Ø§Ø¯: ${response.statusCode}');
      }
    } catch (e) {
      return Left('Ø®Ø·Ø§ÛŒ Ø´Ø¨Ú©Ù‡ Ø¯Ø± Ø­Ø°Ù Ù¾ÛŒØ´Ù†Ù‡Ø§Ø¯: ${e.toString()}');
    }
  }
}


