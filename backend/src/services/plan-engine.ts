import { randomUUID } from 'node:crypto';

export type PlanTemplate =
  | 'classic_50_30_20'
  | 'aggressive_saver'
  | 'debt_crusher'
  | 'family_balanced'
  | 'zero_based'
  | 'freelancer_smoothing'
  | 'retirement_booster'
  | 'goal_sprint';

export interface PlanGoalInput {
  id: string;
  name: string;
  remainingPaise: number;
  priority: number;
  targetDate: Date;
}

export interface PlanInput {
  month: string;
  incomePaise: number;
  template: PlanTemplate;
  occupationType?: 'salaried' | 'business' | 'freelance' | 'retired' | 'other';
  riskProfile?: 'conservative' | 'moderate' | 'aggressive';
  essentialExpensesPaise?: number;
  emergencyFundPaise?: number;
  emergencyTargetMonths?: number;
  fixedObligations?: Array<{ label: string; amountPaise: number; categoryId?: string; bucket?: string }>;
  highInterestDebtPaise?: number;
  protectionPremiumPaise?: number;
  goals?: PlanGoalInput[];
}

export interface PlanAllocationResult {
  id: string;
  bucket: string;
  label: string;
  amountPaise: number;
  percentage: number;
  reason: string;
  categoryId?: string;
  breakdown?: Record<string, number | string>;
}

export interface PlanResult {
  month: string;
  incomeTotalPaise: number;
  template: PlanTemplate;
  rulesVersion: string;
  allocations: PlanAllocationResult[];
  warnings: string[];
  assumptions: string[];
}

const templates: Record<PlanTemplate, { needs: number; wants: number; goals: number; investments: number; emergency: number }> = {
  classic_50_30_20: { needs: 0.50, wants: 0.30, goals: 0.10, investments: 0.10, emergency: 0.10 },
  aggressive_saver: { needs: 0.45, wants: 0.15, goals: 0.20, investments: 0.20, emergency: 0.15 },
  debt_crusher: { needs: 0.50, wants: 0.10, goals: 0.10, investments: 0.10, emergency: 0.10 },
  family_balanced: { needs: 0.55, wants: 0.15, goals: 0.20, investments: 0.10, emergency: 0.12 },
  zero_based: { needs: 0.50, wants: 0.15, goals: 0.15, investments: 0.10, emergency: 0.10 },
  freelancer_smoothing: { needs: 0.45, wants: 0.10, goals: 0.10, investments: 0.10, emergency: 0.15 },
  retirement_booster: { needs: 0.45, wants: 0.15, goals: 0.10, investments: 0.30, emergency: 0.10 },
  goal_sprint: { needs: 0.45, wants: 0.10, goals: 0.35, investments: 0.10, emergency: 0.10 },
};

function assertAmount(value: number, label: string): void {
  if (!Number.isSafeInteger(value) || value < 0) throw new RangeError(`${label} must be a non-negative integer number of paise`);
}

function allocate(
  input: PlanInput,
  allocations: PlanAllocationResult[],
  bucket: string,
  label: string,
  amountPaise: number,
  reason: string,
  categoryId?: string,
  breakdown?: Record<string, number | string>,
): void {
  if (amountPaise <= 0) return;
  allocations.push({
    id: randomUUID(),
    bucket,
    label,
    amountPaise,
    percentage: input.incomePaise === 0 ? 0 : Number((amountPaise / input.incomePaise * 100).toFixed(2)),
    reason,
    ...(categoryId ? { categoryId } : {}),
    ...(breakdown ? { breakdown } : {}),
  });
}

export function generatePlan(input: PlanInput): PlanResult {
  assertAmount(input.incomePaise, 'Income');
  if (input.incomePaise <= 0) throw new RangeError('Income must be greater than zero');
  if (!/^\d{4}-(0[1-9]|1[0-2])$/.test(input.month)) throw new RangeError('Month must use YYYY-MM format');

  for (const obligation of input.fixedObligations ?? []) assertAmount(obligation.amountPaise, `Obligation "${obligation.label}"`);
  assertAmount(input.essentialExpensesPaise ?? 0, 'Essential expenses');
  assertAmount(input.emergencyFundPaise ?? 0, 'Emergency fund');
  assertAmount(input.highInterestDebtPaise ?? 0, 'High-interest debt prepayment');
  assertAmount(input.protectionPremiumPaise ?? 0, 'Protection premiums');
  for (const goal of input.goals ?? []) {
    assertAmount(goal.remainingPaise, `Goal "${goal.name}" remaining amount`);
    if (!Number.isInteger(goal.priority) || goal.priority < 1 || goal.priority > 5) throw new RangeError('Goal priority must be from 1 to 5');
  }

  const template = templates[input.template];
  if (!template) throw new RangeError(`Unknown plan template: ${input.template}`);
  const obligations = input.fixedObligations ?? [];
  const fixedTotal = obligations.reduce((sum, item) => sum + item.amountPaise, 0);
  const defaultNeeds = Math.max(0, Math.round(input.incomePaise * template.needs) - fixedTotal);
  const essentialPaise = input.essentialExpensesPaise ?? defaultNeeds;
  const committedTotal = fixedTotal + essentialPaise;
  if (committedTotal > input.incomePaise) {
    throw new RangeError('Fixed obligations and essential expenses exceed monthly income');
  }

  const allocations: PlanAllocationResult[] = [];
  const warnings: string[] = [];
  const assumptions: string[] = [`Template: ${input.template}`, `Risk profile: ${input.riskProfile ?? 'moderate'}`];
  for (const obligation of obligations) {
    allocate(input, allocations, obligation.bucket ?? 'Essentials', obligation.label, obligation.amountPaise,
      'Reserved as a declared fixed monthly obligation.', obligation.categoryId);
  }
  allocate(input, allocations, 'Essentials', 'Essential living expenses', essentialPaise,
    'Estimated essential expenses excluding the fixed obligations listed above.');

  let remaining = input.incomePaise - committedTotal;
  const emergencyMonths = input.emergencyTargetMonths
    ?? (input.occupationType === 'freelance' || input.occupationType === 'business' ? 9 : 6);
  const emergencyTarget = Math.round(essentialPaise * emergencyMonths);
  const emergencyGap = Math.max(0, emergencyTarget - (input.emergencyFundPaise ?? 0));
  const emergencyContribution = Math.min(emergencyGap, Math.round(input.incomePaise * template.emergency), remaining);
  allocate(input, allocations, 'Savings & Safety', 'Emergency fund top-up', emergencyContribution,
    `Builds toward ${emergencyMonths} months of essential expenses.` , 'emergency');
  remaining -= emergencyContribution;
  if (emergencyGap > emergencyContribution) warnings.push('Emergency fund remains below its target after this plan.');
  if ((input.emergencyFundPaise ?? 0) < essentialPaise * 3) warnings.push('Emergency fund cover is below three months of essential expenses.');

  const debtPrepayment = Math.min(input.highInterestDebtPaise ?? 0, remaining);
  allocate(input, allocations, 'Debt Prepayment', 'High-interest debt prepayment', debtPrepayment,
    'Prioritises declared high-interest debt before discretionary investing.', 'emi');
  remaining -= debtPrepayment;
  if (debtPrepayment < (input.highInterestDebtPaise ?? 0)) warnings.push('Available income could not cover the requested high-interest debt prepayment.');

  const protection = Math.min(input.protectionPremiumPaise ?? 0, remaining);
  allocate(input, allocations, 'Protection', 'Insurance premiums', protection,
    'Reserves the declared insurance premium due this month.', 'insurance');
  remaining -= protection;

  const goalPool = Math.min(remaining, Math.round(input.incomePaise * template.goals));
  const goals = (input.goals ?? []).filter((goal) => goal.remainingPaise > 0);
  if (goals.length && goalPool > 0) {
    const now = new Date(`${input.month}-01T00:00:00.000Z`);
    const scores = goals.map((goal) => {
      const monthsLeft = Math.max(1, (goal.targetDate.getUTCFullYear() - now.getUTCFullYear()) * 12
        + goal.targetDate.getUTCMonth() - now.getUTCMonth());
      return (6 - goal.priority) / monthsLeft;
    });
    const scoreTotal = scores.reduce((sum, score) => sum + score, 0);
    let assigned = 0;
    goals.forEach((goal, index) => {
      const proposed = index === goals.length - 1
        ? goalPool - assigned
        : Math.floor(goalPool * scores[index]! / scoreTotal);
      const contribution = Math.min(goal.remainingPaise, proposed);
      assigned += contribution;
      allocate(input, allocations, 'Goals', goal.name, contribution,
        `Weighted by priority and months remaining; ${goal.remainingPaise - contribution} paise remains to target.`, undefined,
        { goalId: goal.id });
    });
    remaining -= assigned;
  }

  const investable = Math.min(remaining, Math.round(input.incomePaise * template.investments));
  const risk = input.riskProfile ?? 'moderate';
  const investmentSplit = risk === 'conservative'
    ? { equity: 30, debt: 60, gold: 10 }
    : risk === 'aggressive'
      ? { equity: 80, debt: 15, gold: 5 }
      : { equity: 60, debt: 30, gold: 10 };
  allocate(input, allocations, 'Investments', 'Risk-aligned investment allocation', investable,
    'Illustrative asset-class split based on the selected risk profile; not a product recommendation.', 'investment', investmentSplit);
  remaining -= investable;

  const lifestyleCap = Math.round(input.incomePaise * template.wants);
  const lifestyle = Math.min(remaining, lifestyleCap);
  allocate(input, allocations, 'Lifestyle', 'Lifestyle spending', lifestyle,
    'Discretionary spending is capped by the selected template.', 'dining');
  remaining -= lifestyle;

  allocate(input, allocations, 'Buffer / Misc', 'Contingency buffer', remaining,
    'Unallocated income is kept as a cash-flow buffer.');

  const sum = allocations.reduce((total, allocation) => total + allocation.amountPaise, 0);
  if (sum !== input.incomePaise || allocations.some((item) => item.amountPaise < 0)) {
    throw new Error('Plan invariant failed: allocations must be non-negative and sum exactly to income');
  }
  if (committedTotal > Math.round(input.incomePaise * template.needs)) {
    warnings.push('Fixed obligations and essential costs exceed the template needs allocation.');
  }

  return {
    month: input.month,
    incomeTotalPaise: input.incomePaise,
    template: input.template,
    rulesVersion: '1.0.0',
    allocations,
    warnings,
    assumptions,
  };
}
