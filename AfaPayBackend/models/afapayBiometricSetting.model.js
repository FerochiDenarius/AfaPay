const mongoose = require('mongoose');

const { Schema } = mongoose;

const afapayBiometricSettingSchema = new Schema(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'AfaPayUser',
      required: true,
      unique: true,
      index: true,
    },
    biometricEnabled: {
      type: Boolean,
      default: false,
    },
  },
  {
    collection: 'afapay_biometric_settings',
    timestamps: true,
  },
);

module.exports =
  mongoose.models.AfaPayBiometricSetting ||
  mongoose.model('AfaPayBiometricSetting', afapayBiometricSettingSchema);
