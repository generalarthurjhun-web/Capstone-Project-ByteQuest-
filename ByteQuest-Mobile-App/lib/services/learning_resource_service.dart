import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/learning_resource_model.dart';

class LearningResourceService {
  LearningResourceService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<LearningResource>> getAssignedResources() async {
    final rows = await _client
        .from('learning_resources')
        .select(
          'id,class_id,title,description,storage_bucket,storage_path,mime_type,size_bytes,created_at,classes(title)',
        )
        .eq('status', 'active')
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => LearningResource.fromMap(
              Map<String, dynamic>.from(row as Map),
            ))
        .toList(growable: false);
  }

  Future<void> openResource(LearningResource resource) async {
    final signedUrl = await createSignedUrl(resource);
    await openSignedUrl(signedUrl);
  }

  Future<String> createSignedUrl(
    LearningResource resource, {
    int expiresInSeconds = 300,
  }) async {
    return _client.storage
        .from(resource.storageBucket)
        .createSignedUrl(resource.storagePath, expiresInSeconds);
  }

  Future<String> loadTextResource(LearningResource resource) async {
    final signedUrl = await createSignedUrl(resource);
    return NetworkAssetBundle(Uri.parse(signedUrl)).loadString('');
  }

  Future<void> openSignedUrl(String signedUrl) async {
    final uri = Uri.parse(signedUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      throw StateError('The resource could not be opened on this device.');
    }
  }
}
