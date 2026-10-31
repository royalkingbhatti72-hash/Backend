import { prisma } from '../prisma';
import crypto from 'crypto';

export async function syncAllUsersProgress() {
  console.log('[Sync] Starting high-performance user level and task progression synchronization...');

  // Fetch all 10 levels
  const levels = await prisma.level.findMany({
    orderBy: { levelNumber: 'asc' },
    include: {
      tasks: {
        orderBy: { taskNumber: 'asc' },
      },
    },
  });

  if (levels.length !== 10) {
    throw new Error(`Expected exactly 10 levels in DB, found ${levels.length}`);
  }

  const allTasks = levels.flatMap((l) => l.tasks);
  if (allTasks.length !== 100) {
    throw new Error(`Expected exactly 100 tasks in DB, found ${allTasks.length}`);
  }

  // Fetch all users
  const users = await prisma.user.findMany({
    select: {
      id: true,
      phone: true,
      name: true,
      submissions: {
        select: {
          id: true,
          taskId: true,
          status: true,
        },
      },
      taskProgress: {
        select: {
          id: true,
          taskId: true,
          status: true,
          isPaidUnlocked: true,
        },
      },
      levelProgress: {
        select: {
          id: true,
          levelId: true,
          completionStatus: true,
          approvedTaskCount: true,
        },
      },
    },
  });

  console.log(`[Sync] Found ${users.length} users to synchronize.`);

  const levelProgressRows: Array<{
    id: string;
    userId: string;
    levelId: string;
    completionStatus: string;
    approvedTaskCount: number;
    completedAt: string | null;
  }> = [];

  const taskProgressRows: Array<{
    id: string;
    userId: string;
    taskId: string;
    status: string;
    isPaidUnlocked: boolean;
    approvedAt: string | null;
  }> = [];

  for (const user of users) {
    const approvedTaskIds = new Set<string>();
    const pendingTaskIds = new Set<string>();

    for (const sub of user.submissions) {
      if (sub.status === 'APPROVED') {
        approvedTaskIds.add(sub.taskId);
      } else if (sub.status === 'PENDING') {
        pendingTaskIds.add(sub.taskId);
      }
    }

    for (const tp of user.taskProgress) {
      if (tp.status === 'APPROVED') {
        approvedTaskIds.add(tp.taskId);
      } else if (tp.status === 'PENDING_VERIFICATION') {
        pendingTaskIds.add(tp.taskId);
      }
    }

    // Determine approved counts per level
    const approvedCountsByLevelNum = new Map<number, number>();
    for (const lvl of levels) {
      let count = 0;
      for (const t of lvl.tasks) {
        if (approvedTaskIds.has(t.id)) count++;
      }
      approvedCountsByLevelNum.set(lvl.levelNumber, count);
    }

    // Determine completion status of each level
    const l1Approved = approvedCountsByLevelNum.get(1) || 0;
    const l1Completed = l1Approved >= 10;

    const l2Approved = approvedCountsByLevelNum.get(2) || 0;
    const l2Completed = l1Completed && l2Approved >= 10;

    const l3Approved = approvedCountsByLevelNum.get(3) || 0;
    const l3Completed = l2Completed && l3Approved >= 10;

    const l4Approved = approvedCountsByLevelNum.get(4) || 0;
    const l4Completed = l3Completed && l4Approved >= 1;

    const levelCompletedMap = new Map<number, boolean>();
    levelCompletedMap.set(1, l1Completed);
    levelCompletedMap.set(2, l2Completed);
    levelCompletedMap.set(3, l3Completed);
    levelCompletedMap.set(4, l4Completed);

    let prevCompleted = l4Completed;
    for (let ln = 5; ln <= 10; ln++) {
      const app = approvedCountsByLevelNum.get(ln) || 0;
      const isComp = prevCompleted && app >= 10;
      levelCompletedMap.set(ln, isComp);
      prevCompleted = isComp;
    }

    for (const lvl of levels) {
      const ln = lvl.levelNumber;
      const appCount = approvedCountsByLevelNum.get(ln) || 0;
      const isComp = levelCompletedMap.get(ln) || false;

      let completionStatus = 'LOCKED';
      if (isComp) {
        completionStatus = 'COMPLETED';
      } else if (ln === 1) {
        completionStatus = 'IN_PROGRESS';
      } else if (ln === 2) {
        completionStatus = l1Completed ? 'IN_PROGRESS' : 'LOCKED';
      } else if (ln === 3) {
        completionStatus = l2Completed ? 'IN_PROGRESS' : 'LOCKED';
      } else if (ln === 4) {
        completionStatus = l3Completed ? 'IN_PROGRESS' : 'LOCKED';
      } else if (ln === 5) {
        completionStatus = l4Completed ? 'IN_PROGRESS' : l3Completed ? 'IN_PROGRESS' : 'LOCKED';
      } else {
        const prevLevelComp = levelCompletedMap.get(ln - 1) || false;
        completionStatus = prevLevelComp ? 'IN_PROGRESS' : l3Completed ? 'IN_PROGRESS' : 'LOCKED';
      }

      const existingLp = user.levelProgress.find((p) => p.levelId === lvl.id);
      const lpId = existingLp?.id || `ulp_${crypto.randomBytes(12).toString('hex')}`;

      levelProgressRows.push({
        id: lpId,
        userId: user.id,
        levelId: lvl.id,
        completionStatus,
        approvedTaskCount: appCount,
        completedAt: isComp ? new Date().toISOString() : null,
      });

      for (const task of lvl.tasks) {
        const tn = task.taskNumber;
        const isApproved = approvedTaskIds.has(task.id);
        const isPending = pendingTaskIds.has(task.id);

        let taskStatus = 'LOCKED';

        if (isApproved) {
          taskStatus = 'APPROVED';
        } else if (isPending) {
          taskStatus = 'PENDING_VERIFICATION';
        } else {
          if (ln === 1) {
            if (tn === appCount + 1) {
              taskStatus = 'AVAILABLE';
            } else {
              taskStatus = 'LOCKED';
            }
          } else if (ln === 2) {
            if (l1Completed && tn === appCount + 1) {
              taskStatus = 'AVAILABLE';
            } else {
              taskStatus = 'LOCKED';
            }
          } else if (ln === 3) {
            if (l2Completed && tn === appCount + 1) {
              taskStatus = 'AVAILABLE';
            } else {
              taskStatus = 'LOCKED';
            }
          } else if (ln === 4) {
            if (l3Completed) {
              taskStatus = 'AVAILABLE';
            } else {
              taskStatus = 'LOCKED';
            }
          } else if (ln === 5) {
            if (l4Completed && tn === appCount + 1) {
              taskStatus = 'AVAILABLE';
            } else {
              taskStatus = 'LOCKED';
            }
          } else {
            const prevComp = levelCompletedMap.get(ln - 1) || false;
            if (prevComp && tn === appCount + 1) {
              taskStatus = 'AVAILABLE';
            } else {
              taskStatus = 'LOCKED';
            }
          }
        }

        const existingTp = user.taskProgress.find((p) => p.taskId === task.id);
        const tpId = existingTp?.id || `utp_${crypto.randomBytes(12).toString('hex')}`;

        taskProgressRows.push({
          id: tpId,
          userId: user.id,
          taskId: task.id,
          status: taskStatus,
          isPaidUnlocked: task.isPaid && isApproved,
          approvedAt: isApproved ? new Date().toISOString() : null,
        });
      }
    }
  }

  console.log(`[Sync] Prepared ${levelProgressRows.length} LevelProgress rows and ${taskProgressRows.length} TaskProgress rows.`);

  // Bulk upsert LevelProgress in chunks of 200
  const CHUNK_SIZE = 200;
  for (let i = 0; i < levelProgressRows.length; i += CHUNK_SIZE) {
    const chunk = levelProgressRows.slice(i, i + CHUNK_SIZE);
    const values = chunk
      .map(
        (r) =>
          `('${r.id}', '${r.userId}', '${r.levelId}', '${r.completionStatus}', ${r.approvedTaskCount}, ${
            r.completedAt ? `'${r.completedAt}'::timestamp` : 'NULL'
          }, NOW(), NOW())`
      )
      .join(',\n');

    const sql = `
      INSERT INTO "UserLevelProgress" ("id", "userId", "levelId", "completionStatus", "approvedTaskCount", "completedAt", "createdAt", "updatedAt")
      VALUES ${values}
      ON CONFLICT ("userId", "levelId") DO UPDATE SET
        "completionStatus" = EXCLUDED."completionStatus",
        "approvedTaskCount" = EXCLUDED."approvedTaskCount",
        "completedAt" = EXCLUDED."completedAt",
        "updatedAt" = NOW();
    `;

    await prisma.$executeRawUnsafe(sql);
    console.log(`[Sync] Upserted LevelProgress chunk ${i / CHUNK_SIZE + 1} (${chunk.length} rows)`);
  }

  // Bulk upsert TaskProgress in chunks of 250
  const TP_CHUNK_SIZE = 250;
  for (let i = 0; i < taskProgressRows.length; i += TP_CHUNK_SIZE) {
    const chunk = taskProgressRows.slice(i, i + TP_CHUNK_SIZE);
    const values = chunk
      .map(
        (r) =>
          `('${r.id}', '${r.userId}', '${r.taskId}', '${r.status}', ${r.isPaidUnlocked}, ${
            r.approvedAt ? `'${r.approvedAt}'::timestamp` : 'NULL'
          }, NOW(), NOW())`
      )
      .join(',\n');

    const sql = `
      INSERT INTO "UserTaskProgress" ("id", "userId", "taskId", "status", "isPaidUnlocked", "approvedAt", "createdAt", "updatedAt")
      VALUES ${values}
      ON CONFLICT ("userId", "taskId") DO UPDATE SET
        "status" = EXCLUDED."status",
        "isPaidUnlocked" = EXCLUDED."isPaidUnlocked",
        "approvedAt" = EXCLUDED."approvedAt",
        "updatedAt" = NOW();
    `;

    await prisma.$executeRawUnsafe(sql);
    console.log(`[Sync] Upserted TaskProgress chunk ${i / TP_CHUNK_SIZE + 1} (${chunk.length} rows)`);
  }

  console.log(`[Sync] User progression synchronization completed successfully!`);
}

// Direct execution
if (import.meta.url === `file://${process.argv[1]}`) {
  syncAllUsersProgress()
    .then(() => {
      console.log('[Sync] Done!');
      process.exit(0);
    })
    .catch((err) => {
      console.error('[Sync] Failed:', err);
      process.exit(1);
    });
}
