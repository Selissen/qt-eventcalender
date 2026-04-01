#!/usr/bin/env python3
"""
Lightweight gRPC test server for CalendarService.

Generates Python stubs from proto/calendar.proto on first run, then starts
an in-memory server that implements all five RPCs plus the SubscribePlans
server-streaming subscription.

Usage:
    python scripts/test_server.py [--port 50051]

Requirements:
    pip install grpcio grpcio-tools

Pair with start_grpcwebproxy.py when testing from the WASM build.
"""

import argparse
import sys
import threading
import queue
from concurrent import futures
from pathlib import Path

# ── Stub generation ───────────────────────────────────────────────────────────

SCRIPT_DIR  = Path(__file__).parent
PROJECT_DIR = SCRIPT_DIR.parent
PROTO_FILE  = PROJECT_DIR / "proto" / "calendar.proto"
GEN_DIR     = SCRIPT_DIR / "gen"


def ensure_stubs() -> None:
    """Generate calendar_pb2.py and calendar_pb2_grpc.py from the proto if absent."""
    if (GEN_DIR / "calendar_pb2.py").exists():
        return
    GEN_DIR.mkdir(exist_ok=True)
    (GEN_DIR / "__init__.py").touch()
    try:
        from grpc_tools import protoc
    except ImportError:
        sys.exit(
            "grpcio-tools not found.\n"
            "Install with:  pip install grpcio grpcio-tools"
        )
    rc = protoc.main([
        "grpc_tools.protoc",
        f"-I{PROTO_FILE.parent}",
        f"--python_out={GEN_DIR}",
        f"--grpc_python_out={GEN_DIR}",
        str(PROTO_FILE),
    ])
    if rc != 0:
        sys.exit(f"protoc exited with code {rc}")
    print(f"[test_server] Stubs generated in {GEN_DIR}")


ensure_stubs()
sys.path.insert(0, str(GEN_DIR))

import grpc                        # noqa: E402 (after path setup)
import calendar_pb2                # noqa: E402
import calendar_pb2_grpc           # noqa: E402

# ── Sample reference data ─────────────────────────────────────────────────────

UNITS = [
    calendar_pb2.Unit(id=1, name="Alpha"),
    calendar_pb2.Unit(id=2, name="Bravo"),
    calendar_pb2.Unit(id=3, name="Charlie"),
]

ROUTES = [
    calendar_pb2.Route(id=1, name="Route A"),
    calendar_pb2.Route(id=2, name="Route B"),
    calendar_pb2.Route(id=3, name="Route C"),
    calendar_pb2.Route(id=4, name="Route D"),
]

# ── In-memory plan store ──────────────────────────────────────────────────────

_plans: dict[int, calendar_pb2.PlanData] = {}
_next_id = 1
_state_lock = threading.Lock()

# ── Subscription fanout ───────────────────────────────────────────────────────

# Each active SubscribePlans call registers a (queue, unit_id_filter) entry.
# unit_id_filter is an empty list for "all units".
_subscribers: dict[int, tuple[queue.Queue, list[int]]] = {}
_subs_lock = threading.Lock()
_sub_counter = 0


def _broadcast(event: calendar_pb2.PlanEvent, unit_id: int = 0) -> None:
    """Push an event to all matching subscribers."""
    with _subs_lock:
        for sub_id, (q, unit_filter) in list(_subscribers.items()):
            if not unit_filter or not unit_id or unit_id in unit_filter:
                try:
                    q.put_nowait(event)
                except queue.Full:
                    pass  # slow subscriber — drop the event


# ── Service implementation ────────────────────────────────────────────────────

class CalendarServicer(calendar_pb2_grpc.CalendarServiceServicer):

    # ── Reference data ────────────────────────────────────────────────────────

    def GetUnits(self, request, context):
        return calendar_pb2.GetUnitsResponse(units=UNITS)

    def GetRoutes(self, request, context):
        return calendar_pb2.GetRoutesResponse(routes=ROUTES)

    # ── Plan CRUD ─────────────────────────────────────────────────────────────

    def AddPlan(self, request, context):
        global _next_id
        with _state_lock:
            plan_id = _next_id
            _next_id += 1
            _plans[plan_id] = request.data
        print(f"[test_server] AddPlan    id={plan_id}  name={request.data.name!r}"
              f"  unit={request.data.unit_id}")
        _broadcast(
            calendar_pb2.PlanEvent(
                type=calendar_pb2.PLAN_ADDED,
                id=plan_id,
                data=request.data,
            ),
            unit_id=request.data.unit_id,
        )
        return calendar_pb2.AddPlanResponse(id=plan_id, success=True)

    def UpdatePlan(self, request, context):
        with _state_lock:
            if request.id not in _plans:
                context.abort(grpc.StatusCode.NOT_FOUND,
                              f"Plan {request.id} not found")
                return
            _plans[request.id] = request.data
        print(f"[test_server] UpdatePlan id={request.id}  name={request.data.name!r}"
              f"  unit={request.data.unit_id}")
        _broadcast(
            calendar_pb2.PlanEvent(
                type=calendar_pb2.PLAN_UPDATED,
                id=request.id,
                data=request.data,
            ),
            unit_id=request.data.unit_id,
        )
        return calendar_pb2.UpdatePlanResponse(success=True)

    def DeletePlan(self, request, context):
        with _state_lock:
            data = _plans.pop(request.id, None)
        unit_id = data.unit_id if data else 0
        print(f"[test_server] DeletePlan id={request.id}")
        _broadcast(
            calendar_pb2.PlanEvent(
                type=calendar_pb2.PLAN_DELETED,
                id=request.id,
            ),
            unit_id=unit_id,
        )
        return calendar_pb2.DeletePlanResponse(success=True)

    # ── Subscription ──────────────────────────────────────────────────────────

    def SubscribePlans(self, request, context):
        global _sub_counter
        unit_filter = list(request.unit_ids)
        sub_queue: queue.Queue = queue.Queue(maxsize=256)

        with _subs_lock:
            _sub_counter += 1
            sub_id = _sub_counter
            _subscribers[sub_id] = (sub_queue, unit_filter)

        peer = context.peer()
        print(f"[test_server] SubscribePlans open   sub={sub_id}  peer={peer}"
              f"  filter={unit_filter or 'all'}")
        try:
            while context.is_active():
                try:
                    event = sub_queue.get(timeout=1.0)
                    yield event
                except queue.Empty:
                    continue  # heartbeat — keep checking context.is_active()
        finally:
            with _subs_lock:
                _subscribers.pop(sub_id, None)
            print(f"[test_server] SubscribePlans closed sub={sub_id}  peer={peer}")


# ── Entry point ───────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(
        description="CalendarService gRPC test server (in-memory)"
    )
    parser.add_argument("--port", type=int, default=50051,
                        help="Port to listen on (default: 50051)")
    args = parser.parse_args()

    server = grpc.server(futures.ThreadPoolExecutor(max_workers=16))
    calendar_pb2_grpc.add_CalendarServiceServicer_to_server(CalendarServicer(), server)

    address = f"[::]:{args.port}"
    server.add_insecure_port(address)
    server.start()

    print(f"[test_server] CalendarService listening on port {args.port} (insecure)")
    print(f"[test_server] Units:  {[u.name for u in UNITS]}")
    print(f"[test_server] Routes: {[r.name for r in ROUTES]}")
    print("[test_server] Press Ctrl+C to stop\n")

    try:
        server.wait_for_termination()
    except KeyboardInterrupt:
        print("\n[test_server] Shutting down...")
        server.stop(grace=2)


if __name__ == "__main__":
    main()
