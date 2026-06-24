const mongoose = require('mongoose');

const { Schema } = mongoose;

const afapayUserSchema = new Schema(
  {
    firstName: {
      type: String,
      required: true,
      trim: true,
      maxlength: 80,
    },
    lastName: {
      type: String,
      required: true,
      trim: true,
      maxlength: 80,
    },
    username: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      lowercase: true,
      minlength: 4,
      maxlength: 20,
      index: true,
    },
    country: {
      type: String,
      required: true,
      trim: true,
      maxlength: 80,
    },
    location: {
      type: String,
      trim: true,
      default: '',
      maxlength: 80,
    },
    phoneNumber: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      maxlength: 30,
      index: true,
    },
    phoneVerified: {
      type: Boolean,
      default: false,
    },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
      maxlength: 254,
      index: true,
      match: [/.+\@.+\..+/, 'Please fill a valid email address'],
    },
    emailVerified: {
      type: Boolean,
      default: false,
    },
    password: {
      type: String,
      required: true,
    },
    emailVerificationCode: String,
    emailVerificationExpires: Date,
    emailVerificationCooldown: Date,
    emailVerificationAttempts: {
      type: Number,
      default: 0,
    },
    refreshToken: String,
    lastLoginAt: {
      type: Date,
      default: null,
    },
    lastLoginIp: {
      type: String,
      default: '',
    },
    lastLoginUserAgent: {
      type: String,
      default: '',
    },
    accountStatus: {
      type: String,
      enum: ['pending', 'active', 'suspended'],
      default: 'pending',
      index: true,
    },
    blockedUsers: [
      {
        type: Schema.Types.ObjectId,
        ref: 'AfaPayUser',
      },
    ],
    online: {
      type: Boolean,
      default: false,
      index: true,
    },
    lastSeen: {
      type: Date,
      default: null,
    },
  },
  {
    collection: 'afapay_users',
    timestamps: true,
  },
);

module.exports =
  mongoose.models.AfaPayUser ||
  mongoose.model('AfaPayUser', afapayUserSchema);
