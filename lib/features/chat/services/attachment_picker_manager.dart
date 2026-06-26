import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/chat_attachment.dart';
import '../repositories/attachment_repository.dart';

class AttachmentPickerState {
  const AttachmentPickerState({
    this.attachment,
    this.isBusy = false,
    this.isRecording = false,
    this.errorMessage,
  });

  final ChatAttachment? attachment;
  final bool isBusy;
  final bool isRecording;
  final String? errorMessage;

  AttachmentPickerState copyWith({
    ChatAttachment? attachment,
    bool clearAttachment = false,
    bool? isBusy,
    bool? isRecording,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AttachmentPickerState(
      attachment: clearAttachment ? null : attachment ?? this.attachment,
      isBusy: isBusy ?? this.isBusy,
      isRecording: isRecording ?? this.isRecording,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AttachmentPickerManager extends ChangeNotifier {
  AttachmentPickerManager({AttachmentRepository? repository})
    : _repository = repository ?? PlatformAttachmentRepository();

  static const maxDocumentBytes = 25 * 1024 * 1024;
  static const maxImageBytes = 10 * 1024 * 1024;
  static const maxAudioDuration = Duration(minutes: 5);

  final AttachmentRepository _repository;
  final _stateController = StreamController<AttachmentPickerState>.broadcast();

  AttachmentPickerState _state = const AttachmentPickerState();

  AttachmentPickerState get state => _state;
  Stream<AttachmentPickerState> get stateFlow => _stateController.stream;

  Future<void> pickDocument() async {
    await _runPicker(() async {
      final attachment = await _repository.pickDocument();
      if (attachment == null) return;
      if (attachment.fileSizeBytes > maxDocumentBytes) {
        _emitError('Documents must be 25MB or smaller.');
        return;
      }
      _emit(_state.copyWith(attachment: attachment, clearError: true));
    });
  }

  Future<void> pickImage() async {
    await _runPicker(() async {
      final attachment = await _repository.pickImage();
      if (attachment == null) return;
      if (attachment.fileSizeBytes > maxImageBytes) {
        _emitError('Images must be 10MB or smaller.');
        return;
      }
      _emit(_state.copyWith(attachment: attachment, clearError: true));
    });
  }

  Future<void> pickContact() async {
    await _runPicker(() async {
      final attachment = await _repository.pickContact();
      if (attachment != null) {
        _emit(_state.copyWith(attachment: attachment, clearError: true));
      }
    });
  }

  Future<void> pickCurrentLocation() async {
    await _runPicker(() async {
      final attachment = await _repository.pickCurrentLocation();
      if (attachment != null) {
        _emit(_state.copyWith(attachment: attachment, clearError: true));
      }
    });
  }

  void setPoll(PollAttachment attachment) {
    _emit(_state.copyWith(attachment: attachment, clearError: true));
  }

  void setEvent(EventAttachment attachment) {
    _emit(_state.copyWith(attachment: attachment, clearError: true));
  }

  Future<void> startAudioRecording() async {
    if (_state.isRecording) return;
    try {
      await _repository.startAudioRecording();
      _emit(
        _state.copyWith(isRecording: true, isBusy: false, clearError: true),
      );
    } on Object catch (error) {
      _emitError(_platformErrorMessage(error, 'Unable to start recording.'));
    }
  }

  Future<void> stopAudioRecording() async {
    if (!_state.isRecording) return;
    try {
      final attachment = await _repository.stopAudioRecording();
      if (attachment == null) {
        _emit(_state.copyWith(isRecording: false));
        return;
      }
      if (attachment.duration > maxAudioDuration) {
        _emit(
          _state.copyWith(
            isRecording: false,
            errorMessage: 'Audio recordings must be 5 minutes or shorter.',
          ),
        );
        return;
      }
      _emit(
        _state.copyWith(
          attachment: attachment,
          isRecording: false,
          clearError: true,
        ),
      );
    } on Object catch (error) {
      _emit(
        _state.copyWith(
          isRecording: false,
          errorMessage: _platformErrorMessage(
            error,
            'Unable to stop recording.',
          ),
        ),
      );
    }
  }

  void clearAttachment() {
    _emit(_state.copyWith(clearAttachment: true, clearError: true));
  }

  void clearError() {
    _emit(_state.copyWith(clearError: true));
  }

  Future<void> _runPicker(Future<void> Function() action) async {
    if (_state.isBusy) return;
    _emit(_state.copyWith(isBusy: true, clearError: true));
    try {
      await action();
    } on Object catch (error) {
      _emitError(_platformErrorMessage(error, 'Unable to select attachment.'));
    } finally {
      _emit(_state.copyWith(isBusy: false));
    }
  }

  void _emitError(String message) {
    _emit(_state.copyWith(errorMessage: message));
  }

  void _emit(AttachmentPickerState state) {
    _state = state;
    _stateController.add(state);
    notifyListeners();
  }

  @override
  void dispose() {
    _stateController.close();
    super.dispose();
  }
}

String _platformErrorMessage(Object error, String fallback) {
  final text = error.toString();
  if (text.contains('PlatformException(')) {
    final parts = text.split(',');
    if (parts.length >= 2) {
      final message = parts[1].trim();
      if (message.isNotEmpty && message != 'null') return message;
    }
  }
  return fallback;
}
