import { describe, expect, it } from 'vitest';
import { generatePlan } from '../src/services/plan-engine.js';

const base = {
  month: '2026-10',
  incomePaise: 6_000_000,
  template: 'family_balanced' as const,
  essentialExpensesPaise: 2_200_000,
  emergencyFundPaise: 500_000,
  fixedObligations: [{ label: 'Home loan EMI', amountPaise: 1_400_000, categoryId: 'emi' }],
  highInterestDebtPaise: 100_000,
  protectionPremiumPaise: 200_000,
  goals: [{ id: 'goal-1', name: 'Emergency reserve', remainingPaise: 800_000, priority: 1, targetDate: new Date('2027-10-01') }],
};

describe('generatePlan', () => {
  it('allocates every paise exactly once and never returns negative allocations', () => {
    const plan = generatePlan(base);
    expect(plan.allocations.reduce((sum, item) => sum + item.amountPaise, 0)).toBe(base.incomePaise);
    expect(plan.allocations.every((item) => item.amountPaise >= 0)).toBe(true);
    expect(plan.template).toBe('family_balanced');
  });

  it('reserves declared fixed obligations before discretionary allocations', () => {
    const plan = generatePlan(base);
    expect(plan.allocations[0]).toMatchObject({ label: 'Home loan EMI', amountPaise: 1_400_000 });
    expect(plan.allocations.find((item) => item.label === 'High-interest debt prepayment')?.amountPaise).toBe(100_000);
  });

  it('warns when emergency savings are below three months of essentials', () => {
    const plan = generatePlan({ ...base, emergencyFundPaise: 100_000 });
    expect(plan.warnings).toContain('Emergency fund cover is below three months of essential expenses.');
  });

  it('rejects fixed obligations and essentials above income', () => {
    expect(() => generatePlan({
      ...base,
      fixedObligations: [{ label: 'EMI', amountPaise: 5_000_000 }],
      essentialExpensesPaise: 2_000_000,
    })).toThrow(/exceed monthly income/);
  });

  it('rejects invalid month and unsafe/negative amounts', () => {
    expect(() => generatePlan({ ...base, month: 'October 2026' })).toThrow(/YYYY-MM/);
    expect(() => generatePlan({ ...base, incomePaise: -1 })).toThrow(/non-negative integer/);
  });
});
