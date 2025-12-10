class UpdateMissionDto {
  final String? status;
  final String? chosenProposalId;

  UpdateMissionDto({
    this.status,
    this.chosenProposalId,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (status != null) {
      json['status'] = status;
    }
    if (chosenProposalId != null) {
      json['chosenProposalId'] = chosenProposalId;
    }
    return json;
  }
}