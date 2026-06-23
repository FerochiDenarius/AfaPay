const mongoose = require('mongoose');

const { Schema } = mongoose;

const afapayChatRoomSchema = new Schema(
  {
    participants: [
      {
        type: Schema.Types.ObjectId,
        ref: 'AfaPayUser',
        required: true,
      },
    ],
    participantKey: {
      type: String,
      unique: true,
      sparse: true,
      index: true,
    },
    roomType: {
      type: String,
      enum: ['private', 'group'],
      default: 'private',
      index: true,
    },
    groupName: {
      type: String,
      trim: true,
      maxlength: 80,
      default: '',
    },
    groupCreatedBy: {
      type: Schema.Types.ObjectId,
      ref: 'AfaPayUser',
      default: null,
    },
    groupMembers: [
      {
        type: Schema.Types.ObjectId,
        ref: 'AfaPayUser',
      },
    ],
    lastMessage: {
      type: String,
      default: '',
      maxlength: 2000,
    },
    lastMessageAt: {
      type: Date,
      default: null,
      index: true,
    },
  },
  {
    collection: 'afapay_chat_rooms',
    timestamps: true,
  },
);

afapayChatRoomSchema.pre('validate', function setParticipantKey(next) {
  if (this.roomType === 'private' && this.participants?.length === 2) {
    this.participantKey = this.participants
      .map((participant) => participant.toString())
      .sort()
      .join(':');
  } else {
    this.participantKey = undefined;
  }

  if (this.roomType === 'group' && (!this.groupMembers || this.groupMembers.length === 0)) {
    this.groupMembers = this.participants || [];
  }
  next();
});

afapayChatRoomSchema.index({ roomType: 1, participants: 1, updatedAt: -1 });

module.exports =
  mongoose.models.AfaPayChatRoom ||
  mongoose.model('AfaPayChatRoom', afapayChatRoomSchema);
