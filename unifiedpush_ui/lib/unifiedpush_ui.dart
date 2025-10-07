import 'dart:async';
import 'package:flutter/material.dart';
import 'package:unifiedpush_storage_interface/storage.dart';

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
  late UnifiedPushStorage storage;

  UnifiedPushUi(
      this.context, this.instances, this.unifiedPushFunctions, this.storage);

  static const noDistribAck = "noDistributorAck";

  Future<void> onNoDistributorFound() async {
    if (!context.mounted) return;
    if (!(await storage.getBool(noDistribAck) ?? false)) {
      return showDialog(
          context: context,
          builder: noDistributorDialog(onDismissed: () async {
            await storage.setBool(noDistribAck, true);
          }));
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

  Future<void> removeNoDistributorDialogACK() async {
    await storage.remove(noDistribAck);
  }
}
