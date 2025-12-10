import 'package:either_dart/either.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../infrastructure/commons/url_repository.dart';
import '../../../infrastructure/commons/status.dart';
import '../models/view_models/proposal_profile_model.dart';
import '../models/dto/update_proposal_dto.dart';
import '../../missions/edit_mission/models/mission_model.dart' as EditMissionModel;

class HunterProposalRepository {
  // No external repository: fetch mission details directly here to keep logic local.

  Future<Either<String, List<ProposalProfileModel>>> getAllHunterProposals({
    required String hunterId,
    bool? isAccepted,
    bool? isCompleted,
  }) async {
    try {
      // Build URI from base and merge optional query parameters for server-side filtering
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

        // For proposals without embedded mission, fetch mission by id and attach it.
        final Map<String, EditMissionModel.MissionModel> fetchedMissions = {};
        final List<Future<void>> fetchers = [];

        for (final p in bids) {
          if (p.mission == null && !fetchedMissions.containsKey(p.missionId)) {
            // fetch and cache per missionId to avoid duplicate requests
            fetchers.add(http.get(UrlRepository.getMissionById(missionId: p.missionId)).then((resp) {
              if (resp.statusCode == 200) {
                try {
                  final body = utf8.decode(resp.bodyBytes);
                  final Map<String, dynamic> data = json.decode(body);
                  final m = EditMissionModel.MissionModel.fromJson(json: data);
                  fetchedMissions[p.missionId] = m;
                } catch (_) {
                  // ignore parse errors; leave mission missing
                }
              }
            }).catchError((_) {
              // ignore network errors for individual missions
            }));
          }
        }

        if (fetchers.isNotEmpty) {
          await Future.wait(fetchers);
        }

        // Attach fetched mission models to proposals via copyWith
        final List<ProposalProfileModel> enriched = bids.map((p) {
          final m = fetchedMissions[p.missionId];
          if (m != null) {
            return p.copyWith(mission: m);
          }
          return p;
        }).toList();

        return Right(enriched);
      } else {
        return Left('خطا در دریافت پیشنهادات شکارچی: ${response.statusCode}');
      }
    } catch (e) {
      return Left('خطای شبکه یا سرور: ${e.toString()}');
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
        return Left('خطا در اعلام اتمام ماموریت: ${response.statusCode}');
      }
    } catch (e) {
      return Left('خطای شبکه در اعلام اتمام: ${e.toString()}');
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
        return Left('خطا در اعلام شکست ماموریت: ${response.statusCode}');
      }
    } catch (e) {
      return Left('خطای شبکه در اعلام شکست: ${e.toString()}');
    }
  }

  /// Update a proposal (e.g., change proposedPrice) by PATCHing the proposal resource.
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
        return Left('خطا در به‌روزرسانی پیشنهاد: ${response.statusCode}');
      }
    } catch (e) {
      return Left('خطای شبکه در به‌روزرسانی پیشنهاد: ${e.toString()}');
    }
  }

  /// Delete a proposal by id.
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
        return Left('خطا در حذف پیشنهاد: ${response.statusCode}');
      }
    } catch (e) {
      return Left('خطای شبکه در حذف پیشنهاد: ${e.toString()}');
    }
  }
}
