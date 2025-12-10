import 'dart:convert';
import 'package:either_dart/either.dart';
import 'package:get/Get.dart';
import 'package:http/http.dart' as http;
import '../../../../../generated/locales.g.dart';
import '../../../../infrastructure/commons/url_repository.dart';
import '../../../../infrastructure/commons/role.dart';
import '../../../../infrastructure/commons/status.dart';
import '../models/create_proposal_dto.dart';
import '../models/missions_model.dart';

class MissionListRepository {
  Future<Either<String, List<MissionsModel>>> getMissions(
      String userId, String role,
      {String? search,
      List<String>? categories,
      int? minBudget,
      int? maxBudget,
      List<String>? statuses,
      String? sortByDate // 'asc' or 'desc'
      }) async {
    try {
      // build query parameters for json-server
      final Map<String, String> queryParams = {};

      // search across multiple fields using title_like, description_like
      if (search != null && search.trim().isNotEmpty) {
        final s = search.trim();
        // json-server supports multiple _like params; we'll use title_like and description_like
        queryParams['title_like'] = s;
        queryParams['description_like'] = s;
        queryParams['location_like'] = s; // in case there is a location field
      }

      // categories: json-server supports category=val (multiple params allowed)
      if (categories != null && categories.isNotEmpty) {
        // we'll append first category to queryParams and rely on Uri.http to accept multiple same keys by joining
        // as a simple approach, if multiple categories provided, we'll fetch all and filter client-side
        // but include the first to reduce payload
        queryParams['category'] = categories.first;
      }

      // budget range: json-server doesn't support range natively; use _gte and _lte on budget
      if (minBudget != null) queryParams['budget_gte'] = minBudget.toString();
      if (maxBudget != null) queryParams['budget_lte'] = maxBudget.toString();

      // statuses: as with categories, include first status and filter client-side if multiple
      if (statuses != null && statuses.isNotEmpty) {
        queryParams['status'] = statuses.first;
      }

      // sorting
      if (sortByDate != null && (sortByDate == 'asc' || sortByDate == 'desc')) {
        queryParams['_sort'] = 'deadline';
        queryParams['_order'] = sortByDate;
      }

      Uri uri = UrlRepository.missions;
      // if any query params exist, rebuild uri with them
      if (queryParams.isNotEmpty) {
        // Use Uri.parse(...).replace(...) to preserve scheme and port (previous approach lost port)
        final base = Uri.parse(UrlRepository.missions.toString());
        uri = base.replace(queryParameters: queryParams);
      }

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final bodyString = utf8.decode(response.bodyBytes);
        final List<dynamic> jsonList = jsonDecode(bodyString);
        final List<MissionsModel> allMissions =
            jsonList.map((json) => MissionsModel.fromJson(json)).toList();

        // apply additional client-side filtering for multiple categories/statuses and search across fields
        Iterable<MissionsModel> filtered = allMissions;

        if (search != null && search.trim().isNotEmpty) {
          final s = search.trim().toLowerCase();
          filtered = filtered.where((m) {
            final combined = '${m.title} ${m.description} ${m.category} ${m.status}'.toLowerCase();
            return combined.contains(s);
          });
        }

        if (categories != null && categories.isNotEmpty) {
          filtered = filtered.where((m) => categories.contains(m.category));
        }

        if (minBudget != null) filtered = filtered.where((m) => m.budget >= minBudget);
        if (maxBudget != null) filtered = filtered.where((m) => m.budget <= maxBudget);

        if (statuses != null && statuses.isNotEmpty) {
          final parsed = statuses.map((s) => parseStatus(s)).toSet();
          filtered = filtered.where((m) => parsed.contains(m.status));
        }

        // role-based restriction
        List<MissionsModel> finalList;
        if (role == roleToString(Role.hunter)) {
          finalList = filtered.toList();
        } else if (role == roleToString(Role.employer)) {
          finalList = filtered.where((m) => m.employerId == userId).toList();
        } else {
          // unknown role string from caller; fall back to hunter behavior (show all)
          finalList = filtered.toList();
        }

        // ensure sorting by date if not already applied server-side
        if (!(queryParams.containsKey('_sort') && queryParams['_sort'] == 'deadline')) {
          finalList.sort((a, b) => a.deadline.compareTo(b.deadline));
        } else if (queryParams['_order'] == 'desc') {
          finalList.sort((a, b) => b.deadline.compareTo(a.deadline));
        }

        // Mark missions expired/failed if their deadline already passed and persist change to server.
        final now = DateTime.now();
        final List<MissionsModel> processedList = [];
        final List<Future<void>> updateFutures = [];

        for (final m in finalList) {
          try {
            if (m.deadline.isBefore(now) && !m.status.isExpired) {
              // If the mission was in progress (an accepted proposal) or has a chosenProposalId, mark as failed when deadline passed.
              final shouldBeFailed = m.status.isInProgress || (m.chosenProposalId != null && m.chosenProposalId!.isNotEmpty);
              final newStatus = shouldBeFailed ? Status.failed : Status.expired;

              final updated = MissionsModel(
                id: m.id,
                title: m.title,
                description: m.description,
                category: m.category,
                budget: m.budget,
                deadline: m.deadline,
                status: newStatus,
                employerId: m.employerId,
                chosenProposalId: m.chosenProposalId,
              );

              processedList.add(updated);

              // persist change to server (fire-and-collect)
              updateFutures.add(() async {
                final res = await updateMissionStatus(missionId: m.id, status: newStatus);
                res.fold((l) {
                  try {
                    Get.log('Failed to persist status for mission ${m.id}: $l');
                  } catch (_) {}
                }, (r) {
                  try {
                    Get.log('Persisted status ${statusToString(newStatus)} for mission ${m.id}');
                  } catch (_) {}
                });
              }());
            } else {
              processedList.add(m);
            }
          } catch (_) {
            processedList.add(m);
          }
        }

        // await all server updates, but don't fail the whole operation if one update fails
        if (updateFutures.isNotEmpty) {
          try {
            await Future.wait(updateFutures);
          } catch (_) {
            // ignore individual update errors (they are logged above)
          }
        }

        // debug: log number of missions returned
        try {
          Get.log('Missions fetched: ${processedList.length} from $uri');
        } catch (_) {}

        return Right(processedList);
      } else {
        return Left('خطا در لود لیست: ${response.statusCode}');
      }
    } catch (e) {
      return Left("${LocaleKeys.error_error.tr}  ${e.toString()}");
    }
  }

  Future<Either<String, Map<String, dynamic>>> createProposal(
      {required CreateProposalDto proposalDto}) async {
    final url = UrlRepository.proposals;
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(proposalDto.toJson()),
      );

      if (response.statusCode == 201) {
        // decode bodyBytes to preserve Persian/Unicode characters
        final bodyString = utf8.decode(response.bodyBytes);
        return Right(jsonDecode(bodyString) as Map<String, dynamic>);
      } else if (response.statusCode == 400) {
        final errorJson = jsonDecode(utf8.decode(response.bodyBytes));
        final errorMessage =
            errorJson['message'] ?? 'Bad Request. Please check your data.';
        return Left(errorMessage);
      } else {
        // خطاهای عمومی سرور (مثل 500)
        final errorMsg =
            'Error ${response.statusCode}: Failed to submit proposal.';
        return Left(errorMsg);
      }
    } catch (e) {
      // خطای شبکه/Timeout/Parsing
      return Left('Network connection error or request timed out.');
    }
  }

  /// Check whether a proposal already exists for [missionId] by [hunterId].
  Future<Either<String, bool>> hasProposal({required String missionId, required String hunterId}) async {
    try {
      final base = Uri.parse(UrlRepository.proposals.toString());
      final uri = base.replace(queryParameters: {'missionId': missionId, 'hunterId': hunterId});
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final bodyString = utf8.decode(response.bodyBytes);
        final List<dynamic> jsonList = jsonDecode(bodyString);
        return Right(jsonList.isNotEmpty);
      }
      return Left('خطا در بررسی پیشنهادات: ${response.statusCode}');
    } catch (e) {
      return Left('خطا در بررسی پیشنهادات: ${e.toString()}');
    }
  }

  /// Update mission status on server (PATCH /missions/{id})
  Future<Either<String, bool>> updateMissionStatus({required String missionId, required Status status}) async {
    try {
      final url = UrlRepository.getMissionById(missionId: missionId);
      final body = jsonEncode({'status': statusToString(status)});
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        return const Right(true);
      } else {
        return Left('خطا در به‌روزرسانی وضعیت ماموریت: ${response.statusCode}');
      }
    } catch (e) {
      return Left('خطای شبکه در به‌روزرسانی وضعیت: ${e.toString()}');
    }
  }

  /// Delete mission on server (DELETE /missions/{id})
  Future<Either<String, bool>> deleteMission({required String missionId}) async {
    try {
      final url = UrlRepository.getMissionById(missionId: missionId);
      final response = await http.delete(url);
      // json-server returns 200 with an empty object on delete, but accept 200/204
      if (response.statusCode == 200 || response.statusCode == 204) {
        return const Right(true);
      } else {
        return Left('خطا در حذف ماموریت: ${response.statusCode}');
      }
    } catch (e) {
      return Left('خطای شبکه در حذف ماموریت: ${e.toString()}');
    }
  }

  /// Fetch all missions and compute the global min/max budget values.
  Future<Either<String, Map<String, int>>> getBudgetRange() async {
    try {
      final response = await http.get(UrlRepository.missions);
      if (response.statusCode == 200) {
        final bodyString = utf8.decode(response.bodyBytes);
        final List<dynamic> jsonList = jsonDecode(bodyString);
        final List<MissionsModel> allMissions = jsonList.map((json) => MissionsModel.fromJson(json)).toList();

        if (allMissions.isEmpty) return const Right({'min': 0, 'max': 0});

        final budgets = allMissions.map((m) => m.budget).where((b) => b >= 0).toList();
        int minBudget = budgets.reduce((a, b) => a < b ? a : b);
        int maxBudget = budgets.reduce((a, b) => a > b ? a : b);
        return Right({'min': minBudget, 'max': maxBudget});
      } else {
        return Left('خطا در دریافت بازه بودجه: ${response.statusCode}');
      }
    } catch (e) {
      return Left('خطا در دریافت بازه بودجه: ${e.toString()}');
    }
  }
}
