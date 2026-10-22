import 'package:atrapa_rules/atrapa_rules.dart';
import 'package:flutter/material.dart';

import 'play/play_screen.dart';
import 'policy/local_policy.dart';
import 'policy/policy_loader.dart';

/// Readiness adapter only: all observations and movement remain in rules core.
class PolicyPlayScreen extends StatefulWidget {
  const PolicyPlayScreen({super.key});

  @override
  State<PolicyPlayScreen> createState() => _PolicyPlayScreenState();
}

class _PolicyPlayScreenState extends State<PolicyPlayScreen> {
  PolicyLoadResult? _result;
  final List<int> _samples = [];
  bool _evaluationFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    const name = String.fromEnvironment(
      'ATRAPA_POLICY',
      defaultValue: 'default',
    );
    final result = await PolicyLoader.load(
      assetDirectory: 'assets/policies/$name',
      expectedObservationSchema: observationSchema,
      expectedActions: policyActions,
      expectedRulesSchemaVersion: rulesSchemaVersion,
      expectedInputSize: observationSize,
    );
    if (!result.isReady) {
      debugPrint(result.error);
    }
    if (mounted) setState(() => _result = result);
  }

  Heading _choose(LocalPolicy policy, RulesMatch match, int id) {
    if (_evaluationFailed) {
      return const FreeSpaceBot().chooseDirection(match, id);
    }
    final watch = Stopwatch()..start();
    try {
      final decision = policy.evaluate(encodeObservation(match, id));
      final heading = match.snakes
          .firstWhere((snake) => snake.id == id)
          .heading;
      return switch (decision.actionId) {
        'left' => Heading.values[(heading.index + 3) % 4],
        'right' => Heading.values[(heading.index + 1) % 4],
        _ => heading,
      };
    } catch (error) {
      // A failed output never bypasses the authoritative interpreter.
      _evaluationFailed = true;
      debugPrint('Policy failed; baseline used: $error');
      Future.microtask(() {
        if (mounted) {
          setState(() => _result = PolicyLoadResult.fallback(error.toString()));
        }
      });
      return const FreeSpaceBot().chooseDirection(match, id);
    } finally {
      _samples.add(watch.elapsedMicroseconds);
      if (_samples.length == 60) {
        final ordered = [..._samples]..sort();
        debugPrint(
          'Atrapa policy ${policy.modelId}: n=60, p95=${ordered[56]} us/decision',
        );
        _samples.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final policy = _result?.policy;
    return PlayScreen(
      decide: policy == null ? null : (match, id) => _choose(policy, match, id),
      policyLabel: policy == null
          ? 'Baseline opponents'
          : 'Policy ${policy.modelId}',
      policyDetail: _result == null
          ? 'Checking local policy bundle…'
          : policy == null
          ? 'No compatible policy bundle loaded.'
          : 'Local Dart inference · ${policy.inputSize} inputs',
    );
  }
}
