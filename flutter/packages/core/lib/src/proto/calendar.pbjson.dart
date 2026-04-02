// This is a generated file - do not edit.
//
// Generated from calendar.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use planEventTypeDescriptor instead')
const PlanEventType$json = {
  '1': 'PlanEventType',
  '2': [
    {'1': 'PLAN_ADDED', '2': 0},
    {'1': 'PLAN_UPDATED', '2': 1},
    {'1': 'PLAN_DELETED', '2': 2},
  ],
};

/// Descriptor for `PlanEventType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List planEventTypeDescriptor = $convert.base64Decode(
    'Cg1QbGFuRXZlbnRUeXBlEg4KClBMQU5fQURERUQQABIQCgxQTEFOX1VQREFURUQQARIQCgxQTE'
    'FOX0RFTEVURUQQAg==');

@$core.Deprecated('Use unitDescriptor instead')
const Unit$json = {
  '1': 'Unit',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 5, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `Unit`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List unitDescriptor = $convert
    .base64Decode('CgRVbml0Eg4KAmlkGAEgASgFUgJpZBISCgRuYW1lGAIgASgJUgRuYW1l');

@$core.Deprecated('Use routeDescriptor instead')
const Route$json = {
  '1': 'Route',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 5, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `Route`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List routeDescriptor = $convert.base64Decode(
    'CgVSb3V0ZRIOCgJpZBgBIAEoBVICaWQSEgoEbmFtZRgCIAEoCVIEbmFtZQ==');

@$core.Deprecated('Use getUnitsResponseDescriptor instead')
const GetUnitsResponse$json = {
  '1': 'GetUnitsResponse',
  '2': [
    {
      '1': 'units',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.calendar.Unit',
      '10': 'units'
    },
  ],
};

/// Descriptor for `GetUnitsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getUnitsResponseDescriptor = $convert.base64Decode(
    'ChBHZXRVbml0c1Jlc3BvbnNlEiQKBXVuaXRzGAEgAygLMg4uY2FsZW5kYXIuVW5pdFIFdW5pdH'
    'M=');

@$core.Deprecated('Use getRoutesResponseDescriptor instead')
const GetRoutesResponse$json = {
  '1': 'GetRoutesResponse',
  '2': [
    {
      '1': 'routes',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.calendar.Route',
      '10': 'routes'
    },
  ],
};

/// Descriptor for `GetRoutesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getRoutesResponseDescriptor = $convert.base64Decode(
    'ChFHZXRSb3V0ZXNSZXNwb25zZRInCgZyb3V0ZXMYASADKAsyDy5jYWxlbmRhci5Sb3V0ZVIGcm'
    '91dGVz');

@$core.Deprecated('Use planDataDescriptor instead')
const PlanData$json = {
  '1': 'PlanData',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'start_date', '3': 2, '4': 1, '5': 9, '10': 'startDate'},
    {'1': 'start_time_secs', '3': 3, '4': 1, '5': 5, '10': 'startTimeSecs'},
    {'1': 'end_date', '3': 4, '4': 1, '5': 9, '10': 'endDate'},
    {'1': 'end_time_secs', '3': 5, '4': 1, '5': 5, '10': 'endTimeSecs'},
    {'1': 'unit_id', '3': 6, '4': 1, '5': 5, '10': 'unitId'},
    {'1': 'route_ids', '3': 7, '4': 3, '5': 5, '10': 'routeIds'},
  ],
};

/// Descriptor for `PlanData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List planDataDescriptor = $convert.base64Decode(
    'CghQbGFuRGF0YRISCgRuYW1lGAEgASgJUgRuYW1lEh0KCnN0YXJ0X2RhdGUYAiABKAlSCXN0YX'
    'J0RGF0ZRImCg9zdGFydF90aW1lX3NlY3MYAyABKAVSDXN0YXJ0VGltZVNlY3MSGQoIZW5kX2Rh'
    'dGUYBCABKAlSB2VuZERhdGUSIgoNZW5kX3RpbWVfc2VjcxgFIAEoBVILZW5kVGltZVNlY3MSFw'
    'oHdW5pdF9pZBgGIAEoBVIGdW5pdElkEhsKCXJvdXRlX2lkcxgHIAMoBVIIcm91dGVJZHM=');

@$core.Deprecated('Use addPlanRequestDescriptor instead')
const AddPlanRequest$json = {
  '1': 'AddPlanRequest',
  '2': [
    {
      '1': 'data',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.calendar.PlanData',
      '10': 'data'
    },
  ],
};

/// Descriptor for `AddPlanRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addPlanRequestDescriptor = $convert.base64Decode(
    'Cg5BZGRQbGFuUmVxdWVzdBImCgRkYXRhGAEgASgLMhIuY2FsZW5kYXIuUGxhbkRhdGFSBGRhdG'
    'E=');

@$core.Deprecated('Use addPlanResponseDescriptor instead')
const AddPlanResponse$json = {
  '1': 'AddPlanResponse',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 5, '10': 'id'},
    {'1': 'success', '3': 2, '4': 1, '5': 8, '10': 'success'},
  ],
};

/// Descriptor for `AddPlanResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addPlanResponseDescriptor = $convert.base64Decode(
    'Cg9BZGRQbGFuUmVzcG9uc2USDgoCaWQYASABKAVSAmlkEhgKB3N1Y2Nlc3MYAiABKAhSB3N1Y2'
    'Nlc3M=');

@$core.Deprecated('Use updatePlanRequestDescriptor instead')
const UpdatePlanRequest$json = {
  '1': 'UpdatePlanRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 5, '10': 'id'},
    {
      '1': 'data',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.calendar.PlanData',
      '10': 'data'
    },
  ],
};

/// Descriptor for `UpdatePlanRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updatePlanRequestDescriptor = $convert.base64Decode(
    'ChFVcGRhdGVQbGFuUmVxdWVzdBIOCgJpZBgBIAEoBVICaWQSJgoEZGF0YRgCIAEoCzISLmNhbG'
    'VuZGFyLlBsYW5EYXRhUgRkYXRh');

@$core.Deprecated('Use updatePlanResponseDescriptor instead')
const UpdatePlanResponse$json = {
  '1': 'UpdatePlanResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
  ],
};

/// Descriptor for `UpdatePlanResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updatePlanResponseDescriptor =
    $convert.base64Decode(
        'ChJVcGRhdGVQbGFuUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2Vzcw==');

@$core.Deprecated('Use deletePlanRequestDescriptor instead')
const DeletePlanRequest$json = {
  '1': 'DeletePlanRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 5, '10': 'id'},
  ],
};

/// Descriptor for `DeletePlanRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deletePlanRequestDescriptor =
    $convert.base64Decode('ChFEZWxldGVQbGFuUmVxdWVzdBIOCgJpZBgBIAEoBVICaWQ=');

@$core.Deprecated('Use deletePlanResponseDescriptor instead')
const DeletePlanResponse$json = {
  '1': 'DeletePlanResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
  ],
};

/// Descriptor for `DeletePlanResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deletePlanResponseDescriptor =
    $convert.base64Decode(
        'ChJEZWxldGVQbGFuUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2Vzcw==');

@$core.Deprecated('Use emptyDescriptor instead')
const Empty$json = {
  '1': 'Empty',
};

/// Descriptor for `Empty`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List emptyDescriptor =
    $convert.base64Decode('CgVFbXB0eQ==');

@$core.Deprecated('Use subscribePlansRequestDescriptor instead')
const SubscribePlansRequest$json = {
  '1': 'SubscribePlansRequest',
  '2': [
    {'1': 'unit_ids', '3': 1, '4': 3, '5': 5, '10': 'unitIds'},
  ],
};

/// Descriptor for `SubscribePlansRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscribePlansRequestDescriptor =
    $convert.base64Decode(
        'ChVTdWJzY3JpYmVQbGFuc1JlcXVlc3QSGQoIdW5pdF9pZHMYASADKAVSB3VuaXRJZHM=');

@$core.Deprecated('Use planEventDescriptor instead')
const PlanEvent$json = {
  '1': 'PlanEvent',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.calendar.PlanEventType',
      '10': 'type'
    },
    {'1': 'id', '3': 2, '4': 1, '5': 5, '10': 'id'},
    {
      '1': 'data',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.calendar.PlanData',
      '10': 'data'
    },
  ],
};

/// Descriptor for `PlanEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List planEventDescriptor = $convert.base64Decode(
    'CglQbGFuRXZlbnQSKwoEdHlwZRgBIAEoDjIXLmNhbGVuZGFyLlBsYW5FdmVudFR5cGVSBHR5cG'
    'USDgoCaWQYAiABKAVSAmlkEiYKBGRhdGEYAyABKAsyEi5jYWxlbmRhci5QbGFuRGF0YVIEZGF0'
    'YQ==');
