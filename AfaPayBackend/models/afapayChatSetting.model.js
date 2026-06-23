const mongoose = require('mongoose');

const { Schema } = mongoose;

const afapayChatSettingSchema = new Schema(
  {
    roomId: {
      type: Schema.Types.ObjectId,
      ref: 'AfaPayChatRoom',
      required: true,
      index: true,
    },
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'AfaPayUser',
      required: true,
      index: true,
    },
    theme: {
      type: String,
      enum: ['gold', 'emerald', 'sky', 'rose'],
      default: 'gold',
    },
    wallpaper: {
      type: String,
      enum: ['midnight', 'graphite', 'aurora', 'clean'],
      default: 'midnight',
    },
    muted: {
      type: Boolean,
      default: false,
    },
    disappearingSeconds: {
      type: Number,
      default: null,
      min: 0,
    },
    clearedBefore: {
      type: Date,
      default: null,
    },
  },
  {
    collection: 'afapay_chat_settings',
    timestamps: true,
  },
);

afapayChatSettingSchema.index({ roomId: 1, userId: 1 }, { unique: true });

module.exports =
  mongoose.models.AfaPayChatSetting ||
  mongoose.model('AfaPayChatSetting', afapayChatSettingSchema);
