const mongoose = require('mongoose');

const { Schema } = mongoose;

const afapayMessageSchema = new Schema(
  {
    roomId: {
      type: Schema.Types.ObjectId,
      ref: 'AfaPayChatRoom',
      required: true,
      index: true,
    },
    conversationId: {
      type: Schema.Types.ObjectId,
      ref: 'AfaPayChatRoom',
      index: true,
    },
    senderId: {
      type: Schema.Types.ObjectId,
      ref: 'AfaPayUser',
      required: true,
      index: true,
    },
    text: {
      type: String,
      trim: true,
      maxlength: 2000,
      default: '',
    },
    imageUrl: {
      type: String,
      trim: true,
      default: '',
    },
    videoUrl: {
      type: String,
      trim: true,
      default: '',
    },
    audioUrl: {
      type: String,
      trim: true,
      default: '',
    },
    fileUrl: {
      type: String,
      trim: true,
      default: '',
    },
    mediaType: {
      type: String,
      enum: ['image', 'video', 'audio', 'file', ''],
      default: '',
    },
    mediaName: {
      type: String,
      trim: true,
      maxlength: 255,
      default: '',
    },
    mediaMimeType: {
      type: String,
      trim: true,
      maxlength: 120,
      default: '',
    },
    mediaSizeBytes: {
      type: Number,
      default: 0,
    },
    repliedTo: {
      type: Schema.Types.ObjectId,
      ref: 'AfaPayMessage',
      default: null,
      index: true,
    },
    timestamp: {
      type: Date,
      default: Date.now,
      index: true,
    },
    status: {
      type: String,
      enum: ['sent', 'delivered', 'read'],
      default: 'sent',
    },
    isEdited: {
      type: Boolean,
      default: false,
    },
    editedAt: {
      type: Date,
      default: null,
    },
  },
  {
    collection: 'afapay_messages',
    timestamps: true,
  },
);

module.exports =
  mongoose.models.AfaPayMessage ||
  mongoose.model('AfaPayMessage', afapayMessageSchema);
