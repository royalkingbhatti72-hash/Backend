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
INSERT INTO "Level" ("id", "levelNumber", "title", "description", "status", "requiredTaskCount", "completionReward", "totalCreditPoints", "displayOrder", "createdAt", "updatedAt") VALUES ('level_1', 1, 'Study', 'Complete all 10 tasks in Level 1 (Study) to claim the PKR 500 milestone reward.', 'ACTIVE', 10, 500, 100, 1, NOW(), NOW()) ON CONFLICT ("levelNumber") DO UPDATE SET "title" = EXCLUDED."title", "completionReward" = EXCLUDED."completionReward", "requiredTaskCount" = EXCLUDED."requiredTaskCount", "totalCreditPoints" = EXCLUDED."totalCreditPoints";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_1_1', 'level_1', 1, 'YouTube Subscribe Task #1', 'Complete the Subscribe action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 40 and 5 credit points.', 'Subscribe', 40, 5, false, 0, 'https://youtu.be/vo4pMVb0R6M?si=I1idXSAT49o8qQlA', '1. Open link: https://youtu.be/vo4pMVb0R6M?si=I1idXSAT49o8qQlA
2. Perform Subscribe action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Available to start', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_1_2', 'level_1', 2, 'YouTube Like and Comment Task #2', 'Complete the Like and Comment action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 40 and 5 credit points.', 'Like and Comment', 40, 5, false, 0, 'https://youtu.be/00jbG', '1. Open link: https://youtu.be/00jbG
2. Perform Like and Comment action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 1 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_1_3', 'level_1', 3, 'YouTube Watch Video (30s) Task #3', 'Complete the Watch Video (30s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 40 and 5 credit points.', 'Watch Video (30s)', 40, 5, false, 0, 'https://youtu.be/Yocja', '1. Open link: https://youtu.be/Yocja
2. Perform Watch Video (30s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 2 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_1_4', 'level_1', 4, 'YouTube Watch Video (45s) Task #4', 'Complete the Watch Video (45s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 40 and 5 credit points.', 'Watch Video (45s)', 40, 5, false, 0, 'https://youtu.be/B3u4EFTwprM?si=Yklgf1smjHpY-rbh', '1. Open link: https://youtu.be/B3u4EFTwprM?si=Yklgf1smjHpY-rbh
2. Perform Watch Video (45s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 3 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_1_5', 'level_1', 5, 'Prepaid Task #1 (PKR 1,000)', 'Prepaid task requiring deposit unlock fee of PKR 1,000. Yields commission of PKR 80 and 30 credit points upon completion.', 'Prepaid Task #1', 80, 30, true, 1000, 'https://youtu.be/FrlJl2UXRU0?si=un0Uee3RG2nIciDe', '1. Ensure wallet has sufficient balance or deposit PKR 1,000.
2. Click Unlock Task to pay fee.
3. Open protected link: https://youtu.be/FrlJl2UXRU0?si=un0Uee3RG2nIciDe
4. Complete engagement steps.
5. Submit transaction and proof screenshot for admin approval.', 'Complete and receive approval for Task 4 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_1_6', 'level_1', 6, 'YouTube Subscribe Task #6', 'Complete the Subscribe action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 40 and 5 credit points.', 'Subscribe', 40, 5, false, 0, 'https://youtu.be/9t5NOKVUTZo?si=rD4k5-dQY4icij07', '1. Open link: https://youtu.be/9t5NOKVUTZo?si=rD4k5-dQY4icij07
2. Perform Subscribe action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 5 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_1_7', 'level_1', 7, 'YouTube Like and Comment Task #7', 'Complete the Like and Comment action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 40 and 5 credit points.', 'Like and Comment', 40, 5, false, 0, 'https://youtu.be/tZ7lsQV95yo?si=KGD7uqw1px-uC8Fb', '1. Open link: https://youtu.be/tZ7lsQV95yo?si=KGD7uqw1px-uC8Fb
2. Perform Like and Comment action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 6 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_1_8', 'level_1', 8, 'YouTube Watch Video (30s) Task #8', 'Complete the Watch Video (30s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 40 and 5 credit points.', 'Watch Video (30s)', 40, 5, false, 0, 'https://youtu.be/I6O', '1. Open link: https://youtu.be/I6O
2. Perform Watch Video (30s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 7 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_1_9', 'level_1', 9, 'YouTube Watch Video (45s) Task #9', 'Complete the Watch Video (45s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 40 and 5 credit points.', 'Watch Video (45s)', 40, 5, false, 0, 'https://youtu.be/', '1. Open link: https://youtu.be/
2. Perform Watch Video (45s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 8 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_1_10', 'level_1', 10, 'Prepaid Task #2 (PKR 3,500)', 'Prepaid task requiring deposit unlock fee of PKR 3,500. Yields commission of PKR 80 and 30 credit points upon completion.', 'Prepaid Task #2', 80, 30, true, 3500, 'https://youtu.be/JSXlT', '1. Ensure wallet has sufficient balance or deposit PKR 3,500.
2. Click Unlock Task to pay fee.
3. Open protected link: https://youtu.be/JSXlT
4. Complete engagement steps.
5. Submit transaction and proof screenshot for admin approval.', 'Complete and receive approval for Task 9 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Level" ("id", "levelNumber", "title", "description", "status", "requiredTaskCount", "completionReward", "totalCreditPoints", "displayOrder", "createdAt", "updatedAt") VALUES ('level_2', 2, 'Vlog', 'Complete all 10 tasks in Level 2 (Vlog) to claim the PKR 1,000 milestone reward.', 'ACTIVE', 10, 1000, 100, 2, NOW(), NOW()) ON CONFLICT ("levelNumber") DO UPDATE SET "title" = EXCLUDED."title", "completionReward" = EXCLUDED."completionReward", "requiredTaskCount" = EXCLUDED."requiredTaskCount", "totalCreditPoints" = EXCLUDED."totalCreditPoints";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_2_1', 'level_2', 1, 'YouTube Subscribe Task #1', 'Complete the Subscribe action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 60 and 5 credit points.', 'Subscribe', 60, 5, false, 0, 'https://youtu.be/nzciqaNN4I0?si=QcGDCUl8ABo9Qlwd', '1. Open link: https://youtu.be/nzciqaNN4I0?si=QcGDCUl8ABo9Qlwd
2. Perform Subscribe action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for all tasks in Level 1 to unlock Level 2.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_2_2', 'level_2', 2, 'YouTube Like and Comment Task #2', 'Complete the Like and Comment action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 60 and 5 credit points.', 'Like and Comment', 60, 5, false, 0, 'https://youtu.be/1iJE8Lyvvls?si=yP3qFuihCpIdC5UV', '1. Open link: https://youtu.be/1iJE8Lyvvls?si=yP3qFuihCpIdC5UV
2. Perform Like and Comment action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 1 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_2_3', 'level_2', 3, 'YouTube Watch Video (30s) Task #3', 'Complete the Watch Video (30s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 60 and 5 credit points.', 'Watch Video (30s)', 60, 5, false, 0, 'https://youtu.be/wyBimQmMZMo?si=BM6sLmxsw3UiQetL', '1. Open link: https://youtu.be/wyBimQmMZMo?si=BM6sLmxsw3UiQetL
2. Perform Watch Video (30s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 2 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_2_4', 'level_2', 4, 'YouTube Watch Video (45s) Task #4', 'Complete the Watch Video (45s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 60 and 5 credit points.', 'Watch Video (45s)', 60, 5, false, 0, 'https://youtu.be/798f3txy4Zs?si=NpAZSSjCHf5sXQHn', '1. Open link: https://youtu.be/798f3txy4Zs?si=NpAZSSjCHf5sXQHn
2. Perform Watch Video (45s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 3 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_2_5', 'level_2', 5, 'Prepaid Task #1 (PKR 5,500)', 'Prepaid task requiring deposit unlock fee of PKR 5,500. Yields commission of PKR 120 and 30 credit points upon completion.', 'Prepaid Task #1', 120, 30, true, 5500, 'https://youtu.be/M2iHz1cVKxc?si=AKicqraZOjPv3mgg', '1. Ensure wallet has sufficient balance or deposit PKR 5,500.
2. Click Unlock Task to pay fee.
3. Open protected link: https://youtu.be/M2iHz1cVKxc?si=AKicqraZOjPv3mgg
4. Complete engagement steps.
5. Submit transaction and proof screenshot for admin approval.', 'Complete and receive approval for Task 4 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_2_6', 'level_2', 6, 'YouTube Subscribe Task #6', 'Complete the Subscribe action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 60 and 5 credit points.', 'Subscribe', 60, 5, false, 0, 'https://youtu.be/3cZ', '1. Open link: https://youtu.be/3cZ
2. Perform Subscribe action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 5 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_2_7', 'level_2', 7, 'YouTube Like and Comment Task #7', 'Complete the Like and Comment action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 60 and 5 credit points.', 'Like and Comment', 60, 5, false, 0, 'https://youtu.be/HGX31br5XD4?si=i55C748M-mSi0lts', '1. Open link: https://youtu.be/HGX31br5XD4?si=i55C748M-mSi0lts
2. Perform Like and Comment action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 6 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_2_8', 'level_2', 8, 'YouTube Watch Video (30s) Task #8', 'Complete the Watch Video (30s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 60 and 5 credit points.', 'Watch Video (30s)', 60, 5, false, 0, 'https://youtu.be/pgn8wq-WRN8?si=EcwXdqRmVC9LynqC', '1. Open link: https://youtu.be/pgn8wq-WRN8?si=EcwXdqRmVC9LynqC
2. Perform Watch Video (30s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 7 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_2_9', 'level_2', 9, 'YouTube Watch Video (45s) Task #9', 'Complete the Watch Video (45s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 60 and 5 credit points.', 'Watch Video (45s)', 60, 5, false, 0, 'https://youtu.be/UlvuMvKkg5U?si=O35IJAiVVAKTmttz', '1. Open link: https://youtu.be/UlvuMvKkg5U?si=O35IJAiVVAKTmttz
2. Perform Watch Video (45s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 8 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_2_10', 'level_2', 10, 'Prepaid Task #2 (PKR 9,500)', 'Prepaid task requiring deposit unlock fee of PKR 9,500. Yields commission of PKR 120 and 30 credit points upon completion.', 'Prepaid Task #2', 120, 30, true, 9500, 'https://youtu.be/K8Y2V9AwOos?si=SxysGiMzNJ9Eg2id', '1. Ensure wallet has sufficient balance or deposit PKR 9,500.
2. Click Unlock Task to pay fee.
3. Open protected link: https://youtu.be/K8Y2V9AwOos?si=SxysGiMzNJ9Eg2id
4. Complete engagement steps.
5. Submit transaction and proof screenshot for admin approval.', 'Complete and receive approval for Task 9 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Level" ("id", "levelNumber", "title", "description", "status", "requiredTaskCount", "completionReward", "totalCreditPoints", "displayOrder", "createdAt", "updatedAt") VALUES ('level_3', 3, 'Vlog', 'Complete all 10 tasks in Level 3 (Vlog) to claim the PKR 1,500 milestone reward.', 'ACTIVE', 10, 1500, 100, 3, NOW(), NOW()) ON CONFLICT ("levelNumber") DO UPDATE SET "title" = EXCLUDED."title", "completionReward" = EXCLUDED."completionReward", "requiredTaskCount" = EXCLUDED."requiredTaskCount", "totalCreditPoints" = EXCLUDED."totalCreditPoints";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_3_1', 'level_3', 1, 'YouTube Subscribe Task #1', 'Complete the Subscribe action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 80 and 5 credit points.', 'Subscribe', 80, 5, false, 0, 'https://youtu.be/7vOkn4m-XCs?si=t75KaK78GG1D87ev', '1. Open link: https://youtu.be/7vOkn4m-XCs?si=t75KaK78GG1D87ev
2. Perform Subscribe action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for all tasks in Level 2 to unlock Level 3.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_3_2', 'level_3', 2, 'YouTube Like and Comment Task #2', 'Complete the Like and Comment action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 80 and 5 credit points.', 'Like and Comment', 80, 5, false, 0, 'https://youtu.be/96GXqWaQcEE?si=QGeuAtrOng32KBf2', '1. Open link: https://youtu.be/96GXqWaQcEE?si=QGeuAtrOng32KBf2
2. Perform Like and Comment action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 1 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_3_3', 'level_3', 3, 'YouTube Watch Video (30s) Task #3', 'Complete the Watch Video (30s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 80 and 5 credit points.', 'Watch Video (30s)', 80, 5, false, 0, 'https://youtu.be/CZvYvUGLNMg?si=CAdnkQ9DrlGLeNji', '1. Open link: https://youtu.be/CZvYvUGLNMg?si=CAdnkQ9DrlGLeNji
2. Perform Watch Video (30s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 2 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_3_4', 'level_3', 4, 'YouTube Watch Video (45s) Task #4', 'Complete the Watch Video (45s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 80 and 5 credit points.', 'Watch Video (45s)', 80, 5, false, 0, 'https://youtu.be/APe0TO49E00?si=uzr2jUeVwfwiCEpC', '1. Open link: https://youtu.be/APe0TO49E00?si=uzr2jUeVwfwiCEpC
2. Perform Watch Video (45s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 3 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_3_5', 'level_3', 5, 'Prepaid Task #1 (PKR 15,000)', 'Prepaid task requiring deposit unlock fee of PKR 15,000. Yields commission of PKR 160 and 30 credit points upon completion.', 'Prepaid Task #1', 160, 30, true, 15000, 'https://youtu.be/hbHILEt52VI?si=M-5ga8nGEDax316y', '1. Ensure wallet has sufficient balance or deposit PKR 15,000.
2. Click Unlock Task to pay fee.
3. Open protected link: https://youtu.be/hbHILEt52VI?si=M-5ga8nGEDax316y
4. Complete engagement steps.
5. Submit transaction and proof screenshot for admin approval.', 'Complete and receive approval for Task 4 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_3_6', 'level_3', 6, 'YouTube Subscribe Task #6', 'Complete the Subscribe action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 80 and 5 credit points.', 'Subscribe', 80, 5, false, 0, 'https://youtu.be/WkQrMzwqKv4?si=', '1. Open link: https://youtu.be/WkQrMzwqKv4?si=
2. Perform Subscribe action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 5 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_3_7', 'level_3', 7, 'YouTube Like and Comment Task #7', 'Complete the Like and Comment action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 80 and 5 credit points.', 'Like and Comment', 80, 5, false, 0, 'https://youtu.be/CQpxJhN16pM?si=Huj0tEOmziuHzY-A', '1. Open link: https://youtu.be/CQpxJhN16pM?si=Huj0tEOmziuHzY-A
2. Perform Like and Comment action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 6 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_3_8', 'level_3', 8, 'YouTube Watch Video (30s) Task #8', 'Complete the Watch Video (30s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 80 and 5 credit points.', 'Watch Video (30s)', 80, 5, false, 0, 'https://youtu.be/CBhRIsc', '1. Open link: https://youtu.be/CBhRIsc
2. Perform Watch Video (30s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 7 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_3_9', 'level_3', 9, 'YouTube Watch Video (45s) Task #9', 'Complete the Watch Video (45s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 80 and 5 credit points.', 'Watch Video (45s)', 80, 5, false, 0, 'https://youtu.be/F7sPLM-ThnA?si=GozFZ1wHIl4HPnSL', '1. Open link: https://youtu.be/F7sPLM-ThnA?si=GozFZ1wHIl4HPnSL
2. Perform Watch Video (45s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 8 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_3_10', 'level_3', 10, 'Prepaid Task #2 (PKR 23,000)', 'Prepaid task requiring deposit unlock fee of PKR 23,000. Yields commission of PKR 160 and 30 credit points upon completion.', 'Prepaid Task #2', 160, 30, true, 23000, 'https://youtu.be/8T0m8f44Kgs?si=XPXvxc3B5IOOXrP-', '1. Ensure wallet has sufficient balance or deposit PKR 23,000.
2. Click Unlock Task to pay fee.
3. Open protected link: https://youtu.be/8T0m8f44Kgs?si=XPXvxc3B5IOOXrP-
4. Complete engagement steps.
5. Submit transaction and proof screenshot for admin approval.', 'Complete and receive approval for Task 9 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Level" ("id", "levelNumber", "title", "description", "status", "requiredTaskCount", "completionReward", "totalCreditPoints", "displayOrder", "createdAt", "updatedAt") VALUES ('level_4', 4, 'Vlog', 'Complete all 10 tasks in Level 4 (Vlog) to claim the PKR 2,000 milestone reward.', 'ACTIVE', 10, 2000, 100, 4, NOW(), NOW()) ON CONFLICT ("levelNumber") DO UPDATE SET "title" = EXCLUDED."title", "completionReward" = EXCLUDED."completionReward", "requiredTaskCount" = EXCLUDED."requiredTaskCount", "totalCreditPoints" = EXCLUDED."totalCreditPoints";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_4_1', 'level_4', 1, 'YouTube Subscribe Task #1', 'Complete the Subscribe action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 100 and 5 credit points.', 'Subscribe', 100, 5, false, 0, 'https://youtu.be/ew', '1. Open link: https://youtu.be/ew
2. Perform Subscribe action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for all tasks in Level 3 to unlock Level 4.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_4_2', 'level_4', 2, 'YouTube Like and Comment Task #2', 'Complete the Like and Comment action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 100 and 5 credit points.', 'Like and Comment', 100, 5, false, 0, 'https://youtu.be/YCzRPKRAWmw?si=OKAr0OUB0T9XBzhJ', '1. Open link: https://youtu.be/YCzRPKRAWmw?si=OKAr0OUB0T9XBzhJ
2. Perform Like and Comment action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 1 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_4_3', 'level_4', 3, 'YouTube Watch Video (30s) Task #3', 'Complete the Watch Video (30s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 100 and 5 credit points.', 'Watch Video (30s)', 100, 5, false, 0, 'https://youtu.be/irHIeMEP5hw?si=Fh8SSfl0koXUrYrk', '1. Open link: https://youtu.be/irHIeMEP5hw?si=Fh8SSfl0koXUrYrk
2. Perform Watch Video (30s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 2 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_4_4', 'level_4', 4, 'YouTube Watch Video (45s) Task #4', 'Complete the Watch Video (45s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 100 and 5 credit points.', 'Watch Video (45s)', 100, 5, false, 0, 'https://youtu.be/45GUatkxX3s?si=ZjsYNezm1YpflOOJ', '1. Open link: https://youtu.be/45GUatkxX3s?si=ZjsYNezm1YpflOOJ
2. Perform Watch Video (45s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 3 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_4_5', 'level_4', 5, 'Prepaid Task #1 (PKR 35,000)', 'Prepaid task requiring deposit unlock fee of PKR 35,000. Yields commission of PKR 200 and 30 credit points upon completion.', 'Prepaid Task #1', 200, 30, true, 35000, 'https://youtu.be/', '1. Ensure wallet has sufficient balance or deposit PKR 35,000.
2. Click Unlock Task to pay fee.
3. Open protected link: https://youtu.be/
4. Complete engagement steps.
5. Submit transaction and proof screenshot for admin approval.', 'Complete and receive approval for Task 4 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_4_6', 'level_4', 6, 'YouTube Subscribe Task #6', 'Complete the Subscribe action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 100 and 5 credit points.', 'Subscribe', 100, 5, false, 0, 'https://youtu.be/ZnmU', '1. Open link: https://youtu.be/ZnmU
2. Perform Subscribe action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 5 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_4_7', 'level_4', 7, 'YouTube Like and Comment Task #7', 'Complete the Like and Comment action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 100 and 5 credit points.', 'Like and Comment', 100, 5, false, 0, 'https://youtu.be/jCPcZUifbkc?si=W8SFeXKJEnh6h', '1. Open link: https://youtu.be/jCPcZUifbkc?si=W8SFeXKJEnh6h
2. Perform Like and Comment action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 6 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_4_8', 'level_4', 8, 'YouTube Watch Video (30s) Task #8', 'Complete the Watch Video (30s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 100 and 5 credit points.', 'Watch Video (30s)', 100, 5, false, 0, 'https://youtu.be/EYeG5TiE2B0?si=IdoR0rcI430rFiXP', '1. Open link: https://youtu.be/EYeG5TiE2B0?si=IdoR0rcI430rFiXP
2. Perform Watch Video (30s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 7 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_4_9', 'level_4', 9, 'YouTube Watch Video (45s) Task #9', 'Complete the Watch Video (45s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 100 and 5 credit points.', 'Watch Video (45s)', 100, 5, false, 0, 'https://youtu.be/veNdcvpCNRM?si=LTwSsN-0YCpuY4he', '1. Open link: https://youtu.be/veNdcvpCNRM?si=LTwSsN-0YCpuY4he
2. Perform Watch Video (45s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 8 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_4_10', 'level_4', 10, 'Prepaid Task #2 (PKR 50,000)', 'Prepaid task requiring deposit unlock fee of PKR 50,000. Yields commission of PKR 200 and 30 credit points upon completion.', 'Prepaid Task #2', 200, 30, true, 50000, 'https://youtu.be/bA1j3q0Q5wo?si=IpB8KdfE9f7NA-', '1. Ensure wallet has sufficient balance or deposit PKR 50,000.
2. Click Unlock Task to pay fee.
3. Open protected link: https://youtu.be/bA1j3q0Q5wo?si=IpB8KdfE9f7NA-
4. Complete engagement steps.
5. Submit transaction and proof screenshot for admin approval.', 'Complete and receive approval for Task 9 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Level" ("id", "levelNumber", "title", "description", "status", "requiredTaskCount", "completionReward", "totalCreditPoints", "displayOrder", "createdAt", "updatedAt") VALUES ('level_5', 5, 'Level 5', 'Complete all 10 tasks in Level 5 (Level 5) to claim the PKR 2,500 milestone reward.', 'ACTIVE', 10, 2500, 100, 5, NOW(), NOW()) ON CONFLICT ("levelNumber") DO UPDATE SET "title" = EXCLUDED."title", "completionReward" = EXCLUDED."completionReward", "requiredTaskCount" = EXCLUDED."requiredTaskCount", "totalCreditPoints" = EXCLUDED."totalCreditPoints";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_5_1', 'level_5', 1, 'YouTube Subscribe Task #1', 'Complete the Subscribe action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 150 and 5 credit points.', 'Subscribe', 150, 5, false, 0, 'https://youtu.be/bmyXHQQctyQ?si=WE3n94', '1. Open link: https://youtu.be/bmyXHQQctyQ?si=WE3n94
2. Perform Subscribe action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for all tasks in Level 4 to unlock Level 5.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_5_2', 'level_5', 2, 'YouTube Like and Comment Task #2', 'Complete the Like and Comment action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 150 and 5 credit points.', 'Like and Comment', 150, 5, false, 0, 'https://youtu.be/XgnSxvUiXO0?si=22ktWXjGWh1OOnwt', '1. Open link: https://youtu.be/XgnSxvUiXO0?si=22ktWXjGWh1OOnwt
2. Perform Like and Comment action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 1 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_5_3', 'level_5', 3, 'YouTube Watch Video (30s) Task #3', 'Complete the Watch Video (30s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 150 and 5 credit points.', 'Watch Video (30s)', 150, 5, false, 0, 'https://youtu.be/pmjH9erWu48?si=ZPVv0sGjxwpdQ2JW', '1. Open link: https://youtu.be/pmjH9erWu48?si=ZPVv0sGjxwpdQ2JW
2. Perform Watch Video (30s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 2 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_5_4', 'level_5', 4, 'YouTube Watch Video (45s) Task #4', 'Complete the Watch Video (45s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 150 and 5 credit points.', 'Watch Video (45s)', 150, 5, false, 0, 'https://youtu.be/HOWaPR9brOE?si=q508JZyHn6ROxrB0', '1. Open link: https://youtu.be/HOWaPR9brOE?si=q508JZyHn6ROxrB0
2. Perform Watch Video (45s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 3 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_5_5', 'level_5', 5, 'Prepaid Task #1 (PKR 62,500)', 'Prepaid task requiring deposit unlock fee of PKR 62,500. Yields commission of PKR 300 and 30 credit points upon completion.', 'Prepaid Task #1', 300, 30, true, 62500, 'https://youtu.be/yqH3DcxB6Dk?si=kjp1orUfY-WKbbJS', '1. Ensure wallet has sufficient balance or deposit PKR 62,500.
2. Click Unlock Task to pay fee.
3. Open protected link: https://youtu.be/yqH3DcxB6Dk?si=kjp1orUfY-WKbbJS
4. Complete engagement steps.
5. Submit transaction and proof screenshot for admin approval.', 'Complete and receive approval for Task 4 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_5_6', 'level_5', 6, 'YouTube Subscribe Task #6', 'Complete the Subscribe action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 150 and 5 credit points.', 'Subscribe', 150, 5, false, 0, 'https://youtu.be/31HJbpU2RpU?si=y--XuUEVnQumEdqj', '1. Open link: https://youtu.be/31HJbpU2RpU?si=y--XuUEVnQumEdqj
2. Perform Subscribe action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 5 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_5_7', 'level_5', 7, 'YouTube Like and Comment Task #7', 'Complete the Like and Comment action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 150 and 5 credit points.', 'Like and Comment', 150, 5, false, 0, 'https://youtu.be/GwifegtMmUI?si=eP2xJ1bdsoVzTyzY', '1. Open link: https://youtu.be/GwifegtMmUI?si=eP2xJ1bdsoVzTyzY
2. Perform Like and Comment action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 6 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_5_8', 'level_5', 8, 'YouTube Watch Video (30s) Task #8', 'Complete the Watch Video (30s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 150 and 5 credit points.', 'Watch Video (30s)', 150, 5, false, 0, 'https://youtu.be/6Ct2D12cHqw?si=', '1. Open link: https://youtu.be/6Ct2D12cHqw?si=
2. Perform Watch Video (30s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 7 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_5_9', 'level_5', 9, 'YouTube Watch Video (45s) Task #9', 'Complete the Watch Video (45s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 150 and 5 credit points.', 'Watch Video (45s)', 150, 5, false, 0, 'https://youtu.be/-6kARhVxEWA?si=dB6y1GiHnaEJBRkC', '1. Open link: https://youtu.be/-6kARhVxEWA?si=dB6y1GiHnaEJBRkC
2. Perform Watch Video (45s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 8 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_5_10', 'level_5', 10, 'Prepaid Task #2 (PKR 80,000)', 'Prepaid task requiring deposit unlock fee of PKR 80,000. Yields commission of PKR 300 and 30 credit points upon completion.', 'Prepaid Task #2', 300, 30, true, 80000, 'https://youtu.be/yIjjg5', '1. Ensure wallet has sufficient balance or deposit PKR 80,000.
2. Click Unlock Task to pay fee.
3. Open protected link: https://youtu.be/yIjjg5
4. Complete engagement steps.
5. Submit transaction and proof screenshot for admin approval.', 'Complete and receive approval for Task 9 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Level" ("id", "levelNumber", "title", "description", "status", "requiredTaskCount", "completionReward", "totalCreditPoints", "displayOrder", "createdAt", "updatedAt") VALUES ('level_6', 6, 'Level 6', 'Complete all 15 tasks in Level 6 (Level 6) to claim the PKR 5,000 milestone reward.', 'ACTIVE', 15, 5000, 100, 6, NOW(), NOW()) ON CONFLICT ("levelNumber") DO UPDATE SET "title" = EXCLUDED."title", "completionReward" = EXCLUDED."completionReward", "requiredTaskCount" = EXCLUDED."requiredTaskCount", "totalCreditPoints" = EXCLUDED."totalCreditPoints";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_6_1', 'level_6', 1, 'YouTube Subscribe Task #1', 'Complete the Subscribe action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 200 and 5 credit points.', 'Subscribe', 200, 5, false, 0, 'https://youtu.be/qgz-ydhRs4s?si=Il542hKwwSHMMFT3', '1. Open link: https://youtu.be/qgz-ydhRs4s?si=Il542hKwwSHMMFT3
2. Perform Subscribe action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for all tasks in Level 5 to unlock Level 6.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_6_2', 'level_6', 2, 'YouTube Like and Comment Task #2', 'Complete the Like and Comment action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 200 and 5 credit points.', 'Like and Comment', 200, 5, false, 0, 'https://youtu.be/XaEkHoMtc5Q?si=h0RzVrtAK9jQBRcg', '1. Open link: https://youtu.be/XaEkHoMtc5Q?si=h0RzVrtAK9jQBRcg
2. Perform Like and Comment action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 1 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_6_3', 'level_6', 3, 'YouTube Watch Video (30s) Task #3', 'Complete the Watch Video (30s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 200 and 5 credit points.', 'Watch Video (30s)', 200, 5, false, 0, 'https://youtu.be/3nYntR', '1. Open link: https://youtu.be/3nYntR
2. Perform Watch Video (30s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 2 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_6_4', 'level_6', 4, 'YouTube Watch Video (45s) Task #4', 'Complete the Watch Video (45s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 200 and 5 credit points.', 'Watch Video (45s)', 200, 5, false, 0, 'https://youtu.be/8BOnFKojVYc?si=59knG1PQVKYd6gVk', '1. Open link: https://youtu.be/8BOnFKojVYc?si=59knG1PQVKYd6gVk
2. Perform Watch Video (45s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 3 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_6_5', 'level_6', 5, 'Prepaid Task #1 (PKR 100,000)', 'Prepaid task requiring deposit unlock fee of PKR 100,000. Yields commission of PKR 400 and 13 credit points upon completion.', 'Prepaid Task #1', 400, 13, true, 100000, 'https://youtu.be/B3j7o3RfBVI?si=nSo3Ii77SdDR4iI4', '1. Ensure wallet has sufficient balance or deposit PKR 100,000.
2. Click Unlock Task to pay fee.
3. Open protected link: https://youtu.be/B3j7o3RfBVI?si=nSo3Ii77SdDR4iI4
4. Complete engagement steps.
5. Submit transaction and proof screenshot for admin approval.', 'Complete and receive approval for Task 4 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_6_6', 'level_6', 6, 'YouTube Subscribe Task #6', 'Complete the Subscribe action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 200 and 5 credit points.', 'Subscribe', 200, 5, false, 0, 'https://youtu.be/TYWrS9lbHVo?si=vylP', '1. Open link: https://youtu.be/TYWrS9lbHVo?si=vylP
2. Perform Subscribe action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 5 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_6_7', 'level_6', 7, 'YouTube Like and Comment Task #7', 'Complete the Like and Comment action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 200 and 5 credit points.', 'Like and Comment', 200, 5, false, 0, 'https://youtu.be/Jjpfl2hgN5k?si=XhKzdxX-i616kqTs', '1. Open link: https://youtu.be/Jjpfl2hgN5k?si=XhKzdxX-i616kqTs
2. Perform Like and Comment action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 6 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_6_8', 'level_6', 8, 'YouTube Watch Video (30s) Task #8', 'Complete the Watch Video (30s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 200 and 5 credit points.', 'Watch Video (30s)', 200, 5, false, 0, 'https://youtu.be/t1y9vFl3LQc?si=H-TnYfPxFjrPx91H', '1. Open link: https://youtu.be/t1y9vFl3LQc?si=H-TnYfPxFjrPx91H
2. Perform Watch Video (30s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 7 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_6_9', 'level_6', 9, 'YouTube Watch Video (45s) Task #9', 'Complete the Watch Video (45s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 200 and 5 credit points.', 'Watch Video (45s)', 200, 5, false, 0, 'https://youtu.be/esY3mHyDFi4?si=3hxcM', '1. Open link: https://youtu.be/esY3mHyDFi4?si=3hxcM
2. Perform Watch Video (45s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 8 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_6_10', 'level_6', 10, 'Prepaid Task #2 (PKR 130,000)', 'Prepaid task requiring deposit unlock fee of PKR 130,000. Yields commission of PKR 400 and 13 credit points upon completion.', 'Prepaid Task #2', 400, 13, true, 130000, 'https://youtu.be/1lCZKskfCqI?si=GiRq7gaiCzepy0ka', '1. Ensure wallet has sufficient balance or deposit PKR 130,000.
2. Click Unlock Task to pay fee.
3. Open protected link: https://youtu.be/1lCZKskfCqI?si=GiRq7gaiCzepy0ka
4. Complete engagement steps.
5. Submit transaction and proof screenshot for admin approval.', 'Complete and receive approval for Task 9 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_6_11', 'level_6', 11, 'YouTube Subscribe Task #11', 'Complete the Subscribe action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 200 and 5 credit points.', 'Subscribe', 200, 5, false, 0, 'https://youtu.be/2G34ILUfSPg?si=kAQkhhfMnBzMUxgM', '1. Open link: https://youtu.be/2G34ILUfSPg?si=kAQkhhfMnBzMUxgM
2. Perform Subscribe action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 10 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_6_12', 'level_6', 12, 'YouTube Like and Comment Task #12', 'Complete the Like and Comment action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 200 and 5 credit points.', 'Like and Comment', 200, 5, false, 0, 'https://youtu.be/kSeHcwfE6VQ?si=-0ADsQw', '1. Open link: https://youtu.be/kSeHcwfE6VQ?si=-0ADsQw
2. Perform Like and Comment action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 11 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_6_13', 'level_6', 13, 'YouTube Watch Video (30s) Task #13', 'Complete the Watch Video (30s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 200 and 5 credit points.', 'Watch Video (30s)', 200, 5, false, 0, 'https://youtu.be/L-uUzPvBqd8?si=jUhVHtx89nY8', '1. Open link: https://youtu.be/L-uUzPvBqd8?si=jUhVHtx89nY8
2. Perform Watch Video (30s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 12 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_6_14', 'level_6', 14, 'YouTube Watch Video (45s) Task #14', 'Complete the Watch Video (45s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 200 and 5 credit points.', 'Watch Video (45s)', 200, 5, false, 0, 'https://youtu.be/Cek3y8wZNd8?si=wAfx4TWuvGd4KYcX', '1. Open link: https://youtu.be/Cek3y8wZNd8?si=wAfx4TWuvGd4KYcX
2. Perform Watch Video (45s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 13 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_6_15', 'level_6', 15, 'Prepaid Task #3 (PKR 158,000)', 'Prepaid task requiring deposit unlock fee of PKR 158,000. Yields commission of PKR 400 and 14 credit points upon completion.', 'Prepaid Task #3', 400, 14, true, 158000, 'https://youtu.be/neKBxcwqsU4?si=whNCyFEItWErsb7t', '1. Ensure wallet has sufficient balance or deposit PKR 158,000.
2. Click Unlock Task to pay fee.
3. Open protected link: https://youtu.be/neKBxcwqsU4?si=whNCyFEItWErsb7t
4. Complete engagement steps.
5. Submit transaction and proof screenshot for admin approval.', 'Complete and receive approval for Task 14 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Level" ("id", "levelNumber", "title", "description", "status", "requiredTaskCount", "completionReward", "totalCreditPoints", "displayOrder", "createdAt", "updatedAt") VALUES ('level_7', 7, 'Level 7', 'Complete all 15 tasks in Level 7 (Level 7) to claim the PKR 7,500 milestone reward.', 'ACTIVE', 15, 7500, 100, 7, NOW(), NOW()) ON CONFLICT ("levelNumber") DO UPDATE SET "title" = EXCLUDED."title", "completionReward" = EXCLUDED."completionReward", "requiredTaskCount" = EXCLUDED."requiredTaskCount", "totalCreditPoints" = EXCLUDED."totalCreditPoints";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_7_1', 'level_7', 1, 'YouTube Subscribe Task #1', 'Complete the Subscribe action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 250 and 5 credit points.', 'Subscribe', 250, 5, false, 0, 'https://youtu.be/B9WFwGvMUZg?si=0iEB2lrtL56J4cmx', '1. Open link: https://youtu.be/B9WFwGvMUZg?si=0iEB2lrtL56J4cmx
2. Perform Subscribe action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for all tasks in Level 6 to unlock Level 7.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_7_2', 'level_7', 2, 'YouTube Like and Comment Task #2', 'Complete the Like and Comment action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 250 and 5 credit points.', 'Like and Comment', 250, 5, false, 0, 'https://youtu.be/YqedmavuG64?si=prGU4MJUaaDCnoBI', '1. Open link: https://youtu.be/YqedmavuG64?si=prGU4MJUaaDCnoBI
2. Perform Like and Comment action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 1 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_7_3', 'level_7', 3, 'YouTube Watch Video (30s) Task #3', 'Complete the Watch Video (30s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 250 and 5 credit points.', 'Watch Video (30s)', 250, 5, false, 0, 'https://youtu.be/bA33aA83DUs?si=oOEtJwbWRdtsXZIe', '1. Open link: https://youtu.be/bA33aA83DUs?si=oOEtJwbWRdtsXZIe
2. Perform Watch Video (30s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 2 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_7_4', 'level_7', 4, 'YouTube Watch Video (45s) Task #4', 'Complete the Watch Video (45s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 250 and 5 credit points.', 'Watch Video (45s)', 250, 5, false, 0, 'https://youtu.be/l0EC6dvS89M?si=WlG698OLMa', '1. Open link: https://youtu.be/l0EC6dvS89M?si=WlG698OLMa
2. Perform Watch Video (45s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 3 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_7_5', 'level_7', 5, 'Prepaid Task #1 (PKR 180,000)', 'Prepaid task requiring deposit unlock fee of PKR 180,000. Yields commission of PKR 500 and 13 credit points upon completion.', 'Prepaid Task #1', 500, 13, true, 180000, 'https://youtu.be/SJYdo3ScJDM?si=rofNESmY3HHZDE9d', '1. Ensure wallet has sufficient balance or deposit PKR 180,000.
2. Click Unlock Task to pay fee.
3. Open protected link: https://youtu.be/SJYdo3ScJDM?si=rofNESmY3HHZDE9d
4. Complete engagement steps.
5. Submit transaction and proof screenshot for admin approval.', 'Complete and receive approval for Task 4 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_7_6', 'level_7', 6, 'YouTube Subscribe Task #6', 'Complete the Subscribe action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 250 and 5 credit points.', 'Subscribe', 250, 5, false, 0, 'https://youtu.be/nsV-B79x33I?si=aLI7nHiMwgl0yG1i', '1. Open link: https://youtu.be/nsV-B79x33I?si=aLI7nHiMwgl0yG1i
2. Perform Subscribe action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 5 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_7_7', 'level_7', 7, 'YouTube Like and Comment Task #7', 'Complete the Like and Comment action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 250 and 5 credit points.', 'Like and Comment', 250, 5, false, 0, 'https://youtu.be/fCDVn0Ri2dU?si=MmFVxtjmJalzqsSQ', '1. Open link: https://youtu.be/fCDVn0Ri2dU?si=MmFVxtjmJalzqsSQ
2. Perform Like and Comment action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 6 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_7_8', 'level_7', 8, 'YouTube Watch Video (30s) Task #8', 'Complete the Watch Video (30s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 250 and 5 credit points.', 'Watch Video (30s)', 250, 5, false, 0, 'https://youtu.be/4z1OyqDyR2E?si=C0Qc5ZF84', '1. Open link: https://youtu.be/4z1OyqDyR2E?si=C0Qc5ZF84
2. Perform Watch Video (30s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 7 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_7_9', 'level_7', 9, 'YouTube Watch Video (45s) Task #9', 'Complete the Watch Video (45s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 250 and 5 credit points.', 'Watch Video (45s)', 250, 5, false, 0, 'https://youtu.be/sSFYNRoo4r4?si=6hWH6qxt9ylI7pWi', '1. Open link: https://youtu.be/sSFYNRoo4r4?si=6hWH6qxt9ylI7pWi
2. Perform Watch Video (45s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 8 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_7_10', 'level_7', 10, 'Prepaid Task #2 (PKR 250,000)', 'Prepaid task requiring deposit unlock fee of PKR 250,000. Yields commission of PKR 500 and 13 credit points upon completion.', 'Prepaid Task #2', 500, 13, true, 250000, 'https://youtu.be/Wr5X3lJ30R4?si=KHX-cBl50XRgR3D1', '1. Ensure wallet has sufficient balance or deposit PKR 250,000.
2. Click Unlock Task to pay fee.
3. Open protected link: https://youtu.be/Wr5X3lJ30R4?si=KHX-cBl50XRgR3D1
4. Complete engagement steps.
5. Submit transaction and proof screenshot for admin approval.', 'Complete and receive approval for Task 9 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_7_11', 'level_7', 11, 'YouTube Subscribe Task #11', 'Complete the Subscribe action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 250 and 5 credit points.', 'Subscribe', 250, 5, false, 0, 'https://youtu.be/g', '1. Open link: https://youtu.be/g
2. Perform Subscribe action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 10 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_7_12', 'level_7', 12, 'YouTube Like and Comment Task #12', 'Complete the Like and Comment action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 250 and 5 credit points.', 'Like and Comment', 250, 5, false, 0, 'https://youtu.be/z5X413CeFvk?si=Wy-DnuFa7Hst6mt3', '1. Open link: https://youtu.be/z5X413CeFvk?si=Wy-DnuFa7Hst6mt3
2. Perform Like and Comment action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 11 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_7_13', 'level_7', 13, 'YouTube Watch Video (30s) Task #13', 'Complete the Watch Video (30s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 250 and 5 credit points.', 'Watch Video (30s)', 250, 5, false, 0, 'https://youtu.be/xum7JzyS6e8?si=EcDLPRZ13apIuVAX', '1. Open link: https://youtu.be/xum7JzyS6e8?si=EcDLPRZ13apIuVAX
2. Perform Watch Video (30s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 12 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_7_14', 'level_7', 14, 'YouTube Watch Video (45s) Task #14', 'Complete the Watch Video (45s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 250 and 5 credit points.', 'Watch Video (45s)', 250, 5, false, 0, 'https://youtu.be/5PPwEg1kDRE?si=NWUo', '1. Open link: https://youtu.be/5PPwEg1kDRE?si=NWUo
2. Perform Watch Video (45s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 13 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_7_15', 'level_7', 15, 'Prepaid Task #3 (PKR 330,000)', 'Prepaid task requiring deposit unlock fee of PKR 330,000. Yields commission of PKR 500 and 14 credit points upon completion.', 'Prepaid Task #3', 500, 14, true, 330000, 'https://youtu.be/fHDijn2Il8E?si=s42SIQM3iiylVKBG', '1. Ensure wallet has sufficient balance or deposit PKR 330,000.
2. Click Unlock Task to pay fee.
3. Open protected link: https://youtu.be/fHDijn2Il8E?si=s42SIQM3iiylVKBG
4. Complete engagement steps.
5. Submit transaction and proof screenshot for admin approval.', 'Complete and receive approval for Task 14 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Level" ("id", "levelNumber", "title", "description", "status", "requiredTaskCount", "completionReward", "totalCreditPoints", "displayOrder", "createdAt", "updatedAt") VALUES ('level_8', 8, 'Level 8', 'Complete all 15 tasks in Level 8 (Level 8) to claim the PKR 10,000 milestone reward.', 'ACTIVE', 15, 10000, 100, 8, NOW(), NOW()) ON CONFLICT ("levelNumber") DO UPDATE SET "title" = EXCLUDED."title", "completionReward" = EXCLUDED."completionReward", "requiredTaskCount" = EXCLUDED."requiredTaskCount", "totalCreditPoints" = EXCLUDED."totalCreditPoints";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_8_1', 'level_8', 1, 'YouTube Subscribe Task #1', 'Complete the Subscribe action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 300 and 5 credit points.', 'Subscribe', 300, 5, false, 0, 'https://youtu.be/OS-WTughD14?si=xyiP5FPupBzSfQ9p', '1. Open link: https://youtu.be/OS-WTughD14?si=xyiP5FPupBzSfQ9p
2. Perform Subscribe action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for all tasks in Level 7 to unlock Level 8.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_8_2', 'level_8', 2, 'YouTube Like and Comment Task #2', 'Complete the Like and Comment action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 300 and 5 credit points.', 'Like and Comment', 300, 5, false, 0, 'https://youtu.be/d4M3YRLiSwM?si=D0a3oKwRCFUdkJ5B', '1. Open link: https://youtu.be/d4M3YRLiSwM?si=D0a3oKwRCFUdkJ5B
2. Perform Like and Comment action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 1 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_8_3', 'level_8', 3, 'YouTube Watch Video (30s) Task #3', 'Complete the Watch Video (30s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 300 and 5 credit points.', 'Watch Video (30s)', 300, 5, false, 0, 'https://youtu.be/nGNlcnGobAY?si=nK83aH5a-W8ph9Xv', '1. Open link: https://youtu.be/nGNlcnGobAY?si=nK83aH5a-W8ph9Xv
2. Perform Watch Video (30s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 2 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_8_4', 'level_8', 4, 'YouTube Watch Video (45s) Task #4', 'Complete the Watch Video (45s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 300 and 5 credit points.', 'Watch Video (45s)', 300, 5, false, 0, 'https://youtu.be/hTkjqhOsgwc?si=QGKy8vK', '1. Open link: https://youtu.be/hTkjqhOsgwc?si=QGKy8vK
2. Perform Watch Video (45s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 3 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_8_5', 'level_8', 5, 'Prepaid Task #1 (PKR 350,000)', 'Prepaid task requiring deposit unlock fee of PKR 350,000. Yields commission of PKR 600 and 13 credit points upon completion.', 'Prepaid Task #1', 600, 13, true, 350000, 'https://youtu.be/AGUb2Nn7pKQ?si=-3czbIuznEgR0tew', '1. Ensure wallet has sufficient balance or deposit PKR 350,000.
2. Click Unlock Task to pay fee.
3. Open protected link: https://youtu.be/AGUb2Nn7pKQ?si=-3czbIuznEgR0tew
4. Complete engagement steps.
5. Submit transaction and proof screenshot for admin approval.', 'Complete and receive approval for Task 4 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_8_6', 'level_8', 6, 'YouTube Subscribe Task #6', 'Complete the Subscribe action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 300 and 5 credit points.', 'Subscribe', 300, 5, false, 0, 'https://youtu.be/h76Q3E', '1. Open link: https://youtu.be/h76Q3E
2. Perform Subscribe action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 5 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_8_7', 'level_8', 7, 'YouTube Like and Comment Task #7', 'Complete the Like and Comment action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 300 and 5 credit points.', 'Like and Comment', 300, 5, false, 0, 'https://youtu.be/m7pxtU5qz2U?si=QoDpPdbZNjePMXMb', '1. Open link: https://youtu.be/m7pxtU5qz2U?si=QoDpPdbZNjePMXMb
2. Perform Like and Comment action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 6 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_8_8', 'level_8', 8, 'YouTube Watch Video (30s) Task #8', 'Complete the Watch Video (30s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 300 and 5 credit points.', 'Watch Video (30s)', 300, 5, false, 0, 'https://youtu.be/7bGRQJzAKZw?si=uwF3CcleRr4o30up', '1. Open link: https://youtu.be/7bGRQJzAKZw?si=uwF3CcleRr4o30up
2. Perform Watch Video (30s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 7 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_8_9', 'level_8', 9, 'YouTube Watch Video (45s) Task #9', 'Complete the Watch Video (45s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 300 and 5 credit points.', 'Watch Video (45s)', 300, 5, false, 0, 'https://youtu.be/5Z-qAutLgHA?si=GyPFMacS3gxvVogE', '1. Open link: https://youtu.be/5Z-qAutLgHA?si=GyPFMacS3gxvVogE
2. Perform Watch Video (45s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 8 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_8_10', 'level_8', 10, 'Prepaid Task #2 (PKR 452,000)', 'Prepaid task requiring deposit unlock fee of PKR 452,000. Yields commission of PKR 600 and 13 credit points upon completion.', 'Prepaid Task #2', 600, 13, true, 452000, 'https://youtu.be/0TCQClBCJA8?si=S9dn0asC5H9fRU8p', '1. Ensure wallet has sufficient balance or deposit PKR 452,000.
2. Click Unlock Task to pay fee.
3. Open protected link: https://youtu.be/0TCQClBCJA8?si=S9dn0asC5H9fRU8p
4. Complete engagement steps.
5. Submit transaction and proof screenshot for admin approval.', 'Complete and receive approval for Task 9 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_8_11', 'level_8', 11, 'YouTube Subscribe Task #11', 'Complete the Subscribe action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 300 and 5 credit points.', 'Subscribe', 300, 5, false, 0, 'https://youtu.be/WQ3ilqvjWkA?si=', '1. Open link: https://youtu.be/WQ3ilqvjWkA?si=
2. Perform Subscribe action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 10 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_8_12', 'level_8', 12, 'YouTube Like and Comment Task #12', 'Complete the Like and Comment action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 300 and 5 credit points.', 'Like and Comment', 300, 5, false, 0, 'https://youtu.be/Y', '1. Open link: https://youtu.be/Y
2. Perform Like and Comment action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 11 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_8_13', 'level_8', 13, 'YouTube Watch Video (30s) Task #13', 'Complete the Watch Video (30s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 300 and 5 credit points.', 'Watch Video (30s)', 300, 5, false, 0, 'https://youtu.be/ALEEcf3P2ik?si=lPeca', '1. Open link: https://youtu.be/ALEEcf3P2ik?si=lPeca
2. Perform Watch Video (30s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 12 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_8_14', 'level_8', 14, 'YouTube Watch Video (45s) Task #14', 'Complete the Watch Video (45s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 300 and 5 credit points.', 'Watch Video (45s)', 300, 5, false, 0, 'https://youtu.be/ah8c4GSOdIE?si=N3lHphBCuhG1wdrR', '1. Open link: https://youtu.be/ah8c4GSOdIE?si=N3lHphBCuhG1wdrR
2. Perform Watch Video (45s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 13 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_8_15', 'level_8', 15, 'Prepaid Task #3 (PKR 550,000)', 'Prepaid task requiring deposit unlock fee of PKR 550,000. Yields commission of PKR 600 and 14 credit points upon completion.', 'Prepaid Task #3', 600, 14, true, 550000, 'https://youtu.be/hA9a9ZSj3zY?si=704', '1. Ensure wallet has sufficient balance or deposit PKR 550,000.
2. Click Unlock Task to pay fee.
3. Open protected link: https://youtu.be/hA9a9ZSj3zY?si=704
4. Complete engagement steps.
5. Submit transaction and proof screenshot for admin approval.', 'Complete and receive approval for Task 14 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Level" ("id", "levelNumber", "title", "description", "status", "requiredTaskCount", "completionReward", "totalCreditPoints", "displayOrder", "createdAt", "updatedAt") VALUES ('level_9', 9, 'Level 9', 'Complete all 20 tasks in Level 9 (Level 9) to claim the PKR 12,500 milestone reward.', 'ACTIVE', 20, 12500, 100, 9, NOW(), NOW()) ON CONFLICT ("levelNumber") DO UPDATE SET "title" = EXCLUDED."title", "completionReward" = EXCLUDED."completionReward", "requiredTaskCount" = EXCLUDED."requiredTaskCount", "totalCreditPoints" = EXCLUDED."totalCreditPoints";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_9_1', 'level_9', 1, 'YouTube Subscribe Task #1', 'Complete the Subscribe action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 400 and 4 credit points.', 'Subscribe', 400, 4, false, 0, 'https://youtu.be/AnYl6Nk9GOA?si=uJMUmAkCoFVqzSZ2', '1. Open link: https://youtu.be/AnYl6Nk9GOA?si=uJMUmAkCoFVqzSZ2
2. Perform Subscribe action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for all tasks in Level 8 to unlock Level 9.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_9_2', 'level_9', 2, 'YouTube Like and Comment Task #2', 'Complete the Like and Comment action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 400 and 4 credit points.', 'Like and Comment', 400, 4, false, 0, 'https://youtu.be/UItWltVZZmE?si=4fMmgvmTZhm9xq9s', '1. Open link: https://youtu.be/UItWltVZZmE?si=4fMmgvmTZhm9xq9s
2. Perform Like and Comment action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 1 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_9_3', 'level_9', 3, 'YouTube Watch Video (30s) Task #3', 'Complete the Watch Video (30s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 400 and 4 credit points.', 'Watch Video (30s)', 400, 4, false, 0, 'https://youtu.be/Cw-Wt4xKD2s?si=HCCHU3lcQEGIOpAV', '1. Open link: https://youtu.be/Cw-Wt4xKD2s?si=HCCHU3lcQEGIOpAV
2. Perform Watch Video (30s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 2 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_9_4', 'level_9', 4, 'YouTube Watch Video (45s) Task #4', 'Complete the Watch Video (45s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 400 and 4 credit points.', 'Watch Video (45s)', 400, 4, false, 0, 'https://youtu.be/jC5xlKIQgR8?si=SM5t6XKxplYQIXlP', '1. Open link: https://youtu.be/jC5xlKIQgR8?si=SM5t6XKxplYQIXlP
2. Perform Watch Video (45s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 3 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_9_5', 'level_9', 5, 'Prepaid Task #1 (PKR 600,000)', 'Prepaid task requiring deposit unlock fee of PKR 600,000. Yields commission of PKR 800 and 9 credit points upon completion.', 'Prepaid Task #1', 800, 9, true, 600000, 'https://youtu.be/X8FNAzCoCoI?si=VLs5Ol5Gh2StDnzK', '1. Ensure wallet has sufficient balance or deposit PKR 600,000.
2. Click Unlock Task to pay fee.
3. Open protected link: https://youtu.be/X8FNAzCoCoI?si=VLs5Ol5Gh2StDnzK
4. Complete engagement steps.
5. Submit transaction and proof screenshot for admin approval.', 'Complete and receive approval for Task 4 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_9_6', 'level_9', 6, 'YouTube Subscribe Task #6', 'Complete the Subscribe action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 400 and 4 credit points.', 'Subscribe', 400, 4, false, 0, 'https://youtu.be/fsJ14Bra8Io?si=Q2E7TZ-Gi0s6Eu7A', '1. Open link: https://youtu.be/fsJ14Bra8Io?si=Q2E7TZ-Gi0s6Eu7A
2. Perform Subscribe action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 5 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_9_7', 'level_9', 7, 'YouTube Like and Comment Task #7', 'Complete the Like and Comment action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 400 and 4 credit points.', 'Like and Comment', 400, 4, false, 0, 'https://youtu.be/4tQrUif5pHY?si=qkw8NRq', '1. Open link: https://youtu.be/4tQrUif5pHY?si=qkw8NRq
2. Perform Like and Comment action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 6 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_9_8', 'level_9', 8, 'YouTube Watch Video (30s) Task #8', 'Complete the Watch Video (30s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 400 and 4 credit points.', 'Watch Video (30s)', 400, 4, false, 0, 'https://youtu.be/Nw5rO-fmL0A?si=JzoRZ80tEG6itSRk', '1. Open link: https://youtu.be/Nw5rO-fmL0A?si=JzoRZ80tEG6itSRk
2. Perform Watch Video (30s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 7 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_9_9', 'level_9', 9, 'YouTube Watch Video (45s) Task #9', 'Complete the Watch Video (45s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 400 and 4 credit points.', 'Watch Video (45s)', 400, 4, false, 0, 'https://youtu.be/EtjXNMS3eeU?si=kxWkl392jatI2qT6', '1. Open link: https://youtu.be/EtjXNMS3eeU?si=kxWkl392jatI2qT6
2. Perform Watch Video (45s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 8 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_9_10', 'level_9', 10, 'Prepaid Task #2 (PKR 700,000)', 'Prepaid task requiring deposit unlock fee of PKR 700,000. Yields commission of PKR 800 and 9 credit points upon completion.', 'Prepaid Task #2', 800, 9, true, 700000, 'https://youtu.be/UV63-EXSFI8?si=amwqxlSS2QF08epH', '1. Ensure wallet has sufficient balance or deposit PKR 700,000.
2. Click Unlock Task to pay fee.
3. Open protected link: https://youtu.be/UV63-EXSFI8?si=amwqxlSS2QF08epH
4. Complete engagement steps.
5. Submit transaction and proof screenshot for admin approval.', 'Complete and receive approval for Task 9 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_9_11', 'level_9', 11, 'YouTube Subscribe Task #11', 'Complete the Subscribe action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 400 and 4 credit points.', 'Subscribe', 400, 4, false, 0, 'https://youtu.be/oNGDopPcghA?si=N87jtZd0fqhR6sqM', '1. Open link: https://youtu.be/oNGDopPcghA?si=N87jtZd0fqhR6sqM
2. Perform Subscribe action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 10 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_9_12', 'level_9', 12, 'YouTube Like and Comment Task #12', 'Complete the Like and Comment action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 400 and 4 credit points.', 'Like and Comment', 400, 4, false, 0, 'https://youtu.be/k', '1. Open link: https://youtu.be/k
2. Perform Like and Comment action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 11 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_9_13', 'level_9', 13, 'YouTube Watch Video (30s) Task #13', 'Complete the Watch Video (30s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 400 and 4 credit points.', 'Watch Video (30s)', 400, 4, false, 0, 'https://youtu.be/M2vs', '1. Open link: https://youtu.be/M2vs
2. Perform Watch Video (30s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 12 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_9_14', 'level_9', 14, 'YouTube Watch Video (45s) Task #14', 'Complete the Watch Video (45s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 400 and 4 credit points.', 'Watch Video (45s)', 400, 4, false, 0, 'https://youtu.be/-4E9tAH7cfU?si=2Al-wYIi-diJ-BlS', '1. Open link: https://youtu.be/-4E9tAH7cfU?si=2Al-wYIi-diJ-BlS
2. Perform Watch Video (45s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 13 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_9_15', 'level_9', 15, 'Prepaid Task #3 (PKR 850,000)', 'Prepaid task requiring deposit unlock fee of PKR 850,000. Yields commission of PKR 800 and 9 credit points upon completion.', 'Prepaid Task #3', 800, 9, true, 850000, 'https://youtu.be/tlxJv2cdlAU?si=a1g4vUtwS8Lj', '1. Ensure wallet has sufficient balance or deposit PKR 850,000.
2. Click Unlock Task to pay fee.
3. Open protected link: https://youtu.be/tlxJv2cdlAU?si=a1g4vUtwS8Lj
4. Complete engagement steps.
5. Submit transaction and proof screenshot for admin approval.', 'Complete and receive approval for Task 14 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_9_16', 'level_9', 16, 'YouTube Subscribe Task #16', 'Complete the Subscribe action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 400 and 4 credit points.', 'Subscribe', 400, 4, false, 0, 'https://youtu.be/DLGqHOMIE5c?si=f4XCCwwkd0hwxnOL', '1. Open link: https://youtu.be/DLGqHOMIE5c?si=f4XCCwwkd0hwxnOL
2. Perform Subscribe action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 15 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_9_17', 'level_9', 17, 'YouTube Like and Comment Task #17', 'Complete the Like and Comment action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 400 and 4 credit points.', 'Like and Comment', 400, 4, false, 0, 'https://youtu.be/gjV-K4g3fm4?si=n', '1. Open link: https://youtu.be/gjV-K4g3fm4?si=n
2. Perform Like and Comment action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 16 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_9_18', 'level_9', 18, 'YouTube Watch Video (30s) Task #18', 'Complete the Watch Video (30s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 400 and 4 credit points.', 'Watch Video (30s)', 400, 4, false, 0, 'https://youtu.be/LhUkk8z5V5E?si=yJjzGjtCLVAhvVem', '1. Open link: https://youtu.be/LhUkk8z5V5E?si=yJjzGjtCLVAhvVem
2. Perform Watch Video (30s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 17 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_9_19', 'level_9', 19, 'YouTube Watch Video (45s) Task #19', 'Complete the Watch Video (45s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 400 and 4 credit points.', 'Watch Video (45s)', 400, 4, false, 0, 'https://youtu.be/Idek3A89slQ?si=onRru3zLmNC-Cvt', '1. Open link: https://youtu.be/Idek3A89slQ?si=onRru3zLmNC-Cvt
2. Perform Watch Video (45s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 18 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_9_20', 'level_9', 20, 'Prepaid Task #4 (PKR 1,000,000)', 'Prepaid task requiring deposit unlock fee of PKR 1,000,000. Yields commission of PKR 800 and 9 credit points upon completion.', 'Prepaid Task #4', 800, 9, true, 1000000, 'https://youtu.be/LK11EmCjJzQ?si=Q3s0EJYu4GKC5XWq', '1. Ensure wallet has sufficient balance or deposit PKR 1,000,000.
2. Click Unlock Task to pay fee.
3. Open protected link: https://youtu.be/LK11EmCjJzQ?si=Q3s0EJYu4GKC5XWq
4. Complete engagement steps.
5. Submit transaction and proof screenshot for admin approval.', 'Complete and receive approval for Task 19 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Level" ("id", "levelNumber", "title", "description", "status", "requiredTaskCount", "completionReward", "totalCreditPoints", "displayOrder", "createdAt", "updatedAt") VALUES ('level_10', 10, 'Level 10', 'Complete all 20 tasks in Level 10 (Level 10) to claim the PKR 15,000 milestone reward.', 'ACTIVE', 20, 15000, 100, 10, NOW(), NOW()) ON CONFLICT ("levelNumber") DO UPDATE SET "title" = EXCLUDED."title", "completionReward" = EXCLUDED."completionReward", "requiredTaskCount" = EXCLUDED."requiredTaskCount", "totalCreditPoints" = EXCLUDED."totalCreditPoints";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_10_1', 'level_10', 1, 'YouTube Subscribe Task #1', 'Complete the Subscribe action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 500 and 4 credit points.', 'Subscribe', 500, 4, false, 0, 'https://youtu.be/Z22mFwbCrCA?si=9Yjc9AH0eRZ4FNxb', '1. Open link: https://youtu.be/Z22mFwbCrCA?si=9Yjc9AH0eRZ4FNxb
2. Perform Subscribe action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for all tasks in Level 9 to unlock Level 10.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_10_2', 'level_10', 2, 'YouTube Like and Comment Task #2', 'Complete the Like and Comment action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 500 and 4 credit points.', 'Like and Comment', 500, 4, false, 0, 'https://youtu.be/PGpb6Zc4KkE?si=hd0i40qWqeRPca4L', '1. Open link: https://youtu.be/PGpb6Zc4KkE?si=hd0i40qWqeRPca4L
2. Perform Like and Comment action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 1 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_10_3', 'level_10', 3, 'YouTube Watch Video (30s) Task #3', 'Complete the Watch Video (30s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 500 and 4 credit points.', 'Watch Video (30s)', 500, 4, false, 0, 'https://youtu.be/YHccUdhUE', '1. Open link: https://youtu.be/YHccUdhUE
2. Perform Watch Video (30s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 2 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_10_4', 'level_10', 4, 'YouTube Watch Video (45s) Task #4', 'Complete the Watch Video (45s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 500 and 4 credit points.', 'Watch Video (45s)', 500, 4, false, 0, 'https://youtu.be/RVpKbiTvLWY?si=BpMN-6bpskK0ORfp', '1. Open link: https://youtu.be/RVpKbiTvLWY?si=BpMN-6bpskK0ORfp
2. Perform Watch Video (45s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 3 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_10_5', 'level_10', 5, 'Prepaid Task #1 (PKR 1,200,000)', 'Prepaid task requiring deposit unlock fee of PKR 1,200,000. Yields commission of PKR 1,000 and 9 credit points upon completion.', 'Prepaid Task #1', 1000, 9, true, 1200000, 'https://youtu.be/AJtkuFN1apc?si=ampDjQmn6PkH5PWs', '1. Ensure wallet has sufficient balance or deposit PKR 1,200,000.
2. Click Unlock Task to pay fee.
3. Open protected link: https://youtu.be/AJtkuFN1apc?si=ampDjQmn6PkH5PWs
4. Complete engagement steps.
5. Submit transaction and proof screenshot for admin approval.', 'Complete and receive approval for Task 4 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_10_6', 'level_10', 6, 'YouTube Subscribe Task #6', 'Complete the Subscribe action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 500 and 4 credit points.', 'Subscribe', 500, 4, false, 0, 'https://youtu.be/k8eR5sBUCPw?si=tMuw34hpQu6CC5Fe', '1. Open link: https://youtu.be/k8eR5sBUCPw?si=tMuw34hpQu6CC5Fe
2. Perform Subscribe action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 5 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_10_7', 'level_10', 7, 'YouTube Like and Comment Task #7', 'Complete the Like and Comment action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 500 and 4 credit points.', 'Like and Comment', 500, 4, false, 0, 'https://youtu.be/LSKRceF5ykE?si=EJkkg6RzukZppH0y', '1. Open link: https://youtu.be/LSKRceF5ykE?si=EJkkg6RzukZppH0y
2. Perform Like and Comment action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 6 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_10_8', 'level_10', 8, 'YouTube Watch Video (30s) Task #8', 'Complete the Watch Video (30s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 500 and 4 credit points.', 'Watch Video (30s)', 500, 4, false, 0, 'https://youtu.be/KPIC2P', '1. Open link: https://youtu.be/KPIC2P
2. Perform Watch Video (30s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 7 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_10_9', 'level_10', 9, 'YouTube Watch Video (45s) Task #9', 'Complete the Watch Video (45s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 500 and 4 credit points.', 'Watch Video (45s)', 500, 4, false, 0, 'https://youtu.be/qOWVl6j87nI?si=rMV76Ws1W3PnzqpC', '1. Open link: https://youtu.be/qOWVl6j87nI?si=rMV76Ws1W3PnzqpC
2. Perform Watch Video (45s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 8 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_10_10', 'level_10', 10, 'Prepaid Task #2 (PKR 1,500,000)', 'Prepaid task requiring deposit unlock fee of PKR 1,500,000. Yields commission of PKR 1,000 and 9 credit points upon completion.', 'Prepaid Task #2', 1000, 9, true, 1500000, 'https://youtu.be/UrjimhELcok?si=WRKmKc2Gcyje6pTV', '1. Ensure wallet has sufficient balance or deposit PKR 1,500,000.
2. Click Unlock Task to pay fee.
3. Open protected link: https://youtu.be/UrjimhELcok?si=WRKmKc2Gcyje6pTV
4. Complete engagement steps.
5. Submit transaction and proof screenshot for admin approval.', 'Complete and receive approval for Task 9 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_10_11', 'level_10', 11, 'YouTube Subscribe Task #11', 'Complete the Subscribe action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 500 and 4 credit points.', 'Subscribe', 500, 4, false, 0, 'https://youtu.be/pLF0bhcY5l8?si=4cRiZSz35yJ1f8q6', '1. Open link: https://youtu.be/pLF0bhcY5l8?si=4cRiZSz35yJ1f8q6
2. Perform Subscribe action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 10 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_10_12', 'level_10', 12, 'YouTube Like and Comment Task #12', 'Complete the Like and Comment action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 500 and 4 credit points.', 'Like and Comment', 500, 4, false, 0, 'https://youtu.be/JdPkgySQkyU?si=htapyrUIMYzOr', '1. Open link: https://youtu.be/JdPkgySQkyU?si=htapyrUIMYzOr
2. Perform Like and Comment action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 11 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_10_13', 'level_10', 13, 'YouTube Watch Video (30s) Task #13', 'Complete the Watch Video (30s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 500 and 4 credit points.', 'Watch Video (30s)', 500, 4, false, 0, 'https://youtu.be/OUdF9tyMlgM?si=rCXLot9IZombP88f', '1. Open link: https://youtu.be/OUdF9tyMlgM?si=rCXLot9IZombP88f
2. Perform Watch Video (30s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 12 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_10_14', 'level_10', 14, 'YouTube Watch Video (45s) Task #14', 'Complete the Watch Video (45s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 500 and 4 credit points.', 'Watch Video (45s)', 500, 4, false, 0, 'https://youtu.be/OQLWQEb-FgY?si=OOmTvdyEJb2U7VJV', '1. Open link: https://youtu.be/OQLWQEb-FgY?si=OOmTvdyEJb2U7VJV
2. Perform Watch Video (45s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 13 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_10_15', 'level_10', 15, 'Prepaid Task #3 (PKR 1,900,000)', 'Prepaid task requiring deposit unlock fee of PKR 1,900,000. Yields commission of PKR 1,000 and 9 credit points upon completion.', 'Prepaid Task #3', 1000, 9, true, 1900000, 'https://youtu.be/p8ZHLMusfEk?si=G1GFQzDwT77oIEfc', '1. Ensure wallet has sufficient balance or deposit PKR 1,900,000.
2. Click Unlock Task to pay fee.
3. Open protected link: https://youtu.be/p8ZHLMusfEk?si=G1GFQzDwT77oIEfc
4. Complete engagement steps.
5. Submit transaction and proof screenshot for admin approval.', 'Complete and receive approval for Task 14 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_10_16', 'level_10', 16, 'YouTube Subscribe Task #16', 'Complete the Subscribe action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 500 and 4 credit points.', 'Subscribe', 500, 4, false, 0, 'https://youtu.be/mYDrGq0OHhQ?si=thc2AaWGV4GbAHAW', '1. Open link: https://youtu.be/mYDrGq0OHhQ?si=thc2AaWGV4GbAHAW
2. Perform Subscribe action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 15 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_10_17', 'level_10', 17, 'YouTube Like and Comment Task #17', 'Complete the Like and Comment action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 500 and 4 credit points.', 'Like and Comment', 500, 4, false, 0, 'https://youtu.be/-wrAWg', '1. Open link: https://youtu.be/-wrAWg
2. Perform Like and Comment action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 16 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_10_18', 'level_10', 18, 'YouTube Watch Video (30s) Task #18', 'Complete the Watch Video (30s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 500 and 4 credit points.', 'Watch Video (30s)', 500, 4, false, 0, 'https://youtu.be/y8bFjc1gucQ?si=rwg40AmHWnb0iwIj', '1. Open link: https://youtu.be/y8bFjc1gucQ?si=rwg40AmHWnb0iwIj
2. Perform Watch Video (30s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 17 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_10_19', 'level_10', 19, 'YouTube Watch Video (45s) Task #19', 'Complete the Watch Video (45s) action on YouTube. Watch, engage, and submit confirmation proof for admin verification to earn PKR 500 and 4 credit points.', 'Watch Video (45s)', 500, 4, false, 0, 'https://youtu.be/7lEqFKmCoaE?si=8HHU7uOV568gxPmn', '1. Open link: https://youtu.be/7lEqFKmCoaE?si=8HHU7uOV568gxPmn
2. Perform Watch Video (45s) action.
3. Take a screenshot showing proof of action.
4. Submit reference and proof for instant admin verification.', 'Complete and receive approval for Task 18 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('task_10_20', 'level_10', 20, 'Prepaid Task #4 (PKR 2,500,000)', 'Prepaid task requiring deposit unlock fee of PKR 2,500,000. Yields commission of PKR 1,000 and 9 credit points upon completion.', 'Prepaid Task #4', 1000, 9, true, 2500000, 'https://youtu.be/2toTTlle6Vs?si=lykA3vdnPTgRclZi', '1. Ensure wallet has sufficient balance or deposit PKR 2,500,000.
2. Click Unlock Task to pay fee.
3. Open protected link: https://youtu.be/2toTTlle6Vs?si=lykA3vdnPTgRclZi
4. Complete engagement steps.
5. Submit transaction and proof screenshot for admin approval.', 'Complete and receive approval for Task 19 to unlock this task.', 'Submit proof reference or transaction details for verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "creditPoints" = EXCLUDED."creditPoints", "isPaid" = EXCLUDED."isPaid", "unlockFee" = EXCLUDED."unlockFee", "protectedUrl" = EXCLUDED."protectedUrl", "taskType" = EXCLUDED."taskType";
