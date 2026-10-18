import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { execSync } from 'child_process';
import bcrypt from 'bcryptjs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function generate() {
  console.log('Generating fresh Supabase SQL setup script...');
  
  // 1. Get accurate DDL directly from prisma schema
  const ddl = execSync('npx prisma migrate diff --from-empty --to-schema-datamodel prisma/schema.prisma --script', {
    cwd: path.resolve(__dirname, '..'),
    encoding: 'utf-8',
  });

  // 2. Generate Seed statements
  const seedStatements: string[] = [];

  // Site Settings
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

  for (let i = 0; i < settings.length; i++) {
    const s = settings[i];
    seedStatements.push(
      `INSERT INTO "SiteSetting" ("id", "key", "value", "description", "category", "updatedAt") VALUES ('setting_${i + 1}', '${s.key}', '${s.value.replace(/'/g, "''")}', '${s.description.replace(/'/g, "''")}', '${s.category}', NOW()) ON CONFLICT ("key") DO UPDATE SET "value" = EXCLUDED."value";`
    );
  }

  // Admin User
  const adminPasswordHash = await bcrypt.hash('Admin@Royal2026!', 10);
  seedStatements.push(
    `INSERT INTO "AdminUser" ("id", "username", "passwordHash", "role", "status", "createdAt", "updatedAt") VALUES ('admin_root_1', 'admin', '${adminPasswordHash}', 'SUPER_ADMIN', 'ACTIVE', NOW(), NOW()) ON CONFLICT ("username") DO NOTHING;`
  );

  // Spin Configuration
  seedStatements.push(
    `INSERT INTO "SpinConfiguration" ("id", "name", "isEnabled", "minLevelRequired", "referralsRequired", "cooldownHours", "createdAt", "updatedAt") VALUES ('spin_config_default', 'Default Royal Spin', true, 1, 0, 24, NOW(), NOW()) ON CONFLICT ("id") DO NOTHING;`
  );

  // Spin Prizes
  const spinPrizesData = [
    { id: 'prize_1', name: 'PKR 50', prizeType: 'CASH', monetaryValue: 50, displayLabel: 'PKR 50', color: '#1459E8', icon: 'Coins' },
    { id: 'prize_2', name: 'PKR 100', prizeType: 'CASH', monetaryValue: 100, displayLabel: 'PKR 100', color: '#792BFF', icon: 'Gift' },
    { id: 'prize_3', name: 'PKR 250', prizeType: 'CASH', monetaryValue: 250, displayLabel: 'PKR 250', color: '#22D3EE', icon: 'Zap' },
    { id: 'prize_4', name: 'PKR 500', prizeType: 'CASH', monetaryValue: 500, displayLabel: 'PKR 500', color: '#FFD45A', icon: 'Crown' },
    { id: 'prize_5', name: 'PKR 1,000', prizeType: 'CASH', monetaryValue: 1000, displayLabel: 'PKR 1,000', color: '#22C55E', icon: 'Sparkles' },
    { id: 'prize_6', name: 'PKR 5,000', prizeType: 'CASH', monetaryValue: 5000, displayLabel: 'PKR 5,000 Mega', color: '#EF4444', icon: 'Trophy' },
    { id: 'prize_7', name: 'Royal Gold Watch', prizeType: 'PHYSICAL', monetaryValue: 15000, displayLabel: 'Gold Watch', color: '#F59E0B', icon: 'Watch' },
    { id: 'prize_8', name: 'Smartphone Pro', prizeType: 'PHYSICAL', monetaryValue: 75000, displayLabel: 'Smartphone Pro', color: '#6366F1', icon: 'Smartphone' },
  ];

  for (const p of spinPrizesData) {
    seedStatements.push(
      `INSERT INTO "SpinPrize" ("id", "name", "prizeType", "monetaryValue", "displayLabel", "color", "icon", "inventory", "status", "createdAt", "updatedAt") VALUES ('${p.id}', '${p.name}', '${p.prizeType}', ${p.monetaryValue}, '${p.displayLabel}', '${p.color}', '${p.icon}', 999999, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("id") DO UPDATE SET "monetaryValue" = EXCLUDED."monetaryValue";`
    );
  }

  // 10 Levels & 100 Tasks
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

  for (let i = 1; i <= 10; i++) {
    const info = levelNames[i - 1];
    const levelId = `level_${i}`;
    seedStatements.push(
      `INSERT INTO "Level" ("id", "levelNumber", "title", "description", "status", "requiredTaskCount", "completionReward", "totalCreditPoints", "displayOrder", "createdAt", "updatedAt") VALUES ('${levelId}', ${i}, '${info.title}', '${info.desc}', 'ACTIVE', 10, ${info.reward}, 100, ${i}, NOW(), NOW()) ON CONFLICT ("levelNumber") DO UPDATE SET "title" = EXCLUDED."title", "completionReward" = EXCLUDED."completionReward";`
    );

    for (let t = 1; t <= 10; t++) {
      const template = taskTemplates[t - 1];
      const isPaid = !!template.isPaid;
      const unlockFee = template.fee || 0;
      const rewardMultiplier = 1 + (i - 1) * 0.25;
      const taskReward = Math.round((template.reward || 50) * rewardMultiplier);
      const taskId = `task_${i}_${t}`;
      const title = `L${i}-T${t}: ${template.title}`;
      const description = `Level ${i} Task ${t} assignment. Complete sequential steps to claim verified PKR reward.`;
      const instructions = `1. Open the protected assignment link.\\n2. Complete the required activity carefully.\\n3. Take a screenshot showing proof of completion.\\n4. Send evidence to the verification line with your Royal ID.\\n5. Click "Submit for Review" below.`;
      const lockMessage = t === 1 
        ? (i === 1 ? 'Available to start' : `Complete and receive approval for all 10 tasks in Level ${i - 1} to unlock Level ${i}.`)
        : `Complete and receive approval for Task ${t - 1} to unlock this task.`;

      seedStatements.push(
        `INSERT INTO "Task" ("id", "levelId", "taskNumber", "title", "description", "taskType", "rewardAmount", "creditPoints", "isPaid", "unlockFee", "protectedUrl", "instructions", "lockMessage", "submissionInstructions", "requiresAdminApproval", "status", "createdAt", "updatedAt") VALUES ('${taskId}', '${levelId}', ${t}, '${title.replace(/'/g, "''")}', '${description.replace(/'/g, "''")}', '${template.type}', ${isPaid ? template.reward : taskReward}, 5, ${isPaid}, ${unlockFee}, '${template.url}', '${instructions.replace(/'/g, "''")}', '${lockMessage.replace(/'/g, "''")}', 'Submit proof reference or transaction details for administrator verification.', true, 'ACTIVE', NOW(), NOW()) ON CONFLICT ("levelId", "taskNumber") DO UPDATE SET "title" = EXCLUDED."title", "rewardAmount" = EXCLUDED."rewardAmount", "unlockFee" = EXCLUDED."unlockFee";`
      );
    }
  }

  const fullSql = [
    '--',
    '-- ROYAL REWARDS / EARN SHEET - COMPLETE SUPABASE POSTGRESQL SETUP',
    '-- Copy and paste this ENTIRE file into your Supabase SQL Editor and click "RUN"',
    '--',
    '',
    ddl,
    '',
    '--',
    '-- SEED DATA (Site Settings, Admin, Spin Wheel, 10 Levels & 100 Tasks)',
    '--',
    ...seedStatements,
    '',
  ].join('\n');

  const outputPath = path.resolve(__dirname, 'supabase_full_setup.sql');
  fs.writeFileSync(outputPath, fullSql, 'utf-8');
  console.log(`✅ Successfully generated clean ${outputPath} (${fullSql.length} bytes, ${seedStatements.length} seed statements)`);
}

generate().catch(console.error);
