const mongoose = require('mongoose');

const { Schema } = mongoose;

const afapaySecurityAuditLogSchema = new Schema(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'AfaPayUser',
      index: true,
      default: null,
    },
    eventType: {
      type: String,
      required: true,
      trim: true,
      maxlength: 80,
      index: true,
    },
    status: {
      type: String,
      enum: ['success', 'failed', 'blocked'],
      default: 'success',
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
    metadata: {
      type: Schema.Types.Mixed,
      default: {},
    },
    createdAt: {
      type: Date,
      default: Date.now,
      index: true,
    },
  },
  {
    collection: 'afapay_security_audit_logs',
  },
);

module.exports =
  mongoose.models.AfaPaySecurityAuditLog ||
  mongoose.model('AfaPaySecurityAuditLog', afapaySecurityAuditLogSchema);
