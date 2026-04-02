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

class PlanEventType extends $pb.ProtobufEnum {
  static const PlanEventType PLAN_ADDED =
      PlanEventType._(0, _omitEnumNames ? '' : 'PLAN_ADDED');
  static const PlanEventType PLAN_UPDATED =
      PlanEventType._(1, _omitEnumNames ? '' : 'PLAN_UPDATED');
  static const PlanEventType PLAN_DELETED =
      PlanEventType._(2, _omitEnumNames ? '' : 'PLAN_DELETED');

  static const $core.List<PlanEventType> values = <PlanEventType>[
    PLAN_ADDED,
    PLAN_UPDATED,
    PLAN_DELETED,
  ];

  static final $core.List<PlanEventType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static PlanEventType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PlanEventType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
