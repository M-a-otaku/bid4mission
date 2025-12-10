import '../../../../infrastructure/commons/status.dart';

class CreateMissionDto {
  final String title;
  final String description;
  final String category;
  final int budget;
  final DateTime deadline;
  final String employerId;
  final String? chosenProposalId;

  CreateMissionDto({
    required this.title,
    required this.description,
    required this.category,
    required this.budget,
    required this.deadline,
    required this.employerId,
    this.chosenProposalId,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'category': category,
        'budget': budget,
        'deadline': deadline.toUtc().toIso8601String(),
        'employerId': employerId,
        'chosenProposalId': null,
        'status': statusToString(Status.open),
      };
}
