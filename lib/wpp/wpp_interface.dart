import 'qrcode/qr_code_image.dart';

typedef OnNewEventFromListener = Function(String eventName, dynamic eventData);

abstract class WpClientInterface {
  Future injectJs(String content);

  Future<dynamic> evaluateJs(
    String source, {
    String? methodName,
    bool tryPromise,
  });

  Future<void> dispose();

  bool isConnected();

  Future initializeEventListener(OnNewEventFromListener onNewEventFromListener);

  Future<QrCodeImage?> getQrCode();
}
