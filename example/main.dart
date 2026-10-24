// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_clarity/otel_clarity.dart';

/// Traces Microsoft Clarity calls with OpenTelemetry.
///
/// `otel_clarity` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Microsoft Clarity call in
/// [tracedClarity]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'clarity-example');

  // Wraps a Microsoft Clarity SDK call in a CLIENT span.
  final clarityId = await tracedClarity<String>(
    operation: 'create',
    invoke: () async {
      // Make the Microsoft Clarity call here, then report what it returned.
      const id = 'clarity_8f3a2c';
      return const ClarityCallResult(
          value: id,
          result: ClarityResult(
              projectId: '3Mtw8f3a2c3Mtw8f3a2c3Mtw8f3a2cx',
              sessionId: 'session_8f3a2c',
              userId: 'setCustomUserId',
              eventName: 'setCustomTag',
              tagKey: 'orders/2026/inv-1042.pdf',
              tagValue: 'example',
              maskingMode: 'Strict',
              priorityCallEnabled: true,
              maskedAttributeCount: 3,
              deadClicksDetected: true,
              rageClicksDetected: true,
              excessiveScroll: true,
              recordingPaused: true,
              crashDetected: true,
              statusCode: 201));
    },
  );
  OTelLog.info('tracedClarity create returned $clarityId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutClarityInstrumentationAsync.
  await runWithoutClarityInstrumentationAsync(
    () => tracedClarity<String>(
      operation: 'create',
      invoke: () async {
        const id = 'clarity_8f3a2c';
        return const ClarityCallResult(
            value: id,
            result: ClarityResult(
                projectId: '3Mtw8f3a2c3Mtw8f3a2c3Mtw8f3a2cx',
                sessionId: 'session_8f3a2c',
                userId: 'setCustomUserId',
                eventName: 'setCustomTag',
                tagKey: 'orders/2026/inv-1042.pdf',
                tagValue: 'example',
                maskingMode: 'Strict',
                priorityCallEnabled: true,
                maskedAttributeCount: 3,
                deadClicksDetected: true,
                rageClicksDetected: true,
                excessiveScroll: true,
                recordingPaused: true,
                crashDetected: true,
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
