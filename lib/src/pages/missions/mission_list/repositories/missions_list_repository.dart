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
      String? sortByDate 
      }) async {
    try {
      
      final Map<String, String> queryParams = {};

      
      if (search != null && search.trim().isNotEmpty) {
        final s = search.trim();
        
        queryParams['title_like'] = s;
        queryParams['description_like'] = s;
        queryParams['location_like'] = s; 
      }

      
      if (categories != null && categories.isNotEmpty) {
        
        
        
        queryParams['category'] = categories.first;
      }

      
      if (minBudget != null) queryParams['budget_gte'] = minBudget.toString();
      if (maxBudget != null) queryParams['budget_lte'] = maxBudget.toString();

      
      if (statuses != null && statuses.isNotEmpty) {
        queryParams['status'] = statuses.first;
      }

      
      if (sortByDate != null && (sortByDate == 'asc' || sortByDate == 'desc')) {
        queryParams['_sort'] = 'deadline';
        queryParams['_order'] = sortByDate;
      }

      Uri uri = UrlRepository.missions;
      
      if (queryParams.isNotEmpty) {
        
        final base = Uri.parse(UrlRepository.missions.toString());
        uri = base.replace(queryParameters: queryParams);
      }

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final bodyString = utf8.decode(response.bodyBytes);
        final List<dynamic> jsonList = jsonDecode(bodyString);
        final List<MissionsModel> allMissions =
            jsonList.map((json) => MissionsModel.fromJson(json)).toList();

        
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

        
        List<MissionsModel> finalList;
        if (role == roleToString(Role.hunter)) {
          finalList = filtered.toList();
        } else if (role == roleToString(Role.employer)) {
          finalList = filtered.where((m) => m.employerId == userId).toList();
        } else {
          
          finalList = filtered.toList();
        }

        
        if (!(queryParams.containsKey('_sort') && queryParams['_sort'] == 'deadline')) {
          finalList.sort((a, b) => a.deadline.compareTo(b.deadline));
        } else if (queryParams['_order'] == 'desc') {
          finalList.sort((a, b) => b.deadline.compareTo(a.deadline));
        }

        
        final now = DateTime.now();
        final List<MissionsModel> processedList = [];
        final List<Future<void>> updateFutures = [];

        for (final m in finalList) {
          try {
            if (m.deadline.isBefore(now) && !m.status.isExpired) {
              
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

        
        if (updateFutures.isNotEmpty) {
          try {
            await Future.wait(updateFutures);
          } catch (_) {
            
          }
        }

        
        try {
          Get.log('Missions fetched: ${processedList.length} from $uri');
        } catch (_) {}

        return Right(processedList);
      } else {
        return Left('Ø®Ø·Ø§ Ø¯Ø± Ù„ÙˆØ¯ Ù„ÛŒØ³Øª: ${response.statusCode}');
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
        
        final bodyString = utf8.decode(response.bodyBytes);
        return Right(jsonDecode(bodyString) as Map<String, dynamic>);
      } else if (response.statusCode == 400) {
        final errorJson = jsonDecode(utf8.decode(response.bodyBytes));
        final errorMessage =
            errorJson['message'] ?? 'Bad Request. Please check your data.';
        return Left(errorMessage);
      } else {
        
        final errorMsg =
            'Error ${response.statusCode}: Failed to submit proposal.';
        return Left(errorMsg);
      }
    } catch (e) {
      
      return Left('Network connection error or request timed out.');
    }
  }

  
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
      return Left('Ø®Ø·Ø§ Ø¯Ø± Ø¨Ø±Ø±Ø³ÛŒ Ù¾ÛŒØ´Ù†Ù‡Ø§Ø¯Ø§Øª: ${response.statusCode}');
    } catch (e) {
      return Left('Ø®Ø·Ø§ Ø¯Ø± Ø¨Ø±Ø±Ø³ÛŒ Ù¾ÛŒØ´Ù†Ù‡Ø§Ø¯Ø§Øª: ${e.toString()}');
    }
  }

  
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
        return Left('Ø®Ø·Ø§ Ø¯Ø± Ø¨Ù‡â€ŒØ±ÙˆØ²Ø±Ø³Ø§Ù†ÛŒ ÙˆØ¶Ø¹ÛŒØª Ù…Ø§Ù…ÙˆØ±ÛŒØª: ${response.statusCode}');
      }
    } catch (e) {
      return Left('Ø®Ø·Ø§ÛŒ Ø´Ø¨Ú©Ù‡ Ø¯Ø± Ø¨Ù‡â€ŒØ±ÙˆØ²Ø±Ø³Ø§Ù†ÛŒ ÙˆØ¶Ø¹ÛŒØª: ${e.toString()}');
    }
  }

  
  Future<Either<String, bool>> deleteMission({required String missionId}) async {
    try {
      final url = UrlRepository.getMissionById(missionId: missionId);
      final response = await http.delete(url);
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return const Right(true);
      } else {
        return Left('Ø®Ø·Ø§ Ø¯Ø± Ø­Ø°Ù Ù…Ø§Ù…ÙˆØ±ÛŒØª: ${response.statusCode}');
      }
    } catch (e) {
      return Left('Ø®Ø·Ø§ÛŒ Ø´Ø¨Ú©Ù‡ Ø¯Ø± Ø­Ø°Ù Ù…Ø§Ù…ÙˆØ±ÛŒØª: ${e.toString()}');
    }
  }

  
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
        return Left('Ø®Ø·Ø§ Ø¯Ø± Ø¯Ø±ÛŒØ§ÙØª Ø¨Ø§Ø²Ù‡ Ø¨ÙˆØ¯Ø¬Ù‡: ${response.statusCode}');
      }
    } catch (e) {
      return Left('Ø®Ø·Ø§ Ø¯Ø± Ø¯Ø±ÛŒØ§ÙØª Ø¨Ø§Ø²Ù‡ Ø¨ÙˆØ¯Ø¬Ù‡: ${e.toString()}');
    }
  }

  Future<List<String>> getAllCategories() async {
    try {
      final response = await http.get(UrlRepository.missions);
      if (response.statusCode != 200) return [];

      final body = utf8.decode(response.bodyBytes);
      final List<dynamic> missions = jsonDecode(body);

      final Set<String> categories = {};
      for (final m in missions) {
        try {
          final dynamic rawCat = m['category'];
          if (rawCat == null) continue;
          final catStr = rawCat is String ? rawCat : rawCat.toString();
          categories.add(catStr.trim());
        } catch (_) {
          continue;
        }
      }

      final List<String> result = categories.toList()..sort();
      return result;
    } catch (_) {
      return [];
    }
  }

}


