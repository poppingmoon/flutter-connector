import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unifiedpush/unifiedpush.dart';
import 'package:unifiedpush_platform_interface/unifiedpush_platform_interface.dart';
import 'package:unifiedpush_storage_shared_preferences/storage.dart';
import 'package:unifiedpush_ui/unifiedpush_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'notification_utils.dart';

Future<void> main(List<String> args) async {
  debugPrint("main");
  for (var arg in args) {
    debugPrint(arg);
  }
  WidgetsFlutterBinding.ensureInitialized();
  UnifiedPushConnection().init(args.contains("--unifiedpush-bg"));
  if (!args.contains("--unifiedpush-bg")) {
    runApp(const MyApp());
    EasyLoading.instance.userInteractions = false;
  }
}

class UnifiedPushConnection {
  var bg = false;
  void _onUpdate() {
    controller.add("update");
  }

  void init(bool background) {
    bg = background;
    UnifiedPush.initialize(
      onNewEndpoint: onNewEndpoint,
      // takes (String endpoint, String instance) in args
      onRegistrationFailed: onRegistrationFailed,
      // takes (String instance)
      onUnregistered: onUnregistered,
      // takes (String instance)
      onMessage: onMessage,
      linuxOptions: LinuxOptions(
        dbusName: linuxAppName,
        storage: UnifiedPushStorageSharedPreferences(),
        background: background,
      ),
    ).then((registered) {
      if (registered) {
        UnifiedPush.register(instance: localInstance);
      }
    });
  }

  void onMessage(PushMessage message, String instance) {
    Future.wait([
      SharedPreferencesAsync().setInt(keyNPush, nPush + 1).then((_) {
        nPush++;
      }),
      if (bg) ...[
        SharedPreferencesAsync().setInt(keyNPushBg, nPushBg + 1).then((_) {
          nPushBg++;
        }),
      ],
      if (utf8.decode(message.content) == testNotif) ...[
        SharedPreferencesAsync().setBool(keyTestPushReceived, true).then((_) {
          testPushReceived = true;
        }),
      ],
    ]).then((_) {
      _onUpdate();
    });
    UPNotificationUtils.basicOnNotification(message, instance);
  }

  void onNewEndpoint(PushEndpoint nEndpoint, String instance) {
    if (instance != localInstance) {
      return;
    }
    endpoint = nEndpoint;
    debugPrint("New endpoint on $hashCode");
    debugPrint("Endpoint (temp=${nEndpoint.temporary}): ${nEndpoint.url}");
    debugPrint("To test: ${testPage(nEndpoint)}");
    _onUpdate();
  }

  void onUnregistered(String instance) {
    if (instance != localInstance) {
      return;
    }
    endpoint = null;
    debugPrint("unregistered");
    _onUpdate();
  }

  void onRegistrationFailed(FailedReason reason, String instance) {
    debugPrint("Registration failed: $reason");
    onUnregistered(instance);
  }
}

final controller = StreamController<String>.broadcast();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const localInstance = "myInstance";
// The Linux app name is used to register the application with DBus
// Because of this it needs to be a valid fully-qualified name
const linuxAppName = "org.unifiedpush.Troubleshooter";

PushEndpoint? endpoint;
var showNoDistribDialog = true;
String? distrib;
var distributors = [];
var testPushReceived = false;
var nPush = 0;
var nPushBg = 0;
const testNotif = "org.unifiedpush.TEST_NOTIF";
const keyNPush = "org.unifiedpush.key.nPush";
const keyNPushBg = "org.unifiedpush.key.nPushBg";
const keyTestPushReceived = "org.unifiedpush.key.testPushReceived";

class UPFunctions extends UnifiedPushFunctions {
  final List<String> features = [/*list of features*/];

  @override
  Future<String?> getDistributor() async {
    return await UnifiedPush.getDistributor();
  }

  @override
  Future<List<String>> getDistributors() async {
    return await UnifiedPush.getDistributors(features);
  }

  @override
  Future<void> registerApp(String instance) async {
    debugPrint("Calling registerApp");
    await UnifiedPush.register(instance: instance, features: features);
  }

  @override
  Future<void> saveDistributor(String distributor) async {
    await UnifiedPush.saveDistributor(distributor);
  }

  Future<void> unregister(String instance) async {
    await UnifiedPush.unregister(instance);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  @override
  void initState() {
    _isAndroidPermissionGranted().catchError((err) {
      debugPrint("Exception while granting permissions");
    });
    controller.stream.listen((_) => refresh());
    refresh();
    super.initState();
  }

  Future<void> _isAndroidPermissionGranted() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      await androidImplementation?.requestNotificationsPermission();
    }
  }

  void refresh() async {
    debugPrint("Refreshing values");
    distrib = (await UnifiedPush.getDistributor());
    if (distrib == null) {
      endpoint = null;
      await Future.wait([
        UnifiedPush.getDistributors().then((v) {
          distributors = v;
        }),
        SharedPreferencesAsync().remove(keyNPush).then((_) {
          nPush = 0;
        }),
        SharedPreferencesAsync().remove(keyNPushBg).then((_) {
          nPushBg = 0;
        }),
        SharedPreferencesAsync().remove(keyTestPushReceived).then((_) {
          testPushReceived = false;
        }),
      ]);
    } else {
      await Future.wait([
        UnifiedPush.getDistributors().then((v) {
          distributors = v;
        }),
        SharedPreferencesAsync().getInt(keyNPush).then((v) {
          nPush = v ?? 0;
        }),
        SharedPreferencesAsync().getInt(keyNPushBg).then((v) {
          nPushBg = v ?? 0;
        }),
        SharedPreferencesAsync().getBool(keyTestPushReceived).then((v) {
          testPushReceived = v ?? false;
        }),
      ]);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {HomePage.routeName: (context) => HomePage(refresh: refresh)},
      builder: EasyLoading.init(),
    );
  }
}

class HomePage extends StatefulWidget {
  static const routeName = '/';
  final VoidCallback refresh;

  const HomePage({required this.refresh, super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> notify() async {
    final e = endpoint;
    if (e == null) {
      debugPrint("Can't request unknown endpoint");
      return;
    }
    final resp = await http.post(
      Uri.parse(e.url),
      headers: {"content-encoding": "aes128gcm", "ttl": "5"},
      body: testNotif,
    );
    debugPrint("resp: ${resp.statusCode}");
  }

  void register() async {
    UnifiedPush.tryUseCurrentOrDefaultDistributor().then((success) {
      debugPrint("Current or Default found=$success");
      if (success) {
        UnifiedPush.register(instance: localInstance);
      } else {
        UnifiedPushUi(
          context: context,
          instances: [localInstance],
          unifiedPushFunctions: UPFunctions(),
          showNoDistribDialog: showNoDistribDialog,
          onNoDistribDialogDismissed: () {
            showNoDistribDialog = false;
          },
        ).registerAppWithDialog();
      }
    });
  }

  void showToast(BuildContext context, String text) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final up = UPFunctions();
    return Scaffold(
      appBar:
          Platform.isAndroid
              ? AppBar(title: const Text('Unifiedpush Troubleshooter'))
              : null,
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                label(context, "Visible Push Services"),
                if (distributors.isEmpty) ...[
                  detail("No service found", ""),
                  const SizedBox(height: 8),
                  cardList(
                    children: [
                      (
                        cardContent(
                          context,
                          CardData(label: "Refresh service list"),
                        ),
                        widget.refresh,
                      ),
                      (
                        cardContent(
                          context,
                          CardData(label: "Open UnifiedPush documentation"),
                        ),
                        () {
                          launchUrl(
                            Uri.parse(
                              "https://unifiedpush.org/users/distributors/",
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
                if (distributors.isNotEmpty) ...[
                  cardList(
                    children:
                        distributors.map((d) {
                          final selected = d == distrib;
                          return (
                            cardContent(
                              context,
                              CardData(
                                label: d,
                                desc:
                                    selected
                                        ? (endpoint == null
                                            ? "Connecting..."
                                            : "Connected")
                                        : null,
                                rightWidgets: [
                                  if (selected) ...[
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        elevation: 0,
                                        shadowColor: Colors.transparent,
                                      ),
                                      onPressed: () {
                                        up.unregister(localInstance).then((_) {
                                          widget.refresh();
                                        });
                                      },
                                      child: const Text('Disconnect'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            () {
                              up
                                  .unregister(localInstance)
                                  .then((_) {
                                    return widget.refresh();
                                  })
                                  .then((_) {
                                    return up.saveDistributor(d);
                                  })
                                  .then((_) {
                                    return UPFunctions().registerApp(
                                      localInstance,
                                    );
                                  })
                                  .then((_) {
                                    widget.refresh();
                                  });
                            },
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 8),
                  cardList(
                    children: [
                      (
                        cardContent(
                          context,
                          CardData(label: "Refresh service list"),
                        ),
                        widget.refresh,
                      ),
                      (
                        cardContent(
                          context,
                          CardData(
                            label: "Use default service",
                            desc: "Open a dialog without default",
                          ),
                        ),
                        register,
                      ),
                      (
                        cardContent(context, CardData(label: "Send test")),
                        endpoint == null ? null : notify,
                      ),
                      (
                        cardContent(
                          context,
                          CardData(
                            label: "Open test page",
                            rightWidgets: [
                              if (endpoint != null) ...[
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                  ),
                                  onPressed: () {
                                    final e = endpoint;
                                    if (e != null) {
                                      Clipboard.setData(
                                        ClipboardData(text: testPage(e)),
                                      );
                                      showToast(context, "URL Copied");
                                    }
                                  },
                                  child: const Text('Copy'),
                                ),
                              ],
                            ],
                          ),
                        ),
                        endpoint == null
                            ? null
                            : () {
                              final e = endpoint;
                              if (e != null) launchUrl(Uri.parse(testPage(e)));
                            },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  label(context, "Details"),
                  detail("Distributor", distrib ?? ""),
                  detail("Endpoint", endpoint?.url ?? ""),
                  detail("Test received", "$testPushReceived"),
                  detail("Push received", "$nPush"),
                  detail("From background", "$nPushBg"),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CardData {
  String label;
  String? desc;
  List<Widget> rightWidgets = [];
  CardData({required this.label, this.desc, this.rightWidgets = const []});
}

Widget cardContent(BuildContext context, CardData data) {
  return SizedBox(
    width: double.infinity,
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      children: [
        data.desc == null
            ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // compensate bodyMedium + SizedBox for desc = 14+4 = 18
                const SizedBox(height: 8),
                Text(
                  data.label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
              ],
            )
            : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  data.desc ?? "Error",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
              ],
            ),
        ...data.rightWidgets,
      ],
    ),
  );
}

Widget cardList({required List<(Widget, void Function()?)> children}) {
  return Column(
    children:
        children.asMap().entries.map((entry) {
          final i = entry.key;
          final v = entry.value;
          final isFirst = i == 0;
          final isLast = i == children.length - 1;
          return Opacity(
            opacity: v.$2 == null ? 0.4 : 1,
            child: Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: isFirst ? const Radius.circular(12) : Radius.zero,
                  bottom: isLast ? const Radius.circular(12) : Radius.zero,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: v.$2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: v.$1,
                ),
              ),
            ),
          );
        }).toList(),
  );
}

Widget detail(String label, String value) {
  return Row(
    children: [
      Expanded(
        flex: 10,
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
            label,
          ),
        ),
      ),
      const Expanded(flex: 1, child: Spacer()),
      Expanded(
        flex: 19,
        child: Text(maxLines: 2, overflow: TextOverflow.ellipsis, value),
      ),
    ],
  );
}

Widget label(BuildContext context, String data) {
  return Text(
    data,
    style: Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
  );
}

String testPage(PushEndpoint endpoint) {
  return "https://unifiedpush.org/test_wp.html#endpoint=${endpoint.url}&p256dh=${endpoint.pubKeySet?.pubKey}&auth=${endpoint.pubKeySet?.auth}";
}
