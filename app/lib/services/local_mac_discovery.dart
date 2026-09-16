import 'dart:async';

import 'package:nsd/nsd.dart' as nsd;

/// One Mac found on the local network advertising the omiloc backend.
class DiscoveredMac {
  const DiscoveredMac({required this.name, required this.address});

  /// Bonjour instance name, e.g. "omiloc".
  final String name;

  /// Pairing address in the form accepted by the Local Mac page.
  final String address;
}

/// Emits Macs advertising `_omiloc._tcp` until the subscription is cancelled.
typedef LocalMacScan = Stream<DiscoveredMac> Function();

Stream<DiscoveredMac> discoverLocalMacs() {
  late final StreamController<DiscoveredMac> controller;
  nsd.Discovery? discovery;

  Future<void> start() async {
    discovery = await nsd.startDiscovery('_omiloc._tcp', ipLookupType: nsd.IpLookupType.v4);
    discovery!.addServiceListener((service, status) {
      if (status != nsd.ServiceStatus.found || controller.isClosed) return;
      final port = service.port;
      final host = service.addresses
          ?.map((address) => address.address)
          .firstWhere((address) => address.isNotEmpty, orElse: () => '');
      if (port == null || host == null || host.isEmpty) return;
      controller.add(DiscoveredMac(name: service.name ?? 'omiloc', address: 'http://$host:$port'));
    });
  }

  Future<void> stop() async {
    final active = discovery;
    discovery = null;
    if (active != null) await nsd.stopDiscovery(active);
  }

  controller = StreamController<DiscoveredMac>(
    onListen: () => start().catchError((Object error) {
      if (!controller.isClosed) controller.addError(error);
    }),
    onCancel: stop,
  );
  return controller.stream;
}
