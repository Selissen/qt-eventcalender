// This is a generated file - do not edit.
//
// Generated from calendar.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'calendar.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'calendar.pbenum.dart';

class Unit extends $pb.GeneratedMessage {
  factory Unit({
    $core.int? id,
    $core.String? name,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    return result;
  }

  Unit._();

  factory Unit.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Unit.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Unit',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'calendar'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Unit clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Unit copyWith(void Function(Unit) updates) =>
      super.copyWith((message) => updates(message as Unit)) as Unit;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Unit create() => Unit._();
  @$core.override
  Unit createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Unit getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Unit>(create);
  static Unit? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);
}

class Route extends $pb.GeneratedMessage {
  factory Route({
    $core.int? id,
    $core.String? name,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    return result;
  }

  Route._();

  factory Route.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Route.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Route',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'calendar'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Route clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Route copyWith(void Function(Route) updates) =>
      super.copyWith((message) => updates(message as Route)) as Route;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Route create() => Route._();
  @$core.override
  Route createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Route getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Route>(create);
  static Route? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);
}

class GetUnitsResponse extends $pb.GeneratedMessage {
  factory GetUnitsResponse({
    $core.Iterable<Unit>? units,
  }) {
    final result = create();
    if (units != null) result.units.addAll(units);
    return result;
  }

  GetUnitsResponse._();

  factory GetUnitsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetUnitsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetUnitsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'calendar'),
      createEmptyInstance: create)
    ..pPM<Unit>(1, _omitFieldNames ? '' : 'units', subBuilder: Unit.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetUnitsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetUnitsResponse copyWith(void Function(GetUnitsResponse) updates) =>
      super.copyWith((message) => updates(message as GetUnitsResponse))
          as GetUnitsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetUnitsResponse create() => GetUnitsResponse._();
  @$core.override
  GetUnitsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetUnitsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetUnitsResponse>(create);
  static GetUnitsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Unit> get units => $_getList(0);
}

class GetRoutesResponse extends $pb.GeneratedMessage {
  factory GetRoutesResponse({
    $core.Iterable<Route>? routes,
  }) {
    final result = create();
    if (routes != null) result.routes.addAll(routes);
    return result;
  }

  GetRoutesResponse._();

  factory GetRoutesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetRoutesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetRoutesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'calendar'),
      createEmptyInstance: create)
    ..pPM<Route>(1, _omitFieldNames ? '' : 'routes', subBuilder: Route.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRoutesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRoutesResponse copyWith(void Function(GetRoutesResponse) updates) =>
      super.copyWith((message) => updates(message as GetRoutesResponse))
          as GetRoutesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetRoutesResponse create() => GetRoutesResponse._();
  @$core.override
  GetRoutesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetRoutesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetRoutesResponse>(create);
  static GetRoutesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Route> get routes => $_getList(0);
}

/// Dates are ISO strings ("yyyy-MM-dd"); times are seconds since midnight.
class PlanData extends $pb.GeneratedMessage {
  factory PlanData({
    $core.String? name,
    $core.String? startDate,
    $core.int? startTimeSecs,
    $core.String? endDate,
    $core.int? endTimeSecs,
    $core.int? unitId,
    $core.Iterable<$core.int>? routeIds,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (startDate != null) result.startDate = startDate;
    if (startTimeSecs != null) result.startTimeSecs = startTimeSecs;
    if (endDate != null) result.endDate = endDate;
    if (endTimeSecs != null) result.endTimeSecs = endTimeSecs;
    if (unitId != null) result.unitId = unitId;
    if (routeIds != null) result.routeIds.addAll(routeIds);
    return result;
  }

  PlanData._();

  factory PlanData.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PlanData.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlanData',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'calendar'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'startDate')
    ..aI(3, _omitFieldNames ? '' : 'startTimeSecs')
    ..aOS(4, _omitFieldNames ? '' : 'endDate')
    ..aI(5, _omitFieldNames ? '' : 'endTimeSecs')
    ..aI(6, _omitFieldNames ? '' : 'unitId')
    ..p<$core.int>(7, _omitFieldNames ? '' : 'routeIds', $pb.PbFieldType.K3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlanData clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlanData copyWith(void Function(PlanData) updates) =>
      super.copyWith((message) => updates(message as PlanData)) as PlanData;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PlanData create() => PlanData._();
  @$core.override
  PlanData createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PlanData getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PlanData>(create);
  static PlanData? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get startDate => $_getSZ(1);
  @$pb.TagNumber(2)
  set startDate($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStartDate() => $_has(1);
  @$pb.TagNumber(2)
  void clearStartDate() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get startTimeSecs => $_getIZ(2);
  @$pb.TagNumber(3)
  set startTimeSecs($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasStartTimeSecs() => $_has(2);
  @$pb.TagNumber(3)
  void clearStartTimeSecs() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get endDate => $_getSZ(3);
  @$pb.TagNumber(4)
  set endDate($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEndDate() => $_has(3);
  @$pb.TagNumber(4)
  void clearEndDate() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get endTimeSecs => $_getIZ(4);
  @$pb.TagNumber(5)
  set endTimeSecs($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEndTimeSecs() => $_has(4);
  @$pb.TagNumber(5)
  void clearEndTimeSecs() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get unitId => $_getIZ(5);
  @$pb.TagNumber(6)
  set unitId($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasUnitId() => $_has(5);
  @$pb.TagNumber(6)
  void clearUnitId() => $_clearField(6);

  @$pb.TagNumber(7)
  $pb.PbList<$core.int> get routeIds => $_getList(6);
}

class AddPlanRequest extends $pb.GeneratedMessage {
  factory AddPlanRequest({
    PlanData? data,
  }) {
    final result = create();
    if (data != null) result.data = data;
    return result;
  }

  AddPlanRequest._();

  factory AddPlanRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddPlanRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddPlanRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'calendar'),
      createEmptyInstance: create)
    ..aOM<PlanData>(1, _omitFieldNames ? '' : 'data',
        subBuilder: PlanData.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddPlanRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddPlanRequest copyWith(void Function(AddPlanRequest) updates) =>
      super.copyWith((message) => updates(message as AddPlanRequest))
          as AddPlanRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddPlanRequest create() => AddPlanRequest._();
  @$core.override
  AddPlanRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddPlanRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddPlanRequest>(create);
  static AddPlanRequest? _defaultInstance;

  @$pb.TagNumber(1)
  PlanData get data => $_getN(0);
  @$pb.TagNumber(1)
  set data(PlanData value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasData() => $_has(0);
  @$pb.TagNumber(1)
  void clearData() => $_clearField(1);
  @$pb.TagNumber(1)
  PlanData ensureData() => $_ensure(0);
}

class AddPlanResponse extends $pb.GeneratedMessage {
  factory AddPlanResponse({
    $core.int? id,
    $core.bool? success,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (success != null) result.success = success;
    return result;
  }

  AddPlanResponse._();

  factory AddPlanResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddPlanResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddPlanResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'calendar'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'id')
    ..aOB(2, _omitFieldNames ? '' : 'success')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddPlanResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddPlanResponse copyWith(void Function(AddPlanResponse) updates) =>
      super.copyWith((message) => updates(message as AddPlanResponse))
          as AddPlanResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddPlanResponse create() => AddPlanResponse._();
  @$core.override
  AddPlanResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddPlanResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddPlanResponse>(create);
  static AddPlanResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get success => $_getBF(1);
  @$pb.TagNumber(2)
  set success($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSuccess() => $_has(1);
  @$pb.TagNumber(2)
  void clearSuccess() => $_clearField(2);
}

class UpdatePlanRequest extends $pb.GeneratedMessage {
  factory UpdatePlanRequest({
    $core.int? id,
    PlanData? data,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (data != null) result.data = data;
    return result;
  }

  UpdatePlanRequest._();

  factory UpdatePlanRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdatePlanRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdatePlanRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'calendar'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'id')
    ..aOM<PlanData>(2, _omitFieldNames ? '' : 'data',
        subBuilder: PlanData.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdatePlanRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdatePlanRequest copyWith(void Function(UpdatePlanRequest) updates) =>
      super.copyWith((message) => updates(message as UpdatePlanRequest))
          as UpdatePlanRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdatePlanRequest create() => UpdatePlanRequest._();
  @$core.override
  UpdatePlanRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdatePlanRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdatePlanRequest>(create);
  static UpdatePlanRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  PlanData get data => $_getN(1);
  @$pb.TagNumber(2)
  set data(PlanData value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasData() => $_has(1);
  @$pb.TagNumber(2)
  void clearData() => $_clearField(2);
  @$pb.TagNumber(2)
  PlanData ensureData() => $_ensure(1);
}

class UpdatePlanResponse extends $pb.GeneratedMessage {
  factory UpdatePlanResponse({
    $core.bool? success,
  }) {
    final result = create();
    if (success != null) result.success = success;
    return result;
  }

  UpdatePlanResponse._();

  factory UpdatePlanResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdatePlanResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdatePlanResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'calendar'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdatePlanResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdatePlanResponse copyWith(void Function(UpdatePlanResponse) updates) =>
      super.copyWith((message) => updates(message as UpdatePlanResponse))
          as UpdatePlanResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdatePlanResponse create() => UpdatePlanResponse._();
  @$core.override
  UpdatePlanResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdatePlanResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdatePlanResponse>(create);
  static UpdatePlanResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);
}

class DeletePlanRequest extends $pb.GeneratedMessage {
  factory DeletePlanRequest({
    $core.int? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  DeletePlanRequest._();

  factory DeletePlanRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeletePlanRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeletePlanRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'calendar'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeletePlanRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeletePlanRequest copyWith(void Function(DeletePlanRequest) updates) =>
      super.copyWith((message) => updates(message as DeletePlanRequest))
          as DeletePlanRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeletePlanRequest create() => DeletePlanRequest._();
  @$core.override
  DeletePlanRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeletePlanRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeletePlanRequest>(create);
  static DeletePlanRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class DeletePlanResponse extends $pb.GeneratedMessage {
  factory DeletePlanResponse({
    $core.bool? success,
  }) {
    final result = create();
    if (success != null) result.success = success;
    return result;
  }

  DeletePlanResponse._();

  factory DeletePlanResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeletePlanResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeletePlanResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'calendar'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeletePlanResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeletePlanResponse copyWith(void Function(DeletePlanResponse) updates) =>
      super.copyWith((message) => updates(message as DeletePlanResponse))
          as DeletePlanResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeletePlanResponse create() => DeletePlanResponse._();
  @$core.override
  DeletePlanResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeletePlanResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeletePlanResponse>(create);
  static DeletePlanResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);
}

class Empty extends $pb.GeneratedMessage {
  factory Empty() => create();

  Empty._();

  factory Empty.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Empty.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Empty',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'calendar'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Empty clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Empty copyWith(void Function(Empty) updates) =>
      super.copyWith((message) => updates(message as Empty)) as Empty;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Empty create() => Empty._();
  @$core.override
  Empty createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Empty getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Empty>(create);
  static Empty? _defaultInstance;
}

/// Filter by unit IDs; leave empty to receive events for all units.
class SubscribePlansRequest extends $pb.GeneratedMessage {
  factory SubscribePlansRequest({
    $core.Iterable<$core.int>? unitIds,
  }) {
    final result = create();
    if (unitIds != null) result.unitIds.addAll(unitIds);
    return result;
  }

  SubscribePlansRequest._();

  factory SubscribePlansRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SubscribePlansRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubscribePlansRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'calendar'),
      createEmptyInstance: create)
    ..p<$core.int>(1, _omitFieldNames ? '' : 'unitIds', $pb.PbFieldType.K3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscribePlansRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscribePlansRequest copyWith(
          void Function(SubscribePlansRequest) updates) =>
      super.copyWith((message) => updates(message as SubscribePlansRequest))
          as SubscribePlansRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubscribePlansRequest create() => SubscribePlansRequest._();
  @$core.override
  SubscribePlansRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SubscribePlansRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubscribePlansRequest>(create);
  static SubscribePlansRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.int> get unitIds => $_getList(0);
}

/// Pushed by the server whenever a plan is mutated.
/// data is populated for PLAN_ADDED and PLAN_UPDATED; empty for PLAN_DELETED.
class PlanEvent extends $pb.GeneratedMessage {
  factory PlanEvent({
    PlanEventType? type,
    $core.int? id,
    PlanData? data,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (id != null) result.id = id;
    if (data != null) result.data = data;
    return result;
  }

  PlanEvent._();

  factory PlanEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PlanEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlanEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'calendar'),
      createEmptyInstance: create)
    ..aE<PlanEventType>(1, _omitFieldNames ? '' : 'type',
        enumValues: PlanEventType.values)
    ..aI(2, _omitFieldNames ? '' : 'id')
    ..aOM<PlanData>(3, _omitFieldNames ? '' : 'data',
        subBuilder: PlanData.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlanEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlanEvent copyWith(void Function(PlanEvent) updates) =>
      super.copyWith((message) => updates(message as PlanEvent)) as PlanEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PlanEvent create() => PlanEvent._();
  @$core.override
  PlanEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PlanEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PlanEvent>(create);
  static PlanEvent? _defaultInstance;

  @$pb.TagNumber(1)
  PlanEventType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(PlanEventType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get id => $_getIZ(1);
  @$pb.TagNumber(2)
  set id($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(2)
  void clearId() => $_clearField(2);

  @$pb.TagNumber(3)
  PlanData get data => $_getN(2);
  @$pb.TagNumber(3)
  set data(PlanData value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasData() => $_has(2);
  @$pb.TagNumber(3)
  void clearData() => $_clearField(3);
  @$pb.TagNumber(3)
  PlanData ensureData() => $_ensure(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
