import { Router } from 'express';
import { z } from 'zod';
import { asyncHandler } from '../middleware/async-handler.js';
import { requireAuth, userIdFrom } from '../middleware/auth.js';
import { ApiError } from '../middleware/errors.js';
import { Asset, FinancialSnapshot, Goal, InsurancePolicy, Liability, Profile, User } from '../models/index.js';
import { rupeesToPaise } from '../utils/money.js';

const router = Router();
router.use(requireAuth);

const profileInput = z.object({
  name: z.string().trim().min(1).max(120).optional(),
  age: z.number().int().min(18).max(120).optional(),
  cityTier: z.string().max(80).optional(),
  maritalStatus: z.string().max(40).optional(),
  dependents: z.number().int().min(0).max(30).optional(),
  occupation: z.string().max(100).optional(),
  occupationType: z.enum(['salaried', 'business', 'freelance', 'retired', 'other']).optional(),
  riskProfile: z.enum(['conservative', 'moderate', 'aggressive']).optional(),
  riskScore: z.number().int().min(0).max(100).optional(),
  taxRegime: z.enum(['old', 'new', 'unknown']).optional(),
  monthlyIncome: z.number().nonnegative().max(1_000_000_000).optional(),
  monthlyEssentialExpenses: z.number().nonnegative().max(1_000_000_000).optional(),
  emergencyFund: z.number().nonnegative().max(1_000_000_000).optional(),
  termCover: z.number().nonnegative().max(10_000_000_000).optional(),
  healthCover: z.number().nonnegative().max(10_000_000_000).optional(),
  onboardingComplete: z.boolean().optional(),
}).strict();

const sections = new Set(['personal', 'income', 'expenses', 'assets', 'liabilities', 'protection', 'goals', 'risk', 'tax']);

router.get('/profile', asyncHandler(async (request, response) => {
  const userId = userIdFrom(request);
  const [user, profile] = await Promise.all([
    User.findById(userId).select('phone email name locale'),
    Profile.findOne({ userId }),
  ]);
  if (!user) throw new ApiError(404, 'User Not Found', 'The user does not exist.');
  const value = profile?.toObject();
  response.json({
    id: user._id.toString(),
    name: user.name,
    phone: user.phone,
    email: user.email,
    age: value?.age,
    cityTier: value?.cityTier,
    maritalStatus: value?.maritalStatus,
    dependents: value?.dependents,
    occupation: value?.occupation,
    occupationType: value?.occupationType,
    riskProfile: value?.riskProfile,
    riskScore: value?.riskScore,
    taxRegime: value?.taxRegime,
    monthlyIncome: (value?.monthlyIncomePaise ?? 0) / 100,
    monthlyEssentialExpenses: (value?.monthlyEssentialExpensesPaise ?? 0) / 100,
    emergencyFund: (value?.emergencyFundPaise ?? 0) / 100,
    termCover: (value?.termCoverPaise ?? 0) / 100,
    healthCover: (value?.healthCoverPaise ?? 0) / 100,
    onboardingComplete: value?.onboardingComplete ?? false,
  });
}));

router.put('/profile', asyncHandler(async (request, response) => {
  const input = profileInput.parse(request.body);
  const userId = userIdFrom(request);
  const { name, monthlyIncome, monthlyEssentialExpenses, emergencyFund, termCover, healthCover, ...fields } = input;
  const update: Record<string, unknown> = { ...fields };
  if (monthlyIncome !== undefined) update.monthlyIncomePaise = rupeesToPaise(monthlyIncome);
  if (monthlyEssentialExpenses !== undefined) update.monthlyEssentialExpensesPaise = rupeesToPaise(monthlyEssentialExpenses);
  if (emergencyFund !== undefined) update.emergencyFundPaise = rupeesToPaise(emergencyFund);
  if (termCover !== undefined) update.termCoverPaise = rupeesToPaise(termCover);
  if (healthCover !== undefined) update.healthCoverPaise = rupeesToPaise(healthCover);
  if (name !== undefined) await User.updateOne({ _id: userId }, { $set: { name } });
  const profile = await Profile.findOneAndUpdate({ userId }, { $set: update, $setOnInsert: { userId } }, { upsert: true, new: true, runValidators: true });
  response.json({ profile });
}));

router.post('/onboarding/sections/:name', asyncHandler(async (request, response) => {
  const sectionName = request.params.name;
  if (typeof sectionName !== 'string' || !sections.has(sectionName)) throw new ApiError(404, 'Unknown Section', 'This onboarding section is not supported.');
  const data = z.record(z.unknown()).parse(request.body);
  const userId = userIdFrom(request);
  const set: Record<string, unknown> = { [`onboardingSections.${sectionName}`]: data };
  const profile = await Profile.findOneAndUpdate({ userId }, { $set: set, $setOnInsert: { userId } }, { upsert: true, new: true, runValidators: true });
  response.json({ section: sectionName, saved: true, updatedAt: profile.get('updatedAt') });
}));

router.get('/onboarding/status', asyncHandler(async (request, response) => {
  const profile = await Profile.findOne({ userId: userIdFrom(request) }).select('onboardingSections onboardingComplete');
  const saved = profile?.onboardingSections instanceof Map ? [...profile.onboardingSections.keys()] : [];
  response.json({ complete: profile?.onboardingComplete ?? false, completedSections: saved, requiredSections: [...sections] });
}));

router.get('/health-score', asyncHandler(async (request, response) => {
  const userId = userIdFrom(request);
  const [profile, assets, liabilities, goals, insurance] = await Promise.all([
    Profile.findOne({ userId }),
    Asset.find({ userId, active: true }).select('currentValuePaise'),
    Liability.find({ userId, active: true }).select('outstandingPaise emiPaise'),
    Goal.find({ userId, status: 'active' }).select('_id'),
    InsurancePolicy.find({ userId, active: true }).select('sumAssuredPaise type'),
  ]);
  const totalAssets = assets.reduce((sum, item) => sum + (item.currentValuePaise ?? 0), 0);
  const totalLiabilities = liabilities.reduce((sum, item) => sum + (item.outstandingPaise ?? 0), 0);
  const income = profile?.monthlyIncomePaise ?? 0;
  const expenses = profile?.monthlyEssentialExpensesPaise ?? 0;
  const emergencyMonths = expenses > 0 ? (profile?.emergencyFundPaise ?? 0) / expenses : 0;
  const emi = liabilities.reduce((sum, item) => sum + (item.emiPaise ?? 0), 0);
  const dtiRatio = income > 0 ? emi / income : 0;
  const savingsRate = income > 0 ? Math.max(0, Math.min(1, (income - expenses - emi) / income)) : 0;
  const components = {
    emergencyFund: Math.min(25, emergencyMonths / 6 * 25),
    debt: dtiRatio <= 0.2 ? 20 : Math.max(0, 20 * (1 - (dtiRatio - 0.2) / 0.8)),
    savings: Math.min(20, savingsRate / 0.3 * 20),
    protection: insurance.length > 0 ? 15 : 0,
    goals: Math.min(10, goals.length * 3),
    netWorth: totalAssets >= totalLiabilities ? 10 : 0,
  };
  const healthScore = Math.round(Object.values(components).reduce((sum, value) => sum + value, 0));
  const snapshot = await FinancialSnapshot.create({
    userId,
    asOf: new Date(),
    netWorthPaise: totalAssets - totalLiabilities,
    totalAssetsPaise: totalAssets,
    totalLiabilitiesPaise: totalLiabilities,
    monthlyIncomePaise: income,
    monthlyExpensesPaise: expenses,
    savingsRate: Number((savingsRate * 100).toFixed(2)),
    dtiRatio: Number((dtiRatio * 100).toFixed(2)),
    emergencyMonths: Number(emergencyMonths.toFixed(2)),
    healthScore,
    components,
  });
  response.json({
    score: healthScore,
    netWorth: (totalAssets - totalLiabilities) / 100,
    totalAssets: totalAssets / 100,
    totalLiabilities: totalLiabilities / 100,
    savingsRate: snapshot.savingsRate,
    dtiRatio: snapshot.dtiRatio,
    emergencyMonths: snapshot.emergencyMonths,
    components,
    snapshotId: snapshot._id.toString(),
    disclaimer: 'This score is an educational estimate, not financial advice.',
  });
}));

router.post('/snapshots', asyncHandler(async (request, response) => {
  const userId = userIdFrom(request);
  const [profile, assets, liabilities] = await Promise.all([
    Profile.findOne({ userId }),
    Asset.find({ userId, active: true }).select('currentValuePaise'),
    Liability.find({ userId, active: true }).select('outstandingPaise emiPaise'),
  ]);
  const totalAssetsPaise = assets.reduce((sum, item) => sum + (item.currentValuePaise ?? 0), 0);
  const totalLiabilitiesPaise = liabilities.reduce((sum, item) => sum + (item.outstandingPaise ?? 0), 0);
  const monthlyIncomePaise = profile?.monthlyIncomePaise ?? 0;
  const monthlyExpensesPaise = profile?.monthlyEssentialExpensesPaise ?? 0;
  const snapshot = await FinancialSnapshot.create({
    userId, asOf: new Date(), totalAssetsPaise, totalLiabilitiesPaise,
    netWorthPaise: totalAssetsPaise - totalLiabilitiesPaise,
    monthlyIncomePaise, monthlyExpensesPaise,
  });
  response.status(201).json({ snapshot });
}));

router.get('/snapshots/latest', asyncHandler(async (request, response) => {
  const snapshot = await FinancialSnapshot.findOne({ userId: userIdFrom(request) }).sort({ asOf: -1 });
  if (!snapshot) throw new ApiError(404, 'Snapshot Not Found', 'No financial snapshot has been computed yet.');
  response.json({ snapshot });
}));

export default router;
