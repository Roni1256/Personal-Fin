import { Router } from 'express';
import { z } from 'zod';
import { asyncHandler } from '../middleware/async-handler.js';
import { ApiError } from '../middleware/errors.js';
import { requireAuth, userIdFrom } from '../middleware/auth.js';
import { Goal, Month, MonthPlan, Profile, Transaction } from '../models/index.js';
import { generatePlan, type PlanTemplate } from '../services/plan-engine.js';
import { toClientPlan } from '../services/plan-mapper.js';
import { rupeesToPaise } from '../utils/money.js';

const router = Router();
router.use(requireAuth);

const templateMap: Record<string, PlanTemplate> = {
  'Family Balanced': 'family_balanced',
  'family_balanced': 'family_balanced',
  '50/30/20 Classic': 'classic_50_30_20',
  classic_50_30_20: 'classic_50_30_20',
  'Aggressive Saver': 'aggressive_saver',
  aggressive_saver: 'aggressive_saver',
  'Debt Crusher': 'debt_crusher',
  debt_crusher: 'debt_crusher',
  'Freelancer Smoothing': 'freelancer_smoothing',
  freelancer_smoothing: 'freelancer_smoothing',
  'Retirement Booster': 'retirement_booster',
  retirement_booster: 'retirement_booster',
  'Goal Sprint': 'goal_sprint',
  goal_sprint: 'goal_sprint',
  'Zero Based': 'zero_based',
  zero_based: 'zero_based',
};

const planInputSchema = z.object({
  month: z.string().regex(/^\d{4}-(0[1-9]|1[0-2])$/),
  income: z.number().nonnegative().optional(),
  incomePaise: z.number().int().nonnegative().optional(),
  template: z.string().default('family_balanced'),
  essentialExpensesPaise: z.number().int().nonnegative().optional(),
  emergencyFundPaise: z.number().int().nonnegative().optional(),
  highInterestDebtPaise: z.number().int().nonnegative().optional(),
  protectionPremiumPaise: z.number().int().nonnegative().optional(),
  fixedObligations: z.array(z.object({
    label: z.string().min(1),
    amountPaise: z.number().int().nonnegative(),
    categoryId: z.string().optional(),
    bucket: z.string().optional(),
  })).optional(),
  goals: z.array(z.object({
    id: z.string(),
    name: z.string().min(1),
    remainingPaise: z.number().int().nonnegative(),
    priority: z.number().int().min(1).max(5),
    targetDate: z.coerce.date(),
  })).optional(),
}).strict();

const transactionInputSchema = z.object({
  title: z.string().min(1).max(160),
  amount: z.number().positive(),
  categoryId: z.string().min(1),
  date: z.union([z.string(), z.coerce.date()]).optional(),
  paymentMode: z.string().min(1).max(40).default('UPI'),
  type: z.enum(['expense', 'income', 'transfer']).default('expense'),
  merchant: z.string().max(120).optional(),
  note: z.string().max(1000).optional(),
}).strict();

const goalInputSchema = z.object({
  name: z.string().min(1).max(120),
  goalType: z.string().max(40).optional(),
  targetAmount: z.number().positive(),
  currentSaved: z.number().nonnegative().optional(),
  targetDate: z.union([z.string(), z.coerce.date()]),
  priority: z.number().int().min(1).max(5).optional(),
  icon: z.string().optional(),
}).strict();

function normalizeTemplate(value: string): PlanTemplate {
  const template = templateMap[value] ?? templateMap[value.trim()];
  if (!template) throw new ApiError(400, 'Invalid Template', 'The requested budgeting template is not supported.');
  return template;
}

router.post('/plan/generate', asyncHandler(async (request, response) => {
  const body = planInputSchema.parse(request.body);
  const userId = userIdFrom(request);
  const profile = await Profile.findOne({ userId });

  const profileMonthlyIncome = profile?.monthlyIncomePaise ? Number((profile.monthlyIncomePaise ?? 0) / 100) : 0;
  const incomeAmount = body.incomePaise ?? rupeesToPaise(body.income ?? profileMonthlyIncome);
  const safetyProfile = normalizeTemplate(body.template);
  const fixedObligations = body.fixedObligations ?? [];
  const goals = body.goals ?? (await Goal.find({ userId, status: 'active' }).lean()).map((goal) => ({
    id: goal._id.toString(),
    name: goal.name,
    remainingPaise: Math.max(0, (goal.targetAmountPaise ?? 0) - (goal.currentSavedPaise ?? 0)),
    priority: goal.priority ?? 3,
    targetDate: goal.targetDate,
  }));

  const plan = generatePlan({
    month: body.month,
    incomePaise: incomeAmount,
    template: safetyProfile,
    occupationType: profile?.occupationType ?? 'salaried',
    riskProfile: profile?.riskProfile ?? 'moderate',
    essentialExpensesPaise: body.essentialExpensesPaise ?? profile?.monthlyEssentialExpensesPaise ?? Math.round(incomeAmount * 0.55),
    emergencyFundPaise: body.emergencyFundPaise ?? profile?.emergencyFundPaise ?? 0,
    fixedObligations,
    highInterestDebtPaise: body.highInterestDebtPaise ?? 0,
    protectionPremiumPaise: body.protectionPremiumPaise ?? 0,
    goals,
  });

  const monthDoc = await Month.findOneAndUpdate(
    { userId, ym: body.month },
    {
      $set: {
        userId,
        ym: body.month,
        status: 'planned',
        incomeTotalPaise: incomeAmount,
        activePlanId: null,
      },
    },
    { upsert: true, new: true, setDefaultsOnInsert: true },
  );

  const planDoc = await MonthPlan.create({
    userId,
    monthId: monthDoc._id,
    version: 1,
    template: plan.template,
    status: 'proposed',
    rulesVersion: plan.rulesVersion,
    incomeTotalPaise: plan.incomeTotalPaise,
    allocations: plan.allocations.map((item) => ({
      id: item.id,
      bucket: item.bucket,
      label: item.label,
      amountPaise: item.amountPaise,
      percentage: item.percentage,
      reason: item.reason,
      categoryId: item.categoryId,
      breakdown: item.breakdown,
    })),
    warnings: plan.warnings,
    assumptions: plan.assumptions,
  });

  response.status(201).json({
    plan: toClientPlan(plan),
    month: monthDoc.toObject(),
    planDoc: planDoc.toObject(),
  });
}));

router.get('/plan/current', asyncHandler(async (_request, response) => {
  const userId = userIdFrom(_request);
  const latestPlan = await MonthPlan.findOne({ userId }).sort({ createdAt: -1 }).lean();
  if (!latestPlan) {
    throw new ApiError(404, 'Plan Not Found', 'No plan has been generated for this user yet.');
  }

  const monthDoc = await Month.findById(latestPlan.monthId).select('ym').lean();
  const plan = toClientPlan({
    month: monthDoc?.ym ?? `${new Date().toISOString().slice(0, 7)}`,
    incomeTotalPaise: latestPlan.incomeTotalPaise,
    template: latestPlan.template,
    templateName: latestPlan.template,
    allocations: (latestPlan.allocations ?? []).map((item: any) => ({
      id: item.id,
      bucket: item.bucket,
      label: item.label,
      amountPaise: item.amountPaise,
      percentage: item.percentage,
      reason: item.reason,
      categoryId: item.categoryId,
    })),
    warnings: latestPlan.warnings ?? [],
    assumptions: latestPlan.assumptions ?? [],
    isApproved: latestPlan.status === 'approved',
  });

  response.json({ plan });
}));

router.get('/transactions', asyncHandler(async (_request, response) => {
  const userId = userIdFrom(_request);
  const txns = await Transaction.find({ userId, deletedAt: { $exists: false } }).sort({ txnDate: -1 }).lean();
  response.json({
    transactions: txns.map((txn) => ({
      id: txn._id.toString(),
      title: txn.title,
      amount: Number((txn.amountPaise ?? 0) / 100),
      categoryId: txn.categoryId,
      date: txn.txnDate,
      paymentMode: txn.paymentMode,
      type: txn.type ?? 'expense',
      merchant: txn.merchant,
      note: txn.note,
    })),
  });
}));

router.post('/transactions', asyncHandler(async (request, response) => {
  const input = transactionInputSchema.parse(request.body);
  const userId = userIdFrom(request);
  const created = await Transaction.create({
    userId,
    title: input.title,
    amountPaise: rupeesToPaise(input.amount),
    categoryId: input.categoryId,
    txnDate: input.date ? new Date(input.date) : new Date(),
    paymentMode: input.paymentMode,
    type: input.type,
    merchant: input.merchant,
    note: input.note,
    source: 'manual',
  });

  response.status(201).json({
    transaction: {
      id: created._id.toString(),
      title: created.title,
      amount: Number((created.amountPaise ?? 0) / 100),
      categoryId: created.categoryId,
      date: created.txnDate,
      paymentMode: created.paymentMode,
      type: created.type,
      merchant: created.merchant,
      note: created.note,
    },
  });
}));

router.delete('/transactions/:id', asyncHandler(async (request, response) => {
  const userId = userIdFrom(request);
  const transaction = await Transaction.findOneAndUpdate(
    { _id: request.params.id, userId },
    { $set: { deletedAt: new Date() } },
    { new: true },
  );
  if (!transaction) throw new ApiError(404, 'Transaction Not Found', 'This transaction does not exist for the signed-in user.');
  response.json({ deleted: true, id: request.params.id });
}));

router.get('/goals', asyncHandler(async (_request, response) => {
  const userId = userIdFrom(_request);
  const goals = await Goal.find({ userId, status: 'active' }).sort({ priority: 1, targetDate: 1 }).lean();
  response.json({
    goals: goals.map((goal) => ({
      id: goal._id.toString(),
      name: goal.name,
      goalType: goal.goalType,
      targetAmount: Number((goal.targetAmountPaise ?? 0) / 100),
      currentSaved: Number((goal.currentSavedPaise ?? 0) / 100),
      targetDate: goal.targetDate,
      priority: goal.priority ?? 1,
      icon: 'flag_rounded',
    })),
  });
}));

router.post('/goals', asyncHandler(async (request, response) => {
  const input = goalInputSchema.parse(request.body);
  const userId = userIdFrom(request);
  const goal = await Goal.create({
    userId,
    name: input.name,
    goalType: input.goalType ?? 'custom',
    targetAmountPaise: rupeesToPaise(input.targetAmount),
    currentSavedPaise: rupeesToPaise(input.currentSaved ?? 0),
    targetDate: new Date(input.targetDate),
    priority: input.priority ?? 3,
    status: 'active',
  });

  response.status(201).json({
    goal: {
      id: goal._id.toString(),
      name: goal.name,
      goalType: goal.goalType,
      targetAmount: Number((goal.targetAmountPaise ?? 0) / 100),
      currentSaved: Number((goal.currentSavedPaise ?? 0) / 100),
      targetDate: goal.targetDate,
      priority: goal.priority ?? 3,
      icon: 'flag_rounded',
    },
  });
}));

router.post('/goals/:id/contribute', asyncHandler(async (request, response) => {
  const userId = userIdFrom(request);
  const amount = z.number().positive().parse(request.body.amount);
  const goal = await Goal.findOne({ _id: request.params.id, userId, status: 'active' });
  if (!goal) throw new ApiError(404, 'Goal Not Found', 'This goal is not available for the signed-in user.');
  goal.currentSavedPaise = (goal.currentSavedPaise ?? 0) + rupeesToPaise(amount);
  await goal.save();
  response.json({
    goal: {
      id: goal._id.toString(),
      name: goal.name,
      goalType: goal.goalType,
      targetAmount: Number((goal.targetAmountPaise ?? 0) / 100),
      currentSaved: Number((goal.currentSavedPaise ?? 0) / 100),
      targetDate: goal.targetDate,
      priority: goal.priority ?? 3,
      icon: 'flag_rounded',
    },
  });
}));

export default router;
