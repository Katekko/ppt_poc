import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart';

import 'wpp/qrcode/text_to_qrcode.dart';
import 'wpp/wpp_client_desktop.dart';
import 'wpp/wpp_connect.dart';
import 'wpp/wpp_interface.dart';

class WhatsAppMetadata {
  static String whatsAppURL = "https://web.whatsapp.com/";
  static String userAgent =
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/64.0.3282.39 Safari/537.36';
}

Browser? browser;

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

    final qrcode = await wpClient.getQrCode();

    String? urlCode;
    // ignore: unused_local_variable
    Uint8List? imageBytes;
    if (qrcode != null &&
        qrcode.base64Image != null &&
        qrcode.urlCode != null) {
      try {
        final base64Image =
            qrcode.base64Image?.replaceFirst("data:image/png;base64,", "");
        imageBytes = base64Decode(base64Image!);
      } catch (e) {
        print(e);
      }

      urlCode = qrcode.urlCode!;
    }

    final image = convertStringToQrCode(urlCode!);
    print(image);
  } catch (err) {
    wpClient.dispose();
  }
}
