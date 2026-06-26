import 'dart:io';

import 'package:flutter/foundation.dart';

sealed class AttachmentType {
  const AttachmentType(this.name);

  final String name;
}

final class DocumentAttachmentType extends AttachmentType {
  const DocumentAttachmentType() : super('document');
}

final class ImageAttachmentType extends AttachmentType {
  const ImageAttachmentType() : super('image');
}

final class ContactAttachmentType extends AttachmentType {
  const ContactAttachmentType() : super('contact');
}

final class LocationAttachmentType extends AttachmentType {
  const LocationAttachmentType() : super('location');
}

final class PollAttachmentType extends AttachmentType {
  const PollAttachmentType() : super('poll');
}

final class EventAttachmentType extends AttachmentType {
  const EventAttachmentType() : super('event');
}

final class AudioAttachmentType extends AttachmentType {
  const AudioAttachmentType() : super('audio');
}

@immutable
sealed class ChatAttachment {
  const ChatAttachment({required this.type});

  final AttachmentType type;
}

final class DocumentAttachment extends ChatAttachment {
  const DocumentAttachment({
    required this.uri,
    required this.fileName,
    required this.fileSizeBytes,
    required this.mimeType,
    this.cachePath,
  }) : super(type: const DocumentAttachmentType());

  final String uri;
  final String fileName;
  final int fileSizeBytes;
  final String mimeType;
  final String? cachePath;
}

final class ImageAttachment extends ChatAttachment {
  const ImageAttachment({
    required this.uri,
    required this.fileSizeBytes,
    required this.width,
    required this.height,
    this.fileName,
    this.mimeType,
    this.cachePath,
  }) : super(type: const ImageAttachmentType());

  final String uri;
  final int fileSizeBytes;
  final int width;
  final int height;
  final String? fileName;
  final String? mimeType;
  final String? cachePath;

  File? get previewFile {
    final path = cachePath;
    if (path == null || path.isEmpty) return null;
    return File(path);
  }
}

final class ContactAttachment extends ChatAttachment {
  const ContactAttachment({required this.name, required this.phoneNumber})
    : super(type: const ContactAttachmentType());

  final String name;
  final String phoneNumber;
}

final class LocationAttachment extends ChatAttachment {
  const LocationAttachment({required this.latitude, required this.longitude})
    : super(type: const LocationAttachmentType());

  final double latitude;
  final double longitude;
}

final class PollAttachment extends ChatAttachment {
  const PollAttachment({required this.question, required this.options})
    : super(type: const PollAttachmentType());

  final String question;
  final List<String> options;
}

final class EventAttachment extends ChatAttachment {
  const EventAttachment({
    required this.title,
    required this.date,
    required this.time,
    required this.description,
  }) : super(type: const EventAttachmentType());

  final String title;
  final String date;
  final String time;
  final String description;
}

final class AudioAttachment extends ChatAttachment {
  const AudioAttachment({
    required this.uri,
    required this.path,
    required this.durationMs,
    required this.fileSizeBytes,
    required this.mimeType,
  }) : super(type: const AudioAttachmentType());

  final String uri;
  final String path;
  final int durationMs;
  final int fileSizeBytes;
  final String mimeType;

  Duration get duration => Duration(milliseconds: durationMs);
}

ChatAttachment? chatAttachmentFromPayload({
  required String type,
  required Map<String, dynamic>? payload,
}) {
  if (payload == null) return null;
  switch (type) {
    case 'contact':
      return ContactAttachment(
        name: payload['name']?.toString() ?? '',
        phoneNumber: payload['phoneNumber']?.toString() ?? '',
      );
    case 'location':
      return LocationAttachment(
        latitude: _double(payload['latitude']),
        longitude: _double(payload['longitude']),
      );
    case 'poll':
      final options = payload['options'];
      return PollAttachment(
        question: payload['question']?.toString() ?? '',
        options: options is List
            ? options.map((value) => value.toString()).toList()
            : const [],
      );
    case 'event':
      return EventAttachment(
        title: payload['title']?.toString() ?? '',
        date: payload['date']?.toString() ?? '',
        time: payload['time']?.toString() ?? '',
        description: payload['description']?.toString() ?? '',
      );
  }
  return null;
}

Map<String, Object?>? chatAttachmentPayload(ChatAttachment attachment) {
  return switch (attachment) {
    ContactAttachment(:final name, :final phoneNumber) => {
      'name': name,
      'phoneNumber': phoneNumber,
    },
    LocationAttachment(:final latitude, :final longitude) => {
      'latitude': latitude,
      'longitude': longitude,
    },
    PollAttachment(:final question, :final options) => {
      'question': question,
      'options': options,
    },
    EventAttachment(
      :final title,
      :final date,
      :final time,
      :final description,
    ) =>
      {'title': title, 'date': date, 'time': time, 'description': description},
    DocumentAttachment() || ImageAttachment() || AudioAttachment() => null,
  };
}

String structuredAttachmentTypeName(ChatAttachment attachment) {
  return switch (attachment) {
    ContactAttachment() => 'contact',
    LocationAttachment() => 'location',
    PollAttachment() => 'poll',
    EventAttachment() => 'event',
    DocumentAttachment() || ImageAttachment() || AudioAttachment() => '',
  };
}

String chatAttachmentPreviewText(ChatAttachment attachment) {
  return switch (attachment) {
    DocumentAttachment(:final fileName) => fileName,
    ImageAttachment() => 'Photo',
    ContactAttachment(:final name) => name.isEmpty ? 'Contact' : name,
    LocationAttachment(:final latitude, :final longitude) =>
      'Location: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
    PollAttachment(:final question) => question,
    EventAttachment(:final title) => title,
    AudioAttachment(:final duration) =>
      'Voice message ${_formatDuration(duration)}',
  };
}

double _double(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString();
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
