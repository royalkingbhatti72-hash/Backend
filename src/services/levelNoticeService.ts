import { prisma } from '../prisma';

export const DEFAULT_LEVEL_WITHDRAWAL_NOTICES: Record<number, string> = {
  1: 'Complete Level 1 to unlock the withdrawal panel for the withdrawal',
  2: 'Complete Level 2 to unlock the withdrawal panel for Level 2 reward',
  3: 'Complete Level 3 to unlock the withdrawal panel for Level 3 reward',
  4: 'Complete any of the tasks from Level 4 to unlock the withdrawal panel for Level 4 reward',
  5: 'Complete Level 5 to unlock the withdrawal panel for Level 5 reward',
  6: 'Complete Level 6 to unlock the withdrawal panel for Level 6 reward',
  7: 'Complete Level 7 to unlock the withdrawal panel for Level 7 reward',
  8: 'Complete Level 8 to unlock the withdrawal panel for Level 8 reward',
  9: 'Complete Level 9 to unlock the withdrawal panel for Level 9 reward',
  10: 'Complete Level 10 to unlock the withdrawal panel for Level 10 reward',
};

/**
 * Retrieves all level withdrawal notices from SiteSetting,
 * falling back to default notices.
 */
export async function getAllLevelWithdrawalNotices(): Promise<Record<number, string>> {
  try {
    const settings = await prisma.siteSetting.findMany({
      where: {
        key: {
          startsWith: 'WITHDRAWAL_NOTICE_LEVEL_',
        },
      },
    });

    const result: Record<number, string> = { ...DEFAULT_LEVEL_WITHDRAWAL_NOTICES };
    for (const s of settings) {
      const lvlNum = parseInt(s.key.replace('WITHDRAWAL_NOTICE_LEVEL_', ''), 10);
      if (!isNaN(lvlNum) && s.value) {
        result[lvlNum] = s.value;
      }
    }
    return result;
  } catch (err) {
    console.error('Failed to load level withdrawal notices from SiteSetting:', err);
    return { ...DEFAULT_LEVEL_WITHDRAWAL_NOTICES };
  }
}

/**
 * Retrieves withdrawal notice for a specific level.
 */
export async function getLevelWithdrawalNotice(levelNumber: number): Promise<string> {
  const notices = await getAllLevelWithdrawalNotices();
  return (
    notices[levelNumber] ||
    DEFAULT_LEVEL_WITHDRAWAL_NOTICES[levelNumber] ||
    `Complete Level ${levelNumber} to unlock the withdrawal panel for the withdrawal`
  );
}

/**
 * Sets withdrawal notice for a specific level in SiteSetting.
 */
export async function setLevelWithdrawalNotice(
  levelNumber: number,
  notice: string
): Promise<void> {
  const key = `WITHDRAWAL_NOTICE_LEVEL_${levelNumber}`;
  await prisma.siteSetting.upsert({
    where: { key },
    create: {
      key,
      value: notice.trim(),
      category: 'FINANCE',
      description: `Withdrawal requirement notice for Level ${levelNumber}`,
    },
    update: {
      value: notice.trim(),
    },
  });
}

