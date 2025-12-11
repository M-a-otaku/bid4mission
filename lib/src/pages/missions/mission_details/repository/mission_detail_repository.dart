import 'package:either_dart/either.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../../infrastructure/commons/url_repository.dart';
import '../models/dto/update_mission_dto.dart';
import '../models/dto/update_proposal_dto.dart';
import '../models/view_models/mission_model.dart';
import '../models/view_models/proposal_model.dart';

class MissionDetailRepository {
  Future<Either<String, MissionModel>> getMissionById({
    required String missionId,
  }) async {
    try {
      final url = UrlRepository.getMissionById(missionId: missionId);
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(body);
        final mission = MissionModel.fromJson(data);
        return Right(mission);
      } else {
        return Left('Ø®Ø·Ø§ Ø¯Ø± Ø¯Ø±ÛŒØ§ÙØª Ù…Ø§Ù…ÙˆØ±ÛŒØª: ${response.statusCode}');
      }
    } catch (e) {
      return Left('Ø®Ø·Ø§ÛŒ Ø´Ø¨Ú©Ù‡ ÛŒØ§ Ø³Ø±ÙˆØ±: $e');
    }
  }

  Future<Either<String, List<ProposalsModel>>> getBidsForMission({
    required String missionId,
  }) async {
    try {
      final url = UrlRepository.getBidsForMissionId(missionId: missionId);
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList =
            json.decode(utf8.decode(response.bodyBytes));

        final List<ProposalsModel> bids =
            jsonList.map((item) => ProposalsModel.fromJson(item)).toList();

        return Right(bids);
      } else {
        final errorMsg = 'Ø®Ø·Ø§ Ø¯Ø± Ø¯Ø±ÛŒØ§ÙØª Ù¾ÛŒØ´Ù†Ù‡Ø§Ø¯Ø§Øª: ${response.statusCode}';
        return Left(errorMsg);
      }
    } catch (e) {
      return const Left(
          'Ø®Ø·Ø§ÛŒ Ø§Ø±ØªØ¨Ø§Ø· Ø¨Ø§ Ø³Ø±ÙˆØ±. Ø§ØªØµØ§Ù„ Ø§ÛŒÙ†ØªØ±Ù†Øª Ø®ÙˆØ¯ Ø±Ø§ Ø¨Ø±Ø±Ø³ÛŒ Ú©Ù†ÛŒØ¯.');
    }
  }

  Future<Either<String, bool>> selectHunter({
    required String missionId,
    required String proposalId,
    required UpdateProposalDto proposalDto,
    required UpdateMissionDto missionDto,
  }) async {
    try {
      final proposalUrl = UrlRepository.getProposalById(proposalId: proposalId);

      final proposalResponse = await http.patch(
        proposalUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(proposalDto.toJson()),
      );

      if (proposalResponse.statusCode != 200) {
        return const Left('Ø®Ø·Ø§ (Û±): Ø¨Ù‡â€ŒØ±ÙˆØ²Ø±Ø³Ø§Ù†ÛŒ ÙˆØ¶Ø¹ÛŒØª Ù¾ÛŒØ´Ù†Ù‡Ø§Ø¯ Ù†Ø§Ù…ÙˆÙÙ‚ Ø¨ÙˆØ¯.');
      }
    } catch (e) {
      return Left('Ø®Ø·Ø§ÛŒ Ø´Ø¨Ú©Ù‡ Ø¯Ø± Ø¨Ù‡â€ŒØ±ÙˆØ²Ø±Ø³Ø§Ù†ÛŒ Ù¾ÛŒØ´Ù†Ù‡Ø§Ø¯: ${e.toString()}');
    }

    try {
      final missionUrl = UrlRepository.getMissionById(missionId: missionId);

      final missionResponse = await http.patch(
        missionUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(missionDto.toJson()),
      );

      if (missionResponse.statusCode == 200) {
        return const Right(true);
      } else {
        return const Left('Ø®Ø·Ø§ (Û²): Ø¨Ù‡â€ŒØ±ÙˆØ²Ø±Ø³Ø§Ù†ÛŒ ÙˆØ¶Ø¹ÛŒØª Ù…Ø§Ù…ÙˆØ±ÛŒØª Ù†Ø§Ù…ÙˆÙÙ‚ Ø¨ÙˆØ¯.');
      }
    } catch (e) {
      return Left('Ø®Ø·Ø§ÛŒ Ø´Ø¨Ú©Ù‡ Ø¯Ø± Ø¨Ù‡â€ŒØ±ÙˆØ²Ø±Ø³Ø§Ù†ÛŒ Ù…Ø§Ù…ÙˆØ±ÛŒØª: ${e.toString()}');
    }
  }

  Future<Either<String, bool>> cancelHunterSelection({
    required String missionId,
    required String proposalId,
    required UpdateProposalDto proposalDto,
    required UpdateMissionDto missionDto,
  }) async {

    try {
      final proposalUrl = UrlRepository.getProposalById(proposalId: proposalId);

      final proposalResponse = await http.patch(
        proposalUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(proposalDto.toJson()),
      );

      if (proposalResponse.statusCode != 200) {
        return const Left('Ø®Ø·Ø§ (Û±): Ù„ØºÙˆ ÙˆØ¶Ø¹ÛŒØª Ù¾ÛŒØ´Ù†Ù‡Ø§Ø¯ Ù†Ø§Ù…ÙˆÙÙ‚ Ø¨ÙˆØ¯.');
      }
    } catch (e) {
      return Left('Ø®Ø·Ø§ÛŒ Ø´Ø¨Ú©Ù‡ Ø¯Ø± Ù„ØºÙˆ Ù¾ÛŒØ´Ù†Ù‡Ø§Ø¯: ${e.toString()}');
    }

    try {
      final missionUrl = UrlRepository.getMissionById(missionId: missionId);

      final missionResponse = await http.patch(
        missionUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(missionDto.toJson()),
      );

      if (missionResponse.statusCode == 200) {
        return const Right(true);
      } else {
        return const Left('Ø®Ø·Ø§ (Û²): Ù„ØºÙˆ ÙˆØ¶Ø¹ÛŒØª Ù…Ø§Ù…ÙˆØ±ÛŒØª Ù†Ø§Ù…ÙˆÙÙ‚ Ø¨ÙˆØ¯.');
      }
    } catch (e) {
      return Left('Ø®Ø·Ø§ÛŒ Ø´Ø¨Ú©Ù‡ Ø¯Ø± Ù„ØºÙˆ Ù…Ø§Ù…ÙˆØ±ÛŒØª: ${e.toString()}');
    }
  }

  Future<Either<String, String>> getUsernameById({required String hunterId}) async {
    try {
      
      final url = UrlRepository.getUserById(userId: hunterId);
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(body);
        
        final username = data['username'];
        return Right(username.toString());
      } else {
        return Left('Ø®Ø·Ø§ Ø¯Ø± Ø¯Ø±ÛŒØ§ÙØª Ú©Ø§Ø±Ø¨Ø±: ${response.statusCode}');
      }
    } catch (e) {
      return Left('Ø®Ø·Ø§ÛŒ Ø´Ø¨Ú©Ù‡ Ø¯Ø± Ø¯Ø±ÛŒØ§ÙØª Ú©Ø§Ø±Ø¨Ø±: $e');
    }
  }
}


