-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

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



-- SEED DATA
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_site_name', 'site_name', 'Earn Sheet', 'Public platform brand name', 'GENERAL', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_support_email', 'support_email', 'support@earnsheet.com', 'Official support email', 'GENERAL', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_support_whatsapp', 'support_whatsapp', '+92 300 1234567', 'Official verification and support line', 'GENERAL', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_welcome_message', 'welcome_message', 'Welcome to Earn Sheet! Complete tasks, earn verified rewards, and spin the royal wheel!', 'User dashboard greeting banner', 'BRANDING', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_default_submission_instructions', 'default_submission_instructions', 'Complete the required task steps. Send proof or screenshot to the official verification channel and submit your confirmation reference below.', 'Default submission guidance', 'TASKS', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_currency', 'currency', 'PKR', 'Platform base currency', 'FINANCE', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_min_deposit', 'min_deposit', '500', 'Minimum allowed deposit in PKR', 'FINANCE', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_min_withdrawal', 'min_withdrawal', '1000', 'Minimum allowed withdrawal in PKR', 'FINANCE', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_easypaisa_title', 'easypaisa_title', 'Earn Sheet Official', 'Receiving Easypaisa title', 'FINANCE', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_easypaisa_number', 'easypaisa_number', '0312-3456789', 'Receiving Easypaisa account number', 'FINANCE', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_jazzcash_title', 'jazzcash_title', 'Earn Sheet Official', 'Receiving JazzCash title', 'FINANCE', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_jazzcash_number', 'jazzcash_number', '0301-9876543', 'Receiving JazzCash account number', 'FINANCE', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_bank_name', 'bank_name', 'Meezan Bank Limited', 'Receiving Bank name', 'FINANCE', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_bank_title', 'bank_title', 'Earn Sheet Enterprise PVT', 'Receiving Bank account title', 'FINANCE', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_bank_account', 'bank_account', '01020304050607', 'Receiving Bank account number', 'FINANCE', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_bank_iban', 'bank_iban', 'PK12MEZN0001020304050607', 'Receiving Bank IBAN', 'FINANCE', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_referral_reward', 'referral_reward', '250', 'Reward per qualifying referral in PKR', 'REFERRAL', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_referral_level1_required', 'referral_level1_required', 'true', 'Whether referee must complete Level 1 to qualify', 'REFERRAL', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_spin_enabled', 'spin_enabled', 'true', 'Global spin wheel feature toggle', 'SPIN', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_spin_cooldown_hours', 'spin_cooldown_hours', '24', 'Cooldown between spins in hours', 'SPIN', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";
INSERT INTO "AdminUser" ("id", "username", "email", "passwordHash", "fullName", "role", "status", "updatedAt") VALUES ('admin_root_1', 'admin', 'admin@earnsheet.com', '$2b$10$uuPAa0UhNNfkIHHhjCyt7OtEyRoYItmJ32ZQP8kdqkUXN8sUPwPw2', 'Super Administrator', 'SUPER_ADMIN', 'ACTIVE', NOW()) ON CONFLICT ("username") DO NOTHING;
INSERT INTO "SpinConfiguration" ("id", "isEnabled", "cooldownHours", "costPerSpin", "allowPaidSpins", "updatedAt") VALUES ('spin_config_default', true, 24, 0, false, NOW()) ON CONFLICT ("id") DO NOTHING;
INSERT INTO "SpinPrize" ("id", "label", "prizeType", "value", "probabilityWeight", "displayColor", "slotIndex", "isActive", "createdAt", "updatedAt") VALUES ('prize_1', 'PKR 100 Cash', 'CASH', 100, 0.35, '#3B82F6', 1, true, NOW(), NOW()) ON CONFLICT ("id") DO NOTHING;
INSERT INTO "SpinPrize" ("id", "label", "prizeType", "value", "probabilityWeight", "displayColor", "slotIndex", "isActive", "createdAt", "updatedAt") VALUES ('prize_2', 'PKR 250 Cash', 'CASH', 250, 0.25, '#10B981', 2, true, NOW(), NOW()) ON CONFLICT ("id") DO NOTHING;
INSERT INTO "SpinPrize" ("id", "label", "prizeType", "value", "probabilityWeight", "displayColor", "slotIndex", "isActive", "createdAt", "updatedAt") VALUES ('prize_3', 'PKR 500 Bonus', 'CASH', 500, 0.18, '#8B5CF6', 3, true, NOW(), NOW()) ON CONFLICT ("id") DO NOTHING;
INSERT INTO "SpinPrize" ("id", "label", "prizeType", "value", "probabilityWeight", "displayColor", "slotIndex", "isActive", "createdAt", "updatedAt") VALUES ('prize_4', 'PKR 1,000 Major', 'CASH', 1000, 0.12, '#EC4899', 4, true, NOW(), NOW()) ON CONFLICT ("id") DO NOTHING;
INSERT INTO "SpinPrize" ("id", "label", "prizeType", "value", "probabilityWeight", "displayColor", "slotIndex", "isActive", "createdAt", "updatedAt") VALUES ('prize_5', 'PKR 2,500 VIP', 'CASH', 2500, 0.07, '#F59E0B', 5, true, NOW(), NOW()) ON CONFLICT ("id") DO NOTHING;
INSERT INTO "SpinPrize" ("id", "label", "prizeType", "value", "probabilityWeight", "displayColor", "slotIndex", "isActive", "createdAt", "updatedAt") VALUES ('prize_6', 'PKR 5,000 Jackpot', 'CASH', 5000, 0.03, '#EF4444', 6, true, NOW(), NOW()) ON CONFLICT ("id") DO NOTHING;
INSERT INTO "Level" ("id", "levelNumber", "title", "description", "completionReward", "requiredTaskCount", "displayOrder", "status", "createdAt", "updatedAt") VALUES ('level_1', 1, 'Bronze Starter', 'Begin your journey with essential community tasks', 1000, 10, 1, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelNumber") DO UPDATE SET "title" = EXCLUDED."title", "completionReward" = EXCLUDED."completionReward";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_1_1', 'level_1', 1, 'Official Telegram Channel Join', 'Join Group', 'https://t.me/earnsheet', 'Complete the required task steps carefully.', 50, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_1_2', 'level_1', 2, 'Subscribe to YouTube Channel', 'YouTube Promotion', 'https://youtube.com/@earnsheet', 'Complete the required task steps carefully.', 60, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_1_3', 'level_1', 3, 'Follow Official Facebook Page', 'Follow Page', 'https://facebook.com/earnsheet', 'Complete the required task steps carefully.', 50, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_1_4', 'level_1', 4, 'Engage with Instagram Post', 'Social Media', 'https://instagram.com/p/earnsheet', 'Complete the required task steps carefully.', 75, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_1_5', 'level_1', 5, 'Watch Sponsored Explainer Video', 'Watch Video', 'https://youtube.com/watch?v=earnsheet', 'Complete the required task steps carefully.', 100, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_1_6', 'level_1', 6, 'Complete Quick Consumer Survey', 'Survey', 'https://survey.earnsheet.com/q1', 'Complete the required task steps carefully.', 120, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_1_7', 'level_1', 7, 'Download Partner Rewards App', 'App Installation', 'https://play.google.com/store/apps/details?id=earnsheet', 'Complete the required task steps carefully.', 150, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_1_8', 'level_1', 8, 'Share Referral Banner to WhatsApp', 'Referral', 'https://earnsheet.com/share', 'Complete the required task steps carefully.', 180, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_1_9', 'level_1', 9, 'VIP High-Engagement Campaign', 'YouTube Promotion', 'https://vip.earnsheet.com/campaign-9', 'Complete the required task steps carefully.', 7500, true, true, 5000, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_1_10', 'level_1', 10, 'Royal Imperial Sponsor Mission', 'Custom Task', 'https://vip.earnsheet.com/mission-10', 'Complete the required task steps carefully.', 15000, true, true, 10000, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Level" ("id", "levelNumber", "title", "description", "completionReward", "requiredTaskCount", "displayOrder", "status", "createdAt", "updatedAt") VALUES ('level_2', 2, 'Silver Monarch', 'Step into elite engagement and verified promotions', 1500, 10, 2, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelNumber") DO UPDATE SET "title" = EXCLUDED."title", "completionReward" = EXCLUDED."completionReward";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_2_1', 'level_2', 1, 'Official Telegram Channel Join', 'Join Group', 'https://t.me/earnsheet', 'Complete the required task steps carefully.', 50, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_2_2', 'level_2', 2, 'Subscribe to YouTube Channel', 'YouTube Promotion', 'https://youtube.com/@earnsheet', 'Complete the required task steps carefully.', 60, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_2_3', 'level_2', 3, 'Follow Official Facebook Page', 'Follow Page', 'https://facebook.com/earnsheet', 'Complete the required task steps carefully.', 50, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_2_4', 'level_2', 4, 'Engage with Instagram Post', 'Social Media', 'https://instagram.com/p/earnsheet', 'Complete the required task steps carefully.', 75, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_2_5', 'level_2', 5, 'Watch Sponsored Explainer Video', 'Watch Video', 'https://youtube.com/watch?v=earnsheet', 'Complete the required task steps carefully.', 100, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_2_6', 'level_2', 6, 'Complete Quick Consumer Survey', 'Survey', 'https://survey.earnsheet.com/q1', 'Complete the required task steps carefully.', 120, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_2_7', 'level_2', 7, 'Download Partner Rewards App', 'App Installation', 'https://play.google.com/store/apps/details?id=earnsheet', 'Complete the required task steps carefully.', 150, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_2_8', 'level_2', 8, 'Share Referral Banner to WhatsApp', 'Referral', 'https://earnsheet.com/share', 'Complete the required task steps carefully.', 180, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_2_9', 'level_2', 9, 'VIP High-Engagement Campaign', 'YouTube Promotion', 'https://vip.earnsheet.com/campaign-9', 'Complete the required task steps carefully.', 7500, true, true, 5000, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_2_10', 'level_2', 10, 'Royal Imperial Sponsor Mission', 'Custom Task', 'https://vip.earnsheet.com/mission-10', 'Complete the required task steps carefully.', 15000, true, true, 10000, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Level" ("id", "levelNumber", "title", "description", "completionReward", "requiredTaskCount", "displayOrder", "status", "createdAt", "updatedAt") VALUES ('level_3', 3, 'Gold Viceroy', 'Command greater yields with high-priority assignments', 2500, 10, 3, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelNumber") DO UPDATE SET "title" = EXCLUDED."title", "completionReward" = EXCLUDED."completionReward";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_3_1', 'level_3', 1, 'Official Telegram Channel Join', 'Join Group', 'https://t.me/earnsheet', 'Complete the required task steps carefully.', 50, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_3_2', 'level_3', 2, 'Subscribe to YouTube Channel', 'YouTube Promotion', 'https://youtube.com/@earnsheet', 'Complete the required task steps carefully.', 60, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_3_3', 'level_3', 3, 'Follow Official Facebook Page', 'Follow Page', 'https://facebook.com/earnsheet', 'Complete the required task steps carefully.', 50, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_3_4', 'level_3', 4, 'Engage with Instagram Post', 'Social Media', 'https://instagram.com/p/earnsheet', 'Complete the required task steps carefully.', 75, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_3_5', 'level_3', 5, 'Watch Sponsored Explainer Video', 'Watch Video', 'https://youtube.com/watch?v=earnsheet', 'Complete the required task steps carefully.', 100, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_3_6', 'level_3', 6, 'Complete Quick Consumer Survey', 'Survey', 'https://survey.earnsheet.com/q1', 'Complete the required task steps carefully.', 120, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_3_7', 'level_3', 7, 'Download Partner Rewards App', 'App Installation', 'https://play.google.com/store/apps/details?id=earnsheet', 'Complete the required task steps carefully.', 150, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_3_8', 'level_3', 8, 'Share Referral Banner to WhatsApp', 'Referral', 'https://earnsheet.com/share', 'Complete the required task steps carefully.', 180, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_3_9', 'level_3', 9, 'VIP High-Engagement Campaign', 'YouTube Promotion', 'https://vip.earnsheet.com/campaign-9', 'Complete the required task steps carefully.', 7500, true, true, 5000, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_3_10', 'level_3', 10, 'Royal Imperial Sponsor Mission', 'Custom Task', 'https://vip.earnsheet.com/mission-10', 'Complete the required task steps carefully.', 15000, true, true, 10000, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Level" ("id", "levelNumber", "title", "description", "completionReward", "requiredTaskCount", "displayOrder", "status", "createdAt", "updatedAt") VALUES ('level_4', 4, 'Emerald Regent', 'Exclusive partner activations and elevated multipliers', 4000, 10, 4, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelNumber") DO UPDATE SET "title" = EXCLUDED."title", "completionReward" = EXCLUDED."completionReward";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_4_1', 'level_4', 1, 'Official Telegram Channel Join', 'Join Group', 'https://t.me/earnsheet', 'Complete the required task steps carefully.', 50, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_4_2', 'level_4', 2, 'Subscribe to YouTube Channel', 'YouTube Promotion', 'https://youtube.com/@earnsheet', 'Complete the required task steps carefully.', 60, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_4_3', 'level_4', 3, 'Follow Official Facebook Page', 'Follow Page', 'https://facebook.com/earnsheet', 'Complete the required task steps carefully.', 50, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_4_4', 'level_4', 4, 'Engage with Instagram Post', 'Social Media', 'https://instagram.com/p/earnsheet', 'Complete the required task steps carefully.', 75, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_4_5', 'level_4', 5, 'Watch Sponsored Explainer Video', 'Watch Video', 'https://youtube.com/watch?v=earnsheet', 'Complete the required task steps carefully.', 100, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_4_6', 'level_4', 6, 'Complete Quick Consumer Survey', 'Survey', 'https://survey.earnsheet.com/q1', 'Complete the required task steps carefully.', 120, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_4_7', 'level_4', 7, 'Download Partner Rewards App', 'App Installation', 'https://play.google.com/store/apps/details?id=earnsheet', 'Complete the required task steps carefully.', 150, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_4_8', 'level_4', 8, 'Share Referral Banner to WhatsApp', 'Referral', 'https://earnsheet.com/share', 'Complete the required task steps carefully.', 180, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_4_9', 'level_4', 9, 'VIP High-Engagement Campaign', 'YouTube Promotion', 'https://vip.earnsheet.com/campaign-9', 'Complete the required task steps carefully.', 7500, true, true, 5000, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_4_10', 'level_4', 10, 'Royal Imperial Sponsor Mission', 'Custom Task', 'https://vip.earnsheet.com/mission-10', 'Complete the required task steps carefully.', 15000, true, true, 10000, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Level" ("id", "levelNumber", "title", "description", "completionReward", "requiredTaskCount", "displayOrder", "status", "createdAt", "updatedAt") VALUES ('level_5', 5, 'Ruby Commander', 'Executive campaigns reserved for proven earners', 6000, 10, 5, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelNumber") DO UPDATE SET "title" = EXCLUDED."title", "completionReward" = EXCLUDED."completionReward";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_5_1', 'level_5', 1, 'Official Telegram Channel Join', 'Join Group', 'https://t.me/earnsheet', 'Complete the required task steps carefully.', 50, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_5_2', 'level_5', 2, 'Subscribe to YouTube Channel', 'YouTube Promotion', 'https://youtube.com/@earnsheet', 'Complete the required task steps carefully.', 60, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_5_3', 'level_5', 3, 'Follow Official Facebook Page', 'Follow Page', 'https://facebook.com/earnsheet', 'Complete the required task steps carefully.', 50, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_5_4', 'level_5', 4, 'Engage with Instagram Post', 'Social Media', 'https://instagram.com/p/earnsheet', 'Complete the required task steps carefully.', 75, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_5_5', 'level_5', 5, 'Watch Sponsored Explainer Video', 'Watch Video', 'https://youtube.com/watch?v=earnsheet', 'Complete the required task steps carefully.', 100, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_5_6', 'level_5', 6, 'Complete Quick Consumer Survey', 'Survey', 'https://survey.earnsheet.com/q1', 'Complete the required task steps carefully.', 120, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_5_7', 'level_5', 7, 'Download Partner Rewards App', 'App Installation', 'https://play.google.com/store/apps/details?id=earnsheet', 'Complete the required task steps carefully.', 150, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_5_8', 'level_5', 8, 'Share Referral Banner to WhatsApp', 'Referral', 'https://earnsheet.com/share', 'Complete the required task steps carefully.', 180, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_5_9', 'level_5', 9, 'VIP High-Engagement Campaign', 'YouTube Promotion', 'https://vip.earnsheet.com/campaign-9', 'Complete the required task steps carefully.', 7500, true, true, 5000, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_5_10', 'level_5', 10, 'Royal Imperial Sponsor Mission', 'Custom Task', 'https://vip.earnsheet.com/mission-10', 'Complete the required task steps carefully.', 15000, true, true, 10000, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Level" ("id", "levelNumber", "title", "description", "completionReward", "requiredTaskCount", "displayOrder", "status", "createdAt", "updatedAt") VALUES ('level_6', 6, 'Sapphire Prince', 'High-value network assignments and community growth', 9000, 10, 6, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelNumber") DO UPDATE SET "title" = EXCLUDED."title", "completionReward" = EXCLUDED."completionReward";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_6_1', 'level_6', 1, 'Official Telegram Channel Join', 'Join Group', 'https://t.me/earnsheet', 'Complete the required task steps carefully.', 50, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_6_2', 'level_6', 2, 'Subscribe to YouTube Channel', 'YouTube Promotion', 'https://youtube.com/@earnsheet', 'Complete the required task steps carefully.', 60, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_6_3', 'level_6', 3, 'Follow Official Facebook Page', 'Follow Page', 'https://facebook.com/earnsheet', 'Complete the required task steps carefully.', 50, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_6_4', 'level_6', 4, 'Engage with Instagram Post', 'Social Media', 'https://instagram.com/p/earnsheet', 'Complete the required task steps carefully.', 75, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_6_5', 'level_6', 5, 'Watch Sponsored Explainer Video', 'Watch Video', 'https://youtube.com/watch?v=earnsheet', 'Complete the required task steps carefully.', 100, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_6_6', 'level_6', 6, 'Complete Quick Consumer Survey', 'Survey', 'https://survey.earnsheet.com/q1', 'Complete the required task steps carefully.', 120, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_6_7', 'level_6', 7, 'Download Partner Rewards App', 'App Installation', 'https://play.google.com/store/apps/details?id=earnsheet', 'Complete the required task steps carefully.', 150, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_6_8', 'level_6', 8, 'Share Referral Banner to WhatsApp', 'Referral', 'https://earnsheet.com/share', 'Complete the required task steps carefully.', 180, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_6_9', 'level_6', 9, 'VIP High-Engagement Campaign', 'YouTube Promotion', 'https://vip.earnsheet.com/campaign-9', 'Complete the required task steps carefully.', 7500, true, true, 5000, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_6_10', 'level_6', 10, 'Royal Imperial Sponsor Mission', 'Custom Task', 'https://vip.earnsheet.com/mission-10', 'Complete the required task steps carefully.', 15000, true, true, 10000, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Level" ("id", "levelNumber", "title", "description", "completionReward", "requiredTaskCount", "displayOrder", "status", "createdAt", "updatedAt") VALUES ('level_7', 7, 'Diamond Duke', 'Mastery tier featuring premium sponsored missions', 13000, 10, 7, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelNumber") DO UPDATE SET "title" = EXCLUDED."title", "completionReward" = EXCLUDED."completionReward";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_7_1', 'level_7', 1, 'Official Telegram Channel Join', 'Join Group', 'https://t.me/earnsheet', 'Complete the required task steps carefully.', 50, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_7_2', 'level_7', 2, 'Subscribe to YouTube Channel', 'YouTube Promotion', 'https://youtube.com/@earnsheet', 'Complete the required task steps carefully.', 60, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_7_3', 'level_7', 3, 'Follow Official Facebook Page', 'Follow Page', 'https://facebook.com/earnsheet', 'Complete the required task steps carefully.', 50, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_7_4', 'level_7', 4, 'Engage with Instagram Post', 'Social Media', 'https://instagram.com/p/earnsheet', 'Complete the required task steps carefully.', 75, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_7_5', 'level_7', 5, 'Watch Sponsored Explainer Video', 'Watch Video', 'https://youtube.com/watch?v=earnsheet', 'Complete the required task steps carefully.', 100, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_7_6', 'level_7', 6, 'Complete Quick Consumer Survey', 'Survey', 'https://survey.earnsheet.com/q1', 'Complete the required task steps carefully.', 120, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_7_7', 'level_7', 7, 'Download Partner Rewards App', 'App Installation', 'https://play.google.com/store/apps/details?id=earnsheet', 'Complete the required task steps carefully.', 150, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_7_8', 'level_7', 8, 'Share Referral Banner to WhatsApp', 'Referral', 'https://earnsheet.com/share', 'Complete the required task steps carefully.', 180, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_7_9', 'level_7', 9, 'VIP High-Engagement Campaign', 'YouTube Promotion', 'https://vip.earnsheet.com/campaign-9', 'Complete the required task steps carefully.', 7500, true, true, 5000, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_7_10', 'level_7', 10, 'Royal Imperial Sponsor Mission', 'Custom Task', 'https://vip.earnsheet.com/mission-10', 'Complete the required task steps carefully.', 15000, true, true, 10000, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Level" ("id", "levelNumber", "title", "description", "completionReward", "requiredTaskCount", "displayOrder", "status", "createdAt", "updatedAt") VALUES ('level_8', 8, 'Imperial Archon', 'Apex tier preparing you for royal ascension', 20000, 10, 8, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelNumber") DO UPDATE SET "title" = EXCLUDED."title", "completionReward" = EXCLUDED."completionReward";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_8_1', 'level_8', 1, 'Official Telegram Channel Join', 'Join Group', 'https://t.me/earnsheet', 'Complete the required task steps carefully.', 50, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_8_2', 'level_8', 2, 'Subscribe to YouTube Channel', 'YouTube Promotion', 'https://youtube.com/@earnsheet', 'Complete the required task steps carefully.', 60, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_8_3', 'level_8', 3, 'Follow Official Facebook Page', 'Follow Page', 'https://facebook.com/earnsheet', 'Complete the required task steps carefully.', 50, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_8_4', 'level_8', 4, 'Engage with Instagram Post', 'Social Media', 'https://instagram.com/p/earnsheet', 'Complete the required task steps carefully.', 75, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_8_5', 'level_8', 5, 'Watch Sponsored Explainer Video', 'Watch Video', 'https://youtube.com/watch?v=earnsheet', 'Complete the required task steps carefully.', 100, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_8_6', 'level_8', 6, 'Complete Quick Consumer Survey', 'Survey', 'https://survey.earnsheet.com/q1', 'Complete the required task steps carefully.', 120, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_8_7', 'level_8', 7, 'Download Partner Rewards App', 'App Installation', 'https://play.google.com/store/apps/details?id=earnsheet', 'Complete the required task steps carefully.', 150, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_8_8', 'level_8', 8, 'Share Referral Banner to WhatsApp', 'Referral', 'https://earnsheet.com/share', 'Complete the required task steps carefully.', 180, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_8_9', 'level_8', 9, 'VIP High-Engagement Campaign', 'YouTube Promotion', 'https://vip.earnsheet.com/campaign-9', 'Complete the required task steps carefully.', 7500, true, true, 5000, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_8_10', 'level_8', 10, 'Royal Imperial Sponsor Mission', 'Custom Task', 'https://vip.earnsheet.com/mission-10', 'Complete the required task steps carefully.', 15000, true, true, 10000, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Level" ("id", "levelNumber", "title", "description", "completionReward", "requiredTaskCount", "displayOrder", "status", "createdAt", "updatedAt") VALUES ('level_9', 9, 'Crown Sovereign', 'Pre-final tier with elite multipliers', 30000, 10, 9, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelNumber") DO UPDATE SET "title" = EXCLUDED."title", "completionReward" = EXCLUDED."completionReward";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_9_1', 'level_9', 1, 'Official Telegram Channel Join', 'Join Group', 'https://t.me/earnsheet', 'Complete the required task steps carefully.', 50, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_9_2', 'level_9', 2, 'Subscribe to YouTube Channel', 'YouTube Promotion', 'https://youtube.com/@earnsheet', 'Complete the required task steps carefully.', 60, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_9_3', 'level_9', 3, 'Follow Official Facebook Page', 'Follow Page', 'https://facebook.com/earnsheet', 'Complete the required task steps carefully.', 50, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_9_4', 'level_9', 4, 'Engage with Instagram Post', 'Social Media', 'https://instagram.com/p/earnsheet', 'Complete the required task steps carefully.', 75, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_9_5', 'level_9', 5, 'Watch Sponsored Explainer Video', 'Watch Video', 'https://youtube.com/watch?v=earnsheet', 'Complete the required task steps carefully.', 100, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_9_6', 'level_9', 6, 'Complete Quick Consumer Survey', 'Survey', 'https://survey.earnsheet.com/q1', 'Complete the required task steps carefully.', 120, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_9_7', 'level_9', 7, 'Download Partner Rewards App', 'App Installation', 'https://play.google.com/store/apps/details?id=earnsheet', 'Complete the required task steps carefully.', 150, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_9_8', 'level_9', 8, 'Share Referral Banner to WhatsApp', 'Referral', 'https://earnsheet.com/share', 'Complete the required task steps carefully.', 180, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_9_9', 'level_9', 9, 'VIP High-Engagement Campaign', 'YouTube Promotion', 'https://vip.earnsheet.com/campaign-9', 'Complete the required task steps carefully.', 7500, true, true, 5000, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_9_10', 'level_9', 10, 'Royal Imperial Sponsor Mission', 'Custom Task', 'https://vip.earnsheet.com/mission-10', 'Complete the required task steps carefully.', 15000, true, true, 10000, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Level" ("id", "levelNumber", "title", "description", "completionReward", "requiredTaskCount", "displayOrder", "status", "createdAt", "updatedAt") VALUES ('level_10', 10, 'Royal Emperor', 'The crowning achievement of Earn Sheet (Final Level)', 50000, 10, 10, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelNumber") DO UPDATE SET "title" = EXCLUDED."title", "completionReward" = EXCLUDED."completionReward";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_10_1', 'level_10', 1, 'Official Telegram Channel Join', 'Join Group', 'https://t.me/earnsheet', 'Complete the required task steps carefully.', 50, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_10_2', 'level_10', 2, 'Subscribe to YouTube Channel', 'YouTube Promotion', 'https://youtube.com/@earnsheet', 'Complete the required task steps carefully.', 60, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_10_3', 'level_10', 3, 'Follow Official Facebook Page', 'Follow Page', 'https://facebook.com/earnsheet', 'Complete the required task steps carefully.', 50, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_10_4', 'level_10', 4, 'Engage with Instagram Post', 'Social Media', 'https://instagram.com/p/earnsheet', 'Complete the required task steps carefully.', 75, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_10_5', 'level_10', 5, 'Watch Sponsored Explainer Video', 'Watch Video', 'https://youtube.com/watch?v=earnsheet', 'Complete the required task steps carefully.', 100, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_10_6', 'level_10', 6, 'Complete Quick Consumer Survey', 'Survey', 'https://survey.earnsheet.com/q1', 'Complete the required task steps carefully.', 120, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_10_7', 'level_10', 7, 'Download Partner Rewards App', 'App Installation', 'https://play.google.com/store/apps/details?id=earnsheet', 'Complete the required task steps carefully.', 150, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_10_8', 'level_10', 8, 'Share Referral Banner to WhatsApp', 'Referral', 'https://earnsheet.com/share', 'Complete the required task steps carefully.', 180, true, false, 0, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_10_9', 'level_10', 9, 'VIP High-Engagement Campaign', 'YouTube Promotion', 'https://vip.earnsheet.com/campaign-9', 'Complete the required task steps carefully.', 7500, true, true, 5000, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "taskType", "actionUrl", "instructions", "rewardAmount", "requiresProof", "isPaidUnlock", "unlockFee", "status", "createdAt", "updatedAt") VALUES ('task_10_10', 'level_10', 10, 'Royal Imperial Sponsor Mission', 'Custom Task', 'https://vip.earnsheet.com/mission-10', 'Complete the required task steps carefully.', 15000, true, true, 10000, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount";
