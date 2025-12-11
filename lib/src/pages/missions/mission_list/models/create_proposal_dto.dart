class CreateProposalDto {
  final String missionId;
  final String hunterId;
  final int proposedPrice;

  CreateProposalDto({
    required this.missionId,
    required this.hunterId,
    required this.proposedPrice,
  });

  Map<String, dynamic> toJson() => {
    'missionId': missionId,
    'hunterId': hunterId,
    'proposedPrice': proposedPrice,
    'isAccepted': false,
    'createdAt': DateTime.now().toUtc().toIso8601String(),
  };
}

