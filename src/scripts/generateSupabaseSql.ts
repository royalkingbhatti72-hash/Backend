import fs from 'fs';
import path from 'path';
import { DATASET_10_LEVELS, cleanUrl } from '../../prisma/dataset10Levels';

function escapeSql(str: string): string {
  return str.replace(/'/g, "''");
}

export function generateSql() {
  const sqlLines: string[] = [];

  sqlLines.push(`-- ====================================================================`);
  sqlLines.push(`-- EARN STREET / ROYAL REWARDS - TASKS PLAN & USER PROGRESSION UPDATE`);
  sqlLines.push(`-- Supabase Project: iwzonipiymbsspnyoszt`);
  sqlLines.push(`-- Paste and run this script in Supabase Dashboard -> SQL Editor`);
  sqlLines.push(`-- ====================================================================\n`);

  // Ensure Level table and Task table exist
  sqlLines.push(`-- 1. Upsert All 10 Levels`);
  for (const lvl of DATASET_10_LEVELS) {
    const levelId = `level_${lvl.level}`;
    const title = escapeSql(lvl.title);
    const desc = escapeSql(`Sequential milestone Tier ${lvl.level}. Complete tasks to unlock subsequent tiers.`);
    const reqCount = lvl.level === 4 ? 1 : 10;
    const reward = lvl.level_reward;

    sqlLines.push(`
INSERT INTO "Level" ("id", "levelNumber", "title", "description", "status", "requiredTaskCount", "completionReward", "totalCreditPoints", "displayOrder", "createdAt", "updatedAt")
VALUES ('${levelId}', ${lvl.level}, '${title}', '${desc}', 'ACTIVE', ${reqCount}, ${reward}, 100, ${lvl.level}, NOW(), NOW())
ON CONFLICT ("levelNumber") DO UPDATE SET
  "title" = EXCLUDED."title",
  "description" = EXCLUDED."description",
  "requiredTaskCount" = EXCLUDED."requiredTaskCount",
  "completionReward" = EXCLUDED."completionReward",
  "totalCreditPoints" = EXCLUDED."totalCreditPoints",
  "displayOrder" = EXCLUDED."displayOrder",
  "status" = 'ACTIVE',
  "updatedAt" = NOW();
`);
  }

  // Upsert all 100 Tasks
  sqlLines.push(`\n-- 2. Upsert All 100 Tasks (10 per Level)`);
  for (const lvl of DATASET_10_LEVELS) {
    for (const t of lvl.tasks) {
      const taskId = `task_l${lvl.level}_t${t.task_id}`;
      const url = cleanUrl(t.url);
      const isPaid = t.is_prepaid;
      const unlockFee = t.prepaid_value || 0;
      const reward = t.commission;
      const type = escapeSql(t.type);
      const title = isPaid
        ? escapeSql(`Level ${lvl.level} - Task ${t.task_id} (Prepaid Rs ${unlockFee.toLocaleString()})`)
        : escapeSql(`Level ${lvl.level} - Task ${t.task_id}`);
      const desc = isPaid
        ? escapeSql(`Prepaid Task: Rs ${unlockFee.toLocaleString()} unlock fee with guaranteed 40% commission reward (Rs ${reward.toLocaleString()}).`)
        : escapeSql(`Free Task: Complete ${t.type} assignment to earn Rs ${reward.toLocaleString()} verified reward.`);
      const instructions = escapeSql(`1. Click the official link below: ${url}\n2. Perform the required assignment.\n3. Submit transaction/reference proof for admin review.`);

      sqlLines.push(`
INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  '${taskId}', "id", ${t.task_id}, '${title}', '${desc}', '${type}',
  ${reward}, 0, ${isPaid}, ${unlockFee}, '${url}',
  '${instructions}', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = ${lvl.level}
ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET
  "title" = EXCLUDED."title",
  "description" = EXCLUDED."description",
  "taskType" = EXCLUDED."taskType",
  "rewardAmount" = EXCLUDED."rewardAmount",
  "creditPoints" = 0,
  "isPaid" = EXCLUDED."isPaid",
  "unlockFee" = EXCLUDED."unlockFee",
  "protectedUrl" = EXCLUDED."protectedUrl",
  "instructions" = EXCLUDED."instructions",
  "status" = 'ACTIVE',
  "updatedAt" = NOW();
`);
    }
  }

  // Delete excess tasks (>10) for levels 1 to 10
  sqlLines.push(`\n-- 3. Remove Any Excess Tasks (> 10 per Level)`);
  sqlLines.push(`
DELETE FROM "Task" WHERE "taskNumber" > 10;
`);

  // Synchronize UserLevelProgress & UserTaskProgress for ALL users
  sqlLines.push(`\n-- 4. Synchronize UserLevelProgress for ALL Users`);
  sqlLines.push(`
WITH user_level_counts AS (
  SELECT
    u."id" AS "userId",
    l."id" AS "levelId",
    l."levelNumber",
    COALESCE(COUNT(DISTINCT ts."taskId") FILTER (WHERE ts."status" = 'APPROVED'), 0) AS "approvedCount"
  FROM "User" u
  CROSS JOIN "Level" l
  LEFT JOIN "Task" t ON t."levelId" = l."id"
  LEFT JOIN "TaskSubmission" ts ON ts."userId" = u."id" AND ts."taskId" = t."id"
  GROUP BY u."id", l."id", l."levelNumber"
),
user_level_status AS (
  SELECT
    ulc."userId",
    ulc."levelId",
    ulc."levelNumber",
    ulc."approvedCount",
    CASE
      -- Level 1
      WHEN ulc."levelNumber" = 1 THEN
        CASE WHEN ulc."approvedCount" >= 10 THEN 'COMPLETED' ELSE 'IN_PROGRESS' END
      -- Level 2
      WHEN ulc."levelNumber" = 2 THEN
        CASE
          WHEN ulc."approvedCount" >= 10 AND (SELECT "approvedCount" FROM user_level_counts WHERE "userId" = ulc."userId" AND "levelNumber" = 1) >= 10 THEN 'COMPLETED'
          WHEN (SELECT "approvedCount" FROM user_level_counts WHERE "userId" = ulc."userId" AND "levelNumber" = 1) >= 10 THEN 'IN_PROGRESS'
          ELSE 'LOCKED'
        END
      -- Level 3
      WHEN ulc."levelNumber" = 3 THEN
        CASE
          WHEN ulc."approvedCount" >= 10 AND (SELECT "approvedCount" FROM user_level_counts WHERE "userId" = ulc."userId" AND "levelNumber" = 2) >= 10 THEN 'COMPLETED'
          WHEN (SELECT "approvedCount" FROM user_level_counts WHERE "userId" = ulc."userId" AND "levelNumber" = 2) >= 10 THEN 'IN_PROGRESS'
          ELSE 'LOCKED'
        END
      -- Level 4 (Completing 1 task is required!)
      WHEN ulc."levelNumber" = 4 THEN
        CASE
          WHEN ulc."approvedCount" >= 1 AND (SELECT "approvedCount" FROM user_level_counts WHERE "userId" = ulc."userId" AND "levelNumber" = 3) >= 10 THEN 'COMPLETED'
          WHEN (SELECT "approvedCount" FROM user_level_counts WHERE "userId" = ulc."userId" AND "levelNumber" = 3) >= 10 THEN 'IN_PROGRESS'
          ELSE 'LOCKED'
        END
      -- Levels 5 to 10 (Browseable/visible once Level 3 is completed)
      ELSE
        CASE
          WHEN ulc."approvedCount" >= 10 AND (SELECT "approvedCount" FROM user_level_counts WHERE "userId" = ulc."userId" AND "levelNumber" = ulc."levelNumber" - 1) >= (CASE WHEN ulc."levelNumber" - 1 = 4 THEN 1 ELSE 10 END) THEN 'COMPLETED'
          WHEN (SELECT "approvedCount" FROM user_level_counts WHERE "userId" = ulc."userId" AND "levelNumber" = 3) >= 10 THEN 'IN_PROGRESS'
          ELSE 'LOCKED'
        END
    END AS "computedStatus"
  FROM user_level_counts ulc
)
INSERT INTO "UserLevelProgress" ("id", "userId", "levelId", "completionStatus", "approvedTaskCount", "completedAt", "createdAt", "updatedAt")
SELECT
  'ulp_' || SUBSTRING(MD5(uls."userId" || '_' || uls."levelId") FROM 1 FOR 24),
  uls."userId",
  uls."levelId",
  uls."computedStatus",
  uls."approvedCount",
  CASE WHEN uls."computedStatus" = 'COMPLETED' THEN NOW() ELSE NULL END,
  NOW(),
  NOW()
FROM user_level_status uls
ON CONFLICT ("userId", "levelId") DO UPDATE SET
  "completionStatus" = EXCLUDED."completionStatus",
  "approvedTaskCount" = EXCLUDED."approvedTaskCount",
  "completedAt" = EXCLUDED."completedAt",
  "updatedAt" = NOW();
`);

  sqlLines.push(`\n-- 5. Synchronize UserTaskProgress for ALL Users (all 100 tasks)`);
  sqlLines.push(`
WITH user_comp AS (
  SELECT
    ulp."userId",
    MAX(CASE WHEN l."levelNumber" = 1 AND ulp."completionStatus" = 'COMPLETED' THEN 1 ELSE 0 END) AS l1_comp,
    MAX(CASE WHEN l."levelNumber" = 2 AND ulp."completionStatus" = 'COMPLETED' THEN 1 ELSE 0 END) AS l2_comp,
    MAX(CASE WHEN l."levelNumber" = 3 AND ulp."completionStatus" = 'COMPLETED' THEN 1 ELSE 0 END) AS l3_comp,
    MAX(CASE WHEN l."levelNumber" = 4 AND ulp."completionStatus" = 'COMPLETED' THEN 1 ELSE 0 END) AS l4_comp
  FROM "UserLevelProgress" ulp
  JOIN "Level" l ON l."id" = ulp."levelId"
  GROUP BY ulp."userId"
),
approved_tasks AS (
  SELECT "userId", "taskId"
  FROM "TaskSubmission"
  WHERE "status" = 'APPROVED'
  GROUP BY "userId", "taskId"
),
pending_tasks AS (
  SELECT "userId", "taskId"
  FROM "TaskSubmission"
  WHERE "status" = 'PENDING'
  GROUP BY "userId", "taskId"
),
user_task_eval AS (
  SELECT
    u."id" AS "userId",
    t."id" AS "taskId",
    t."taskNumber",
    l."levelNumber",
    ulp."approvedTaskCount",
    (at."taskId" IS NOT NULL) AS "isApproved",
    (pt."taskId" IS NOT NULL) AS "isPending",
    COALESCE(uc.l1_comp, 0) = 1 AS "l1Comp",
    COALESCE(uc.l2_comp, 0) = 1 AS "l2Comp",
    COALESCE(uc.l3_comp, 0) = 1 AS "l3Comp",
    COALESCE(uc.l4_comp, 0) = 1 AS "l4Comp"
  FROM "User" u
  CROSS JOIN "Task" t
  JOIN "Level" l ON l."id" = t."levelId"
  JOIN "UserLevelProgress" ulp ON ulp."userId" = u."id" AND ulp."levelId" = l."id"
  LEFT JOIN user_comp uc ON uc."userId" = u."id"
  LEFT JOIN approved_tasks at ON at."userId" = u."id" AND at."taskId" = t."id"
  LEFT JOIN pending_tasks pt ON pt."userId" = u."id" AND pt."taskId" = t."id"
)
INSERT INTO "UserTaskProgress" ("id", "userId", "taskId", "status", "isPaidUnlocked", "approvedAt", "createdAt", "updatedAt")
SELECT
  'utp_' || SUBSTRING(MD5(ute."userId" || '_' || ute."taskId") FROM 1 FOR 24),
  ute."userId",
  ute."taskId",
  CASE
    WHEN ute."isApproved" THEN 'APPROVED'
    WHEN ute."isPending" THEN 'PENDING_VERIFICATION'
    -- Level 1: sequential
    WHEN ute."levelNumber" = 1 THEN
      CASE WHEN ute."taskNumber" = ute."approvedTaskCount" + 1 THEN 'AVAILABLE' ELSE 'LOCKED' END
    -- Level 2: sequential if L1 completed
    WHEN ute."levelNumber" = 2 THEN
      CASE WHEN ute."l1Comp" AND ute."taskNumber" = ute."approvedTaskCount" + 1 THEN 'AVAILABLE' ELSE 'LOCKED' END
    -- Level 3: sequential if L2 completed
    WHEN ute."levelNumber" = 3 THEN
      CASE WHEN ute."l2Comp" AND ute."taskNumber" = ute."approvedTaskCount" + 1 THEN 'AVAILABLE' ELSE 'LOCKED' END
    -- Level 4: all 10 tasks AVAILABLE and selectable if Level 3 completed!
    WHEN ute."levelNumber" = 4 THEN
      CASE WHEN ute."l3Comp" THEN 'AVAILABLE' ELSE 'LOCKED' END
    -- Level 5: participation unlocked if Level 4 completed (>= 1 task approved)
    WHEN ute."levelNumber" = 5 THEN
      CASE WHEN ute."l4Comp" AND ute."taskNumber" = ute."approvedTaskCount" + 1 THEN 'AVAILABLE' ELSE 'LOCKED' END
    -- Levels 6 to 10: unlocked sequentially
    ELSE
      CASE WHEN ute."l4Comp" AND ute."taskNumber" = ute."approvedTaskCount" + 1 THEN 'AVAILABLE' ELSE 'LOCKED' END
  END AS "status",
  ute."isApproved" AS "isPaidUnlocked",
  CASE WHEN ute."isApproved" THEN NOW() ELSE NULL END AS "approvedAt",
  NOW(),
  NOW()
FROM user_task_eval ute
ON CONFLICT ("userId", "taskId") DO UPDATE SET
  "status" = EXCLUDED."status",
  "isPaidUnlocked" = EXCLUDED."isPaidUnlocked",
  "approvedAt" = EXCLUDED."approvedAt",
  "updatedAt" = NOW();
`);

  sqlLines.push(`\n-- 6. Verification Queries`);
  sqlLines.push(`
SELECT 'Levels Count' AS metric, COUNT(*) AS total FROM "Level";
SELECT 'Tasks Count' AS metric, COUNT(*) AS total FROM "Task";
SELECT 'UserLevelProgress Rows' AS metric, COUNT(*) AS total FROM "UserLevelProgress";
SELECT 'UserTaskProgress Rows' AS metric, COUNT(*) AS total FROM "UserTaskProgress";
`);

  const fullSql = sqlLines.join('\n');
  const rootDir = process.cwd().endsWith('backend') ? path.resolve(process.cwd(), '..') : process.cwd();
  const outPath1 = path.resolve(rootDir, 'backend/prisma/supabase_update_tasks_and_progression.sql');
  const outPath2 = path.resolve(rootDir, 'prisma/supabase_update_tasks_and_progression.sql');
  fs.writeFileSync(outPath1, fullSql, 'utf-8');
  fs.writeFileSync(outPath2, fullSql, 'utf-8');
  console.log(`[SQL Generator] Wrote ${fullSql.length} bytes to ${outPath1} and ${outPath2}`);

  // Also update supabase_full_setup.sql
  const setupPath = path.resolve(rootDir, 'backend/prisma/supabase_full_setup.sql');
  if (fs.existsSync(setupPath)) {
    const origSetup = fs.readFileSync(setupPath, 'utf-8');
    const ddlHeader = origSetup.split('INSERT INTO "Level"')[0];
    const newFullSetup = ddlHeader.trim() + '\n\n' + fullSql;
    fs.writeFileSync(setupPath, newFullSetup, 'utf-8');
    const rootSetupPath = path.resolve(rootDir, 'prisma/supabase_full_setup.sql');
    if (fs.existsSync(path.dirname(rootSetupPath))) {
      fs.writeFileSync(rootSetupPath, newFullSetup, 'utf-8');
    }
    console.log(`[SQL Generator] Updated full setup SQL at ${setupPath}`);
  }
}

generateSql();
