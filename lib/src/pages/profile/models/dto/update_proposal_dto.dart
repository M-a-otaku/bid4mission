class UpdateProposalDto {
  final int? proposedPrice;
  final bool? isAccepted;
  final bool? isCompleted;

  UpdateProposalDto({
    this.proposedPrice,
    this.isAccepted,
    this.isCompleted,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (proposedPrice != null) json['proposedPrice'] = proposedPrice;
    if (isAccepted != null) json['isAccepted'] = isAccepted;
    if (isCompleted != null) json['isCompleted'] = isCompleted;
    return json;
  }
}

