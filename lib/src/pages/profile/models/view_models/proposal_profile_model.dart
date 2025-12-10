import '../../../missions/edit_mission/models/mission_model.dart';

class ProposalProfileModel {
  final String id;
  final String missionId;
  final String hunterId;
  final int proposedPrice;
  final bool isAccepted;
  final bool isCompleted;
  final DateTime createdAt;
  final MissionModel? mission;

  ProposalProfileModel({
    required this.id,
    required this.missionId,
    required this.hunterId,
    required this.proposedPrice,
    required this.isAccepted,
    required this.isCompleted,
    required this.createdAt,
    this.mission,
  });

  factory ProposalProfileModel.fromJson(Map<String, dynamic> json) {
    return ProposalProfileModel(
      id: json['id'],
      missionId: json['missionId'],
      hunterId: json['hunterId'],
      proposedPrice: json['proposedPrice'],
      isAccepted: json['isAccepted'] ?? false,
      isCompleted: json['isCompleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),

      mission: json['mission'] != null
          ? MissionModel.fromJson(json: json['mission'])
          : null,
    );
  }

  // --- copyWith Method ---
  ProposalProfileModel copyWith({
    String? id,
    String? missionId,
    String? hunterId,
    int? proposedPrice,
    bool? isAccepted,
    bool? isCompleted,
    DateTime? createdAt,
    MissionModel? mission,
  }) {
    return ProposalProfileModel(
      id: id ?? this.id,
      missionId: missionId ?? this.missionId,
      hunterId: hunterId ?? this.hunterId,
      proposedPrice: proposedPrice ?? this.proposedPrice,
      isAccepted: isAccepted ?? this.isAccepted,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      mission: mission ?? this.mission,
    );
  }
}
