import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final supabase = Supabase.instance.client;

  Future<String> uploadAttendancePhoto({
    required Uint8List bytes,
    required String fileName,
  }) async {
    await supabase.storage
        .from('attendance-photos')
        .uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(
            upsert: true,
          ),
        );

    return fileName;
  }

  /// Mengambil URL publik dari foto yang telah diupload
  String getPhotoUrl(String path) {
    return supabase.storage
        .from('attendance-photos')
        .getPublicUrl(path);
  }
}