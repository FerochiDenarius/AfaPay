const mongoose = require('mongoose');

const { Schema } = mongoose;

const afapayUserReportSchema = new Schema(
  {
    reporterId: {
      type: Schema.Types.ObjectId,
      ref: 'AfaPayUser',
      required: true,
      index: true,
    },
    targetUserId: {
      type: Schema.Types.ObjectId,
      ref: 'AfaPayUser',
      required: true,
      index: true,
    },
    roomId: {
      type: Schema.Types.ObjectId,
      ref: 'AfaPayChatRoom',
      default: null,
      index: true,
    },
    reason: {
      type: String,
      trim: true,
      maxlength: 500,
      default: 'Reported from chat',
    },
    status: {
      type: String,
      enum: ['pending', 'reviewed', 'dismissed'],
      default: 'pending',
      index: true,
    },
  },
  {
    collection: 'afapay_user_reports',
    timestamps: true,
  },
);

afapayUserReportSchema.index({ reporterId: 1, targetUserId: 1, status: 1 });

module.exports =
  mongoose.models.AfaPayUserReport ||
  mongoose.model('AfaPayUserReport', afapayUserReportSchema);
