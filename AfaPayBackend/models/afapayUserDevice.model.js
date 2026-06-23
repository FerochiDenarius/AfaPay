const mongoose = require('mongoose');

const { Schema } = mongoose;

const afapayUserDeviceSchema = new Schema(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'AfaPayUser',
      required: true,
      index: true,
    },
    deviceId: {
      type: String,
      required: true,
      trim: true,
      maxlength: 128,
    },
    deviceName: {
      type: String,
      trim: true,
      default: '',
      maxlength: 160,
    },
    platform: {
      type: String,
      trim: true,
      default: '',
      maxlength: 40,
    },
    osVersion: {
      type: String,
      trim: true,
      default: '',
      maxlength: 80,
    },
    pushNotificationToken: {
      type: String,
      trim: true,
      default: '',
      maxlength: 512,
    },
    lastLogin: {
      type: Date,
      default: Date.now,
      index: true,
    },
    lastIp: {
      type: String,
      trim: true,
      default: '',
      maxlength: 80,
    },
    revoked: {
      type: Boolean,
      default: false,
      index: true,
    },
  },
  {
    collection: 'afapay_user_devices',
    timestamps: true,
  },
);

afapayUserDeviceSchema.index({ userId: 1, deviceId: 1 }, { unique: true });

module.exports =
  mongoose.models.AfaPayUserDevice ||
  mongoose.model('AfaPayUserDevice', afapayUserDeviceSchema);
