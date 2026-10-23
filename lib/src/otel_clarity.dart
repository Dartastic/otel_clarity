// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_clarity_suppression.dart';

const _tracerName = 'dartastic_otel_libs_clarity';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

class ClarityResult {
  /// Creates a result.
  const ClarityResult({
    this.projectId,
    this.sessionId,
    this.userId,
    this.eventName,
    this.tagKey,
    this.tagValue,
    this.maskingMode,
    this.priorityCallEnabled,
    this.maskedAttributeCount,
    this.deadClicksDetected,
    this.rageClicksDetected,
    this.excessiveScroll,
    this.recordingPaused,
    this.crashDetected,
    this.statusCode,
  });

  /// Clarity project id (`xxxxxxxxxx`).
  final String? projectId;

  /// Stable Clarity session id.
  final String? sessionId;

  /// Custom user id (`setCustomUserId`).
  final String? userId;

  /// `setCustomTag` event name.
  final String? eventName;

  final String? tagKey;
  final String? tagValue;

  /// `Strict` (default), `Balanced`, `Relaxed`.
  final String? maskingMode;

  /// Session prioritized for upload (`setPriorityCallEnabled(true)`).
  final bool? priorityCallEnabled;

  /// Count of fields masked by the SDK in the current event.
  final int? maskedAttributeCount;

  /// Smart-event signals.
  final bool? deadClicksDetected;
  final bool? rageClicksDetected;
  final bool? excessiveScroll;

  final bool? recordingPaused;

  /// Clarity recorded a crash in the current session.
  final bool? crashDetected;

  final int? statusCode;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class ClarityCallResult<T> {
  /// Creates a call result.
  const ClarityCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final ClarityResult? result;
}

/// Wraps a Microsoft Clarity SDK call in a CLIENT span. [operation] is
/// one of `initialize`, `pause`, `resume`, `setCustomUserId`,
/// `setCustomSessionId`, `setCustomTag`, `setMaskingMode`,
/// `setPriorityCallEnabled`, `getCurrentSessionUrl`, `maskView`,
/// `unmaskView`, `signalCrash`.
Future<T> tracedClarity<T>({
  required String operation,
  required Future<ClarityCallResult<T>> Function() invoke,
}) async {
  if (clarityInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'clarity',
    'rpc.method': operation,
    'clarity.operation': operation,
  };

  final span = _tracer().startSpan(
    'clarity $operation',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final res = r.result!;
      final extras = <Attribute<Object>>[];
      if (res.projectId != null) {
        extras
            .add(OTelAPI.attributeString('clarity.project.id', res.projectId!));
      }
      if (res.sessionId != null) {
        extras
            .add(OTelAPI.attributeString('clarity.session.id', res.sessionId!));
      }
      if (res.userId != null) {
        extras.add(OTelAPI.attributeString('clarity.user.id', res.userId!));
      }
      if (res.eventName != null) {
        extras
            .add(OTelAPI.attributeString('clarity.event.name', res.eventName!));
      }
      if (res.tagKey != null) {
        extras.add(OTelAPI.attributeString('clarity.tag.key', res.tagKey!));
      }
      if (res.tagValue != null) {
        extras.add(OTelAPI.attributeString('clarity.tag.value', res.tagValue!));
      }
      if (res.maskingMode != null) {
        extras.add(OTelAPI.attributeString(
          'clarity.masking.mode',
          res.maskingMode!,
        ));
      }
      if (res.priorityCallEnabled != null) {
        extras.add(OTelAPI.attributeBool(
          'clarity.priority_call.enabled',
          res.priorityCallEnabled!,
        ));
      }
      if (res.maskedAttributeCount != null) {
        extras.add(OTelAPI.attributeInt(
          'clarity.masked_attribute.count',
          res.maskedAttributeCount!,
        ));
      }
      if (res.deadClicksDetected != null) {
        extras.add(OTelAPI.attributeBool(
          'clarity.smart_event.dead_clicks',
          res.deadClicksDetected!,
        ));
      }
      if (res.rageClicksDetected != null) {
        extras.add(OTelAPI.attributeBool(
          'clarity.smart_event.rage_clicks',
          res.rageClicksDetected!,
        ));
      }
      if (res.excessiveScroll != null) {
        extras.add(OTelAPI.attributeBool(
          'clarity.smart_event.excessive_scroll',
          res.excessiveScroll!,
        ));
      }
      if (res.recordingPaused != null) {
        extras.add(OTelAPI.attributeBool(
          'clarity.recording.paused',
          res.recordingPaused!,
        ));
      }
      if (res.crashDetected != null) {
        extras.add(OTelAPI.attributeBool(
          'clarity.crash.detected',
          res.crashDetected!,
        ));
        if (res.crashDetected!) {
          span.setStatus(SpanStatusCode.Error, 'Clarity crash signaled');
        }
      }
      if (res.statusCode != null) {
        extras.add(OTelAPI.attributeInt(
          'http.response.status_code',
          res.statusCode!,
        ));
        if (res.statusCode! >= 400) {
          span.setStatus(
              SpanStatusCode.Error, 'Clarity HTTP ${res.statusCode}');
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTelAPI.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
