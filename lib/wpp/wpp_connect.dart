import 'wpp_interface.dart';
import 'package:http/http.dart' as http;

class WppConnect {
  static Future init(WpClientInterface wpClient) async {
    final latestBuildUrl =
        "https://github.com/wppconnect-team/wa-js/releases/latest/download/wppconnect-wa.js";
    final content = await http.read(Uri.parse(latestBuildUrl));
    await wpClient.injectJs(content);

    var result = await wpClient.evaluateJs(
      '''typeof window.WPP !== 'undefined' && window.WPP.isReady;''',
      tryPromise: false,
    );

    if (result == false) {
      throw Exception("Failed to initialize WPP");
    }

    await wpClient.evaluateJs(
      "WPP.chat.defaultSendMessageOptions.createChat = true;",
      tryPromise: false,
    );
    await wpClient.evaluateJs(
      "WPP.conn.setKeepAlive(true);",
      tryPromise: false,
    );
    await wpClient.evaluateJs(
      "WPP.config.poweredBy = 'Whatsapp-Bot-Flutter';",
      tryPromise: false,
    );
  }
}
