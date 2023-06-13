import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart';

import 'wpp/qrcode/text_to_qrcode.dart';
import 'wpp/wpp_auth.dart';
import 'wpp/wpp_client_desktop.dart';
import 'wpp/wpp_connect.dart';
import 'wpp/wpp_interface.dart';

class WhatsAppMetadata {
  static String whatsAppURL = "https://web.whatsapp.com/";
  static String userAgent =
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/64.0.3282.39 Safari/537.36';
}

Browser? browser;

Future<bool> _waitForInChat(WpClientInterface wpClient) async {
  var inChat = await WppAuth(wpClient).isMainReady();
  if (inChat) return true;
  Completer<bool> completer = Completer();
  late Timer timer;
  WppAuth wppAuth = WppAuth(wpClient);
  timer = Timer.periodic(const Duration(seconds: 1), (self) async {
    if (self.tick > 60) {
      timer.cancel();
      if (!completer.isCompleted) completer.complete(false);
    } else {
      bool inChat = await wppAuth.isMainReady();
      if (inChat && !completer.isCompleted) {
        timer.cancel();
        completer.complete(true);
      }
    }
  });
  return completer.future;
}

void main(List<String> args) async {
  late WpClientInterface wpClient;

  try {
    Logger.root
      ..level = Level.ALL
      ..onRecord.listen(print);

    print("Starting chrome");
    var revisionInfo = await downloadChrome(cachePath: ".local-chromium");
    String executablePath = revisionInfo.executablePath;
    print("Opening browser");
    browser = await puppeteer.launch(
      headless: true,
      executablePath: executablePath,
      args: ['--remote-allow-origins=*'],
      userDataDir: p.join(
        Directory.current.path,
        '.local-chromium/session',
      ),
    );

    print("browserWsEndpoint : ${browser?.wsEndpoint}");

    Page page = await browser!.newPage();
    await page.setUserAgent(WhatsAppMetadata.userAgent);
    await page.goto(WhatsAppMetadata.whatsAppURL);

    wpClient = WpClientDesktop(page: page, browser: browser);

    await WppConnect.init(wpClient);

    final authenticated = await WppAuth(wpClient).isAuthenticated();
    if (!authenticated) {
      final qrcode = await wpClient.getQrCode();

      String? urlCode;
      if (qrcode != null && qrcode.urlCode != null) {
        urlCode = qrcode.urlCode;
      }

      final image = convertStringToQrCode(urlCode!);
      print(image);
    }

    final inChat = await _waitForInChat(wpClient);

    if (!inChat) {
      print('Phone not connected');
      throw 'Phone not connected';
    }

    print('All connected');
  } catch (err) {
    wpClient.dispose();
  }
}
