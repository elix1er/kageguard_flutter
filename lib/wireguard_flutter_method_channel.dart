import 'package:flutter/services.dart';
import 'dart:convert';
import 'model/stats.dart';
import 'wireguard_flutter_platform_interface.dart';

class WireGuardFlutterMethodChannel extends WireGuardFlutterInterface {
  static const _methodChannelVpnControl = "com.kageguard.flutter/wgcontrol";
  static const _methodChannel = MethodChannel(_methodChannelVpnControl);
  static const _eventChannelVpnStage = 'com.kageguard.flutter/wgstage';
  static const _eventChannel = EventChannel(_eventChannelVpnStage);

  @override
  Stream<VpnStage> get vpnStageSnapshot => _eventChannel.receiveBroadcastStream().map(
        (event) => event == VpnStage.denied.code
            ? VpnStage.disconnected
            : VpnStage.values.firstWhere(
                (stage) => stage.code == event,
                orElse: () => VpnStage.noConnection,
              ),
      );

  @override
  Future<void> initialize({required String interfaceName}) {
    return _methodChannel.invokeMethod("initialize", {
      "localizedDescription": interfaceName,
      "win32ServiceName": interfaceName,
    });
  }

  @override
  Future<void> startVpn({
    required String serverAddress,
    required String wgQuickConfig,
    required String providerBundleIdentifier,
  }) async {
    return _methodChannel.invokeMethod("start", {
      "serverAddress": serverAddress,
      "wgQuickConfig": wgQuickConfig,
      "providerBundleIdentifier": providerBundleIdentifier,
    });
  }

  @override
  Future<void> stopVpn() => _methodChannel.invokeMethod('stop');

  @override
  Future<void> refreshStage() => _methodChannel.invokeMethod("refresh");

  @override
  Future<VpnStage> stage() => _methodChannel.invokeMethod("stage").then(
        (value) => value != null
            ? VpnStage.values.firstWhere(
                (stage) => stage.code == value.toString(),
                orElse: () => VpnStage.disconnected,
              )
            : VpnStage.disconnected,
      );

  @override
  Future<Stats?> getStats() async {
    try {
      final result = await _methodChannel.invokeMethod('getStats');
      if (result != "") {
        final jsonDecoded = jsonDecode(result);
        final stats = Stats.fromJson(jsonDecoded);
        return stats;
      } else {
        return null;
      }
    } on Exception catch (e) {
      print("exception when trying to get stats ${e}");
      return null;
    }
  }
}
