import 'dart:async';
import 'package:flutter/material.dart';

import 'dialogs.dart';

abstract class UnifiedPushFunctions {
  Future<String?> getDistributor();
  Future<List<String>> getDistributors();
  Future<void> registerApp(String instance);
  Future<void> saveDistributor(String distributor);
}

class UnifiedPushUi {
  late BuildContext context;
  late List<String> instances;
  late UnifiedPushFunctions unifiedPushFunctions;

  /// Whether we show a dialog if there is no dialog, may be useful to show only
  /// once
  late bool showNoDistribDialog;

  /// The dialog when there is no distrib has been shown. May be useful to save
  /// the info to not show again in the future.
  late void Function() onNoDistribDialogDismissed;

  UnifiedPushUi({
    required this.context,
    required this.instances,
    required this.unifiedPushFunctions,
    required this.showNoDistribDialog,
    required this.onNoDistribDialogDismissed
  });

  static const noDistribAck = "noDistributorAck";

  Future<void> onNoDistributorFound() async {
    if (!context.mounted) return;
    if (showNoDistribDialog) {
      return showDialog(
          context: context,
          builder: noDistributorDialog(
              onDismissed: () async => onNoDistribDialogDismissed.call()
          )
      );
    }
  }

  Future<void> onDistributorSelected(String distributor) async {
    await unifiedPushFunctions.saveDistributor(distributor);
    for (var instance in instances) {
      await unifiedPushFunctions.registerApp(instance);
    }
  }

  Future<void> onManyDistributorFound(List<String> distributors) async {
    final picked = await showDialog<String>(
      context: context,
      builder: pickDistributorDialog(distributors),
    );
    if (picked != null) {
      await onDistributorSelected(picked);
    }
  }

  Future<void> registerAppWithDialog() async {
    var distributor = await unifiedPushFunctions.getDistributor();

    if (distributor != null) {
      for (var instance in instances) {
        await unifiedPushFunctions.registerApp(instance);
      }
    } else {
      final distributors = await unifiedPushFunctions.getDistributors();
      if (distributors.isEmpty) {
        await onNoDistributorFound();
      } else if (distributors.length == 1) {
        await onDistributorSelected(distributors.single);
      } else {
        await onManyDistributorFound(distributors);
      }
    }
  }
}
