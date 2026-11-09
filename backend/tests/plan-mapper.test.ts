import { describe, expect, it } from 'vitest';
import { toClientPlan } from '../src/services/plan-mapper.js';

describe('toClientPlan', () => {
  it('converts backend plan values to the UI-friendly currency format', () => {
    const plan = toClientPlan({
      month: '2026-10',
      incomeTotalPaise: 6_000_000,
      template: 'family_balanced',
      rulesVersion: '1.0.0',
      allocations: [
        {
          id: 'a1',
          bucket: 'Essentials',
          label: 'Essentials',
          amountPaise: 2_200_000,
          percentage: 36.67,
          reason: 'Home and groceries',
          categoryId: 'rent',
        },
      ],
      warnings: [],
      assumptions: ['Template: family_balanced'],
    });

    expect(plan.totalIncome).toBe(60000);
    expect(plan.allocations[0]).toMatchObject({
      bucket: 'Essentials',
      amount: 22000,
      percentage: 36.67,
      categoryId: 'rent',
    });
    expect(plan.templateName).toBe('Family Balanced');
  });
});
