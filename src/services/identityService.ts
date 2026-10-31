import { prisma } from '../prisma';

let tableEnsured = false;

/**
 * Ensures the "IdentityVerification" table exists in PostgreSQL.
 * Guarantees zero downtime and automatic schema provision across serverless instances.
 */
export async function ensureIdentityTable(): Promise<void> {
  if (tableEnsured) return;
  try {
    await prisma.$executeRawUnsafe(`
      CREATE TABLE IF NOT EXISTS "IdentityVerification" (
        "id" TEXT NOT NULL PRIMARY KEY,
        "userId" TEXT NOT NULL UNIQUE,
        "idFrontImage" TEXT NOT NULL,
        "idBackImage" TEXT NOT NULL,
        "status" TEXT NOT NULL DEFAULT 'PENDING',
        "cnicNumber" TEXT,
        "fullName" TEXT,
        "gender" TEXT,
        "dateOfBirth" TIMESTAMP(3),
        "reviewerId" TEXT,
        "reviewerName" TEXT,
        "reviewNotes" TEXT,
        "rejectionReason" TEXT,
        "submittedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
        "reviewedAt" TIMESTAMP(3),
        "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
        "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await prisma.$executeRawUnsafe(`
      CREATE INDEX IF NOT EXISTS "IdentityVerification_status_idx" ON "IdentityVerification"("status")
    `);

    tableEnsured = true;
  } catch (err) {
    console.error('Error ensuring IdentityVerification table:', err);
  }
}
