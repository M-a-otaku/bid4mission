
class EditMissionDto {
  final String id;
  final String title;
  final String description;
  final String category;
  final int budget;
  final DateTime deadline;
  final String? chosenProposalId;

  EditMissionDto({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.budget,
    required this.deadline,
    this.chosenProposalId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'budget': budget,
      'deadline': deadline.toIso8601String(),
      'chosenProposalId': null,
    };
  }
}