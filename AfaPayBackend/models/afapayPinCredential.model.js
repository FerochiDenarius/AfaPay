const mongoose = require('mongoose');

const { Schema } = mongoose;

const afapayPinCredentialSchema = new Schema(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'AfaPayUser',
      required: true,
      unique: true,
      index: true,
    },
    pinHash: {
      type: String,
      required: true,
    },
  },
  {
    collection: 'afapay_pin_credentials',
    timestamps: true,
  },
);

module.exports =
  mongoose.models.AfaPayPinCredential ||
  mongoose.model('AfaPayPinCredential', afapayPinCredentialSchema);
