--
-- ROYAL REWARDS / EARN SHEET - COMPLETE SUPABASE POSTGRESQL SETUP
-- Copy and paste this ENTIRE file into your Supabase SQL Editor and click "RUN"
--

-- Reset public schema cleanly to prevent relation already exists errors
DROP SCHEMA IF EXISTS "public" CASCADE;
CREATE SCHEMA "public";
GRANT ALL ON SCHEMA "public" TO postgres;
GRANT ALL ON SCHEMA "public" TO public;
COMMENT ON SCHEMA "public" IS 'standard public schema';

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "phone" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "referralCode" TEXT NOT NULL,
    "referredById" TEXT,
    "accountStatus" TEXT NOT NULL DEFAULT 'ACTIVE',
    "mustChangePassword" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Session" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Session_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AdminUser" (
    "id" TEXT NOT NULL,
    "username" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "role" TEXT NOT NULL DEFAULT 'SUPER_ADMIN',
    "status" TEXT NOT NULL DEFAULT 'ACTIVE',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "AdminUser_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Level" (
    "id" TEXT NOT NULL,
    "levelNumber" INTEGER NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'ACTIVE',
    "requiredTaskCount" INTEGER NOT NULL DEFAULT 10,
    "completionReward" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "totalCreditPoints" INTEGER NOT NULL DEFAULT 100,
    "displayOrder" INTEGER NOT NULL DEFAULT 1,
    "bannerUrl" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Level_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Task" (
    "id" TEXT NOT NULL,
    "levelId" TEXT NOT NULL,
    "taskNumber" INTEGER NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "taskType" TEXT NOT NULL DEFAULT 'Custom Task',
    "rewardAmount" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "creditPoints" INTEGER NOT NULL DEFAULT 5,
    "isPaid" BOOLEAN NOT NULL DEFAULT false,
    "unlockFee" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "protectedUrl" TEXT,
    "instructions" TEXT NOT NULL,
    "lockMessage" TEXT NOT NULL DEFAULT 'Complete and receive approval for the previous task to unlock this task.',
    "submissionInstructions" TEXT NOT NULL DEFAULT 'Submit task confirmation notes or screenshot reference for admin review.',
    "externalContact" TEXT,
    "requiresAdminApproval" BOOLEAN NOT NULL DEFAULT true,
    "status" TEXT NOT NULL DEFAULT 'ACTIVE',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Task_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "UserLevelProgress" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "levelId" TEXT NOT NULL,
    "completionStatus" TEXT NOT NULL DEFAULT 'LOCKED',
    "approvedTaskCount" INTEGER NOT NULL DEFAULT 0,
    "completedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "UserLevelProgress_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "UserTaskProgress" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "taskId" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'LOCKED',
    "isPaidUnlocked" BOOLEAN NOT NULL DEFAULT false,
    "unlockedAt" TIMESTAMP(3),
    "submissionAt" TIMESTAMP(3),
    "approvedAt" TIMESTAMP(3),
    "reviewerId" TEXT,
    "rejectionReason" TEXT,
    "completedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "UserTaskProgress_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TaskSubmission" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "taskId" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'PENDING',
    "submissionNotes" TEXT,
    "proofEvidence" TEXT,
    "reviewerId" TEXT,
    "reviewerName" TEXT,
    "reviewNotes" TEXT,
    "rejectionReason" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "TaskSubmission_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TaskUnlockTransaction" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "taskId" TEXT NOT NULL,
    "unlockFee" DOUBLE PRECISION NOT NULL,
    "transactionId" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'COMPLETED',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "TaskUnlockTransaction_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Wallet" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'PKR',
    "availableBalance" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "pendingBalance" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "totalEarned" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "totalDeposited" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "totalWithdrawn" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "totalUnlockFees" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "creditPoints" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Wallet_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WalletTransaction" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "transactionType" TEXT NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'PKR',
    "status" TEXT NOT NULL DEFAULT 'COMPLETED',
    "relatedEntityId" TEXT,
    "idempotencyKey" TEXT,
    "actorId" TEXT,
    "actorName" TEXT,
    "reason" TEXT NOT NULL,
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "WalletTransaction_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "DepositRequest" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL,
    "paymentMethod" TEXT NOT NULL,
    "transactionReference" TEXT NOT NULL,
    "proofEvidence" TEXT,
    "status" TEXT NOT NULL DEFAULT 'PENDING',
    "reviewerId" TEXT,
    "reviewerName" TEXT,
    "reviewNotes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "DepositRequest_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WithdrawalRequest" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL,
    "paymentMethod" TEXT NOT NULL,
    "recipientName" TEXT NOT NULL,
    "recipientAccount" TEXT NOT NULL,
    "notes" TEXT,
    "approvalStatus" TEXT NOT NULL DEFAULT 'PENDING',
    "paymentStatus" TEXT NOT NULL DEFAULT 'NOT_SENT',
    "reviewerId" TEXT,
    "reviewerName" TEXT,
    "reviewNotes" TEXT,
    "payoutReference" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "WithdrawalRequest_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Referral" (
    "id" TEXT NOT NULL,
    "referrerId" TEXT NOT NULL,
    "referredId" TEXT NOT NULL,
    "qualifyingStatus" TEXT NOT NULL DEFAULT 'PENDING',
    "rewardStatus" TEXT NOT NULL DEFAULT 'PENDING',
    "rewardAmount" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Referral_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SpinConfiguration" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL DEFAULT 'Default Royal Spin',
    "isEnabled" BOOLEAN NOT NULL DEFAULT true,
    "minLevelRequired" INTEGER NOT NULL DEFAULT 1,
    "referralsRequired" INTEGER NOT NULL DEFAULT 0,
    "cooldownHours" INTEGER NOT NULL DEFAULT 24,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SpinConfiguration_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SpinPrize" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "prizeType" TEXT NOT NULL DEFAULT 'CASH',
    "monetaryValue" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "displayLabel" TEXT NOT NULL,
    "color" TEXT NOT NULL DEFAULT '#1459E8',
    "icon" TEXT DEFAULT 'Crown',
    "inventory" INTEGER NOT NULL DEFAULT 999999,
    "status" TEXT NOT NULL DEFAULT 'ACTIVE',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SpinPrize_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "UserSpinEntitlement" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "assignedPrizeId" TEXT,
    "totalSpins" INTEGER NOT NULL DEFAULT 1,
    "remainingSpins" INTEGER NOT NULL DEFAULT 1,
    "isEligible" BOOLEAN NOT NULL DEFAULT true,
    "triggerReason" TEXT,
    "levelNumber" INTEGER,
    "taskNumber" INTEGER,
    "requiresAdminReview" BOOLEAN NOT NULL DEFAULT false,
    "adminReviewed" BOOLEAN NOT NULL DEFAULT false,
    "expiresAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "UserSpinEntitlement_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SpinHistory" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "entitlementId" TEXT,
    "prizeId" TEXT NOT NULL,
    "resultLabel" TEXT NOT NULL,
    "prizeValue" DOUBLE PRECISION NOT NULL,
    "rewardStatus" TEXT NOT NULL DEFAULT 'CREDITED',
    "transactionId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SpinHistory_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Notification" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "message" TEXT NOT NULL,
    "notificationType" TEXT NOT NULL DEFAULT 'SYSTEM',
    "isRead" BOOLEAN NOT NULL DEFAULT false,
    "linkUrl" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Notification_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Announcement" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "audience" TEXT NOT NULL DEFAULT 'ALL',
    "status" TEXT NOT NULL DEFAULT 'ACTIVE',
    "startDate" TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP,
    "endDate" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Announcement_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AdminAuditLog" (
    "id" TEXT NOT NULL,
    "adminId" TEXT,
    "adminUsername" TEXT NOT NULL,
    "action" TEXT NOT NULL,
    "entityType" TEXT NOT NULL,
    "entityId" TEXT NOT NULL,
    "previousState" TEXT,
    "newState" TEXT,
    "reason" TEXT,
    "ipAddress" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AdminAuditLog_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SiteSetting" (
    "id" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "value" TEXT NOT NULL,
    "description" TEXT,
    "category" TEXT NOT NULL DEFAULT 'GENERAL',
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SiteSetting_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_phone_key" ON "User"("phone");

-- CreateIndex
CREATE UNIQUE INDEX "User_referralCode_key" ON "User"("referralCode");

-- CreateIndex
CREATE UNIQUE INDEX "Session_token_key" ON "Session"("token");

-- CreateIndex
CREATE UNIQUE INDEX "AdminUser_username_key" ON "AdminUser"("username");

-- CreateIndex
CREATE UNIQUE INDEX "Level_levelNumber_key" ON "Level"("levelNumber");

-- CreateIndex
CREATE UNIQUE INDEX "Task_levelId_taskNumber_key" ON "Task"("levelId", "taskNumber");

-- CreateIndex
CREATE UNIQUE INDEX "UserLevelProgress_userId_levelId_key" ON "UserLevelProgress"("userId", "levelId");

-- CreateIndex
CREATE UNIQUE INDEX "UserTaskProgress_userId_taskId_key" ON "UserTaskProgress"("userId", "taskId");

-- CreateIndex
CREATE UNIQUE INDEX "TaskUnlockTransaction_transactionId_key" ON "TaskUnlockTransaction"("transactionId");

-- CreateIndex
CREATE UNIQUE INDEX "Wallet_userId_key" ON "Wallet"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "WalletTransaction_idempotencyKey_key" ON "WalletTransaction"("idempotencyKey");

-- CreateIndex
CREATE UNIQUE INDEX "Referral_referrerId_referredId_key" ON "Referral"("referrerId", "referredId");

-- CreateIndex
CREATE UNIQUE INDEX "SiteSetting_key_key" ON "SiteSetting"("key");

-- AddForeignKey
ALTER TABLE "User" ADD CONSTRAINT "User_referredById_fkey" FOREIGN KEY ("referredById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Session" ADD CONSTRAINT "Session_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Task" ADD CONSTRAINT "Task_levelId_fkey" FOREIGN KEY ("levelId") REFERENCES "Level"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserLevelProgress" ADD CONSTRAINT "UserLevelProgress_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserLevelProgress" ADD CONSTRAINT "UserLevelProgress_levelId_fkey" FOREIGN KEY ("levelId") REFERENCES "Level"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserTaskProgress" ADD CONSTRAINT "UserTaskProgress_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserTaskProgress" ADD CONSTRAINT "UserTaskProgress_taskId_fkey" FOREIGN KEY ("taskId") REFERENCES "Task"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TaskSubmission" ADD CONSTRAINT "TaskSubmission_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TaskSubmission" ADD CONSTRAINT "TaskSubmission_taskId_fkey" FOREIGN KEY ("taskId") REFERENCES "Task"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TaskUnlockTransaction" ADD CONSTRAINT "TaskUnlockTransaction_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TaskUnlockTransaction" ADD CONSTRAINT "TaskUnlockTransaction_taskId_fkey" FOREIGN KEY ("taskId") REFERENCES "Task"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Wallet" ADD CONSTRAINT "Wallet_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WalletTransaction" ADD CONSTRAINT "WalletTransaction_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DepositRequest" ADD CONSTRAINT "DepositRequest_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WithdrawalRequest" ADD CONSTRAINT "WithdrawalRequest_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserSpinEntitlement" ADD CONSTRAINT "UserSpinEntitlement_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserSpinEntitlement" ADD CONSTRAINT "UserSpinEntitlement_assignedPrizeId_fkey" FOREIGN KEY ("assignedPrizeId") REFERENCES "SpinPrize"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SpinHistory" ADD CONSTRAINT "SpinHistory_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SpinHistory" ADD CONSTRAINT "SpinHistory_entitlementId_fkey" FOREIGN KEY ("entitlementId") REFERENCES "UserSpinEntitlement"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SpinHistory" ADD CONSTRAINT "SpinHistory_prizeId_fkey" FOREIGN KEY ("prizeId") REFERENCES "SpinPrize"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Notification" ADD CONSTRAINT "Notification_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;



--
-- SEED DATA (Site Settings, Admin, Spin Wheel, 10 Levels & 100 Tasks)
--
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_1', 'site_name', 'Earn Sheet', 'Public platform brand name', 'GENERAL', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_2', 'support_email', 'support@earnsheet.com', 'Official support email', 'GENERAL', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_3', 'support_whatsapp', '+92 300 1234567', 'Official verification and support line', 'GENERAL', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_4', 'welcome_message', 'Welcome to Earn Sheet! Complete tasks, earn verified rewards, and spin the royal wheel!', 'User dashboard greeting banner', 'BRANDING', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_5', 'default_submission_instructions', 'Complete the required task steps. Send proof or screenshot to the official verification channel and submit your confirmation reference below.', 'Default submission guidance', 'TASKS', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_6', 'currency', 'PKR', 'Platform base currency', 'FINANCE', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_7', 'min_deposit', '500', 'Minimum allowed deposit in PKR', 'FINANCE', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_8', 'min_withdrawal', '1000', 'Minimum allowed withdrawal in PKR', 'FINANCE', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_9', 'easypaisa_title', 'Earn Sheet Official', 'Receiving Easypaisa title', 'FINANCE', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_10', 'easypaisa_number', '0312-3456789', 'Receiving Easypaisa account number', 'FINANCE', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_11', 'jazzcash_title', 'Earn Sheet Official', 'Receiving JazzCash title', 'FINANCE', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_12', 'jazzcash_number', '0301-9876543', 'Receiving JazzCash account number', 'FINANCE', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_13', 'bank_name', 'Meezan Bank Limited', 'Receiving Bank name', 'FINANCE', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_14', 'bank_title', 'Earn Sheet Enterprise PVT', 'Receiving Bank account title', 'FINANCE', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_15', 'bank_account', '01020304050607', 'Receiving Bank account number', 'FINANCE', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_16', 'bank_iban', 'PK12MEZN0001020304050607', 'Receiving Bank IBAN', 'FINANCE', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_17', 'referral_reward', '250', 'Reward per qualifying referral in PKR', 'REFERRAL', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_18', 'referral_level1_required', 'true', 'Whether referee must complete Level 1 to qualify', 'REFERRAL', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_19', 'spin_enabled', 'true', 'Global spin wheel feature toggle', 'SPIN', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_20', 'spin_cooldown_hours', '24', 'Cooldown between spins in hours', 'SPIN', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "AdminUser" ("id", "username", "passwordHash", "role", "status", "createdAt", "updatedAt") VALUES ('admin_root_1', 'admin', '$2b$10$VoGEtbceYNytJ4rvRT6gaOjUxp3.SYjry8aGQpjHTsuX3tNGyXag2', 'SUPER_ADMIN', 'ACTIVE', NOW(), NOW()) ON CONFLICT ("username") DO NOTHING;
INSERT INTO "SpinConfiguration" ("id", "name", "isEnabled", "minLevelRequired", "referralsRequired", "cooldownHours", "createdAt", "updatedAt") VALUES ('spin_config_default', 'Default Royal Spin', true, 1, 0, 24, NOW(), NOW()) ON CONFLICT ("id") DO NOTHING;
INSERT INTO "SpinPrize" ("id", "name", "prizeType", "monetaryValue", "displayLabel", "color", "icon", "inventory", "status", "createdAt", "updatedAt") VALUES ('prize_1', 'PKR 50', 'CASH', 50, 'PKR 50', '#1459E8', 'Coins', 999999, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("id") DO UPDATE SET "monetaryValue" = EXCLUDED."monetaryValue";
INSERT INTO "SpinPrize" ("id", "name", "prizeType", "monetaryValue", "displayLabel", "color", "icon", "inventory", "status", "createdAt", "updatedAt") VALUES ('prize_2', 'PKR 100', 'CASH', 100, 'PKR 100', '#792BFF', 'Gift', 999999, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("id") DO UPDATE SET "monetaryValue" = EXCLUDED."monetaryValue";
INSERT INTO "SpinPrize" ("id", "name", "prizeType", "monetaryValue", "displayLabel", "color", "icon", "inventory", "status", "createdAt", "updatedAt") VALUES ('prize_3', 'PKR 250', 'CASH', 250, 'PKR 250', '#22D3EE', 'Zap', 999999, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("id") DO UPDATE SET "monetaryValue" = EXCLUDED."monetaryValue";
INSERT INTO "SpinPrize" ("id", "name", "prizeType", "monetaryValue", "displayLabel", "color", "icon", "inventory", "status", "createdAt", "updatedAt") VALUES ('prize_4', 'PKR 500', 'CASH', 500, 'PKR 500', '#FFD45A', 'Crown', 999999, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("id") DO UPDATE SET "monetaryValue" = EXCLUDED."monetaryValue";
INSERT INTO "SpinPrize" ("id", "name", "prizeType", "monetaryValue", "displayLabel", "color", "icon", "inventory", "status", "createdAt", "updatedAt") VALUES ('prize_5', 'PKR 1,000', 'CASH', 1000, 'PKR 1,000', '#22C55E', 'Sparkles', 999999, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("id") DO UPDATE SET "monetaryValue" = EXCLUDED."monetaryValue";
INSERT INTO "SpinPrize" ("id", "name", "prizeType", "monetaryValue", "displayLabel", "color", "icon", "inventory", "status", "createdAt", "updatedAt") VALUES ('prize_6', 'PKR 5,000', 'CASH', 5000, 'PKR 5,000 Mega', '#EF4444', 'Trophy', 999999, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("id") DO UPDATE SET "monetaryValue" = EXCLUDED."monetaryValue";
INSERT INTO "SpinPrize" ("id", "name", "prizeType", "monetaryValue", "displayLabel", "color", "icon", "inventory", "status", "createdAt", "updatedAt") VALUES ('prize_7', 'Royal Gold Watch', 'PHYSICAL', 15000, 'Gold Watch', '#F59E0B', 'Watch', 999999, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("id") DO UPDATE SET "monetaryValue" = EXCLUDED."monetaryValue";
INSERT INTO "SpinPrize" ("id", "name", "prizeType", "monetaryValue", "displayLabel", "color", "icon", "inventory", "status", "createdAt", "updatedAt") VALUES ('prize_8', 'Smartphone Pro', 'PHYSICAL', 75000, 'Smartphone Pro', '#6366F1', 'Smartphone', 999999, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("id") DO UPDATE SET "monetaryValue" = EXCLUDED."monetaryValue";

-- ====================================================================
-- EARN STREET / ROYAL REWARDS - TASKS PLAN & USER PROGRESSION UPDATE
-- Supabase Project: iwzonipiymbsspnyoszt
-- Paste and run this script in Supabase Dashboard -> SQL Editor
-- ====================================================================

-- 1. Upsert All 10 Levels

INSERT INTO "Level" ("id", "levelNumber", "title", "description", "status", "requiredTaskCount", "completionReward", "totalCreditPoints", "displayOrder", "createdAt", "updatedAt")
VALUES ('level_1', 1, 'Study', 'Sequential milestone Tier 1. Complete tasks to unlock subsequent tiers.', 'ACTIVE', 10, 150, 100, 1, NOW(), NOW())
ON CONFLICT ("levelNumber") DO UPDATE SET
  "title" = EXCLUDED."title",
  "description" = EXCLUDED."description",
  "requiredTaskCount" = EXCLUDED."requiredTaskCount",
  "completionReward" = EXCLUDED."completionReward",
  "totalCreditPoints" = EXCLUDED."totalCreditPoints",
  "displayOrder" = EXCLUDED."displayOrder",
  "status" = 'ACTIVE',
  "updatedAt" = NOW();


INSERT INTO "Level" ("id", "levelNumber", "title", "description", "status", "requiredTaskCount", "completionReward", "totalCreditPoints", "displayOrder", "createdAt", "updatedAt")
VALUES ('level_2', 2, 'Vlog', 'Sequential milestone Tier 2. Complete tasks to unlock subsequent tiers.', 'ACTIVE', 10, 904, 100, 2, NOW(), NOW())
ON CONFLICT ("levelNumber") DO UPDATE SET
  "title" = EXCLUDED."title",
  "description" = EXCLUDED."description",
  "requiredTaskCount" = EXCLUDED."requiredTaskCount",
  "completionReward" = EXCLUDED."completionReward",
  "totalCreditPoints" = EXCLUDED."totalCreditPoints",
  "displayOrder" = EXCLUDED."displayOrder",
  "status" = 'ACTIVE',
  "updatedAt" = NOW();


INSERT INTO "Level" ("id", "levelNumber", "title", "description", "status", "requiredTaskCount", "completionReward", "totalCreditPoints", "displayOrder", "createdAt", "updatedAt")
VALUES ('level_3', 3, 'Vlog', 'Sequential milestone Tier 3. Complete tasks to unlock subsequent tiers.', 'ACTIVE', 10, 4080, 100, 3, NOW(), NOW())
ON CONFLICT ("levelNumber") DO UPDATE SET
  "title" = EXCLUDED."title",
  "description" = EXCLUDED."description",
  "requiredTaskCount" = EXCLUDED."requiredTaskCount",
  "completionReward" = EXCLUDED."completionReward",
  "totalCreditPoints" = EXCLUDED."totalCreditPoints",
  "displayOrder" = EXCLUDED."displayOrder",
  "status" = 'ACTIVE',
  "updatedAt" = NOW();


INSERT INTO "Level" ("id", "levelNumber", "title", "description", "status", "requiredTaskCount", "completionReward", "totalCreditPoints", "displayOrder", "createdAt", "updatedAt")
VALUES ('level_4', 4, 'Vlog', 'Sequential milestone Tier 4. Complete tasks to unlock subsequent tiers.', 'ACTIVE', 1, 332000, 100, 4, NOW(), NOW())
ON CONFLICT ("levelNumber") DO UPDATE SET
  "title" = EXCLUDED."title",
  "description" = EXCLUDED."description",
  "requiredTaskCount" = EXCLUDED."requiredTaskCount",
  "completionReward" = EXCLUDED."completionReward",
  "totalCreditPoints" = EXCLUDED."totalCreditPoints",
  "displayOrder" = EXCLUDED."displayOrder",
  "status" = 'ACTIVE',
  "updatedAt" = NOW();


INSERT INTO "Level" ("id", "levelNumber", "title", "description", "status", "requiredTaskCount", "completionReward", "totalCreditPoints", "displayOrder", "createdAt", "updatedAt")
VALUES ('level_5', 5, 'Level 5', 'Sequential milestone Tier 5. Complete tasks to unlock subsequent tiers.', 'ACTIVE', 10, 0, 100, 5, NOW(), NOW())
ON CONFLICT ("levelNumber") DO UPDATE SET
  "title" = EXCLUDED."title",
  "description" = EXCLUDED."description",
  "requiredTaskCount" = EXCLUDED."requiredTaskCount",
  "completionReward" = EXCLUDED."completionReward",
  "totalCreditPoints" = EXCLUDED."totalCreditPoints",
  "displayOrder" = EXCLUDED."displayOrder",
  "status" = 'ACTIVE',
  "updatedAt" = NOW();


INSERT INTO "Level" ("id", "levelNumber", "title", "description", "status", "requiredTaskCount", "completionReward", "totalCreditPoints", "displayOrder", "createdAt", "updatedAt")
VALUES ('level_6', 6, 'Level 6', 'Sequential milestone Tier 6. Complete tasks to unlock subsequent tiers.', 'ACTIVE', 10, 0, 100, 6, NOW(), NOW())
ON CONFLICT ("levelNumber") DO UPDATE SET
  "title" = EXCLUDED."title",
  "description" = EXCLUDED."description",
  "requiredTaskCount" = EXCLUDED."requiredTaskCount",
  "completionReward" = EXCLUDED."completionReward",
  "totalCreditPoints" = EXCLUDED."totalCreditPoints",
  "displayOrder" = EXCLUDED."displayOrder",
  "status" = 'ACTIVE',
  "updatedAt" = NOW();


INSERT INTO "Level" ("id", "levelNumber", "title", "description", "status", "requiredTaskCount", "completionReward", "totalCreditPoints", "displayOrder", "createdAt", "updatedAt")
VALUES ('level_7', 7, 'Level 7', 'Sequential milestone Tier 7. Complete tasks to unlock subsequent tiers.', 'ACTIVE', 10, 0, 100, 7, NOW(), NOW())
ON CONFLICT ("levelNumber") DO UPDATE SET
  "title" = EXCLUDED."title",
  "description" = EXCLUDED."description",
  "requiredTaskCount" = EXCLUDED."requiredTaskCount",
  "completionReward" = EXCLUDED."completionReward",
  "totalCreditPoints" = EXCLUDED."totalCreditPoints",
  "displayOrder" = EXCLUDED."displayOrder",
  "status" = 'ACTIVE',
  "updatedAt" = NOW();


INSERT INTO "Level" ("id", "levelNumber", "title", "description", "status", "requiredTaskCount", "completionReward", "totalCreditPoints", "displayOrder", "createdAt", "updatedAt")
VALUES ('level_8', 8, 'Level 8', 'Sequential milestone Tier 8. Complete tasks to unlock subsequent tiers.', 'ACTIVE', 10, 0, 100, 8, NOW(), NOW())
ON CONFLICT ("levelNumber") DO UPDATE SET
  "title" = EXCLUDED."title",
  "description" = EXCLUDED."description",
  "requiredTaskCount" = EXCLUDED."requiredTaskCount",
  "completionReward" = EXCLUDED."completionReward",
  "totalCreditPoints" = EXCLUDED."totalCreditPoints",
  "displayOrder" = EXCLUDED."displayOrder",
  "status" = 'ACTIVE',
  "updatedAt" = NOW();


INSERT INTO "Level" ("id", "levelNumber", "title", "description", "status", "requiredTaskCount", "completionReward", "totalCreditPoints", "displayOrder", "createdAt", "updatedAt")
VALUES ('level_9', 9, 'Level 9', 'Sequential milestone Tier 9. Complete tasks to unlock subsequent tiers.', 'ACTIVE', 10, 0, 100, 9, NOW(), NOW())
ON CONFLICT ("levelNumber") DO UPDATE SET
  "title" = EXCLUDED."title",
  "description" = EXCLUDED."description",
  "requiredTaskCount" = EXCLUDED."requiredTaskCount",
  "completionReward" = EXCLUDED."completionReward",
  "totalCreditPoints" = EXCLUDED."totalCreditPoints",
  "displayOrder" = EXCLUDED."displayOrder",
  "status" = 'ACTIVE',
  "updatedAt" = NOW();


INSERT INTO "Level" ("id", "levelNumber", "title", "description", "status", "requiredTaskCount", "completionReward", "totalCreditPoints", "displayOrder", "createdAt", "updatedAt")
VALUES ('level_10', 10, 'Level 10', 'Sequential milestone Tier 10. Complete tasks to unlock subsequent tiers.', 'ACTIVE', 10, 0, 100, 10, NOW(), NOW())
ON CONFLICT ("levelNumber") DO UPDATE SET
  "title" = EXCLUDED."title",
  "description" = EXCLUDED."description",
  "requiredTaskCount" = EXCLUDED."requiredTaskCount",
  "completionReward" = EXCLUDED."completionReward",
  "totalCreditPoints" = EXCLUDED."totalCreditPoints",
  "displayOrder" = EXCLUDED."displayOrder",
  "status" = 'ACTIVE',
  "updatedAt" = NOW();


-- 2. Upsert All 100 Tasks (10 per Level)

INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l1_t1', "id", 1, 'Level 1 - Task 1', 'Free Task: Complete Subscribe assignment to earn Rs 15 verified reward.', 'Subscribe',
  15, 0, false, 0, 'https://youtu.be/vo4pMVb0R6M?si=I1idXSAT49o8qQlA',
  '1. Click the official link below: https://youtu.be/vo4pMVb0R6M?si=I1idXSAT49o8qQlA
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 1
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l1_t2', "id", 2, 'Level 1 - Task 2', 'Free Task: Complete Like and Comment assignment to earn Rs 15 verified reward.', 'Like and Comment',
  15, 0, false, 0, 'https://youtu.be/00jbG_cfGuQ?si=koLvGK8-Yk-1XBbv',
  '1. Click the official link below: https://youtu.be/00jbG_cfGuQ?si=koLvGK8-Yk-1XBbv
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 1
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l1_t3', "id", 3, 'Level 1 - Task 3', 'Free Task: Complete Watch Video (30s) assignment to earn Rs 15 verified reward.', 'Watch Video (30s)',
  15, 0, false, 0, 'https://youtu.be/Yocja_N5s1I?si=9jvSeT6wfULOpTBX',
  '1. Click the official link below: https://youtu.be/Yocja_N5s1I?si=9jvSeT6wfULOpTBX
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 1
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l1_t4', "id", 4, 'Level 1 - Task 4', 'Free Task: Complete Watch Video (45s) assignment to earn Rs 15 verified reward.', 'Watch Video (45s)',
  15, 0, false, 0, 'https://youtu.be/B3u4EFTwprM?si=Yklgf1smjHpY-rbh',
  '1. Click the official link below: https://youtu.be/B3u4EFTwprM?si=Yklgf1smjHpY-rbh
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 1
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l1_t5', "id", 5, 'Level 1 - Task 5', 'Free Task: Complete Watch Video (30s) assignment to earn Rs 15 verified reward.', 'Watch Video (30s)',
  15, 0, false, 0, 'https://youtu.be/FrlJl2UXRU0?si=un0Uee3RG2nIciDe',
  '1. Click the official link below: https://youtu.be/FrlJl2UXRU0?si=un0Uee3RG2nIciDe
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 1
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l1_t6', "id", 6, 'Level 1 - Task 6', 'Free Task: Complete Subscribe assignment to earn Rs 15 verified reward.', 'Subscribe',
  15, 0, false, 0, 'https://youtu.be/9t5NOKVUTZo?si=rD4k5-dQY4icij07',
  '1. Click the official link below: https://youtu.be/9t5NOKVUTZo?si=rD4k5-dQY4icij07
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 1
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l1_t7', "id", 7, 'Level 1 - Task 7', 'Free Task: Complete Like and Comment assignment to earn Rs 15 verified reward.', 'Like and Comment',
  15, 0, false, 0, 'https://youtu.be/tZ7lsQV95yo?si=KGD7uqw1px-uC8Fb',
  '1. Click the official link below: https://youtu.be/tZ7lsQV95yo?si=KGD7uqw1px-uC8Fb
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 1
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l1_t8', "id", 8, 'Level 1 - Task 8', 'Free Task: Complete Watch Video (30s) assignment to earn Rs 15 verified reward.', 'Watch Video (30s)',
  15, 0, false, 0, 'https://youtu.be/I6O_v-cYh20?si=g4enNZAw5GCqKWb',
  '1. Click the official link below: https://youtu.be/I6O_v-cYh20?si=g4enNZAw5GCqKWb
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 1
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l1_t9', "id", 9, 'Level 1 - Task 9', 'Free Task: Complete Watch Video (45s) assignment to earn Rs 15 verified reward.', 'Watch Video (45s)',
  15, 0, false, 0, 'https://youtu.be/_phJIm8mUT8?si=NYby4z78otMFxM9',
  '1. Click the official link below: https://youtu.be/_phJIm8mUT8?si=NYby4z78otMFxM9
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 1
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l1_t10', "id", 10, 'Level 1 - Task 10', 'Free Task: Complete Watch Video (45s) assignment to earn Rs 15 verified reward.', 'Watch Video (45s)',
  15, 0, false, 0, 'https://youtu.be/JSXlT_xvLko?si=su6ypDXlUoKtPUbT',
  '1. Click the official link below: https://youtu.be/JSXlT_xvLko?si=su6ypDXlUoKtPUbT
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 1
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l2_t1', "id", 1, 'Level 2 - Task 1', 'Free Task: Complete Subscribe assignment to earn Rs 40 verified reward.', 'Subscribe',
  40, 0, false, 0, 'https://youtu.be/nzciqaNN4I0?si=QcGDCUl8ABo9Qlwd',
  '1. Click the official link below: https://youtu.be/nzciqaNN4I0?si=QcGDCUl8ABo9Qlwd
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 2
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l2_t2', "id", 2, 'Level 2 - Task 2', 'Free Task: Complete Like and Comment assignment to earn Rs 40 verified reward.', 'Like and Comment',
  40, 0, false, 0, 'https://youtu.be/1iJE8Lyvvls?si=yP3qFuihCpIdC5UV',
  '1. Click the official link below: https://youtu.be/1iJE8Lyvvls?si=yP3qFuihCpIdC5UV
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 2
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l2_t3', "id", 3, 'Level 2 - Task 3', 'Free Task: Complete Watch Video (30s) assignment to earn Rs 40 verified reward.', 'Watch Video (30s)',
  40, 0, false, 0, 'https://youtu.be/wyBimQmMZMo?si=BM6sLmxsw3UiQetL',
  '1. Click the official link below: https://youtu.be/wyBimQmMZMo?si=BM6sLmxsw3UiQetL
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 2
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l2_t4', "id", 4, 'Level 2 - Task 4', 'Free Task: Complete Watch Video (45s) assignment to earn Rs 40 verified reward.', 'Watch Video (45s)',
  40, 0, false, 0, 'https://youtu.be/798f3txy4Zs?si=NpAZSSjCHf5sXQHn',
  '1. Click the official link below: https://youtu.be/798f3txy4Zs?si=NpAZSSjCHf5sXQHn
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 2
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l2_t5', "id", 5, 'Level 2 - Task 5', 'Free Task: Complete Watch Video (30s) assignment to earn Rs 40 verified reward.', 'Watch Video (30s)',
  40, 0, false, 0, 'https://youtu.be/M2iHz1cVKxc?si=AKicqraZOjPv3mgg',
  '1. Click the official link below: https://youtu.be/M2iHz1cVKxc?si=AKicqraZOjPv3mgg
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 2
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l2_t6', "id", 6, 'Level 2 - Task 6', 'Free Task: Complete Subscribe assignment to earn Rs 40 verified reward.', 'Subscribe',
  40, 0, false, 0, 'https://youtu.be/3cZ_QsA-Q0Q?si=EVMDukq8QHPDKnep',
  '1. Click the official link below: https://youtu.be/3cZ_QsA-Q0Q?si=EVMDukq8QHPDKnep
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 2
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l2_t7', "id", 7, 'Level 2 - Task 7', 'Free Task: Complete Like and Comment assignment to earn Rs 40 verified reward.', 'Like and Comment',
  40, 0, false, 0, 'https://youtu.be/HGX31br5XD4?si=i55C748M-mSi0lts',
  '1. Click the official link below: https://youtu.be/HGX31br5XD4?si=i55C748M-mSi0lts
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 2
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l2_t8', "id", 8, 'Level 2 - Task 8', 'Free Task: Complete Watch Video (30s) assignment to earn Rs 40 verified reward.', 'Watch Video (30s)',
  40, 0, false, 0, 'https://youtu.be/pgn8wq-WRN8?si=EcwXdqRmVC9LynqC',
  '1. Click the official link below: https://youtu.be/pgn8wq-WRN8?si=EcwXdqRmVC9LynqC
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 2
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l2_t9', "id", 9, 'Level 2 - Task 9', 'Free Task: Complete Watch Video (45s) assignment to earn Rs 40 verified reward.', 'Watch Video (45s)',
  40, 0, false, 0, 'https://youtu.be/UlvuMvKkg5U?si=O35IJAiVVAKTmttz',
  '1. Click the official link below: https://youtu.be/UlvuMvKkg5U?si=O35IJAiVVAKTmttz
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 2
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l2_t10', "id", 10, 'Level 2 - Task 10 (Prepaid Rs 1,410)', 'Prepaid Task: Rs 1,410 unlock fee with guaranteed 40% commission reward (Rs 564).', 'Prepaid VIP Task #10',
  564, 0, true, 1410, 'https://youtu.be/K8Y2V9AwOos?si=SxysGiMzNJ9Eg2id',
  '1. Click the official link below: https://youtu.be/K8Y2V9AwOos?si=SxysGiMzNJ9Eg2id
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 2
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l3_t1', "id", 1, 'Level 3 - Task 1', 'Free Task: Complete Subscribe assignment to earn Rs 60 verified reward.', 'Subscribe',
  60, 0, false, 0, 'https://youtu.be/7vOkn4m-XCs?si=t75KaK78GG1D87ev',
  '1. Click the official link below: https://youtu.be/7vOkn4m-XCs?si=t75KaK78GG1D87ev
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 3
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l3_t2', "id", 2, 'Level 3 - Task 2', 'Free Task: Complete Like and Comment assignment to earn Rs 60 verified reward.', 'Like and Comment',
  60, 0, false, 0, 'https://youtu.be/96GXqWaQcEE?si=QGeuAtrOng32KBf2',
  '1. Click the official link below: https://youtu.be/96GXqWaQcEE?si=QGeuAtrOng32KBf2
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 3
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l3_t3', "id", 3, 'Level 3 - Task 3', 'Free Task: Complete Watch Video (30s) assignment to earn Rs 60 verified reward.', 'Watch Video (30s)',
  60, 0, false, 0, 'https://youtu.be/CZvYvUGLNMg?si=CAdnkQ9DrlGLeNji',
  '1. Click the official link below: https://youtu.be/CZvYvUGLNMg?si=CAdnkQ9DrlGLeNji
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 3
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l3_t4', "id", 4, 'Level 3 - Task 4', 'Free Task: Complete Watch Video (45s) assignment to earn Rs 60 verified reward.', 'Watch Video (45s)',
  60, 0, false, 0, 'https://youtu.be/APe0TO49E00?si=uzr2jUeVwfwiCEpC',
  '1. Click the official link below: https://youtu.be/APe0TO49E00?si=uzr2jUeVwfwiCEpC
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 3
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l3_t5', "id", 5, 'Level 3 - Task 5', 'Free Task: Complete Watch Video (45s) assignment to earn Rs 60 verified reward.', 'Watch Video (45s)',
  60, 0, false, 0, 'https://youtu.be/hbHILEt52VI?si=M-5ga8nGEDax316y',
  '1. Click the official link below: https://youtu.be/hbHILEt52VI?si=M-5ga8nGEDax316y
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 3
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l3_t6', "id", 6, 'Level 3 - Task 6', 'Free Task: Complete Subscribe assignment to earn Rs 60 verified reward.', 'Subscribe',
  60, 0, false, 0, 'https://youtu.be/WkQrMzwqKv4?si=_eQzhwDMoiCrsDUi',
  '1. Click the official link below: https://youtu.be/WkQrMzwqKv4?si=_eQzhwDMoiCrsDUi
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 3
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l3_t7', "id", 7, 'Level 3 - Task 7', 'Free Task: Complete Like and Comment assignment to earn Rs 60 verified reward.', 'Like and Comment',
  60, 0, false, 0, 'https://youtu.be/CQpxJhN16pM?si=Huj0tEOmziuHzY-A',
  '1. Click the official link below: https://youtu.be/CQpxJhN16pM?si=Huj0tEOmziuHzY-A
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 3
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l3_t8', "id", 8, 'Level 3 - Task 8', 'Free Task: Complete Watch Video (30s) assignment to earn Rs 60 verified reward.', 'Watch Video (30s)',
  60, 0, false, 0, 'https://youtu.be/CBhRIsc_14A?si=taf3RX_E_M3_wgXs',
  '1. Click the official link below: https://youtu.be/CBhRIsc_14A?si=taf3RX_E_M3_wgXs
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 3
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l3_t9', "id", 9, 'Level 3 - Task 9 (Prepaid Rs 3,500)', 'Prepaid Task: Rs 3,500 unlock fee with guaranteed 40% commission reward (Rs 1,400).', 'Prepaid VIP Task #9',
  1400, 0, true, 3500, 'https://youtu.be/F7sPLM-ThnA?si=GozFZ1wHIl4HPnSL',
  '1. Click the official link below: https://youtu.be/F7sPLM-ThnA?si=GozFZ1wHIl4HPnSL
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 3
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l3_t10', "id", 10, 'Level 3 - Task 10 (Prepaid Rs 5,500)', 'Prepaid Task: Rs 5,500 unlock fee with guaranteed 40% commission reward (Rs 2,200).', 'Prepaid VIP Task #10',
  2200, 0, true, 5500, 'https://youtu.be/8T0m8f44Kgs?si=XPXvxc3B5IOOXrP-',
  '1. Click the official link below: https://youtu.be/8T0m8f44Kgs?si=XPXvxc3B5IOOXrP-
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 3
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l4_t1', "id", 1, 'Level 4 - Task 1 (Prepaid Rs 10,000)', 'Prepaid Task: Rs 10,000 unlock fee with guaranteed 40% commission reward (Rs 4,000).', 'Prepaid VIP Task #1',
  4000, 0, true, 10000, 'https://youtu.be/ew__gmVo3Nk?si=cFdkl1FDuMSy2749',
  '1. Click the official link below: https://youtu.be/ew__gmVo3Nk?si=cFdkl1FDuMSy2749
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 4
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l4_t2', "id", 2, 'Level 4 - Task 2 (Prepaid Rs 20,000)', 'Prepaid Task: Rs 20,000 unlock fee with guaranteed 40% commission reward (Rs 8,000).', 'Prepaid VIP Task #2',
  8000, 0, true, 20000, 'https://youtu.be/YCzRPKRAWmw?si=OKAr0OUB0T9XBzhJ',
  '1. Click the official link below: https://youtu.be/YCzRPKRAWmw?si=OKAr0OUB0T9XBzhJ
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 4
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l4_t3', "id", 3, 'Level 4 - Task 3 (Prepaid Rs 30,000)', 'Prepaid Task: Rs 30,000 unlock fee with guaranteed 40% commission reward (Rs 12,000).', 'Prepaid VIP Task #3',
  12000, 0, true, 30000, 'https://youtu.be/irHIeMEP5hw?si=Fh8SSfl0koXUrYrk',
  '1. Click the official link below: https://youtu.be/irHIeMEP5hw?si=Fh8SSfl0koXUrYrk
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 4
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l4_t4', "id", 4, 'Level 4 - Task 4 (Prepaid Rs 40,000)', 'Prepaid Task: Rs 40,000 unlock fee with guaranteed 40% commission reward (Rs 16,000).', 'Prepaid VIP Task #4',
  16000, 0, true, 40000, 'https://youtu.be/45GUatkxX3s?si=ZjsYNezm1YpflOOJ',
  '1. Click the official link below: https://youtu.be/45GUatkxX3s?si=ZjsYNezm1YpflOOJ
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 4
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l4_t5', "id", 5, 'Level 4 - Task 5 (Prepaid Rs 60,000)', 'Prepaid Task: Rs 60,000 unlock fee with guaranteed 40% commission reward (Rs 24,000).', 'Prepaid VIP Task #5',
  24000, 0, true, 60000, 'https://youtu.be/_PB8D_W6CK8?si=LpdY4Z4-d5CwjcKe',
  '1. Click the official link below: https://youtu.be/_PB8D_W6CK8?si=LpdY4Z4-d5CwjcKe
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 4
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l4_t6', "id", 6, 'Level 4 - Task 6 (Prepaid Rs 80,000)', 'Prepaid Task: Rs 80,000 unlock fee with guaranteed 40% commission reward (Rs 32,000).', 'Prepaid VIP Task #6',
  32000, 0, true, 80000, 'https://youtu.be/ZnmU_6BD0pY?si=XlE3zCfn8ufLolJ8',
  '1. Click the official link below: https://youtu.be/ZnmU_6BD0pY?si=XlE3zCfn8ufLolJ8
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 4
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l4_t7', "id", 7, 'Level 4 - Task 7 (Prepaid Rs 100,000)', 'Prepaid Task: Rs 100,000 unlock fee with guaranteed 40% commission reward (Rs 40,000).', 'Prepaid VIP Task #7',
  40000, 0, true, 100000, 'https://youtu.be/jCPcZUifbkc?si=W8SFeXKJEnh6h_BT',
  '1. Click the official link below: https://youtu.be/jCPcZUifbkc?si=W8SFeXKJEnh6h_BT
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 4
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l4_t8', "id", 8, 'Level 4 - Task 8 (Prepaid Rs 130,000)', 'Prepaid Task: Rs 130,000 unlock fee with guaranteed 40% commission reward (Rs 52,000).', 'Prepaid VIP Task #8',
  52000, 0, true, 130000, 'https://youtu.be/EYeG5TiE2B0?si=IdoR0rcI430rFiXP',
  '1. Click the official link below: https://youtu.be/EYeG5TiE2B0?si=IdoR0rcI430rFiXP
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 4
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l4_t9', "id", 9, 'Level 4 - Task 9 (Prepaid Rs 160,000)', 'Prepaid Task: Rs 160,000 unlock fee with guaranteed 40% commission reward (Rs 64,000).', 'Prepaid VIP Task #9',
  64000, 0, true, 160000, 'https://youtu.be/veNdcvpCNRM?si=LTwSsN-0YCpuY4he',
  '1. Click the official link below: https://youtu.be/veNdcvpCNRM?si=LTwSsN-0YCpuY4he
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 4
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l4_t10', "id", 10, 'Level 4 - Task 10 (Prepaid Rs 200,000)', 'Prepaid Task: Rs 200,000 unlock fee with guaranteed 40% commission reward (Rs 80,000).', 'Prepaid VIP Task #10',
  80000, 0, true, 200000, 'https://youtu.be/bA1j3q0Q5wo?si=IpB8KdfE9f7NA-_A',
  '1. Click the official link below: https://youtu.be/bA1j3q0Q5wo?si=IpB8KdfE9f7NA-_A
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 4
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l5_t1', "id", 1, 'Level 5 - Task 1', 'Free Task: Complete Subscribe assignment to earn Rs 0 verified reward.', 'Subscribe',
  0, 0, false, 0, 'https://youtu.be/bmyXHQQctyQ?si=WE3n94_t2VjUipve',
  '1. Click the official link below: https://youtu.be/bmyXHQQctyQ?si=WE3n94_t2VjUipve
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 5
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l5_t2', "id", 2, 'Level 5 - Task 2', 'Free Task: Complete Like and Comment assignment to earn Rs 0 verified reward.', 'Like and Comment',
  0, 0, false, 0, 'https://youtu.be/XgnSxvUiXO0?si=22ktWXjGWh1OOnwt',
  '1. Click the official link below: https://youtu.be/XgnSxvUiXO0?si=22ktWXjGWh1OOnwt
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 5
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l5_t3', "id", 3, 'Level 5 - Task 3', 'Free Task: Complete Watch Video (30s) assignment to earn Rs 0 verified reward.', 'Watch Video (30s)',
  0, 0, false, 0, 'https://youtu.be/pmjH9erWu48?si=ZPVv0sGjxwpdQ2JW',
  '1. Click the official link below: https://youtu.be/pmjH9erWu48?si=ZPVv0sGjxwpdQ2JW
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 5
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l5_t4', "id", 4, 'Level 5 - Task 4', 'Free Task: Complete Watch Video (45s) assignment to earn Rs 0 verified reward.', 'Watch Video (45s)',
  0, 0, false, 0, 'https://youtu.be/HOWaPR9brOE?si=q508JZyHn6ROxrB0',
  '1. Click the official link below: https://youtu.be/HOWaPR9brOE?si=q508JZyHn6ROxrB0
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 5
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l5_t5', "id", 5, 'Level 5 - Task 5', 'Free Task: Complete Watch Video (30s) assignment to earn Rs 0 verified reward.', 'Watch Video (30s)',
  0, 0, false, 0, 'https://youtu.be/yqH3DcxB6Dk?si=kjp1orUfY-WKbbJS',
  '1. Click the official link below: https://youtu.be/yqH3DcxB6Dk?si=kjp1orUfY-WKbbJS
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 5
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l5_t6', "id", 6, 'Level 5 - Task 6', 'Free Task: Complete Subscribe assignment to earn Rs 0 verified reward.', 'Subscribe',
  0, 0, false, 0, 'https://youtu.be/31HJbpU2RpU?si=y--XuUEVnQumEdqj',
  '1. Click the official link below: https://youtu.be/31HJbpU2RpU?si=y--XuUEVnQumEdqj
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 5
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l5_t7', "id", 7, 'Level 5 - Task 7', 'Free Task: Complete Like and Comment assignment to earn Rs 0 verified reward.', 'Like and Comment',
  0, 0, false, 0, 'https://youtu.be/GwifegtMmUI?si=eP2xJ1bdsoVzTyzY',
  '1. Click the official link below: https://youtu.be/GwifegtMmUI?si=eP2xJ1bdsoVzTyzY
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 5
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l5_t8', "id", 8, 'Level 5 - Task 8', 'Free Task: Complete Watch Video (30s) assignment to earn Rs 0 verified reward.', 'Watch Video (30s)',
  0, 0, false, 0, 'https://youtu.be/6Ct2D12cHqw?si=_hE-crwndkoC1pBS',
  '1. Click the official link below: https://youtu.be/6Ct2D12cHqw?si=_hE-crwndkoC1pBS
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 5
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l5_t9', "id", 9, 'Level 5 - Task 9', 'Free Task: Complete Watch Video (45s) assignment to earn Rs 0 verified reward.', 'Watch Video (45s)',
  0, 0, false, 0, 'https://youtu.be/-6kARhVxEWA?si=dB6y1GiHnaEJBRkC',
  '1. Click the official link below: https://youtu.be/-6kARhVxEWA?si=dB6y1GiHnaEJBRkC
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 5
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l5_t10', "id", 10, 'Level 5 - Task 10', 'Free Task: Complete Watch Video (45s) assignment to earn Rs 0 verified reward.', 'Watch Video (45s)',
  0, 0, false, 0, 'https://youtu.be/yIjjg5_5Cxw?si=jD2O34ChfbY65zqA',
  '1. Click the official link below: https://youtu.be/yIjjg5_5Cxw?si=jD2O34ChfbY65zqA
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 5
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l6_t1', "id", 1, 'Level 6 - Task 1', 'Free Task: Complete Subscribe assignment to earn Rs 0 verified reward.', 'Subscribe',
  0, 0, false, 0, 'https://youtu.be/qgz-ydhRs4s?si=Il542hKwwSHMMFT3',
  '1. Click the official link below: https://youtu.be/qgz-ydhRs4s?si=Il542hKwwSHMMFT3
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 6
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l6_t2', "id", 2, 'Level 6 - Task 2', 'Free Task: Complete Like and Comment assignment to earn Rs 0 verified reward.', 'Like and Comment',
  0, 0, false, 0, 'https://youtu.be/XaEkHoMtc5Q?si=h0RzVrtAK9jQBRcg',
  '1. Click the official link below: https://youtu.be/XaEkHoMtc5Q?si=h0RzVrtAK9jQBRcg
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 6
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l6_t3', "id", 3, 'Level 6 - Task 3', 'Free Task: Complete Watch Video (30s) assignment to earn Rs 0 verified reward.', 'Watch Video (30s)',
  0, 0, false, 0, 'https://youtu.be/3nYntR_BmD0?si=OqMoHNGPDd8x4853',
  '1. Click the official link below: https://youtu.be/3nYntR_BmD0?si=OqMoHNGPDd8x4853
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 6
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l6_t4', "id", 4, 'Level 6 - Task 4', 'Free Task: Complete Watch Video (45s) assignment to earn Rs 0 verified reward.', 'Watch Video (45s)',
  0, 0, false, 0, 'https://youtu.be/8BOnFKojVYc?si=59knG1PQVKYd6gVk',
  '1. Click the official link below: https://youtu.be/8BOnFKojVYc?si=59knG1PQVKYd6gVk
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 6
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l6_t5', "id", 5, 'Level 6 - Task 5', 'Free Task: Complete Watch Video (30s) assignment to earn Rs 0 verified reward.', 'Watch Video (30s)',
  0, 0, false, 0, 'https://youtu.be/B3j7o3RfBVI?si=nSo3Ii77SdDR4iI4',
  '1. Click the official link below: https://youtu.be/B3j7o3RfBVI?si=nSo3Ii77SdDR4iI4
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 6
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l6_t6', "id", 6, 'Level 6 - Task 6', 'Free Task: Complete Subscribe assignment to earn Rs 0 verified reward.', 'Subscribe',
  0, 0, false, 0, 'https://youtu.be/TYWrS9lbHVo?si=vylP_TFVidoIjhWL',
  '1. Click the official link below: https://youtu.be/TYWrS9lbHVo?si=vylP_TFVidoIjhWL
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 6
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l6_t7', "id", 7, 'Level 6 - Task 7', 'Free Task: Complete Like and Comment assignment to earn Rs 0 verified reward.', 'Like and Comment',
  0, 0, false, 0, 'https://youtu.be/Jjpfl2hgN5k?si=XhKzdxX-i616kqTs',
  '1. Click the official link below: https://youtu.be/Jjpfl2hgN5k?si=XhKzdxX-i616kqTs
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 6
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l6_t8', "id", 8, 'Level 6 - Task 8', 'Free Task: Complete Watch Video (30s) assignment to earn Rs 0 verified reward.', 'Watch Video (30s)',
  0, 0, false, 0, 'https://youtu.be/t1y9vFl3LQc?si=H-TnYfPxFjrPx91H',
  '1. Click the official link below: https://youtu.be/t1y9vFl3LQc?si=H-TnYfPxFjrPx91H
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 6
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l6_t9', "id", 9, 'Level 6 - Task 9', 'Free Task: Complete Watch Video (45s) assignment to earn Rs 0 verified reward.', 'Watch Video (45s)',
  0, 0, false, 0, 'https://youtu.be/esY3mHyDFi4?si=3hxcM_soqfG8GTro',
  '1. Click the official link below: https://youtu.be/esY3mHyDFi4?si=3hxcM_soqfG8GTro
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 6
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l6_t10', "id", 10, 'Level 6 - Task 10', 'Free Task: Complete Watch Video (45s) assignment to earn Rs 0 verified reward.', 'Watch Video (45s)',
  0, 0, false, 0, 'https://youtu.be/1lCZKskfCqI?si=GiRq7gaiCzepy0ka',
  '1. Click the official link below: https://youtu.be/1lCZKskfCqI?si=GiRq7gaiCzepy0ka
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 6
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l7_t1', "id", 1, 'Level 7 - Task 1', 'Free Task: Complete Subscribe assignment to earn Rs 0 verified reward.', 'Subscribe',
  0, 0, false, 0, 'https://youtu.be/B9WFwGvMUZg?si=0iEB2lrtL56J4cmx',
  '1. Click the official link below: https://youtu.be/B9WFwGvMUZg?si=0iEB2lrtL56J4cmx
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 7
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l7_t2', "id", 2, 'Level 7 - Task 2', 'Free Task: Complete Like and Comment assignment to earn Rs 0 verified reward.', 'Like and Comment',
  0, 0, false, 0, 'https://youtu.be/YqedmavuG64?si=prGU4MJUaaDCnoBI',
  '1. Click the official link below: https://youtu.be/YqedmavuG64?si=prGU4MJUaaDCnoBI
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 7
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l7_t3', "id", 3, 'Level 7 - Task 3', 'Free Task: Complete Watch Video (30s) assignment to earn Rs 0 verified reward.', 'Watch Video (30s)',
  0, 0, false, 0, 'https://youtu.be/bA33aA83DUs?si=oOEtJwbWRdtsXZIe',
  '1. Click the official link below: https://youtu.be/bA33aA83DUs?si=oOEtJwbWRdtsXZIe
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 7
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l7_t4', "id", 4, 'Level 7 - Task 4', 'Free Task: Complete Watch Video (45s) assignment to earn Rs 0 verified reward.', 'Watch Video (45s)',
  0, 0, false, 0, 'https://youtu.be/l0EC6dvS89M?si=WlG698OLMa_adZkK',
  '1. Click the official link below: https://youtu.be/l0EC6dvS89M?si=WlG698OLMa_adZkK
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 7
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l7_t5', "id", 5, 'Level 7 - Task 5', 'Free Task: Complete Watch Video (30s) assignment to earn Rs 0 verified reward.', 'Watch Video (30s)',
  0, 0, false, 0, 'https://youtu.be/SJYdo3ScJDM?si=rofNESmY3HHZDE9d',
  '1. Click the official link below: https://youtu.be/SJYdo3ScJDM?si=rofNESmY3HHZDE9d
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 7
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l7_t6', "id", 6, 'Level 7 - Task 6', 'Free Task: Complete Subscribe assignment to earn Rs 0 verified reward.', 'Subscribe',
  0, 0, false, 0, 'https://youtu.be/nsV-B79x33I?si=aLI7nHiMwgl0yG1i',
  '1. Click the official link below: https://youtu.be/nsV-B79x33I?si=aLI7nHiMwgl0yG1i
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 7
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l7_t7', "id", 7, 'Level 7 - Task 7', 'Free Task: Complete Like and Comment assignment to earn Rs 0 verified reward.', 'Like and Comment',
  0, 0, false, 0, 'https://youtu.be/fCDVn0Ri2dU?si=MmFVxtjmJalzqsSQ',
  '1. Click the official link below: https://youtu.be/fCDVn0Ri2dU?si=MmFVxtjmJalzqsSQ
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 7
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l7_t8', "id", 8, 'Level 7 - Task 8', 'Free Task: Complete Watch Video (30s) assignment to earn Rs 0 verified reward.', 'Watch Video (30s)',
  0, 0, false, 0, 'https://youtu.be/4z1OyqDyR2E?si=C0Qc5ZF84_vS-EtS',
  '1. Click the official link below: https://youtu.be/4z1OyqDyR2E?si=C0Qc5ZF84_vS-EtS
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 7
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l7_t9', "id", 9, 'Level 7 - Task 9', 'Free Task: Complete Watch Video (45s) assignment to earn Rs 0 verified reward.', 'Watch Video (45s)',
  0, 0, false, 0, 'https://youtu.be/sSFYNRoo4r4?si=6hWH6qxt9ylI7pWi',
  '1. Click the official link below: https://youtu.be/sSFYNRoo4r4?si=6hWH6qxt9ylI7pWi
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 7
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l7_t10', "id", 10, 'Level 7 - Task 10', 'Free Task: Complete Watch Video (45s) assignment to earn Rs 0 verified reward.', 'Watch Video (45s)',
  0, 0, false, 0, 'https://youtu.be/Wr5X3lJ30R4?si=KHX-cBl50XRgR3D1',
  '1. Click the official link below: https://youtu.be/Wr5X3lJ30R4?si=KHX-cBl50XRgR3D1
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 7
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l8_t1', "id", 1, 'Level 8 - Task 1', 'Free Task: Complete Subscribe assignment to earn Rs 0 verified reward.', 'Subscribe',
  0, 0, false, 0, 'https://youtu.be/OS-WTughD14?si=xyiP5FPupBzSfQ9p',
  '1. Click the official link below: https://youtu.be/OS-WTughD14?si=xyiP5FPupBzSfQ9p
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 8
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l8_t2', "id", 2, 'Level 8 - Task 2', 'Free Task: Complete Like and Comment assignment to earn Rs 0 verified reward.', 'Like and Comment',
  0, 0, false, 0, 'https://youtu.be/d4M3YRLiSwM?si=D0a3oKwRCFUdkJ5B',
  '1. Click the official link below: https://youtu.be/d4M3YRLiSwM?si=D0a3oKwRCFUdkJ5B
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 8
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l8_t3', "id", 3, 'Level 8 - Task 3', 'Free Task: Complete Watch Video (30s) assignment to earn Rs 0 verified reward.', 'Watch Video (30s)',
  0, 0, false, 0, 'https://youtu.be/nGNlcnGobAY?si=nK83aH5a-W8ph9Xv',
  '1. Click the official link below: https://youtu.be/nGNlcnGobAY?si=nK83aH5a-W8ph9Xv
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 8
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l8_t4', "id", 4, 'Level 8 - Task 4', 'Free Task: Complete Watch Video (45s) assignment to earn Rs 0 verified reward.', 'Watch Video (45s)',
  0, 0, false, 0, 'https://youtu.be/hTkjqhOsgwc?si=QGKy8vK_l7vLut11',
  '1. Click the official link below: https://youtu.be/hTkjqhOsgwc?si=QGKy8vK_l7vLut11
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 8
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l8_t5', "id", 5, 'Level 8 - Task 5', 'Free Task: Complete Watch Video (30s) assignment to earn Rs 0 verified reward.', 'Watch Video (30s)',
  0, 0, false, 0, 'https://youtu.be/AGUb2Nn7pKQ?si=-3czbIuznEgR0tew',
  '1. Click the official link below: https://youtu.be/AGUb2Nn7pKQ?si=-3czbIuznEgR0tew
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 8
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l8_t6', "id", 6, 'Level 8 - Task 6', 'Free Task: Complete Subscribe assignment to earn Rs 0 verified reward.', 'Subscribe',
  0, 0, false, 0, 'https://youtu.be/h76Q3E_9aNw?si=l3FGEQYqwFooHtvF',
  '1. Click the official link below: https://youtu.be/h76Q3E_9aNw?si=l3FGEQYqwFooHtvF
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 8
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l8_t7', "id", 7, 'Level 8 - Task 7', 'Free Task: Complete Like and Comment assignment to earn Rs 0 verified reward.', 'Like and Comment',
  0, 0, false, 0, 'https://youtu.be/m7pxtU5qz2U?si=QoDpPdbZNjePMXMb',
  '1. Click the official link below: https://youtu.be/m7pxtU5qz2U?si=QoDpPdbZNjePMXMb
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 8
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l8_t8', "id", 8, 'Level 8 - Task 8', 'Free Task: Complete Watch Video (30s) assignment to earn Rs 0 verified reward.', 'Watch Video (30s)',
  0, 0, false, 0, 'https://youtu.be/7bGRQJzAKZw?si=uwF3CcleRr4o30up',
  '1. Click the official link below: https://youtu.be/7bGRQJzAKZw?si=uwF3CcleRr4o30up
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 8
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l8_t9', "id", 9, 'Level 8 - Task 9', 'Free Task: Complete Watch Video (45s) assignment to earn Rs 0 verified reward.', 'Watch Video (45s)',
  0, 0, false, 0, 'https://youtu.be/5Z-qAutLgHA?si=GyPFMacS3gxvVogE',
  '1. Click the official link below: https://youtu.be/5Z-qAutLgHA?si=GyPFMacS3gxvVogE
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 8
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l8_t10', "id", 10, 'Level 8 - Task 10', 'Free Task: Complete Watch Video (45s) assignment to earn Rs 0 verified reward.', 'Watch Video (45s)',
  0, 0, false, 0, 'https://youtu.be/0TCQClBCJA8?si=S9dn0asC5H9fRU8p',
  '1. Click the official link below: https://youtu.be/0TCQClBCJA8?si=S9dn0asC5H9fRU8p
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 8
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l9_t1', "id", 1, 'Level 9 - Task 1', 'Free Task: Complete Subscribe assignment to earn Rs 0 verified reward.', 'Subscribe',
  0, 0, false, 0, 'https://youtu.be/AnYl6Nk9GOA?si=uJMUmAkCoFVqzSZ2',
  '1. Click the official link below: https://youtu.be/AnYl6Nk9GOA?si=uJMUmAkCoFVqzSZ2
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 9
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l9_t2', "id", 2, 'Level 9 - Task 2', 'Free Task: Complete Like and Comment assignment to earn Rs 0 verified reward.', 'Like and Comment',
  0, 0, false, 0, 'https://youtu.be/UItWltVZZmE?si=4fMmgvmTZhm9xq9s',
  '1. Click the official link below: https://youtu.be/UItWltVZZmE?si=4fMmgvmTZhm9xq9s
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 9
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l9_t3', "id", 3, 'Level 9 - Task 3', 'Free Task: Complete Watch Video (30s) assignment to earn Rs 0 verified reward.', 'Watch Video (30s)',
  0, 0, false, 0, 'https://youtu.be/Cw-Wt4xKD2s?si=HCCHU3lcQEGIOpAV',
  '1. Click the official link below: https://youtu.be/Cw-Wt4xKD2s?si=HCCHU3lcQEGIOpAV
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 9
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l9_t4', "id", 4, 'Level 9 - Task 4', 'Free Task: Complete Watch Video (45s) assignment to earn Rs 0 verified reward.', 'Watch Video (45s)',
  0, 0, false, 0, 'https://youtu.be/jC5xlKIQgR8?si=SM5t6XKxplYQIXlP',
  '1. Click the official link below: https://youtu.be/jC5xlKIQgR8?si=SM5t6XKxplYQIXlP
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 9
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l9_t5', "id", 5, 'Level 9 - Task 5', 'Free Task: Complete Watch Video (30s) assignment to earn Rs 0 verified reward.', 'Watch Video (30s)',
  0, 0, false, 0, 'https://youtu.be/X8FNAzCoCoI?si=VLs5Ol5Gh2StDnzK',
  '1. Click the official link below: https://youtu.be/X8FNAzCoCoI?si=VLs5Ol5Gh2StDnzK
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 9
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l9_t6', "id", 6, 'Level 9 - Task 6', 'Free Task: Complete Subscribe assignment to earn Rs 0 verified reward.', 'Subscribe',
  0, 0, false, 0, 'https://youtu.be/fsJ14Bra8Io?si=Q2E7TZ-Gi0s6Eu7A',
  '1. Click the official link below: https://youtu.be/fsJ14Bra8Io?si=Q2E7TZ-Gi0s6Eu7A
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 9
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l9_t7', "id", 7, 'Level 9 - Task 7', 'Free Task: Complete Like and Comment assignment to earn Rs 0 verified reward.', 'Like and Comment',
  0, 0, false, 0, 'https://youtu.be/4tQrUif5pHY?si=qkw8NRq_gj0mmJMW',
  '1. Click the official link below: https://youtu.be/4tQrUif5pHY?si=qkw8NRq_gj0mmJMW
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 9
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l9_t8', "id", 8, 'Level 9 - Task 8', 'Free Task: Complete Watch Video (30s) assignment to earn Rs 0 verified reward.', 'Watch Video (30s)',
  0, 0, false, 0, 'https://youtu.be/Nw5rO-fmL0A?si=JzoRZ80tEG6itSRk',
  '1. Click the official link below: https://youtu.be/Nw5rO-fmL0A?si=JzoRZ80tEG6itSRk
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 9
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l9_t9', "id", 9, 'Level 9 - Task 9', 'Free Task: Complete Watch Video (45s) assignment to earn Rs 0 verified reward.', 'Watch Video (45s)',
  0, 0, false, 0, 'https://youtu.be/EtjXNMS3eeU?si=kxWkl392jatI2qT6',
  '1. Click the official link below: https://youtu.be/EtjXNMS3eeU?si=kxWkl392jatI2qT6
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 9
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l9_t10', "id", 10, 'Level 9 - Task 10', 'Free Task: Complete Watch Video (45s) assignment to earn Rs 0 verified reward.', 'Watch Video (45s)',
  0, 0, false, 0, 'https://youtu.be/UV63-EXSFI8?si=amwqxlSS2QF08epH',
  '1. Click the official link below: https://youtu.be/UV63-EXSFI8?si=amwqxlSS2QF08epH
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 9
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l10_t1', "id", 1, 'Level 10 - Task 1', 'Free Task: Complete Subscribe assignment to earn Rs 0 verified reward.', 'Subscribe',
  0, 0, false, 0, 'https://youtu.be/Z22mFwbCrCA?si=9Yjc9AH0eRZ4FNxb',
  '1. Click the official link below: https://youtu.be/Z22mFwbCrCA?si=9Yjc9AH0eRZ4FNxb
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 10
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l10_t2', "id", 2, 'Level 10 - Task 2', 'Free Task: Complete Like and Comment assignment to earn Rs 0 verified reward.', 'Like and Comment',
  0, 0, false, 0, 'https://youtu.be/PGpb6Zc4KkE?si=hd0i40qWqeRPca4L',
  '1. Click the official link below: https://youtu.be/PGpb6Zc4KkE?si=hd0i40qWqeRPca4L
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 10
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l10_t3', "id", 3, 'Level 10 - Task 3', 'Free Task: Complete Watch Video (30s) assignment to earn Rs 0 verified reward.', 'Watch Video (30s)',
  0, 0, false, 0, 'https://youtu.be/YHccUdhUE_Y?si=u-PDsW3JgEdo5llT',
  '1. Click the official link below: https://youtu.be/YHccUdhUE_Y?si=u-PDsW3JgEdo5llT
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 10
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l10_t4', "id", 4, 'Level 10 - Task 4', 'Free Task: Complete Watch Video (45s) assignment to earn Rs 0 verified reward.', 'Watch Video (45s)',
  0, 0, false, 0, 'https://youtu.be/RVpKbiTvLWY?si=BpMN-6bpskK0ORfp',
  '1. Click the official link below: https://youtu.be/RVpKbiTvLWY?si=BpMN-6bpskK0ORfp
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 10
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l10_t5', "id", 5, 'Level 10 - Task 5', 'Free Task: Complete Watch Video (30s) assignment to earn Rs 0 verified reward.', 'Watch Video (30s)',
  0, 0, false, 0, 'https://youtu.be/AJtkuFN1apc?si=ampDjQmn6PkH5PWs',
  '1. Click the official link below: https://youtu.be/AJtkuFN1apc?si=ampDjQmn6PkH5PWs
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 10
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l10_t6', "id", 6, 'Level 10 - Task 6', 'Free Task: Complete Subscribe assignment to earn Rs 0 verified reward.', 'Subscribe',
  0, 0, false, 0, 'https://youtu.be/k8eR5sBUCPw?si=tMuw34hpQu6CC5Fe',
  '1. Click the official link below: https://youtu.be/k8eR5sBUCPw?si=tMuw34hpQu6CC5Fe
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 10
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l10_t7', "id", 7, 'Level 10 - Task 7', 'Free Task: Complete Like and Comment assignment to earn Rs 0 verified reward.', 'Like and Comment',
  0, 0, false, 0, 'https://youtu.be/LSKRceF5ykE?si=EJkkg6RzukZppH0y',
  '1. Click the official link below: https://youtu.be/LSKRceF5ykE?si=EJkkg6RzukZppH0y
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 10
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l10_t8', "id", 8, 'Level 10 - Task 8', 'Free Task: Complete Watch Video (30s) assignment to earn Rs 0 verified reward.', 'Watch Video (30s)',
  0, 0, false, 0, 'https://youtu.be/KPIC2P_jFfU?si=6Lcs9aV9QdjMDAGO',
  '1. Click the official link below: https://youtu.be/KPIC2P_jFfU?si=6Lcs9aV9QdjMDAGO
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 10
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l10_t9', "id", 9, 'Level 10 - Task 9', 'Free Task: Complete Watch Video (45s) assignment to earn Rs 0 verified reward.', 'Watch Video (45s)',
  0, 0, false, 0, 'https://youtu.be/qOWVl6j87nI?si=rMV76Ws1W3PnzqpC',
  '1. Click the official link below: https://youtu.be/qOWVl6j87nI?si=rMV76Ws1W3PnzqpC
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 10
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


INSERT INTO "Task" (
  "id", "levelId", "taskNumber", "title", "description", "taskType",
  "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl",
  "instructions", "lockMessage", "submissionInstructions",
  "requiresAdminApproval", "status", "createdAt", "updatedAt"
)
SELECT
  'task_l10_t10', "id", 10, 'Level 10 - Task 10', 'Free Task: Complete Watch Video (45s) assignment to earn Rs 0 verified reward.', 'Watch Video (45s)',
  0, 0, false, 0, 'https://youtu.be/UrjimhELcok?si=WRKmKc2Gcyje6pTV',
  '1. Click the official link below: https://youtu.be/UrjimhELcok?si=WRKmKc2Gcyje6pTV
2. Perform the required assignment.
3. Submit transaction/reference proof for admin review.', 'Complete and receive approval for the previous task to unlock this task.',
  'Submit task confirmation notes or reference screenshot for admin review.',
  true, 'ACTIVE', NOW(), NOW()
FROM "Level" WHERE "levelNumber" = 10
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


-- 3. Remove Any Excess Tasks (> 10 per Level)

DELETE FROM "Task" WHERE "taskNumber" > 10;


-- 4. Synchronize UserLevelProgress for ALL Users

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


-- 5. Synchronize UserTaskProgress for ALL Users (all 100 tasks)

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


-- 6. Verification Queries

SELECT 'Levels Count' AS metric, COUNT(*) AS total FROM "Level";
SELECT 'Tasks Count' AS metric, COUNT(*) AS total FROM "Task";
SELECT 'UserLevelProgress Rows' AS metric, COUNT(*) AS total FROM "UserLevelProgress";
SELECT 'UserTaskProgress Rows' AS metric, COUNT(*) AS total FROM "UserTaskProgress";
