import { prisma } from '../prisma';

export interface AdminReferralCodeRecord {
  id: string;
  code: string;
  status: 'AVAILABLE' | 'USED';
  usedById: string | null;
  usedByName: string | null;
  usedByPhone: string | null;
  usedAt: Date | string | null;
  notes: string | null;
  createdAt: Date | string;
  updatedAt: Date | string;
}

let tableEnsured = false;

/**
 * Ensures the AdminReferralCode table exists in PostgreSQL and populates
 * the initial 100 specific exclusive referral codes.
 */
export async function ensureAdminReferralCodes(): Promise<void> {
  if (tableEnsured) return;

  try {
    // 1. Create table if it does not exist
    await prisma.$executeRawUnsafe(`
      CREATE TABLE IF NOT EXISTS "AdminReferralCode" (
        "id" TEXT NOT NULL PRIMARY KEY,
        "code" TEXT NOT NULL UNIQUE,
        "status" TEXT NOT NULL DEFAULT 'AVAILABLE',
        "usedById" TEXT,
        "usedByName" TEXT,
        "usedByPhone" TEXT,
        "usedAt" TIMESTAMP(3),
        "notes" TEXT,
        "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
        "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await prisma.$executeRawUnsafe(`
      CREATE INDEX IF NOT EXISTS "AdminReferralCode_status_idx" ON "AdminReferralCode"("status")
    `);
    await prisma.$executeRawUnsafe(`
      CREATE INDEX IF NOT EXISTS "AdminReferralCode_code_idx" ON "AdminReferralCode"("code")
    `);

    // 2. Count existing codes
    const result: any = await prisma.$queryRawUnsafe(`
      SELECT COUNT(*)::int as count FROM "AdminReferralCode"
    `);
    const count = Number(result[0]?.count || 0);

    // 3. Seed initial 100 specific codes if fewer than 100 exist
    if (count < 100) {
      for (let i = 1; i <= 100; i++) {
        const codeNum = String(i).padStart(3, '0');
        const code = `ROYAL-VIP-${codeNum}`;
        const id = `arc_vip_${codeNum}`;
        await prisma.$executeRawUnsafe(`
          INSERT INTO "AdminReferralCode" ("id", "code", "status", "notes", "createdAt", "updatedAt")
          VALUES ($1, $2, 'AVAILABLE', 'Initial Official Admin Invitation Pool', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
          ON CONFLICT ("code") DO NOTHING;
        `, id, code);
      }
    }

    tableEnsured = true;
  } catch (err) {
    console.error('Error ensuring AdminReferralCode table:', err);
  }
}

/**
 * Fetches all available and used referral codes for the Admin Panel.
 */
export async function getAdminReferralCodesOverview() {
  await ensureAdminReferralCodes();

  const [availableCodes, usedCodes]: [any[], any[]] = await Promise.all([
    prisma.$queryRawUnsafe(`
      SELECT "id", "code", "status", "usedById", "usedByName", "usedByPhone", "usedAt", "notes", "createdAt", "updatedAt"
      FROM "AdminReferralCode"
      WHERE "status" = 'AVAILABLE'
      ORDER BY "code" ASC
    `),
    prisma.$queryRawUnsafe(`
      SELECT "id", "code", "status", "usedById", "usedByName", "usedByPhone", "usedAt", "notes", "createdAt", "updatedAt"
      FROM "AdminReferralCode"
      WHERE "status" = 'USED'
      ORDER BY "usedAt" DESC NULLS LAST, "updatedAt" DESC
    `),
  ]);

  return {
    availableCodes,
    usedCodes,
    stats: {
      total: availableCodes.length + usedCodes.length,
      available: availableCodes.length,
      used: usedCodes.length,
    },
  };
}

/**
 * Validates whether an admin referral code is available.
 */
export async function validateAdminReferralCode(rawCode: string): Promise<boolean> {
  await ensureAdminReferralCodes();
  const code = (rawCode || '').trim().toUpperCase();
  if (!code) return false;

  const result: any[] = await prisma.$queryRawUnsafe(`
    SELECT "id" FROM "AdminReferralCode"
    WHERE "code" = $1 AND "status" = 'AVAILABLE'
    LIMIT 1
  `, code);

  return result.length > 0;
}

/**
 * Claims a referral code upon user registration.
 */
export async function claimAdminReferralCode(
  rawCode: string,
  user: { id: string; name: string; phone: string }
): Promise<boolean> {
  await ensureAdminReferralCodes();
  const code = (rawCode || '').trim().toUpperCase();
  if (!code) return false;

  const updateResult = await prisma.$executeRawUnsafe(`
    UPDATE "AdminReferralCode"
    SET "status" = 'USED',
        "usedById" = $1,
        "usedByName" = $2,
        "usedByPhone" = $3,
        "usedAt" = CURRENT_TIMESTAMP,
        "updatedAt" = CURRENT_TIMESTAMP
    WHERE "code" = $4 AND "status" = 'AVAILABLE'
  `, user.id, user.name, user.phone, code);

  return updateResult > 0;
}

/**
 * Generates additional batches of exclusive referral codes.
 */
export async function generateAdditionalCodes(count = 10, prefix = 'ROYAL-VIP'): Promise<string[]> {
  await ensureAdminReferralCodes();
  const generated: string[] = [];

  const maxResult: any[] = await prisma.$queryRawUnsafe(`
    SELECT "code" FROM "AdminReferralCode"
    WHERE "code" LIKE $1
    ORDER BY "code" DESC
    LIMIT 1
  `, `${prefix}-%`);

  let nextIndex = 101;
  if (maxResult.length > 0) {
    const lastNum = parseInt(maxResult[0].code.replace(`${prefix}-`, ''), 10);
    if (!isNaN(lastNum)) nextIndex = lastNum + 1;
  }

  for (let i = 0; i < count; i++) {
    const codeNum = String(nextIndex + i).padStart(3, '0');
    const code = `${prefix}-${codeNum}`;
    const id = `arc_gen_${Date.now()}_${i}`;

    await prisma.$executeRawUnsafe(`
      INSERT INTO "AdminReferralCode" ("id", "code", "status", "notes", "createdAt", "updatedAt")
      VALUES ($1, $2, 'AVAILABLE', 'Admin Generated Batch', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
      ON CONFLICT ("code") DO NOTHING;
    `, id, code);

    generated.push(code);
  }

  return generated;
}
