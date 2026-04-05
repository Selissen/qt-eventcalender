import 'package:flutter_bloc/flutter_bloc.dart';

import '../proto/calendar.pb.dart' show Route;
import '../repository/calendar_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────────

sealed class RoutesState {
  const RoutesState();
}

final class RoutesInitial extends RoutesState {
  const RoutesInitial();
}

final class RoutesLoading extends RoutesState {
  const RoutesLoading();
}

final class RoutesLoaded extends RoutesState {
  const RoutesLoaded(this.routes);
  final List<Route> routes;
}

final class RoutesError extends RoutesState {
  const RoutesError(this.error);
  final Object error;
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

/// Fetches the full route list once via GetRoutes RPC and caches it.
///
/// Routes change rarely, so [load] no-ops if data is already present.
class RoutesCubit extends Cubit<RoutesState> {
  RoutesCubit(this._repository) : super(const RoutesInitial());

  final CalendarRepository _repository;

  Future<void> load({bool force = false}) async {
    if (!force && state is RoutesLoaded) return;
    emit(const RoutesLoading());
    try {
      final routes = await _repository.getRoutes();
      emit(RoutesLoaded(routes));
    } catch (e) {
      emit(RoutesError(e));
    }
  }
}
