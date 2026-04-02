// This is a generated file - do not edit.
//
// Generated from calendar.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'calendar.pb.dart' as $0;

export 'calendar.pb.dart';

@$pb.GrpcServiceName('calendar.CalendarService')
class CalendarServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  CalendarServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.GetUnitsResponse> getUnits(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getUnits, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetRoutesResponse> getRoutes(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getRoutes, request, options: options);
  }

  $grpc.ResponseFuture<$0.AddPlanResponse> addPlan(
    $0.AddPlanRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$addPlan, request, options: options);
  }

  $grpc.ResponseFuture<$0.UpdatePlanResponse> updatePlan(
    $0.UpdatePlanRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updatePlan, request, options: options);
  }

  $grpc.ResponseFuture<$0.DeletePlanResponse> deletePlan(
    $0.DeletePlanRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deletePlan, request, options: options);
  }

  /// Server-streaming subscription — works via gRPC (desktop) and
  /// gRPC-Web / Envoy (WASM browser). Stays open until cancelled.
  $grpc.ResponseStream<$0.PlanEvent> subscribePlans(
    $0.SubscribePlansRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$subscribePlans, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$getUnits = $grpc.ClientMethod<$0.Empty, $0.GetUnitsResponse>(
      '/calendar.CalendarService/GetUnits',
      ($0.Empty value) => value.writeToBuffer(),
      $0.GetUnitsResponse.fromBuffer);
  static final _$getRoutes = $grpc.ClientMethod<$0.Empty, $0.GetRoutesResponse>(
      '/calendar.CalendarService/GetRoutes',
      ($0.Empty value) => value.writeToBuffer(),
      $0.GetRoutesResponse.fromBuffer);
  static final _$addPlan =
      $grpc.ClientMethod<$0.AddPlanRequest, $0.AddPlanResponse>(
          '/calendar.CalendarService/AddPlan',
          ($0.AddPlanRequest value) => value.writeToBuffer(),
          $0.AddPlanResponse.fromBuffer);
  static final _$updatePlan =
      $grpc.ClientMethod<$0.UpdatePlanRequest, $0.UpdatePlanResponse>(
          '/calendar.CalendarService/UpdatePlan',
          ($0.UpdatePlanRequest value) => value.writeToBuffer(),
          $0.UpdatePlanResponse.fromBuffer);
  static final _$deletePlan =
      $grpc.ClientMethod<$0.DeletePlanRequest, $0.DeletePlanResponse>(
          '/calendar.CalendarService/DeletePlan',
          ($0.DeletePlanRequest value) => value.writeToBuffer(),
          $0.DeletePlanResponse.fromBuffer);
  static final _$subscribePlans =
      $grpc.ClientMethod<$0.SubscribePlansRequest, $0.PlanEvent>(
          '/calendar.CalendarService/SubscribePlans',
          ($0.SubscribePlansRequest value) => value.writeToBuffer(),
          $0.PlanEvent.fromBuffer);
}

@$pb.GrpcServiceName('calendar.CalendarService')
abstract class CalendarServiceBase extends $grpc.Service {
  $core.String get $name => 'calendar.CalendarService';

  CalendarServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.GetUnitsResponse>(
        'GetUnits',
        getUnits_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.GetUnitsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.GetRoutesResponse>(
        'GetRoutes',
        getRoutes_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.GetRoutesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.AddPlanRequest, $0.AddPlanResponse>(
        'AddPlan',
        addPlan_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.AddPlanRequest.fromBuffer(value),
        ($0.AddPlanResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UpdatePlanRequest, $0.UpdatePlanResponse>(
        'UpdatePlan',
        updatePlan_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.UpdatePlanRequest.fromBuffer(value),
        ($0.UpdatePlanResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeletePlanRequest, $0.DeletePlanResponse>(
        'DeletePlan',
        deletePlan_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.DeletePlanRequest.fromBuffer(value),
        ($0.DeletePlanResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SubscribePlansRequest, $0.PlanEvent>(
        'SubscribePlans',
        subscribePlans_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $0.SubscribePlansRequest.fromBuffer(value),
        ($0.PlanEvent value) => value.writeToBuffer()));
  }

  $async.Future<$0.GetUnitsResponse> getUnits_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return getUnits($call, await $request);
  }

  $async.Future<$0.GetUnitsResponse> getUnits(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.GetRoutesResponse> getRoutes_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return getRoutes($call, await $request);
  }

  $async.Future<$0.GetRoutesResponse> getRoutes(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.AddPlanResponse> addPlan_Pre($grpc.ServiceCall $call,
      $async.Future<$0.AddPlanRequest> $request) async {
    return addPlan($call, await $request);
  }

  $async.Future<$0.AddPlanResponse> addPlan(
      $grpc.ServiceCall call, $0.AddPlanRequest request);

  $async.Future<$0.UpdatePlanResponse> updatePlan_Pre($grpc.ServiceCall $call,
      $async.Future<$0.UpdatePlanRequest> $request) async {
    return updatePlan($call, await $request);
  }

  $async.Future<$0.UpdatePlanResponse> updatePlan(
      $grpc.ServiceCall call, $0.UpdatePlanRequest request);

  $async.Future<$0.DeletePlanResponse> deletePlan_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DeletePlanRequest> $request) async {
    return deletePlan($call, await $request);
  }

  $async.Future<$0.DeletePlanResponse> deletePlan(
      $grpc.ServiceCall call, $0.DeletePlanRequest request);

  $async.Stream<$0.PlanEvent> subscribePlans_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SubscribePlansRequest> $request) async* {
    yield* subscribePlans($call, await $request);
  }

  $async.Stream<$0.PlanEvent> subscribePlans(
      $grpc.ServiceCall call, $0.SubscribePlansRequest request);
}
