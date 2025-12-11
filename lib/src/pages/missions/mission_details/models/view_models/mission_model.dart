import 'dart:convert';

import '../../../../../infrastructure/commons/status.dart';

class MissionModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final int budget;
  final DateTime deadline;
  final Status status;
  final String employerId;
  final String? chosenProposalId;

  MissionModel({
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

  MissionModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    int? budget,
    DateTime? deadline,
    Status? status,
    String? employerId,

    String? chosenProposalId,
  }) {
    return MissionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      budget: budget ?? this.budget,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      employerId: employerId ?? this.employerId,

      chosenProposalId: chosenProposalId ?? this.chosenProposalId,
    );
  }

  factory MissionModel.fromJson(Map<String, dynamic> json) => MissionModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Ø¨Ø¯ÙˆÙ† Ø¹Ù†ÙˆØ§Ù†',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Ø¹Ù…ÙˆÙ…ÛŒ',
      budget: json['budget'] ?? 0,
      deadline: DateTime.tryParse(json['deadline'] ?? '') ?? DateTime.now(),
      status: parseStatus(json['status'] ?? 'open'),
      employerId: json['employerId'] ?? '',
      chosenProposalId: json['chosenProposalId'],
    );
}

