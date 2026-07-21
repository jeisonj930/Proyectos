import 'paddock.dart';
import 'rotation_session.dart';

class PaddockState {
  final Paddock paddock;
  final String status;
  final int? daysRemaining;
  final RotationSession? activeSession;
  final RotationSession? lastSession;

  const PaddockState({
    required this.paddock,
    required this.status,
    this.daysRemaining,
    this.activeSession,
    this.lastSession,
  });
}
