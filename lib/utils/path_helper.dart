// utils/path_helper.dart for handling database paths across platforms
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:path_provider/path_provider.dart'; // Add to pubspec.yaml

class PathHelper {
  static Future<String> getDatabasesPath() async {
    // For mobile platforms
    if (Platform.isAndroid || Platform.isIOS) {
      // Use the original method
      final databasesPath = await getDatabasesPath();
      return databasesPath;
    }
    
    // For desktop platforms (Windows/Linux/Mac)
    final Directory documentsDir = await getApplicationDocumentsDirectory();
    final String appDir = p.join(documentsDir.path, 'CS_Exit_Exam', 'databases');
    
    // Create directory if it doesn't exist
    final dir = Directory(appDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    return appDir;
  }
}