import 'package:zxing2/qrcode.dart';

String convertStringToQrCode(String text) {
  var qrCode = Encoder.encode(text, ErrorCorrectionLevel.l);
  var matrix = qrCode.matrix!;
  var stringBuffer = StringBuffer();
  for (var y = 0; y < matrix.height; y += 2) {
    for (var x = 0; x < matrix.width; x++) {
      final y1 = matrix.get(x, y) == 1;
      final y2 = (y + 1 < matrix.height) ? matrix.get(x, y + 1) == 1 : false;

      if (y1 && y2) {
        stringBuffer.write('█');
      } else if (y1) {
        stringBuffer.write('▀');
      } else if (y2) {
        stringBuffer.write('▄');
      } else {
        stringBuffer.write(' ');
      }
    }
    stringBuffer.writeln();
  }
  return stringBuffer.toString();
}
