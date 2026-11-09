import mongoose, { Schema, model, type InferSchemaType, type Model } from 'mongoose';

const models = mongoose.models;
const baseOptions = { timestamps: true, strict: 'throw' as const, versionKey: false as const };
const objectId = Schema.Types.ObjectId;
const userRef = { type: objectId, required: true, index: true };

const userSchema = new Schema({
  phone: { type: String, sparse: true, unique: true, trim: true },
  email: { type: String, trim: true, lowercase: true, sparse: true, unique: true },
  googleSub: { type: String, sparse: true, unique: true },
  name: { type: String, trim: true, maxlength: 120 },
  status: { type: String, enum: ['active', 'locked', 'deleted'], default: 'active' },
  locale: { type: String, default: 'en-IN' },
}, { ...baseOptions, collection: 'users' });

const profileSchema = new Schema({
  userId: { ...userRef, unique: true },
  age: { type: Number, min: 18, max: 120 },
  cityTier: String,
  maritalStatus: String,
  dependents: { type: Number, min: 0, default: 0 },
  occupation: String,
  occupationType: { type: String, enum: ['salaried', 'business', 'freelance', 'retired', 'other'] },
  riskProfile: { type: String, enum: ['conservative', 'moderate', 'aggressive'] },
  riskScore: { type: Number, min: 0, max: 100 },
  taxRegime: { type: String, enum: ['old', 'new', 'unknown'], default: 'unknown' },
  monthlyIncomePaise: { type: Number, min: 0, default: 0 },
  monthlyEssentialExpensesPaise: { type: Number, min: 0, default: 0 },
  emergencyFundPaise: { type: Number, min: 0, default: 0 },
  termCoverPaise: { type: Number, min: 0, default: 0 },
  healthCoverPaise: { type: Number, min: 0, default: 0 },
  riskAnswers: { type: [Schema.Types.Mixed], default: [] },
  onboardingSections: { type: Map, of: Schema.Types.Mixed, default: {} },
  onboardingComplete: { type: Boolean, default: false },
}, baseOptions);
profileSchema.index({ userId: 1 }, { unique: true });

const otpChallengeSchema = new Schema({
  phone: { type: String, required: true, index: true },
  codeHash: { type: String, required: true },
  attempts: { type: Number, default: 0 },
  expiresAt: { type: Date, required: true },
  consumedAt: Date,
}, { ...baseOptions, collection: 'otpRequests' });
otpChallengeSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

const refreshSessionSchema = new Schema({
  userId: userRef,
  familyId: { type: String, required: true, index: true },
  tokenHash: { type: String, required: true, unique: true },
  expiresAt: { type: Date, required: true },
  revokedAt: Date,
  replacedByTokenHash: String,
}, { ...baseOptions, collection: 'refreshTokens' });
refreshSessionSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

const eventSchema = new Schema({
  id: { type: String, required: true },
  title: { type: String, required: true, maxlength: 120 },
  type: { type: String, enum: ['emi', 'sip', 'bill', 'salary', 'one_off'], required: true },
  amountPaise: { type: Number, min: 0, default: 0 },
  date: { type: Date, required: true },
  isDone: { type: Boolean, default: false },
}, { _id: false, strict: 'throw' });

const monthSchema = new Schema({
  userId: userRef,
  ym: { type: String, required: true, match: /^\d{4}-(0[1-9]|1[0-2])$/ },
  status: { type: String, enum: ['draft', 'planned', 'active', 'closed'], default: 'draft' },
  incomeTotalPaise: { type: Number, min: 0, default: 0 },
  incomes: { type: [Schema.Types.Mixed], default: [] },
  events: { type: [eventSchema], default: [] },
  activePlanId: { type: objectId },
  closedAt: Date,
}, baseOptions);
monthSchema.index({ userId: 1, ym: 1 }, { unique: true });

const allocationSchema = new Schema({
  id: { type: String, required: true },
  bucket: { type: String, required: true },
  label: { type: String, required: true },
  amountPaise: { type: Number, required: true, min: 0 },
  percentage: { type: Number, required: true, min: 0, max: 100 },
  reason: { type: String, required: true },
  categoryId: String,
  goalId: { type: objectId },
  breakdown: { type: Schema.Types.Mixed },
  userEdited: { type: Boolean, default: false },
}, { _id: false, strict: 'throw' });

const monthPlanSchema = new Schema({
  userId: userRef,
  monthId: { type: objectId, required: true },
  version: { type: Number, required: true, min: 1 },
  template: { type: String, required: true },
  status: { type: String, enum: ['proposed', 'edited', 'approved', 'superseded'], default: 'proposed' },
  rulesVersion: { type: String, default: '1.0.0' },
  incomeTotalPaise: { type: Number, required: true, min: 0 },
  allocations: { type: [allocationSchema], default: [] },
  warnings: { type: [String], default: [] },
  assumptions: { type: [String], default: [] },
  summary: String,
  approvedAt: Date,
}, baseOptions);
monthPlanSchema.index({ userId: 1, monthId: 1, version: 1 }, { unique: true });

const transactionSchema = new Schema({
  userId: userRef,
  monthId: { type: objectId },
  clientId: String,
  title: { type: String, required: true, trim: true, maxlength: 160 },
  amountPaise: { type: Number, required: true, min: 1 },
  categoryId: { type: String, required: true, trim: true },
  txnDate: { type: Date, required: true, default: Date.now },
  paymentMode: { type: String, required: true, maxlength: 40 },
  type: { type: String, enum: ['expense', 'income', 'transfer'], default: 'expense' },
  merchant: { type: String, maxlength: 120 },
  note: { type: String, maxlength: 1000 },
  source: { type: String, enum: ['manual', 'sync', 'sms', 'ocr', 'voice', 'aa'], default: 'manual' },
  deletedAt: Date,
  updatedAtClient: Date,
}, baseOptions);
transactionSchema.index({ userId: 1, txnDate: -1 });
transactionSchema.index({ userId: 1, monthId: 1, categoryId: 1, txnDate: -1 });
transactionSchema.index({ userId: 1, clientId: 1 }, { unique: true, partialFilterExpression: { clientId: { $exists: true } } });

const goalSchema = new Schema({
  userId: userRef,
  name: { type: String, required: true, trim: true, maxlength: 120 },
  goalType: { type: String, default: 'custom', maxlength: 40 },
  targetAmountPaise: { type: Number, required: true, min: 1 },
  currentSavedPaise: { type: Number, min: 0, default: 0 },
  targetDate: { type: Date, required: true },
  priority: { type: Number, min: 1, max: 5, default: 3 },
  status: { type: String, enum: ['active', 'completed', 'paused'], default: 'active' },
}, baseOptions);
goalSchema.index({ userId: 1, status: 1, priority: 1, targetDate: 1 });

const categorySchema = new Schema({
  userId: { type: objectId, default: null },
  id: { type: String, required: true },
  name: { type: String, required: true },
  bucket: { type: String, required: true },
  icon: String,
  isSystem: { type: Boolean, default: false },
}, baseOptions);
categorySchema.index({ userId: 1, id: 1 }, { unique: true });

const genericFinanceSchema = new Schema({
  userId: userRef,
  name: { type: String, required: true, maxlength: 160 },
  type: { type: String, required: true, maxlength: 60 },
  amountPaise: { type: Number, min: 0, default: 0 },
  currentValuePaise: { type: Number, min: 0, default: 0 },
  outstandingPaise: { type: Number, min: 0, default: 0 },
  interestRateBps: { type: Number, min: 0, default: 0 },
  emiPaise: { type: Number, min: 0, default: 0 },
  tenureLeftMonths: { type: Number, min: 0 },
  dueDay: { type: Number, min: 1, max: 31 },
  frequency: String,
  nextDue: Date,
  sumAssuredPaise: { type: Number, min: 0 },
  metadata: { type: Schema.Types.Mixed, default: {} },
  active: { type: Boolean, default: true },
}, baseOptions);

const recurringRuleSchema = new Schema({
  userId: userRef,
  title: { type: String, required: true, maxlength: 160 },
  categoryId: { type: String, required: true },
  amountPaise: { type: Number, required: true, min: 1 },
  paymentMode: { type: String, default: 'UPI' },
  frequency: { type: String, enum: ['weekly', 'monthly', 'yearly'], default: 'monthly' },
  dayOfMonth: { type: Number, min: 1, max: 31, default: 1 },
  nextRun: { type: Date, required: true },
  active: { type: Boolean, default: true },
}, baseOptions);
recurringRuleSchema.index({ userId: 1, active: 1, nextRun: 1 });

const snapshotSchema = new Schema({
  userId: userRef,
  asOf: { type: Date, default: Date.now },
  netWorthPaise: { type: Number, default: 0 },
  totalAssetsPaise: { type: Number, default: 0 },
  totalLiabilitiesPaise: { type: Number, default: 0 },
  monthlyIncomePaise: { type: Number, default: 0 },
  monthlyExpensesPaise: { type: Number, default: 0 },
  savingsRate: { type: Number, default: 0 },
  dtiRatio: { type: Number, default: 0 },
  emergencyMonths: { type: Number, default: 0 },
  healthScore: { type: Number, min: 0, max: 100, default: 0 },
  components: { type: Schema.Types.Mixed, default: {} },
}, baseOptions);
snapshotSchema.index({ userId: 1, asOf: -1 });

const conversationSchema = new Schema({ userId: userRef, title: { type: String, maxlength: 160 } }, baseOptions);
const messageSchema = new Schema({
  userId: userRef,
  conversationId: { type: objectId, required: true },
  role: { type: String, enum: ['user', 'assistant'], required: true },
  content: { type: String, required: true, maxlength: 20_000 },
  citations: { type: [Schema.Types.Mixed], default: [] },
}, baseOptions);
messageSchema.index({ userId: 1, conversationId: 1, createdAt: 1 });

const notificationSchema = new Schema({
  userId: userRef,
  type: { type: String, required: true },
  title: { type: String, required: true, maxlength: 160 },
  body: { type: String, required: true, maxlength: 2000 },
  readAt: Date,
  scheduledFor: Date,
  sentAt: Date,
}, baseOptions);
notificationSchema.index({ userId: 1, scheduledFor: 1, sentAt: 1 });

const auditSchema = new Schema({
  userId: userRef,
  action: { type: String, required: true },
  entity: { type: String, required: true },
  entityId: String,
  ipHash: String,
  metadata: { type: Schema.Types.Mixed, default: {} },
}, { ...baseOptions, collection: 'auditLogs' });

function modelOnce<TSchema extends Schema>(name: string, schema: TSchema): Model<InferSchemaType<TSchema>> {
  type Document = InferSchemaType<TSchema>;
  return (models[name] as Model<Document> | undefined) ?? model<Document>(name, schema);
}

export const User = modelOnce('User', userSchema);
export const Profile = modelOnce('Profile', profileSchema);
export const OtpChallenge = modelOnce('OtpChallenge', otpChallengeSchema);
export const RefreshSession = modelOnce('RefreshSession', refreshSessionSchema);
export const Month = modelOnce('Month', monthSchema);
export const MonthPlan = modelOnce('MonthPlan', monthPlanSchema);
export const Transaction = modelOnce('Transaction', transactionSchema);
export const Goal = modelOnce('Goal', goalSchema);
export const Category = modelOnce('Category', categorySchema);
export const Asset = modelOnce('Asset', genericFinanceSchema.clone());
export const Liability = modelOnce('Liability', genericFinanceSchema.clone());
export const InsurancePolicy = modelOnce('InsurancePolicy', genericFinanceSchema.clone());
export const RecurringRule = modelOnce('RecurringRule', recurringRuleSchema);
export const FinancialSnapshot = modelOnce('FinancialSnapshot', snapshotSchema);
export const Conversation = modelOnce('Conversation', conversationSchema);
export const Message = modelOnce('Message', messageSchema);
export const Notification = modelOnce('Notification', notificationSchema);
export const AuditLog = modelOnce('AuditLog', auditSchema);

export type UserDocument = InferSchemaType<typeof userSchema>;
export type ProfileDocument = InferSchemaType<typeof profileSchema>;
export type MonthDocument = InferSchemaType<typeof monthSchema>;
export type MonthPlanDocument = InferSchemaType<typeof monthPlanSchema>;
export type TransactionDocument = InferSchemaType<typeof transactionSchema>;
export type GoalDocument = InferSchemaType<typeof goalSchema>;
