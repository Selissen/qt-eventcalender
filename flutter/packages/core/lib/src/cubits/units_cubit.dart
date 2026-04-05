import 'package:flutter_bloc/flutter_bloc.dart';

import '../proto/calendar.pb.dart' show Unit;
import '../repository/calendar_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────────

sealed class UnitsState {
  const UnitsState();
}

final class UnitsInitial extends UnitsState {
  const UnitsInitial();
}

final class UnitsLoading extends UnitsState {
  const UnitsLoading();
}

final class UnitsLoaded extends UnitsState {
  const UnitsLoaded(this.units);
  final List<Unit> units;
}

final class UnitsError extends UnitsState {
  const UnitsError(this.error);
  final Object error;
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

/// Fetches the full unit list once via GetUnits RPC and caches it.
///
/// Units change rarely, so [load] no-ops if data is already present.
/// Call [load] again (e.g. on retry) to force a fresh fetch.
class UnitsCubit extends Cubit<UnitsState> {
  UnitsCubit(this._repository) : super(const UnitsInitial());

  final CalendarRepository _repository;

  Future<void> load({bool force = false}) async {
    if (!force && state is UnitsLoaded) return;
    emit(const UnitsLoading());
    try {
      final units = await _repository.getUnits();
      emit(UnitsLoaded(units));
    } catch (e) {
      emit(UnitsError(e));
    }
  }
}
