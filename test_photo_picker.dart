import 'dart:io';
import 'package:file_picker/file_picker.dart';

void main() async {
  print("=== file_picker test ===");
  print("Platform: ${Platform.operatingSystem}");
  
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'],
    );
    
    if (result != null && result.files.isNotEmpty) {
      print("SUCCESS: Selected file: ${result.files.first.path}");
      print("File name: ${result.files.first.name}");
    } else {
      print("INFO: User cancelled or no file selected");
    }
  } catch (e) {
    print("ERROR: ${e.toString()}");
    print("Stack: ${StackTrace.current}");
  }
  
  print("=== test complete ===");
}
