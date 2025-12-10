import 'dart:convert';
import '../../../../infrastructure/commons/status.dart';

class MissionModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final int budget;
  final DateTime deadline;
  final Status status;
  final String employerId;

  MissionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.budget,
    required this.deadline,
    required this.status,
    required this.employerId,
  });

  factory MissionModel.fromJson({required Map<String, dynamic> json}) {
    return MissionModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      budget: json['budget'],
      deadline: DateTime.parse(json['deadline']),
      status: parseStatus(json['status']),
      employerId: json['employerId'],
    );
  }
}