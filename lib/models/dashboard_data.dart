import 'paddock.dart';
import 'paddock_state.dart';
import 'rotation_movement.dart';
import 'rotation_session.dart';

class DashboardData {
  final int calvesCount;
  final int paddocksCount;
  final double totalCalfInvestment;
  final double totalFarmExpenses;
  final double farmDebtPending;
  final int pendingCalfFollowUps;
  final RotationSession? activeSession;
  final Paddock? activePaddock;
  final List<RotationMovement> recentMovements;
  final List<PaddockState> paddockStates;

  const DashboardData({
    required this.calvesCount,
    required this.paddocksCount,
    required this.totalCalfInvestment,
    required this.totalFarmExpenses,
    required this.farmDebtPending,
    required this.pendingCalfFollowUps,
    required this.activeSession,
    required this.activePaddock,
    required this.recentMovements,
    required this.paddockStates,
  });
}
