import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/learner_ui.dart';
import '../../models/learning_resource_model.dart';
import '../../services/learning_resource_service.dart';

class ResourceViewerScreen extends StatefulWidget {
  final LearningResource resource;
  final LearningResourceService service;

  ResourceViewerScreen({
    super.key,
    required this.resource,
    LearningResourceService? service,
  }) : service = service ?? LearningResourceService();

  @override
  State<ResourceViewerScreen> createState() => _ResourceViewerScreenState();
}

class _ResourceViewerScreenState extends State<ResourceViewerScreen> {
  late Future<_ResourceViewData> _load;
  bool _openingExternal = false;

  @override
  void initState() {
    super.initState();
    _load = _loadResource();
  }

  Future<_ResourceViewData> _loadResource() async {
    final type = _ResourceKind.fromMime(widget.resource.mimeType);
    if (type == _ResourceKind.text) {
      final text = await widget.service.loadTextResource(widget.resource);
      return _ResourceViewData(kind: type, text: text);
    }
    final signedUrl = await widget.service.createSignedUrl(widget.resource);
    return _ResourceViewData(kind: type, signedUrl: signedUrl);
  }

  Future<void> _openExternal(String signedUrl) async {
    setState(() => _openingExternal = true);
    try {
      await widget.service.openSignedUrl(signedUrl);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This resource could not be opened on this device.'),
        ),
      );
      debugPrint('External resource open failed: $error');
    } finally {
      if (mounted) setState(() => _openingExternal = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resource = widget.resource;
    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      body: SafeArea(
        child: FutureBuilder<_ResourceViewData>(
          future: _load,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LearnerLoadingView(label: 'Loading resource');
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Column(
                children: [
                  LearnerPageHeader(
                    title: 'Resource unavailable',
                    subtitle: resource.classTitle,
                    trailing: _closeButton(context),
                  ),
                  Expanded(
                    child: LearnerStateView(
                      icon: Icons.cloud_off_outlined,
                      title: 'Resource could not be loaded',
                      message:
                          'Check your connection and confirm that this class file is still available.',
                      actionLabel: 'Try again',
                      onAction: () => setState(() => _load = _loadResource()),
                    ),
                  ),
                ],
              );
            }

            final data = snapshot.data!;
            return Column(
              children: [
                LearnerPageHeader(
                  title: resource.title,
                  subtitle: _subtitle(resource),
                  trailing: _closeButton(context),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: _viewerFor(data),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _viewerFor(_ResourceViewData data) {
    switch (data.kind) {
      case _ResourceKind.image:
        return _ImageViewer(
          signedUrl: data.signedUrl!,
          resource: widget.resource,
        );
      case _ResourceKind.text:
        return _TextViewer(text: data.text ?? '');
      case _ResourceKind.pdf:
        return _ExternalViewerPrompt(
          icon: Icons.picture_as_pdf_outlined,
          title: 'PDF resource',
          message:
              'Open this authorized class PDF in a viewer installed on your device.',
          actionLabel: 'Open PDF',
          signedUrl: data.signedUrl!,
          opening: _openingExternal,
          onOpen: _openExternal,
        );
      case _ResourceKind.video:
        return _ExternalViewerPrompt(
          icon: Icons.play_circle_outline_rounded,
          title: 'Video resource',
          message:
              'Open this authorized class video in a player installed on your device.',
          actionLabel: 'Open video',
          signedUrl: data.signedUrl!,
          opening: _openingExternal,
          onOpen: _openExternal,
        );
      case _ResourceKind.unsupported:
        return _ExternalViewerPrompt(
          icon: Icons.insert_drive_file_outlined,
          title: 'Unsupported preview type',
          message:
              'ByteQuest cannot preview this file type in-app yet. You can still open the authorized file with a compatible app.',
          actionLabel: 'Open file',
          signedUrl: data.signedUrl!,
          opening: _openingExternal,
          onOpen: _openExternal,
        );
    }
  }

  Widget _closeButton(BuildContext context) => IconButton.filledTonal(
        onPressed: () => Navigator.pop(context),
        tooltip: 'Close resource',
        icon: const Icon(Icons.close_rounded),
      );

  String _subtitle(LearningResource resource) {
    final type = resource.mimeType ?? 'Learning resource';
    final size =
        resource.sizeBytes == null ? null : _formatBytes(resource.sizeBytes!);
    return [
      resource.classTitle,
      type,
      if (size != null) size,
    ].join(' - ');
  }
}

class _ImageViewer extends StatelessWidget {
  final String signedUrl;
  final LearningResource resource;

  const _ImageViewer({
    required this.signedUrl,
    required this.resource,
  });

  @override
  Widget build(BuildContext context) => LearnerSurface(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: AppTheme.radiusLg,
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: Semantics(
              label: 'Image resource ${resource.title}',
              image: true,
              child: Image.network(
                signedUrl,
                width: double.infinity,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    height: 320,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: 320,
                  child: LearnerStateView(
                    icon: Icons.broken_image_outlined,
                    title: 'Image could not be previewed',
                    message: 'Try again or open the file with another viewer.',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _TextViewer extends StatelessWidget {
  final String text;

  const _TextViewer({required this.text});

  @override
  Widget build(BuildContext context) => LearnerSurface(
        child: SingleChildScrollView(
          child: SelectableText(
            text.trim().isEmpty ? 'This text resource is empty.' : text,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textDark,
              height: 1.55,
            ),
          ),
        ),
      );
}

class _ExternalViewerPrompt extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final String signedUrl;
  final bool opening;
  final Future<void> Function(String signedUrl) onOpen;

  const _ExternalViewerPrompt({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.signedUrl,
    required this.opening,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) => LearnerSurface(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.backgroundPaleBlue,
                borderRadius: AppTheme.radiusLg,
              ),
              child: Icon(icon, color: AppTheme.primaryBlue, size: 32),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: AppTheme.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: opening ? null : () => onOpen(signedUrl),
                icon: opening
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.open_in_new_rounded),
                label: Text(opening ? 'Opening...' : actionLabel),
              ),
            ),
          ],
        ),
      );
}

enum _ResourceKind {
  image,
  text,
  pdf,
  video,
  unsupported;

  static _ResourceKind fromMime(String? mimeType) {
    final normalized = mimeType?.toLowerCase() ?? '';
    if (normalized.startsWith('image/')) return _ResourceKind.image;
    if (normalized == 'application/pdf') return _ResourceKind.pdf;
    if (normalized.startsWith('video/')) return _ResourceKind.video;
    if (normalized.startsWith('text/') ||
        normalized == 'application/json' ||
        normalized == 'application/xml') {
      return _ResourceKind.text;
    }
    return _ResourceKind.unsupported;
  }
}

class _ResourceViewData {
  final _ResourceKind kind;
  final String? signedUrl;
  final String? text;

  const _ResourceViewData({
    required this.kind,
    this.signedUrl,
    this.text,
  });
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
  final mb = kb / 1024;
  if (mb < 1024) return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
  final gb = mb / 1024;
  return '${gb.toStringAsFixed(gb < 10 ? 1 : 0)} GB';
}
