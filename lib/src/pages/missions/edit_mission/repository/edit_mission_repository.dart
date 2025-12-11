import 'package:either_dart/either.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../infrastructure/commons/url_repository.dart';
import '../models/edit_mission_dto.dart';
import '../models/mission_model.dart';

class EditMissionRepository {
  Future<Either<String, MissionModel>> getMissionById(
      {required String missionId}) async {
    try {
      final url = UrlRepository.getMissionById(missionId: missionId);
      final response = await http.get(url);

      if (response.statusCode != 200) {
        return Left('Ø®Ø·Ø§ Ø¯Ø± Ø¯Ø±ÛŒØ§ÙØª Ù…Ø§Ù…ÙˆØ±ÛŒØª: ${response.statusCode}');
      }

      
      final body = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> mission = jsonDecode(body);
      return Right(MissionModel.fromJson(json: mission));
    } catch (e) {
      return Left(e.toString());
    }
  }

  Future<Either<String, MissionModel>> editMission(
      {required String missionId, required EditMissionDto dto}) async {
    try {
      final response = await http.patch(
        UrlRepository.getMissionById(missionId: missionId),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dto.toJson()),
      );

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final jsonMap = jsonDecode(body) as Map<String, dynamic>;
        return Right(MissionModel.fromJson(json: jsonMap));
      } else {
        return Left('Ø®Ø·Ø§ Ø¯Ø± ÙˆÛŒØ±Ø§ÛŒØ´: ${response.statusCode}');
      }
    } catch (e) {
      return Left('Ø®Ø·Ø§ Ø¯Ø± Ø§Ø±ØªØ¨Ø§Ø·: $e');
    }
  }
}


