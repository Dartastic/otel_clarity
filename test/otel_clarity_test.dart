// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_clarity/otel_clarity.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_clarity-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('setCustomTag records project + tag + masking', () async {
    await tracedClarity<String>(
      operation: 'setCustomTag',
      invoke: () async => const ClarityCallResult(
        value: 'ok',
        result: ClarityResult(
          projectId: 'clr_1',
          sessionId: 'sess_1',
          eventName: 'plan_change',
          tagKey: 'plan',
          tagValue: 'pro_annual',
          maskingMode: 'Balanced',
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('clarity setCustomTag')!);
    expect(a['clarity.tag.key'], 'plan');
    expect(a['clarity.masking.mode'], 'Balanced');
  });

  test('signalCrash sets span error', () async {
    await tracedClarity<String>(
      operation: 'signalCrash',
      invoke: () async => const ClarityCallResult(
        value: 'ok',
        result: ClarityResult(crashDetected: true),
      ),
    );
    expect(
      spans.findSpanByName('clarity signalCrash')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutClarityInstrumentationAsync(() async {
      await tracedClarity<String>(
        operation: 'pause',
        invoke: () async => const ClarityCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('clarity '), isEmpty);
  });
}
