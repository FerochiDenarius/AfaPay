const mongoose = require('mongoose');

const { Schema } = mongoose;

const afapayLoginHistorySchema = new Schema(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'AfaPayUser',
      required: true,
      index: true,
    },
    ipAddress: {
      type: String,
      trim: true,
      default: '',
      maxlength: 80,
    },
    deviceId: {
      type: String,
      trim: true,
      default: '',
      maxlength: 128,
      index: true,
    },
    loginTime: {
      type: Date,
      default: Date.now,
      index: true,
    },
    status: {
      type: String,
      enum: ['success', 'failed'],
      required: true,
      index: true,
    },
    reason: {
      type: String,
      trim: true,
      default: '',
      maxlength: 180,
    },
  },
  {
    collection: 'afapay_login_history',
  },
);

module.exports =
  mongoose.models.AfaPayLoginHistory ||
  mongoose.model('AfaPayLoginHistory', afapayLoginHistorySchema);
