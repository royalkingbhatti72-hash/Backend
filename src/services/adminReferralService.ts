import { prisma } from '../prisma';
import { notifyTelegramCodeUsed } from './telegramService';

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
 * Generates a random 6-letter alphabetical code in lowercase (e.g. "lbhyfr").
 */
export function generateSixLetterCode(): string {
  const alphabet = 'abcdefghijklmnopqrstuvwxyz';
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += alphabet.charAt(Math.floor(Math.random() * alphabet.length));
  }
  return code;
}

/**
 * Replenishes the available referral code pool so there are always at least 100 available codes.
 */
export async function replenishAvailableCodesTo100(): Promise<void> {
  try {
    // Remove any legacy AVAILABLE codes that are not 6-letter alphabetical (e.g. ROYAL-VIP-001)
    await prisma.$executeRawUnsafe(`
      DELETE FROM "AdminReferralCode"
      WHERE "status" = 'AVAILABLE' AND "code" !~ '^[a-zA-Z]{6}$'
    `);

    // Normalize any existing 6-letter AVAILABLE codes to lowercase for consistency
    await prisma.$executeRawUnsafe(`
      UPDATE "AdminReferralCode"
      SET "code" = LOWER("code")
      WHERE "status" = 'AVAILABLE' AND "code" ~ '^[a-zA-Z]{6}$' AND "code" != LOWER("code")
    `);

    const countRes = await prisma.$queryRawUnsafe<any[]>(`
      SELECT COUNT(*)::int AS count FROM "AdminReferralCode" WHERE "status" = 'AVAILABLE'
    `);
    const currentAvailable = Number(countRes[0]?.count || 0);
    const needed = 100 - currentAvailable;

    if (needed <= 0) return;

    // Fetch existing codes to avoid collisions
    const existingRows = await prisma.$queryRawUnsafe<any[]>(`
      SELECT LOWER("code") AS code FROM "AdminReferralCode"
    `);
    const existingSet = new Set<string>(existingRows.map((r) => String(r.code).toLowerCase()));

    const newCodes: { id: string; code: string }[] = [];
    let attempts = 0;
    while (newCodes.length < needed && attempts < needed * 20) {
      attempts++;
      const candidate = generateSixLetterCode();
      if (!existingSet.has(candidate)) {
        existingSet.add(candidate);
        newCodes.push({
          id: `arc_${Date.now()}_${Math.random().toString(36).substring(2, 8)}_${newCodes.length}`,
          code: candidate,
        });
      }
    }

    if (newCodes.length > 0) {
      const valuesSql = newCodes
        .map(
          (item) =>
            `('${item.id}', '${item.code}', 'AVAILABLE', 'Official 6-Letter Admin Referral Code', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
        )
        .join(',\n');

      await prisma.$executeRawUnsafe(`
        INSERT INTO "AdminReferralCode" ("id", "code", "status", "notes", "createdAt", "updatedAt")
        VALUES ${valuesSql}
        ON CONFLICT ("code") DO NOTHING;
      `);
    }
  } catch (err) {
    console.error('Error replenishing admin referral codes to 100:', err);
  }
}

/**
 * Ensures the AdminReferralCode table exists in PostgreSQL and maintains
 * 100 6-letter alphabetical referral codes.
 */
export async function ensureAdminReferralCodes(): Promise<void> {
  if (!tableEnsured) {
    try {
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

      tableEnsured = true;
    } catch (err) {
      console.error('Error ensuring AdminReferralCode table:', err);
    }
  }

  await replenishAvailableCodesTo100();
}

/**
 * Fetches all available and used referral codes for the Admin Panel.
 */
export async function getAdminReferralCodesOverview() {
  await ensureAdminReferralCodes();

  const [availableCodes, usedCodes] = await Promise.all([
    prisma.$queryRawUnsafe<any[]>(`
      SELECT "id", "code", "status", "usedById", "usedByName", "usedByPhone", "usedAt", "notes", "createdAt", "updatedAt"
      FROM "AdminReferralCode"
      WHERE "status" = 'AVAILABLE'
      ORDER BY "createdAt" DESC, "code" ASC
    `),
    prisma.$queryRawUnsafe<any[]>(`
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
 * Validates whether an admin referral code is available (case-insensitive: lbhyfr, LBHYFR, Lbhyfr).
 */
export async function validateAdminReferralCode(rawCode: string): Promise<boolean> {
  await ensureAdminReferralCodes();
  const code = (rawCode || '').trim().toLowerCase();
  if (!code) return false;

  const result = await prisma.$queryRawUnsafe<any[]>(
    `
    SELECT "id" FROM "AdminReferralCode"
    WHERE LOWER("code") = $1 AND "status" = 'AVAILABLE'
    LIMIT 1
  `,
    code
  );

  return result.length > 0;
}

/**
 * Claims a referral code upon user registration (case-insensitive) and immediately generates
 * 1 replacement code so there are always 100 available codes.
 */
export async function claimAdminReferralCode(
  rawCode: string,
  user: { id: string; name: string; phone: string }
): Promise<boolean> {
  await ensureAdminReferralCodes();
  const code = (rawCode || '').trim().toLowerCase();
  if (!code) return false;

  const updateResult = await prisma.$executeRawUnsafe(
    `
    UPDATE "AdminReferralCode"
    SET "status" = 'USED',
        "usedById" = $1,
        "usedByName" = $2,
        "usedByPhone" = $3,
        "usedAt" = CURRENT_TIMESTAMP,
        "updatedAt" = CURRENT_TIMESTAMP
    WHERE LOWER("code") = $4 AND "status" = 'AVAILABLE'
  `,
    user.id,
    user.name,
    user.phone,
    code
  );

  if (updateResult > 0) {
    // Automatically generate 1 new 6-letter code to replace the used code so pool stays at 100
    await replenishAvailableCodesTo100();

    // Notify the Telegram client who requested this code
    notifyTelegramCodeUsed(code, user).catch((err) => {
      console.error('Error in notifyTelegramCodeUsed:', err);
    });

    return true;
  }

  return false;
}

/**
 * Generates additional batches of 6-letter alphabetical referral codes.
 */
export async function generateAdditionalCodes(count = 10): Promise<string[]> {
  await ensureAdminReferralCodes();
  const generated: string[] = [];

  const existingRows = await prisma.$queryRawUnsafe<any[]>(`
    SELECT LOWER("code") AS code FROM "AdminReferralCode"
  `);
  const existingSet = new Set<string>(existingRows.map((r) => String(r.code).toLowerCase()));

  let attempts = 0;
  while (generated.length < count && attempts < count * 20) {
    attempts++;
    const code = generateSixLetterCode();
    if (!existingSet.has(code)) {
      existingSet.add(code);
      const id = `arc_gen_${Date.now()}_${Math.random().toString(36).substring(2, 7)}_${generated.length}`;

      await prisma.$executeRawUnsafe(
        `
        INSERT INTO "AdminReferralCode" ("id", "code", "status", "notes", "createdAt", "updatedAt")
        VALUES ($1, $2, 'AVAILABLE', 'Official 6-Letter Admin Referral Code', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        ON CONFLICT ("code") DO NOTHING;
      `,
        id,
        code
      );

      generated.push(code);
    }
  }

  return generated;
}
