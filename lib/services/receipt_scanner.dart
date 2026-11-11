import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'receipt_parser.dart';

/// Reads a receipt photo with Google ML Kit's on-device text recognition
/// (free, works offline; Android and iOS only) and parses it.
class ReceiptScanner {
  static Future<ReceiptData> scan(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(imagePath));
      return ReceiptParser.parse(result.text);
    } finally {
      await recognizer.close();
    }
  }
}
