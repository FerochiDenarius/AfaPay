const mongoose = require('mongoose');

const { Schema } = mongoose;

const afapayRefreshTokenSchema = new Schema(
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
      index: true,
    },
    tokenHash: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      maxlength: 128,
    },
    expiresAt: {
      type: Date,
      required: true,
      index: true,
    },
    revoked: {
      type: Boolean,
      default: false,
      index: true,
    },
    revokedAt: {
      type: Date,
      default: null,
    },
  },
  {
    collection: 'afapay_refresh_tokens',
    timestamps: true,
  },
);

afapayRefreshTokenSchema.index({ userId: 1, deviceId: 1, revoked: 1 });

module.exports =
  mongoose.models.AfaPayRefreshToken ||
  mongoose.model('AfaPayRefreshToken', afapayRefreshTokenSchema);
