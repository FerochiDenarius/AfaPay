const mongoose = require('mongoose');

const { Schema } = mongoose;

const afapayPinAttemptSchema = new Schema(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'AfaPayUser',
      required: true,
      unique: true,
      index: true,
    },
    failedCount: {
      type: Number,
      default: 0,
      min: 0,
    },
    lockedUntil: {
      type: Date,
      default: null,
      index: true,
    },
  },
  {
    collection: 'afapay_pin_attempts',
    timestamps: true,
  },
);

module.exports =
  mongoose.models.AfaPayPinAttempt ||
  mongoose.model('AfaPayPinAttempt', afapayPinAttemptSchema);
