#!/usr/bin/env python3
"""
Lightweight gRPC test server for CalendarService.

Generates Python stubs from proto/calendar.proto on first run, then starts
an in-memory server that implements all five RPCs plus the SubscribePlans
server-streaming subscription.

Plan data is persisted to a JSON store file so it survives server restarts
and is shared across all client instances that connect to this server.

Usage:
    python scripts/test_server.py [--port 50051] [--store scripts/plans.json]

Requirements:
    pip install grpcio grpcio-tools

Pair with start_grpcwebproxy.py when testing from the WASM build.
"""

import argparse
import json
import os
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

# ── Persistent plan store ─────────────────────────────────────────────────────

_plans: dict[int, calendar_pb2.PlanData] = {}
_next_id = 1
_state_lock = threading.Lock()
_store_path: Path | None = None  # set in main() from --store argument


def _plan_to_dict(data: calendar_pb2.PlanData) -> dict:
    return {
        "name":            data.name,
        "start_date":      data.start_date,
        "start_time_secs": data.start_time_secs,
        "end_date":        data.end_date,
        "end_time_secs":   data.end_time_secs,
        "unit_id":         data.unit_id,
        "route_ids":       list(data.route_ids),
    }


def _plan_from_dict(d: dict) -> calendar_pb2.PlanData:
    return calendar_pb2.PlanData(
        name=d["name"],
        start_date=d["start_date"],
        start_time_secs=d["start_time_secs"],
        end_date=d["end_date"],
        end_time_secs=d["end_time_secs"],
        unit_id=d["unit_id"],
        route_ids=d.get("route_ids", []),
    )


def load_store(path: Path) -> None:
    """Load persisted plans from *path* into the in-memory store."""
    global _plans, _next_id
    if not path.exists():
        return
    try:
        with path.open() as f:
            doc = json.load(f)
        _next_id = doc.get("next_id", 1)
        _plans   = {int(k): _plan_from_dict(v) for k, v in doc.get("plans", {}).items()}
        print(f"[test_server] Loaded {len(_plans)} plan(s) from {path}")
    except Exception as exc:
        print(f"[test_server] WARNING: could not load store {path}: {exc}")


def _save_store() -> None:
    """Persist current in-memory state to disk (called while holding _state_lock)."""
    if _store_path is None:
        return
    doc = {
        "next_id": _next_id,
        "plans":   {str(k): _plan_to_dict(v) for k, v in _plans.items()},
    }
    # Atomic write: write to a temp file then rename so readers never see a
    # partial file even if the server is killed mid-write.
    tmp = _store_path.with_suffix(".tmp")
    try:
        with tmp.open("w") as f:
            json.dump(doc, f, indent=2)
        os.replace(tmp, _store_path)
    except Exception as exc:
        print(f"[test_server] WARNING: could not save store {_store_path}: {exc}")

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
            _save_store()
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
            _save_store()
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
            _save_store()
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
    global _store_path

    parser = argparse.ArgumentParser(
        description="CalendarService gRPC test server (persistent in-memory)"
    )
    parser.add_argument("--port", type=int, default=50051,
                        help="Port to listen on (default: 50051)")
    parser.add_argument("--store", type=Path,
                        default=SCRIPT_DIR / "plans.json",
                        help="Path to the JSON plan store (default: scripts/plans.json)")
    args = parser.parse_args()

    _store_path = args.store
    load_store(_store_path)

    server = grpc.server(futures.ThreadPoolExecutor(max_workers=16))
    calendar_pb2_grpc.add_CalendarServiceServicer_to_server(CalendarServicer(), server)

    address = f"[::]:{args.port}"
    server.add_insecure_port(address)
    server.start()

    print(f"[test_server] CalendarService listening on port {args.port} (insecure)")
    print(f"[test_server] Store : {_store_path}")
    print(f"[test_server] Units :  {[u.name for u in UNITS]}")
    print(f"[test_server] Routes: {[r.name for r in ROUTES]}")
    print(f"[test_server] Plans : {len(_plans)} loaded from store")
    print("[test_server] Press Ctrl+C to stop\n")

    try:
        server.wait_for_termination()
    except KeyboardInterrupt:
        print("\n[test_server] Shutting down...")
        server.stop(grace=2)


if __name__ == "__main__":
    main()
