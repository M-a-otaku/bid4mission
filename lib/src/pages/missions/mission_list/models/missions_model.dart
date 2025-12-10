import 'dart:convert';
import '../../../../infrastructure/commons/status.dart';

class MissionsModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final int budget;
  final DateTime deadline;
  final Status status;
  final String employerId;
  final String? chosenProposalId;


  MissionsModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.budget,
    required this.deadline,
    required this.status,
    required this.employerId,
    this.chosenProposalId,
  });

  factory MissionsModel.fromJson(Map<String, dynamic> json) {
    // Defensive parsing: ensure non-nullable fields get sensible defaults
    final id = json['id']?.toString() ?? '0';
    final title = json['title']?.toString() ?? '';
    final description = json['description']?.toString() ?? '';
    final category = json['category']?.toString() ?? '';
    final budget = (json['budget'] is int)
        ? json['budget'] as int
        : int.tryParse(json['budget']?.toString() ?? '') ?? 0;

    DateTime deadline;
    try {
      final dl = json['deadline']?.toString();
      deadline = dl != null && dl.isNotEmpty
          ? DateTime.parse(dl)
          : DateTime.now();
    } catch (_) {
      deadline = DateTime.now();
    }

    final status = parseStatus(json['status']?.toString());
    final employerId = json['employerId']?.toString() ?? '0';
    final chosenProposalId = json['chosenProposalId']?.toString();

    return MissionsModel(
      id: id,
      title: title,
      description: description,
      category: category,
      budget: budget,
      deadline: deadline,
      status: status,
      employerId: employerId,
      chosenProposalId: chosenProposalId,
    );
  }
}