import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting Royal Rewards database seed...');

  // 1. Site Settings
  const settings = [
    { key: 'site_name', value: 'Earn Sheet', category: 'GENERAL', description: 'Public platform brand name' },
    { key: 'support_email', value: 'support@earnsheet.com', category: 'GENERAL', description: 'Official support email' },
    { key: 'support_whatsapp', value: '+92 300 1234567', category: 'GENERAL', description: 'Official verification and support line' },
    { key: 'welcome_message', value: 'Welcome to Earn Sheet! Complete tasks, earn verified rewards, and spin the royal wheel!', category: 'BRANDING', description: 'User dashboard greeting banner' },
    { key: 'default_submission_instructions', value: 'Complete the required task steps. Send proof or screenshot to the official verification channel and submit your confirmation reference below.', category: 'TASKS', description: 'Default submission guidance' },
    { key: 'currency', value: 'PKR', category: 'FINANCE', description: 'Platform base currency' },
    { key: 'min_deposit', value: '500', category: 'FINANCE', description: 'Minimum allowed deposit in PKR' },
    { key: 'min_withdrawal', value: '1000', category: 'FINANCE', description: 'Minimum allowed withdrawal in PKR' },
    { key: 'easypaisa_title', value: 'Earn Sheet Official', category: 'FINANCE', description: 'Receiving Easypaisa title' },
    { key: 'easypaisa_number', value: '0312-3456789', category: 'FINANCE', description: 'Receiving Easypaisa account number' },
    { key: 'jazzcash_title', value: 'Earn Sheet Official', category: 'FINANCE', description: 'Receiving JazzCash title' },
    { key: 'jazzcash_number', value: '0301-9876543', category: 'FINANCE', description: 'Receiving JazzCash account number' },
    { key: 'bank_name', value: 'Meezan Bank Limited', category: 'FINANCE', description: 'Receiving Bank name' },
    { key: 'bank_title', value: 'Earn Sheet Enterprise PVT', category: 'FINANCE', description: 'Receiving Bank account title' },
    { key: 'bank_account', value: '01020304050607', category: 'FINANCE', description: 'Receiving Bank account number' },
    { key: 'bank_iban', value: 'PK12MEZN0001020304050607', category: 'FINANCE', description: 'Receiving Bank IBAN' },
    { key: 'referral_reward', value: '250', category: 'REFERRAL', description: 'Reward per qualifying referral in PKR' },
    { key: 'referral_level1_required', value: 'true', category: 'REFERRAL', description: 'Whether referee must complete Level 1 to qualify' },
    { key: 'spin_enabled', value: 'true', category: 'SPIN', description: 'Global spin wheel feature toggle' },
    { key: 'spin_cooldown_hours', value: '24', category: 'SPIN', description: 'Cooldown between spins in hours' },
  ];

  for (const s of settings) {
    await prisma.siteSetting.upsert({
      where: { key: s.key },
      update: { value: s.value, category: s.category, description: s.description },
      create: s,
    });
  }
  console.log(`✅ Seeded ${settings.length} site settings`);

  // 2. Admin User
  const adminPasswordHash = await bcrypt.hash('Admin@Royal2026!', 10);
  const admin = await prisma.adminUser.upsert({
    where: { username: 'admin' },
    update: { passwordHash: adminPasswordHash, role: 'SUPER_ADMIN', status: 'ACTIVE' },
    create: {
      username: 'admin',
      passwordHash: adminPasswordHash,
      role: 'SUPER_ADMIN',
      status: 'ACTIVE',
    },
  });
  console.log(`✅ Seeded Admin User: ${admin.username} (Password: Admin@Royal2026!)`);

  // 3. Spin Prizes
  const spinPrizesData = [
    { name: 'PKR 50', prizeType: 'CASH', monetaryValue: 50, displayLabel: 'PKR 50', color: '#1459E8', icon: 'Coins' },
    { name: 'PKR 100', prizeType: 'CASH', monetaryValue: 100, displayLabel: 'PKR 100', color: '#792BFF', icon: 'Gift' },
    { name: 'PKR 250', prizeType: 'CASH', monetaryValue: 250, displayLabel: 'PKR 250', color: '#22D3EE', icon: 'Zap' },
    { name: 'PKR 500', prizeType: 'CASH', monetaryValue: 500, displayLabel: 'PKR 500', color: '#FFD45A', icon: 'Crown' },
    { name: 'PKR 1,000', prizeType: 'CASH', monetaryValue: 1000, displayLabel: 'PKR 1,000', color: '#22C55E', icon: 'Sparkles' },
    { name: 'PKR 5,000', prizeType: 'CASH', monetaryValue: 5000, displayLabel: 'PKR 5,000 Mega', color: '#EF4444', icon: 'Trophy' },
    { name: 'Royal Gold Watch', prizeType: 'PHYSICAL', monetaryValue: 15000, displayLabel: 'Gold Watch', color: '#F59E0B', icon: 'Watch' },
    { name: 'Smartphone Pro', prizeType: 'PHYSICAL', monetaryValue: 75000, displayLabel: 'Smartphone Pro', color: '#6366F1', icon: 'Smartphone' },
  ];

  await prisma.spinPrize.deleteMany({});
  const createdPrizes = [];
  for (const p of spinPrizesData) {
    const created = await prisma.spinPrize.create({ data: p });
    createdPrizes.push(created);
  }
  console.log(`✅ Seeded ${createdPrizes.length} Spin Prizes`);

  // 4. Exactly 10 Levels & 10 Tasks per Level
  const levelNames = [
    { title: 'Apprentice Tier', desc: 'The starting gateway into the royal realm of rewards', reward: 500 },
    { title: 'Bronze Sovereign', desc: 'Expand your influence and unlock higher daily earnings', reward: 1000 },
    { title: 'Silver Monarch', desc: 'Step into elite engagement and verified promotions', reward: 1500 },
    { title: 'Gold Viceroy', desc: 'Command greater yields with high-priority assignments', reward: 2500 },
    { title: 'Emerald Regent', desc: 'Exclusive partner activations and elevated multipliers', reward: 4000 },
    { title: 'Ruby Commander', desc: 'Executive campaigns reserved for proven earners', reward: 6000 },
    { title: 'Sapphire Prince', desc: 'High-value network assignments and community growth', reward: 9000 },
    { title: 'Diamond Duke', desc: 'Mastery tier featuring premium sponsored missions', reward: 13000 },
    { title: 'Imperial Archon', desc: 'Apex tier preparing you for royal ascension', reward: 20000 },
    { title: 'Royal Emperor', desc: 'The crowning achievement of Royal Rewards (Final Level)', reward: 50000 },
  ];

  const taskTemplates = [
    { title: 'Official Telegram Channel Join', type: 'Join Group', reward: 50, url: 'https://t.me/royalrewards' },
    { title: 'Subscribe to YouTube Channel', type: 'YouTube Promotion', reward: 60, url: 'https://youtube.com/@royalrewards' },
    { title: 'Follow Official Facebook Page', type: 'Follow Page', reward: 50, url: 'https://facebook.com/royalrewards' },
    { title: 'Engage with Instagram Post', type: 'Social Media', reward: 75, url: 'https://instagram.com/p/royalrewards' },
    { title: 'Watch Sponsored Explainer Video', type: 'Watch Video', reward: 100, url: 'https://youtube.com/watch?v=royalrewards' },
    { title: 'Complete Quick Consumer Survey', type: 'Survey', reward: 120, url: 'https://survey.royalrewards.com/q1' },
    { title: 'Download Partner Rewards App', type: 'App Installation', reward: 150, url: 'https://play.google.com/store/apps/details?id=royalrewards' },
    { title: 'Share Referral Banner to WhatsApp', type: 'Referral', reward: 180, url: 'https://royalrewards.com/share' },
    { title: 'VIP High-Engagement Campaign', type: 'YouTube Promotion', reward: 7500, url: 'https://vip.royalrewards.com/campaign-9', isPaid: true, fee: 5000 },
    { title: 'Royal Imperial Sponsor Mission', type: 'Custom Task', reward: 15000, url: 'https://vip.royalrewards.com/mission-10', isPaid: true, fee: 10000 },
  ];

  const levels = [];
  for (let i = 1; i <= 10; i++) {
    const info = levelNames[i - 1];
    const level = await prisma.level.upsert({
      where: { levelNumber: i },
      update: {
        title: info.title,
        description: info.desc,
        completionReward: info.reward,
        requiredTaskCount: 10,
        displayOrder: i,
        status: 'ACTIVE',
      },
      create: {
        levelNumber: i,
        title: info.title,
        description: info.desc,
        completionReward: info.reward,
        requiredTaskCount: 10,
        displayOrder: i,
        status: 'ACTIVE',
      },
    });
    levels.push(level);

    // Create 10 tasks for this level
    for (let t = 1; t <= 10; t++) {
      const template = taskTemplates[t - 1];
      const isPaid = !!template.isPaid;
      const unlockFee = template.fee || 0;
      const rewardMultiplier = 1 + (i - 1) * 0.25;
      const taskReward = Math.round((template.reward || 50) * rewardMultiplier);

      await prisma.task.upsert({
        where: {
          levelId_taskNumber: {
            levelId: level.id,
            taskNumber: t,
          },
        },
        update: {
          title: `L${i}-T${t}: ${template.title}`,
          description: `Level ${i} Task ${t} assignment. Complete sequential steps to claim verified PKR reward.`,
          taskType: template.type,
          rewardAmount: isPaid ? template.reward : taskReward,
          isPaid: isPaid,
          unlockFee: unlockFee,
          protectedUrl: template.url,
          instructions: `1. Open the protected assignment link.\n2. Complete the required activity carefully.\n3. Take a screenshot showing proof of completion.\n4. Send evidence to the verification line with your Royal ID.\n5. Click "Submit for Review" below.`,
          lockMessage: t === 1 
            ? (i === 1 ? 'Available to start' : `Complete and receive approval for all 10 tasks in Level ${i - 1} to unlock Level ${i}.`)
            : `Complete and receive approval for Task ${t - 1} to unlock this task.`,
          submissionInstructions: 'Submit proof reference or transaction details for administrator verification.',
          requiresAdminApproval: true,
          status: 'ACTIVE',
        },
        create: {
          levelId: level.id,
          taskNumber: t,
          title: `L${i}-T${t}: ${template.title}`,
          description: `Level ${i} Task ${t} assignment. Complete sequential steps to claim verified PKR reward.`,
          taskType: template.type,
          rewardAmount: isPaid ? template.reward : taskReward,
          isPaid: isPaid,
          unlockFee: unlockFee,
          protectedUrl: template.url,
          instructions: `1. Open the protected assignment link.\n2. Complete the required activity carefully.\n3. Take a screenshot showing proof of completion.\n4. Send evidence to the verification line with your Royal ID.\n5. Click "Submit for Review" below.`,
          lockMessage: t === 1 
            ? (i === 1 ? 'Available to start' : `Complete and receive approval for all 10 tasks in Level ${i - 1} to unlock Level ${i}.`)
            : `Complete and receive approval for Task ${t - 1} to unlock this task.`,
          submissionInstructions: 'Submit proof reference or transaction details for administrator verification.',
          requiresAdminApproval: true,
          status: 'ACTIVE',
        },
      });
    }
  }
  console.log(`✅ Seeded 10 Levels and 100 Tasks (10 per level)`);

  // 5. Demo Test User
  const demoUserPassword = await bcrypt.hash('Password123!', 10);
  const demoUser = await prisma.user.upsert({
    where: { phone: '03001234567' },
    update: {
      name: 'Shahid Khan',
      passwordHash: demoUserPassword,
      referralCode: 'ROYAL777',
      accountStatus: 'ACTIVE',
    },
    create: {
      name: 'Shahid Khan',
      phone: '03001234567',
      passwordHash: demoUserPassword,
      referralCode: 'ROYAL777',
      accountStatus: 'ACTIVE',
    },
  });

  // Wallet for Demo User with balance
  const wallet = await prisma.wallet.upsert({
    where: { userId: demoUser.id },
    update: {
      availableBalance: 6500,
      totalEarned: 1500,
      totalDeposited: 5000,
    },
    create: {
      userId: demoUser.id,
      availableBalance: 6500,
      totalEarned: 1500,
      totalDeposited: 5000,
    },
  });

  // Level 1 Progress for Demo User
  const level1 = levels[0];
  await prisma.userLevelProgress.upsert({
    where: { userId_levelId: { userId: demoUser.id, levelId: level1.id } },
    update: { completionStatus: 'IN_PROGRESS', approvedTaskCount: 8 },
    create: { userId: demoUser.id, levelId: level1.id, completionStatus: 'IN_PROGRESS', approvedTaskCount: 8 },
  });

  // Initialize all Level 1 tasks for demo user:
  // Tasks 1 to 8: APPROVED
  // Task 9: AWAITING_PAYMENT (paid task with PKR 5000 unlock fee)
  // Task 10: LOCKED
  const level1Tasks = await prisma.task.findMany({
    where: { levelId: level1.id },
    orderBy: { taskNumber: 'asc' },
  });

  for (const task of level1Tasks) {
    if (task.taskNumber <= 8) {
      await prisma.userTaskProgress.upsert({
        where: { userId_taskId: { userId: demoUser.id, taskId: task.id } },
        update: { status: 'APPROVED', approvedAt: new Date() },
        create: { userId: demoUser.id, taskId: task.id, status: 'APPROVED', approvedAt: new Date() },
      });
    } else if (task.taskNumber === 9) {
      await prisma.userTaskProgress.upsert({
        where: { userId_taskId: { userId: demoUser.id, taskId: task.id } },
        update: { status: 'AWAITING_PAYMENT' },
        create: { userId: demoUser.id, taskId: task.id, status: 'AWAITING_PAYMENT' },
      });
    } else {
      await prisma.userTaskProgress.upsert({
        where: { userId_taskId: { userId: demoUser.id, taskId: task.id } },
        update: { status: 'LOCKED' },
        create: { userId: demoUser.id, taskId: task.id, status: 'LOCKED' },
      });
    }
  }

  // Spin entitlement for demo user assigned with a specific prize (PKR 500)
  const prize500 = createdPrizes.find((p) => p.monetaryValue === 500) || createdPrizes[0];
  await prisma.userSpinEntitlement.deleteMany({ where: { userId: demoUser.id } });
  await prisma.userSpinEntitlement.create({
    data: {
      userId: demoUser.id,
      assignedPrizeId: prize500.id,
      totalSpins: 1,
      remainingSpins: 1,
      isEligible: true,
    },
  });

  // Seed sample transactions for Shahid Khan
  await prisma.walletTransaction.deleteMany({ where: { userId: demoUser.id } });
  await prisma.walletTransaction.createMany({
    data: [
      {
        userId: demoUser.id,
        transactionType: 'DEPOSIT_CREDIT',
        amount: 5000,
        currency: 'PKR',
        status: 'COMPLETED',
        reason: 'Deposit Approved via Easypaisa',
        notes: 'Ref: EP-9876543210',
        actorName: 'admin',
      },
      {
        userId: demoUser.id,
        transactionType: 'TASK_REWARD',
        amount: 850,
        currency: 'PKR',
        status: 'COMPLETED',
        reason: 'Level 1 Tasks 1-8 Approved Rewards',
        actorName: 'admin',
      },
      {
        userId: demoUser.id,
        transactionType: 'REFERRAL_REWARD',
        amount: 650,
        currency: 'PKR',
        status: 'COMPLETED',
        reason: 'Referral Bonus for invited members',
        actorName: 'system',
      },
    ],
  });

  // Seed sample pending deposit request for admin panel demonstration
  await prisma.depositRequest.create({
    data: {
      userId: demoUser.id,
      amount: 2500,
      paymentMethod: 'JAZZCASH',
      transactionReference: 'JC-4421098551',
      proofEvidence: 'Proof screenshot sent to verification WhatsApp',
      status: 'PENDING',
    },
  });

  // Seed sample withdrawal request for admin panel demonstration
  await prisma.withdrawalRequest.create({
    data: {
      userId: demoUser.id,
      amount: 1500,
      paymentMethod: 'EASYPAISA',
      recipientName: 'Shahid Khan',
      recipientAccount: '0300-1234567',
      notes: 'Weekly withdrawal request',
      approvalStatus: 'PENDING',
      paymentStatus: 'NOT_SENT',
    },
  });

  // Seed sample notification
  await prisma.notification.createMany({
    data: [
      {
        userId: demoUser.id,
        title: 'Welcome to Earn Sheet! 👑',
        message: 'Your account is active. Start with Level 1 tasks to earn your first rewards.',
        notificationType: 'REGISTRATION',
      },
      {
        userId: demoUser.id,
        title: 'Deposit Approved: PKR 5,000',
        message: 'Your Easypaisa deposit of PKR 5,000 has been verified and added to your wallet.',
        notificationType: 'DEPOSIT_STATUS',
      },
      {
        userId: demoUser.id,
        title: 'Royal Spin Available! 🎡',
        message: 'You have 1 royal spin waiting. Spin now for exclusive cash prizes!',
        notificationType: 'SPIN_REWARD',
      },
    ],
  });

  // Seed announcement
  await prisma.announcement.create({
    data: {
      title: 'Earn Sheet Grand Launch & VIP Task Multipliers',
      content: 'Welcome to Earn Sheet! Enjoy instant verification on all tasks this week and 2x referral bonuses.',
      audience: 'ALL',
      status: 'ACTIVE',
    },
  });

  console.log(`✅ Seeded Demo User (Phone: 03001234567, Pass: Password123!) with wallet, tasks, spin entitlement, and transactions`);
  console.log('🎉 Seeding successfully completed!');
}

main()
  .catch((e) => {
    console.error('❌ Error during database seed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
