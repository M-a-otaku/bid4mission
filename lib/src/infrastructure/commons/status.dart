import 'package:flutter/material.dart';

enum Status { open, inProgress, completed, expired, pendingApproval, failed }

Status parseStatus(String? s) {
  if (s == null) return Status.open;
  switch (s) {
    case 'open':
      return Status.open;
    case 'in_progress':
      return Status.inProgress;
    case 'completed':
      return Status.completed;
    case 'expired':
      return Status.expired;
    case 'pending_approval':
      return Status.pendingApproval;
    case 'failed':
      return Status.failed;
    default:
      return Status.open;
  }
}

String statusToString(Status s) {
  switch (s) {
    case Status.open:
      return 'open';
    case Status.inProgress:
      return 'in_progress';
    case Status.completed:
      return 'completed';
    case Status.expired:
      return 'expired';
    case Status.pendingApproval:
      return 'pending_approval';
    case Status.failed:
      return 'failed';
  }
}

extension StatusX on Status {
  bool get isOpen => this == Status.open;
  bool get isInProgress => this == Status.inProgress;
  bool get isCompleted => this == Status.completed;
  bool get isExpired => this == Status.expired;
  bool get isPendingApproval => this == Status.pendingApproval;
  bool get isFailed => this == Status.failed;
}

extension StatusUI on Status {
  Color get color {
    switch (this) {
      case Status.open:
        return Colors.green;
      case Status.inProgress:
        return Colors.orange;
      case Status.completed:
        return Colors.blue;
      case Status.expired:
        return Colors.red;
      case Status.failed:
        return Colors.redAccent;
      case Status.pendingApproval:
        return Colors.purple;
    }
  }

}
