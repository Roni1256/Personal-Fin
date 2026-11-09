type PlanLike = {
  month?: string;
  monthYm?: string;
  incomeTotalPaise?: number;
  totalIncome?: number;
  template?: string;
  templateName?: string;
  allocations?: Array<{
    id?: string;
    bucket?: string;
    label?: string;
    amountPaise?: number;
    amount?: number;
    percentage?: number;
    reason?: string;
    categoryId?: string;
  }>;
  warnings?: string[];
  assumptions?: string[];
  isApproved?: boolean;
};

const templateLabels = {
  classic_50_30_20: '50/30/20 Classic',
  aggressive_saver: 'Aggressive Saver',
  debt_crusher: 'Debt Crusher',
  family_balanced: 'Family Balanced',
  zero_based: 'Zero Based',
  freelancer_smoothing: 'Freelancer Smoothing',
  retirement_booster: 'Retirement Booster',
  goal_sprint: 'Goal Sprint',
} as const;

export function toClientPlan(plan: PlanLike) {
  const allocations = (plan.allocations ?? []).map((item) => ({
    id: item.id ?? `${item.bucket ?? 'allocation'}-${Math.random().toString(16).slice(2)}`,
    bucket: item.bucket ?? 'Misc',
    label: item.label ?? 'Allocation',
    amount: Number(((item.amountPaise ?? item.amount ?? 0) / 100).toFixed(2)),
    percentage: Number((item.percentage ?? 0).toFixed(2)),
    reason: item.reason ?? 'Budget allocation',
    categoryId: item.categoryId,
  }));

  const incomeTotalPaise = plan.incomeTotalPaise ?? plan.totalIncome ?? 0;
  const month = plan.month ?? plan.monthYm ?? '2026-10';
  const templateKey = (plan.template ?? plan.templateName ?? 'family_balanced').toString();

  return {
    monthYm: month,
    totalIncome: Number((incomeTotalPaise / 100).toFixed(2)),
    templateName: templateLabels[templateKey as keyof typeof templateLabels] ?? templateKey.replace(/_/g, ' ').replace(/\b\w/g, (ch) => ch.toUpperCase()),
    isApproved: Boolean(plan.isApproved ?? true),
    allocations,
    warnings: plan.warnings ?? [],
    assumptions: plan.assumptions ?? [],
  };
}
