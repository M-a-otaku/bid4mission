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
        return Left('خطا در دریافت ماموریت: ${response.statusCode}');
      }
    } catch (e) {
      return Left('خطای شبکه یا سرور: $e');
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
        final errorMsg = 'خطا در دریافت پیشنهادات: ${response.statusCode}';
        return Left(errorMsg);
      }
    } catch (e) {
      return const Left(
          'خطای ارتباط با سرور. اتصال اینترنت خود را بررسی کنید.');
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
        return const Left('خطا (۱): به‌روزرسانی وضعیت پیشنهاد ناموفق بود.');
      }
    } catch (e) {
      return Left('خطای شبکه در به‌روزرسانی پیشنهاد: ${e.toString()}');
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
        return const Left('خطا (۲): به‌روزرسانی وضعیت ماموریت ناموفق بود.');
      }
    } catch (e) {
      return Left('خطای شبکه در به‌روزرسانی ماموریت: ${e.toString()}');
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
        return const Left('خطا (۱): لغو وضعیت پیشنهاد ناموفق بود.');
      }
    } catch (e) {
      return Left('خطای شبکه در لغو پیشنهاد: ${e.toString()}');
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
        return const Left('خطا (۲): لغو وضعیت ماموریت ناموفق بود.');
      }
    } catch (e) {
      return Left('خطای شبکه در لغو ماموریت: ${e.toString()}');
    }
  }

  Future<Either<String, String>> getUsernameById({required String hunterId}) async {
    try {
      // UrlRepository.getUserById expects int userId
      final url = UrlRepository.getUserById(userId: hunterId);
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(body);
        // assume username field is 'username' or 'name' depending on API
        final username = data['username'];
        return Right(username.toString());
      } else {
        return Left('خطا در دریافت کاربر: ${response.statusCode}');
      }
    } catch (e) {
      return Left('خطای شبکه در دریافت کاربر: $e');
    }
  }
}
