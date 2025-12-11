class ProposalsModel {
  final String id;
  final String missionId;
  final String hunterId;
  final int proposedPrice;
  final bool isAccepted;
  final DateTime createdAt;

  ProposalsModel({
    required this.id,
    required this.missionId,
    required this.hunterId,
    required this.proposedPrice,
    required this.isAccepted,
    required this.createdAt,
  });

  factory ProposalsModel.fromJson(Map<String, dynamic> json) {
    return ProposalsModel(
      id: json['id'],
      missionId: json['missionId'],
      hunterId: json['hunterId'],
      proposedPrice: json['proposedPrice'],
      isAccepted: json['isAccepted'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  ProposalsModel copyWith({
    String? id,
    String? missionId,
    String? hunterId,
    int? proposedPrice,
    bool? isAccepted,
    DateTime? createdAt,
  }) {
    return ProposalsModel(
      id: id ?? this.id,
      missionId: missionId ?? this.missionId,
      hunterId: hunterId ?? this.hunterId,
      proposedPrice: proposedPrice ?? this.proposedPrice,
      isAccepted: isAccepted ?? this.isAccepted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

