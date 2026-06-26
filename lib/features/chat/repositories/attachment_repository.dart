import 'package:flutter/services.dart';

import '../models/chat_attachment.dart';

abstract class AttachmentRepository {
  Future<DocumentAttachment?> pickDocument();
  Future<ImageAttachment?> pickImage();
  Future<ContactAttachment?> pickContact();
  Future<LocationAttachment?> pickCurrentLocation();
  Future<void> startAudioRecording();
  Future<AudioAttachment?> stopAudioRecording();
}

class PlatformAttachmentRepository implements AttachmentRepository {
  PlatformAttachmentRepository({
    MethodChannel channel = const MethodChannel('afapay/attachments'),
  }) : _channel = channel;

  final MethodChannel _channel;

  @override
  Future<DocumentAttachment?> pickDocument() async {
    final result = await _channel.invokeMapMethod<String, Object?>(
      'pickDocument',
    );
    if (result == null) return null;
    return DocumentAttachment(
      uri: _string(result['uri']),
      fileName: _string(result['fileName'], fallback: 'Document'),
      fileSizeBytes: _int(result['fileSizeBytes']),
      mimeType: _string(
        result['mimeType'],
        fallback: 'application/octet-stream',
      ),
      cachePath: _nullableString(result['cachePath']),
    );
  }

  @override
  Future<ImageAttachment?> pickImage() async {
    final result = await _channel.invokeMapMethod<String, Object?>('pickImage');
    if (result == null) return null;
    return ImageAttachment(
      uri: _string(result['uri']),
      fileSizeBytes: _int(result['fileSizeBytes']),
      width: _int(result['width']),
      height: _int(result['height']),
      fileName: _nullableString(result['fileName']),
      mimeType: _nullableString(result['mimeType']),
      cachePath: _nullableString(result['cachePath']),
    );
  }

  @override
  Future<ContactAttachment?> pickContact() async {
    final result = await _channel.invokeMapMethod<String, Object?>(
      'pickContact',
    );
    if (result == null) return null;
    return ContactAttachment(
      name: _string(result['name'], fallback: 'Contact'),
      phoneNumber: _string(result['phoneNumber']),
    );
  }

  @override
  Future<LocationAttachment?> pickCurrentLocation() async {
    final result = await _channel.invokeMapMethod<String, Object?>(
      'pickCurrentLocation',
    );
    if (result == null) return null;
    return LocationAttachment(
      latitude: _double(result['latitude']),
      longitude: _double(result['longitude']),
    );
  }

  @override
  Future<void> startAudioRecording() {
    return _channel.invokeMethod<void>('startAudioRecording');
  }

  @override
  Future<AudioAttachment?> stopAudioRecording() async {
    final result = await _channel.invokeMapMethod<String, Object?>(
      'stopAudioRecording',
    );
    if (result == null) return null;
    return AudioAttachment(
      uri: _string(result['uri']),
      path: _string(result['path']),
      durationMs: _int(result['durationMs']),
      fileSizeBytes: _int(result['fileSizeBytes']),
      mimeType: _string(result['mimeType'], fallback: 'audio/mp4'),
    );
  }
}

class UploadDocumentUseCase {
  const UploadDocumentUseCase();

  Future<void> call(DocumentAttachment attachment) {
    return Future.error(
      UnimplementedError('Document upload is not wired yet.'),
    );
  }
}

class UploadImageUseCase {
  const UploadImageUseCase();

  Future<void> call(ImageAttachment attachment) {
    return Future.error(UnimplementedError('Image upload is not wired yet.'));
  }
}

class UploadAudioUseCase {
  const UploadAudioUseCase();

  Future<void> call(AudioAttachment attachment) {
    return Future.error(UnimplementedError('Audio upload is not wired yet.'));
  }
}

String _string(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

String? _nullableString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _double(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
