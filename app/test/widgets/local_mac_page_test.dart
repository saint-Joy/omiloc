import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:omi/backend/preferences.dart';
import 'package:omi/env/dev_env.dart';
import 'package:omi/env/env.dart';
import 'package:omi/l10n/app_localizations.dart';
import 'package:omi/pages/settings/local_mac_page.dart';
import 'package:omi/services/auth/local_mac_session.dart';
import 'package:omi/services/local_mac_discovery.dart';
import 'package:omi/utils/offline_network_policy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    Env.init(DevEnv());
    Env.setRuntimeModeForTesting(OmiRuntimeMode.offline);
  });
  tearDownAll(() => Env.setRuntimeModeForTesting(null));
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await SharedPreferencesUtil.init();
  });
  tearDown(() {
    Env.localTunnelConfigured = false;
    OfflineNetworkPolicy.resetForTesting();
  });

  testWidgets('pairing screen hides key and stops capture before connecting', (tester) async {
    final order = <String>[];
    final session = LocalMacSession(probe: (_, __) async {
      order.add('probe');
      return {'uid': 'alice'};
    });
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
          builder: (context) => Scaffold(
                  body: TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => LocalMacPage(
                          session: session,
                          stopRecording: () async {
                            order.add('stop');
                          },
                          refreshConnection: () async {},
                        ))),
                child: const Text('Open'),
              ))),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Локальный Mac'), findsOneWidget);
    final field = tester.widget<TextField>(find.byKey(const ValueKey('local-mac-key')));
    expect(field.obscureText, isTrue);
    await tester.enterText(find.byKey(const ValueKey('local-mac-address')), 'https://synthetic.ngrok.app');
    await tester.enterText(find.byKey(const ValueKey('local-mac-key')), List.filled(43, 's').join());
    await tester.tap(find.byKey(const ValueKey('local-mac-connect')));
    await tester.pumpAndSettle();
    expect(order, ['stop', 'probe']);
    expect(session.isSignedIn, isTrue);
    expect(find.text('Open'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bonjour discovery fills the address and offers found Macs', (tester) async {
    final session = LocalMacSession(probe: (_, __) async => {'uid': 'alice'});
    final scan = Stream.fromIterable(const [
      DiscoveredMac(name: 'omiloc', address: 'http://192.168.1.5:20000'),
      DiscoveredMac(name: 'omiloc', address: 'http://192.168.1.5:20000'),
      DiscoveredMac(name: 'studio', address: 'http://10.0.0.7:20000'),
    ]);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: LocalMacPage(session: session, scan: () => scan, stopRecording: () async {}),
    ));
    await tester.pumpAndSettle();
    // Duplicates collapse; the first find pre-fills the empty address field.
    expect(find.byKey(const ValueKey('local-mac-found-http://192.168.1.5:20000')), findsOneWidget);
    expect(find.byKey(const ValueKey('local-mac-found-http://10.0.0.7:20000')), findsOneWidget);
    final address = tester.widget<TextField>(find.byKey(const ValueKey('local-mac-address')));
    expect(address.controller!.text, 'http://192.168.1.5:20000');
    // Tapping another found Mac replaces the address.
    await tester.tap(find.byKey(const ValueKey('local-mac-found-http://10.0.0.7:20000')));
    await tester.pump();
    expect(address.controller!.text, 'http://10.0.0.7:20000');
  });
}
