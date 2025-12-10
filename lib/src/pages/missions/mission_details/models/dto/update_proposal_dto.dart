class UpdateProposalDto {
  final bool? isAccepted;

  UpdateProposalDto({
    this.isAccepted,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (isAccepted != null) {
      json['isAccepted'] = isAccepted;
    }
    return json;
  }
}