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
  },
  {
    collection: 'afapay_messages',
    timestamps: true,
  },
);

module.exports =
  mongoose.models.AfaPayMessage ||
  mongoose.model('AfaPayMessage', afapayMessageSchema);
