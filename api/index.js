// src/app.ts
import express from "express";
import cors from "cors";
import morgan from "morgan";

// src/routes/authRoutes.ts
import { Router } from "express";
import bcrypt from "bcryptjs";
import jwt2 from "jsonwebtoken";
import { z } from "zod";

// src/prisma.ts
import { PrismaClient } from "@prisma/client";
var globalForPrisma = globalThis;
var prisma = globalForPrisma.prisma ?? new PrismaClient({
  log: process.env.NODE_ENV === "development" ? ["warn", "error"] : ["error"]
});
if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;

// src/config.ts
import dotenv from "dotenv";
dotenv.config();
var config = {
  port: parseInt(process.env.PORT || "5000", 10),
  jwtSecret: process.env.JWT_SECRET || "royal-rewards-super-secret-jwt-key-2026",
  adminSecret: process.env.ADMIN_SECRET || "royal-rewards-admin-secret-key-2026",
  nodeEnv: process.env.NODE_ENV || "development",
  corsOrigin: process.env.CORS_ORIGIN || "*"
};

// src/middleware/auth.ts
import jwt from "jsonwebtoken";
async function requireAuth(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ error: "Unauthorized: Authentication token is missing" });
    }
    const token = authHeader.split(" ")[1];
    const decoded = jwt.verify(token, config.jwtSecret);
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: {
        id: true,
        phone: true,
        name: true,
        referralCode: true,
        accountStatus: true
      }
    });
    if (!user) {
      return res.status(401).json({ error: "Unauthorized: User no longer exists" });
    }
    if (user.accountStatus === "SUSPENDED") {
      return res.status(403).json({ error: "Account suspended. Please contact Earn Sheet support." });
    }
    req.user = user;
    next();
  } catch (err) {
    return res.status(401).json({ error: "Unauthorized: Invalid or expired token" });
  }
}

// src/services/affiliateService.ts
var affiliateService = {
  /**
   * Fetches current affiliate and referral program settings from database
   */
  async getSettings() {
    const keys = [
      "referral_reward",
      "referral_qualifying_condition",
      "affiliate_program_enabled",
      "affiliate_bronze_target",
      "affiliate_silver_target",
      "affiliate_gold_target",
      "affiliate_share_template",
      "affiliate_auto_payout",
      "affiliate_anti_fraud"
    ];
    const settings = await prisma.siteSetting.findMany({
      where: { key: { in: keys } }
    });
    const map = Object.fromEntries(settings.map((s) => [s.key, s.value]));
    return {
      referralReward: parseFloat(map.referral_reward || "250"),
      qualifyingCondition: map.referral_qualifying_condition || "FIRST_TASK_APPROVED",
      affiliateProgramEnabled: map.affiliate_program_enabled !== "false",
      bronzeTarget: parseInt(map.affiliate_bronze_target || "5", 10),
      silverTarget: parseInt(map.affiliate_silver_target || "15", 10),
      goldTarget: parseInt(map.affiliate_gold_target || "30", 10),
      shareTemplate: map.affiliate_share_template || "\u{1F451} Join Earn Sheet with my exclusive invite code {CODE} and earn daily cash rewards on tasks! Register here: {LINK}",
      autoPayout: map.affiliate_auto_payout !== "false",
      antiFraudEnabled: map.affiliate_anti_fraud !== "false"
    };
  },
  /**
   * Called when a user registers with a referrer code
   */
  async handleNewRegistration(referrerId, refereeId) {
    const settings = await this.getSettings();
    if (!settings.affiliateProgramEnabled) return;
    if (referrerId === refereeId) return;
    const isInstant = settings.qualifyingCondition === "INSTANT_ON_REGISTRATION";
    if (isInstant) {
      await prisma.$transaction(async (tx) => {
        await tx.referral.upsert({
          where: { referrerId_referredId: { referrerId, referredId: refereeId } },
          update: {
            qualifyingStatus: "QUALIFIED",
            rewardStatus: "CREDITED",
            rewardAmount: settings.referralReward
          },
          create: {
            referrerId,
            referredId: refereeId,
            qualifyingStatus: "QUALIFIED",
            rewardStatus: "CREDITED",
            rewardAmount: settings.referralReward
          }
        });
        await tx.wallet.update({
          where: { userId: referrerId },
          data: {
            availableBalance: { increment: settings.referralReward },
            totalEarned: { increment: settings.referralReward }
          }
        });
        await tx.walletTransaction.create({
          data: {
            userId: referrerId,
            transactionType: "REFERRAL_REWARD",
            amount: settings.referralReward,
            currency: "PKR",
            status: "COMPLETED",
            relatedEntityId: refereeId,
            reason: `Referral commission for registering new partner`
          }
        });
        await tx.notification.create({
          data: {
            userId: referrerId,
            title: `Referral Bonus Credited! +PKR ${settings.referralReward.toLocaleString()} \u{1F389}`,
            message: `A new partner registered with your code! PKR ${settings.referralReward.toLocaleString()} has been credited directly to your cash wallet balance.`,
            notificationType: "WALLET_TRANSACTION"
          }
        });
      });
      await this.checkAmbassadorMilestones(referrerId);
    } else {
      await prisma.referral.upsert({
        where: { referrerId_referredId: { referrerId, referredId: refereeId } },
        update: {
          qualifyingStatus: "PENDING",
          rewardStatus: "PENDING",
          rewardAmount: settings.referralReward
        },
        create: {
          referrerId,
          referredId: refereeId,
          qualifyingStatus: "PENDING",
          rewardStatus: "PENDING",
          rewardAmount: settings.referralReward
        }
      });
    }
  },
  /**
   * Evaluates qualification criteria when events occur:
   * 'TASK_APPROVED' | 'LEVEL_1_COMPLETED' | 'DEPOSIT_APPROVED'
   */
  async checkAndQualifyReferral(refereeUserId, triggerType) {
    const settings = await this.getSettings();
    if (!settings.affiliateProgramEnabled) return;
    const referral = await prisma.referral.findFirst({
      where: {
        referredId: refereeUserId,
        qualifyingStatus: "PENDING"
      }
    });
    if (!referral) return;
    let shouldQualify = false;
    if (settings.qualifyingCondition === "FIRST_TASK_APPROVED" && triggerType === "TASK_APPROVED") {
      shouldQualify = true;
    } else if (settings.qualifyingCondition === "LEVEL_1_COMPLETED" && triggerType === "LEVEL_1_COMPLETED") {
      shouldQualify = true;
    } else if (settings.qualifyingCondition === "FIRST_DEPOSIT_COMPLETED" && triggerType === "DEPOSIT_APPROVED") {
      shouldQualify = true;
    }
    if (!shouldQualify) return;
    const rewardAmount = settings.referralReward || 250;
    const referrerId = referral.referrerId;
    await prisma.$transaction(async (tx) => {
      await tx.referral.update({
        where: { id: referral.id },
        data: {
          qualifyingStatus: "QUALIFIED",
          rewardStatus: "CREDITED",
          rewardAmount
        }
      });
      await tx.wallet.update({
        where: { userId: referrerId },
        data: {
          availableBalance: { increment: rewardAmount },
          totalEarned: { increment: rewardAmount }
        }
      });
      await tx.walletTransaction.create({
        data: {
          userId: referrerId,
          transactionType: "REFERRAL_REWARD",
          amount: rewardAmount,
          currency: "PKR",
          status: "COMPLETED",
          relatedEntityId: referral.id,
          reason: `Referral commission for qualifying partner (Criteria: ${settings.qualifyingCondition})`
        }
      });
      await tx.notification.create({
        data: {
          userId: referrerId,
          title: `Partner Qualified! +PKR ${rewardAmount.toLocaleString()} Credited \u{1F389}`,
          message: `Your referred partner has met the qualification criteria! PKR ${rewardAmount.toLocaleString()} has been credited to your available wallet balance.`,
          notificationType: "WALLET_TRANSACTION"
        }
      });
    });
    await this.checkAmbassadorMilestones(referrerId);
  },
  /**
   * Checks Ambassador tier thresholds (Silver, Gold) and awards milestone perks
   */
  async checkAmbassadorMilestones(referrerId) {
    const settings = await this.getSettings();
    const qualifiedCount = await prisma.referral.count({
      where: {
        referrerId,
        qualifyingStatus: "QUALIFIED"
      }
    });
    if (qualifiedCount >= settings.silverTarget) {
      const entitlementReason = `Silver Ambassador Milestone (${settings.silverTarget} Qualified Partners)`;
      const existingSpin = await prisma.userSpinEntitlement.findFirst({
        where: {
          userId: referrerId,
          triggerReason: entitlementReason
        }
      });
      if (!existingSpin) {
        await prisma.userSpinEntitlement.create({
          data: {
            userId: referrerId,
            triggerReason: entitlementReason,
            totalSpins: 1,
            remainingSpins: 1,
            isEligible: false,
            // Goes to admin for prize assignment
            requiresAdminReview: true,
            adminReviewed: false
          }
        });
        await prisma.notification.create({
          data: {
            userId: referrerId,
            title: `Silver Ambassador Rank Achieved! \u{1F948}`,
            message: `Congratulations! You have reached ${settings.silverTarget} qualified partners and unlocked Silver Ambassador status plus a Free Royal Milestone Spin!`,
            notificationType: "SPIN_REWARD"
          }
        });
      }
    }
    if (qualifiedCount >= settings.goldTarget) {
      const goldBonusReason = `Gold Ambassador Milestone Bonus (${settings.goldTarget} Qualified Partners)`;
      const existingBonus = await prisma.walletTransaction.findFirst({
        where: {
          userId: referrerId,
          reason: goldBonusReason
        }
      });
      if (!existingBonus) {
        await prisma.$transaction(async (tx) => {
          const goldBonusAmount = 5e3;
          await tx.wallet.update({
            where: { userId: referrerId },
            data: {
              availableBalance: { increment: goldBonusAmount },
              totalEarned: { increment: goldBonusAmount }
            }
          });
          await tx.walletTransaction.create({
            data: {
              userId: referrerId,
              transactionType: "REFERRAL_REWARD",
              amount: goldBonusAmount,
              currency: "PKR",
              status: "COMPLETED",
              reason: goldBonusReason
            }
          });
          await tx.notification.create({
            data: {
              userId: referrerId,
              title: `Gold Ambassador Crowned! +PKR 5,000 Cash Bonus \u{1F451}`,
              message: `Incredible achievement! You reached ${settings.goldTarget} qualified partners, earning Gold Ambassador rank and a PKR 5,000 royal milestone reward!`,
              notificationType: "WALLET_TRANSACTION"
            }
          });
        });
      }
    }
  }
};

// src/routes/authRoutes.ts
var router = Router();
var registerSchema = z.object({
  name: z.string().min(2, "Name must be at least 2 characters").max(50),
  phone: z.string().min(10, "Valid phone number is required").max(15),
  password: z.string().min(6, "Password must be at least 6 characters"),
  confirmPassword: z.string().min(6, "Confirm password must be at least 6 characters"),
  referralCode: z.string().optional().nullable()
}).refine((data) => data.password === data.confirmPassword, {
  message: "Passwords do not match",
  path: ["confirmPassword"]
});
var loginSchema = z.object({
  phone: z.string().min(10, "Valid phone number is required"),
  password: z.string().min(1, "Password is required")
});
function generateReferralCode(name) {
  const prefix = name.replace(/[^a-zA-Z]/g, "").slice(0, 4).toUpperCase() || "ROYAL";
  const randomSuffix = Math.floor(1e3 + Math.random() * 9e3);
  return `${prefix}${randomSuffix}`;
}
function normalizePhone(phone) {
  return phone.replace(/[^0-9+]/g, "");
}
router.post("/register", async (req, res, next) => {
  try {
    const validated = registerSchema.parse(req.body);
    const normalizedPhone = normalizePhone(validated.phone);
    const existingUser = await prisma.user.findUnique({
      where: { phone: normalizedPhone }
    });
    if (existingUser) {
      return res.status(400).json({ error: "A user with this phone number is already registered" });
    }
    let referrer = null;
    if (validated.referralCode && validated.referralCode.trim()) {
      referrer = await prisma.user.findUnique({
        where: { referralCode: validated.referralCode.trim().toUpperCase() }
      });
      if (!referrer) {
        return res.status(400).json({ error: "Invalid referral code provided" });
      }
    }
    let userReferralCode = generateReferralCode(validated.name);
    let codeExists = await prisma.user.findUnique({ where: { referralCode: userReferralCode } });
    let attempts = 0;
    while (codeExists && attempts < 5) {
      userReferralCode = generateReferralCode(validated.name);
      codeExists = await prisma.user.findUnique({ where: { referralCode: userReferralCode } });
      attempts++;
    }
    const passwordHash = await bcrypt.hash(validated.password, 10);
    const result = await prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          name: validated.name.trim(),
          phone: normalizedPhone,
          passwordHash,
          referralCode: userReferralCode,
          referredById: referrer?.id || null,
          accountStatus: "ACTIVE"
        }
      });
      await tx.wallet.create({
        data: {
          userId: user.id,
          currency: "PKR",
          availableBalance: 0,
          pendingBalance: 0,
          totalEarned: 0,
          totalDeposited: 0
        }
      });
      const level1 = await tx.level.findUnique({ where: { levelNumber: 1 } });
      if (level1) {
        await tx.userLevelProgress.create({
          data: {
            userId: user.id,
            levelId: level1.id,
            completionStatus: "IN_PROGRESS",
            approvedTaskCount: 0
          }
        });
      }
      return user;
    });
    if (referrer) {
      await affiliateService.handleNewRegistration(referrer.id, result.id);
    }
    const token = jwt2.sign({ userId: result.id }, config.jwtSecret, { expiresIn: "7d" });
    res.status(201).json({
      message: "Registration successful! Welcome to Earn Sheet.",
      token,
      user: {
        id: result.id,
        name: result.name,
        phone: result.phone,
        referralCode: result.referralCode,
        accountStatus: result.accountStatus
      }
    });
  } catch (err) {
    next(err);
  }
});
router.post("/login", async (req, res, next) => {
  try {
    const validated = loginSchema.parse(req.body);
    const normalizedPhone = normalizePhone(validated.phone);
    const user = await prisma.user.findUnique({
      where: { phone: normalizedPhone },
      include: { wallet: true }
    });
    if (!user) {
      return res.status(401).json({ error: "Invalid phone number or password" });
    }
    if (user.accountStatus === "SUSPENDED") {
      return res.status(403).json({ error: "Your account is suspended. Please contact customer support." });
    }
    const isValid = await bcrypt.compare(validated.password, user.passwordHash);
    if (!isValid) {
      return res.status(401).json({ error: "Invalid phone number or password" });
    }
    const token = jwt2.sign({ userId: user.id }, config.jwtSecret, { expiresIn: "7d" });
    res.json({
      message: "Login successful",
      token,
      user: {
        id: user.id,
        name: user.name,
        phone: user.phone,
        referralCode: user.referralCode,
        accountStatus: user.accountStatus,
        mustChangePassword: user.mustChangePassword,
        wallet: user.wallet
      }
    });
  } catch (err) {
    next(err);
  }
});
router.get("/me", requireAuth, async (req, res, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: {
        id: true,
        name: true,
        phone: true,
        referralCode: true,
        accountStatus: true,
        mustChangePassword: true,
        createdAt: true,
        wallet: true
      }
    });
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }
    res.json({ user });
  } catch (err) {
    next(err);
  }
});
router.post("/logout", (req, res) => {
  res.json({ message: "Logged out successfully" });
});
var authRoutes_default = router;

// src/routes/userRoutes.ts
import { Router as Router2 } from "express";
import bcrypt2 from "bcryptjs";
import { z as z2 } from "zod";
var router2 = Router2();
router2.get("/dashboard", requireAuth, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        wallet: true
      }
    });
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }
    const levels = await prisma.level.findMany({
      orderBy: { levelNumber: "asc" }
    });
    let currentLevelNumber = 1;
    let currentLevelApprovedTasks = 0;
    let isAllLevelsCompleted = false;
    let completedLevelsCount = 0;
    let foundActiveLevel = false;
    for (const lvl of levels) {
      const approvedCount = await prisma.userTaskProgress.count({
        where: {
          userId,
          task: { levelId: lvl.id },
          status: "APPROVED"
        }
      });
      if (approvedCount >= 10) {
        completedLevelsCount++;
      } else if (!foundActiveLevel) {
        currentLevelNumber = lvl.levelNumber;
        currentLevelApprovedTasks = approvedCount;
        foundActiveLevel = true;
      }
    }
    if (!foundActiveLevel && completedLevelsCount >= 10) {
      currentLevelNumber = 10;
      currentLevelApprovedTasks = 10;
      isAllLevelsCompleted = true;
    }
    const currentLevel = levels.find((l) => l.levelNumber === currentLevelNumber) || levels[0];
    const totalApprovedTasksCount = await prisma.userTaskProgress.count({
      where: { userId, status: "APPROVED" }
    });
    const remainingTasksCount = Math.max(0, 100 - totalApprovedTasksCount);
    const taskRewardTransactions = await prisma.walletTransaction.aggregate({
      where: {
        userId,
        transactionType: "TASK_REWARD",
        status: "COMPLETED"
      },
      _sum: { amount: true }
    });
    const totalTaskRewardsApproved = taskRewardTransactions._sum.amount || 0;
    const referralCount = await prisma.referral.count({
      where: { referrerId: userId }
    });
    const entitlement = await prisma.userSpinEntitlement.findFirst({
      where: {
        userId,
        isEligible: true,
        remainingSpins: { gt: 0 }
      }
    });
    const spinEligibility = {
      canSpin: !!entitlement,
      remainingSpins: entitlement?.remainingSpins || 0
    };
    const unreadNotificationsCount = await prisma.notification.count({
      where: { userId, isRead: false }
    });
    const recentTransactions = await prisma.walletTransaction.findMany({
      where: { userId },
      orderBy: { createdAt: "desc" },
      take: 5
    });
    const recentSubmissions = await prisma.taskSubmission.findMany({
      where: { userId },
      include: {
        task: {
          select: { title: true, taskNumber: true, rewardAmount: true }
        }
      },
      orderBy: { createdAt: "desc" },
      take: 5
    });
    let creditPoints = user.wallet?.creditPoints || 0;
    const minCreditPoints = totalApprovedTasksCount * 10;
    if (user.wallet && creditPoints < minCreditPoints) {
      await prisma.wallet.update({
        where: { userId },
        data: { creditPoints: minCreditPoints }
      });
      creditPoints = minCreditPoints;
      user.wallet.creditPoints = minCreditPoints;
    }
    const eligiblePercent = Math.min(100, completedLevelsCount * 10);
    const availableBalance = user.wallet?.availableBalance || 0;
    const maxWithdrawableAmount = Math.floor(availableBalance * eligiblePercent / 100);
    res.json({
      user: {
        id: user.id,
        name: user.name,
        phone: user.phone,
        referralCode: user.referralCode,
        accountStatus: user.accountStatus,
        createdAt: user.createdAt
      },
      wallet: user.wallet ? {
        ...user.wallet,
        creditPoints
      } : {
        availableBalance: 0,
        pendingBalance: 0,
        totalEarned: 0,
        totalDeposited: 0,
        totalWithdrawn: 0,
        creditPoints: 0
      },
      withdrawalEligibility: {
        completedLevelsCount,
        eligiblePercent,
        maxWithdrawableAmount,
        availableBalance
      },
      levelProgress: {
        currentLevelNumber,
        levelTitle: currentLevel.title,
        levelDescription: currentLevel.description,
        approvedTasksCount: currentLevelApprovedTasks,
        totalLevelTasks: 10,
        isAllLevelsCompleted,
        completedLevelsCount
      },
      taskStats: {
        totalApprovedTasks: totalApprovedTasksCount,
        totalTasks: 100,
        remainingTasks: remainingTasksCount,
        totalTaskRewards: totalTaskRewardsApproved,
        totalCreditPoints: creditPoints
      },
      referralCount,
      spinEligibility,
      unreadNotificationsCount,
      recentTransactions,
      recentSubmissions
    });
  } catch (err) {
    next(err);
  }
});
router2.get("/profile", requireAuth, async (req, res, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      include: {
        wallet: true,
        referredBy: {
          select: { name: true, phone: true }
        }
      }
    });
    if (!user) return res.status(404).json({ error: "User not found" });
    res.json({ user });
  } catch (err) {
    next(err);
  }
});
router2.put("/profile/password", requireAuth, async (req, res, next) => {
  try {
    const schema = z2.object({
      currentPassword: z2.string().min(1, "Current password is required"),
      newPassword: z2.string().min(6, "New password must be at least 6 characters")
    });
    const validated = schema.parse(req.body);
    const user = await prisma.user.findUnique({ where: { id: req.user.id } });
    if (!user) return res.status(404).json({ error: "User not found" });
    const isValid = await bcrypt2.compare(validated.currentPassword, user.passwordHash);
    if (!isValid) {
      return res.status(400).json({ error: "Incorrect current password" });
    }
    const newHash = await bcrypt2.hash(validated.newPassword, 10);
    await prisma.user.update({
      where: { id: user.id },
      data: { passwordHash: newHash, mustChangePassword: false }
    });
    res.json({ message: "Password updated successfully" });
  } catch (err) {
    next(err);
  }
});
var userRoutes_default = router2;

// src/routes/taskRoutes.ts
import { Router as Router3 } from "express";
import { z as z3 } from "zod";

// src/services/taskProgressionService.ts
var taskProgressionService = {
  /**
   * Evaluates sequential task progression for a user in a specific level
   */
  async getLevelTasksForUser(userId, levelNumber) {
    const level = await prisma.level.findUnique({
      where: { levelNumber },
      include: {
        tasks: {
          orderBy: { taskNumber: "asc" }
        }
      }
    });
    if (!level) {
      throw new Error(`Level ${levelNumber} not found`);
    }
    let isLevelUnlocked = false;
    if (levelNumber === 1) {
      isLevelUnlocked = true;
    } else {
      const prevLevel = await prisma.level.findUnique({
        where: { levelNumber: levelNumber - 1 }
      });
      if (prevLevel) {
        const approvedCount = await prisma.userTaskProgress.count({
          where: {
            userId,
            task: { levelId: prevLevel.id },
            status: "APPROVED"
          }
        });
        isLevelUnlocked = approvedCount >= (prevLevel.requiredTaskCount || 10);
      }
    }
    const userProgressRecords = await prisma.userTaskProgress.findMany({
      where: {
        userId,
        task: { levelId: level.id }
      }
    });
    const progressMap = new Map(userProgressRecords.map((p) => [p.taskId, p]));
    const submissions = await prisma.taskSubmission.findMany({
      where: {
        userId,
        task: { levelId: level.id }
      },
      orderBy: { createdAt: "desc" }
    });
    const submissionMap = new Map(submissions.map((s) => [s.taskId, s]));
    const evaluatedTasks = [];
    let previousTaskApproved = isLevelUnlocked;
    for (const task of level.tasks) {
      const progress = progressMap.get(task.id);
      const submission = submissionMap.get(task.id);
      let userStatus = "LOCKED";
      let isPaidUnlocked = progress?.isPaidUnlocked || false;
      if (task.status === "DISABLED") {
        userStatus = "DISABLED";
      } else if (!isLevelUnlocked) {
        userStatus = "LOCKED";
      } else if (progress?.status === "APPROVED") {
        userStatus = "APPROVED";
      } else if (submission?.status === "PENDING" || progress?.status === "PENDING_VERIFICATION") {
        userStatus = "PENDING_VERIFICATION";
      } else if (progress?.status === "REJECTED" || submission?.status === "REJECTED") {
        userStatus = "REJECTED";
      } else if (task.taskNumber === 1 || previousTaskApproved) {
        if (task.isPaid && !isPaidUnlocked) {
          userStatus = "AWAITING_PAYMENT";
        } else if (task.isPaid && isPaidUnlocked) {
          userStatus = "UNLOCKED";
        } else {
          userStatus = "AVAILABLE";
        }
      } else {
        userStatus = "LOCKED";
      }
      previousTaskApproved = userStatus === "APPROVED";
      const hasAccessToProtectedContent = ["UNLOCKED", "AVAILABLE", "IN_PROGRESS", "PENDING_VERIFICATION", "APPROVED", "REJECTED"].includes(userStatus);
      const isLocked = userStatus === "LOCKED";
      evaluatedTasks.push({
        id: task.id,
        levelId: task.levelId,
        taskNumber: task.taskNumber,
        title: task.title,
        description: isLocked ? task.lockMessage || "Complete previous requirements to unlock this task." : task.description,
        taskType: task.taskType,
        rewardAmount: task.rewardAmount,
        creditPoints: task.creditPoints ?? 5,
        isPaid: task.isPaid,
        unlockFee: task.unlockFee,
        requiresAdminApproval: task.requiresAdminApproval,
        status: task.status,
        userStatus,
        isPaidUnlocked,
        lockMessage: isLocked ? task.lockMessage || "Complete previous requirements to unlock this task." : "",
        instructions: hasAccessToProtectedContent ? task.instructions : null,
        protectedUrl: hasAccessToProtectedContent ? task.protectedUrl : null,
        submissionInstructions: hasAccessToProtectedContent ? task.submissionInstructions : null,
        externalContact: hasAccessToProtectedContent ? task.externalContact : null,
        submission: submission || null
      });
    }
    return {
      level,
      tasks: evaluatedTasks,
      isLevelUnlocked
    };
  },
  /**
   * Recalculates and updates level progression for a user
   */
  async updateLevelProgress(userId, levelId) {
    const level = await prisma.level.findUnique({
      where: { id: levelId },
      include: { tasks: true }
    });
    if (!level) return null;
    const approvedCount = await prisma.userTaskProgress.count({
      where: {
        userId,
        task: { levelId },
        status: "APPROVED"
      }
    });
    const isCompleted = approvedCount >= level.requiredTaskCount;
    const progress = await prisma.userLevelProgress.upsert({
      where: {
        userId_levelId: { userId, levelId }
      },
      update: {
        approvedTaskCount: approvedCount,
        completionStatus: isCompleted ? "COMPLETED" : "IN_PROGRESS",
        completedAt: isCompleted ? /* @__PURE__ */ new Date() : void 0
      },
      create: {
        userId,
        levelId,
        approvedTaskCount: approvedCount,
        completionStatus: isCompleted ? "COMPLETED" : "IN_PROGRESS",
        completedAt: isCompleted ? /* @__PURE__ */ new Date() : null
      }
    });
    if (isCompleted && level.completionReward > 0) {
      const rewardKey = `LEVEL_REWARD_${level.id}_${userId}`;
      const existing = await prisma.walletTransaction.findUnique({
        where: { idempotencyKey: rewardKey }
      });
      if (!existing) {
        await prisma.$transaction(async (tx) => {
          await tx.wallet.update({
            where: { userId },
            data: {
              availableBalance: { increment: level.completionReward },
              totalEarned: { increment: level.completionReward }
            }
          });
          await tx.walletTransaction.create({
            data: {
              userId,
              transactionType: "LEVEL_REWARD",
              amount: level.completionReward,
              currency: "PKR",
              status: "COMPLETED",
              idempotencyKey: rewardKey,
              relatedEntityId: level.id,
              reason: `Completion bonus for Level ${level.levelNumber}: ${level.title}`
            }
          });
          await tx.notification.create({
            data: {
              userId,
              title: `Level ${level.levelNumber} Completed! \u{1F3C6}`,
              message: `Congratulations! You completed all 10 tasks in Level ${level.levelNumber} and earned PKR ${level.completionReward.toLocaleString()}!`,
              notificationType: "LEVEL_STATUS"
            }
          });
        });
      }
    }
    if (isCompleted && level.levelNumber === 1) {
      await affiliateService.checkAndQualifyReferral(userId, "LEVEL_1_COMPLETED");
    }
    return progress;
  }
};

// src/services/ledgerService.ts
var InsufficientBalanceError = class extends Error {
  constructor(message = "Insufficient available balance") {
    super(message);
    this.name = "InsufficientBalanceError";
  }
};

// src/routes/taskRoutes.ts
var router3 = Router3();
router3.get("/levels", requireAuth, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const levels = await prisma.level.findMany({
      orderBy: { levelNumber: "asc" }
    });
    const levelsWithProgress = [];
    let previousLevelCompleted = true;
    for (const lvl of levels) {
      const approvedCount = await prisma.userTaskProgress.count({
        where: {
          userId,
          task: { levelId: lvl.id },
          status: "APPROVED"
        }
      });
      const isCompleted = approvedCount >= (lvl.requiredTaskCount || 10);
      const isUnlocked = lvl.levelNumber === 1 || previousLevelCompleted;
      levelsWithProgress.push({
        id: lvl.id,
        levelNumber: lvl.levelNumber,
        title: lvl.title,
        description: lvl.description,
        status: lvl.status,
        requiredTaskCount: lvl.requiredTaskCount,
        completionReward: lvl.completionReward,
        totalCreditPoints: lvl.totalCreditPoints ?? 100,
        approvedTaskCount: approvedCount,
        isCompleted,
        isUnlocked
      });
      previousLevelCompleted = isCompleted;
    }
    res.json({ levels: levelsWithProgress });
  } catch (err) {
    next(err);
  }
});
router3.get("/levels/:levelNumber", requireAuth, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const levelNumber = parseInt(req.params.levelNumber, 10);
    if (isNaN(levelNumber) || levelNumber < 1 || levelNumber > 10) {
      return res.status(400).json({ error: "Valid standard level number between 1 and 10 is required" });
    }
    const result = await taskProgressionService.getLevelTasksForUser(userId, levelNumber);
    res.json(result);
  } catch (err) {
    next(err);
  }
});
router3.get("/:taskId", requireAuth, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const taskId = req.params.taskId;
    const task = await prisma.task.findUnique({
      where: { id: taskId },
      include: { level: true }
    });
    if (!task) {
      return res.status(404).json({ error: "Task not found" });
    }
    const { tasks, isLevelUnlocked } = await taskProgressionService.getLevelTasksForUser(userId, task.level.levelNumber);
    const evaluatedTask = tasks.find((t) => t.id === taskId);
    if (!evaluatedTask) {
      return res.status(404).json({ error: "Task evaluation failed" });
    }
    const submissions = await prisma.taskSubmission.findMany({
      where: { userId, taskId },
      orderBy: { createdAt: "desc" }
    });
    res.json({
      task: evaluatedTask,
      level: task.level,
      isLevelUnlocked,
      submissions
    });
  } catch (err) {
    next(err);
  }
});
router3.post("/:taskId/unlock", requireAuth, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const taskId = req.params.taskId;
    const task = await prisma.task.findUnique({
      where: { id: taskId },
      include: { level: true }
    });
    if (!task) {
      return res.status(404).json({ error: "Task not found" });
    }
    if (!task.isPaid || task.unlockFee <= 0) {
      return res.status(400).json({ error: "This task is free and does not require an unlock fee" });
    }
    const { tasks, isLevelUnlocked } = await taskProgressionService.getLevelTasksForUser(userId, task.level.levelNumber);
    if (!isLevelUnlocked) {
      return res.status(403).json({ error: `Level ${task.level.levelNumber} is locked. Complete all tasks in the previous level first.` });
    }
    const evaluated = tasks.find((t) => t.id === taskId);
    if (!evaluated) {
      return res.status(404).json({ error: "Task evaluation error" });
    }
    if (evaluated.userStatus === "APPROVED") {
      return res.status(400).json({ error: "This task is already completed and approved" });
    }
    if (evaluated.isPaidUnlocked) {
      return res.status(400).json({ error: "This task is already unlocked" });
    }
    if (evaluated.userStatus === "LOCKED") {
      return res.status(403).json({ error: evaluated.lockMessage || "Prerequisite tasks must be approved before unlocking this task" });
    }
    const wallet = await prisma.wallet.findUnique({ where: { userId } });
    if (!wallet || wallet.availableBalance < task.unlockFee) {
      return res.status(400).json({
        error: `Insufficient wallet balance. Required: PKR ${task.unlockFee.toLocaleString()}, Available: PKR ${wallet?.availableBalance.toLocaleString() || 0}. Please deposit funds to proceed.`,
        requiredAmount: task.unlockFee,
        availableBalance: wallet?.availableBalance || 0
      });
    }
    const result = await prisma.$transaction(async (tx) => {
      await tx.wallet.update({
        where: { userId },
        data: {
          availableBalance: { decrement: task.unlockFee },
          totalUnlockFees: { increment: task.unlockFee }
        }
      });
      const transaction = await tx.walletTransaction.create({
        data: {
          userId,
          transactionType: "TASK_UNLOCK_FEE",
          amount: -task.unlockFee,
          currency: "PKR",
          status: "COMPLETED",
          relatedEntityId: task.id,
          reason: `Unlock fee for Level ${task.level.levelNumber} Task ${task.taskNumber}: ${task.title}`
        }
      });
      const unlockTx = await tx.taskUnlockTransaction.create({
        data: {
          userId,
          taskId: task.id,
          unlockFee: task.unlockFee,
          transactionId: transaction.id,
          status: "COMPLETED"
        }
      });
      const progress = await tx.userTaskProgress.upsert({
        where: { userId_taskId: { userId, taskId: task.id } },
        update: {
          status: "UNLOCKED",
          isPaidUnlocked: true,
          unlockedAt: /* @__PURE__ */ new Date()
        },
        create: {
          userId,
          taskId: task.id,
          status: "UNLOCKED",
          isPaidUnlocked: true,
          unlockedAt: /* @__PURE__ */ new Date()
        }
      });
      await tx.notification.create({
        data: {
          userId,
          title: `Task Unlocked: ${task.title} \u{1F513}`,
          message: `Unlock fee of PKR ${task.unlockFee.toLocaleString()} paid. Protected instructions and link are now active.`,
          notificationType: "TASK_STATUS"
        }
      });
      return { progress, unlockTx, transaction };
    });
    res.json({
      message: `Task successfully unlocked! PKR ${task.unlockFee.toLocaleString()} deducted from your wallet.`,
      task: {
        id: task.id,
        title: task.title,
        instructions: task.instructions,
        protectedUrl: task.protectedUrl,
        userStatus: "UNLOCKED",
        isPaidUnlocked: true
      }
    });
  } catch (err) {
    if (err instanceof InsufficientBalanceError) {
      return res.status(400).json({ error: err.message });
    }
    next(err);
  }
});
router3.post("/:taskId/submit", requireAuth, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const taskId = req.params.taskId;
    const schema = z3.object({
      submissionNotes: z3.string().min(2, "Submission notes or confirmation reference is required").max(1e3),
      proofEvidence: z3.string().optional().nullable()
    });
    const validated = schema.parse(req.body);
    const task = await prisma.task.findUnique({
      where: { id: taskId },
      include: { level: true }
    });
    if (!task) {
      return res.status(404).json({ error: "Task not found" });
    }
    const { tasks, isLevelUnlocked } = await taskProgressionService.getLevelTasksForUser(userId, task.level.levelNumber);
    if (!isLevelUnlocked) {
      return res.status(403).json({ error: "This level is locked" });
    }
    const evaluated = tasks.find((t) => t.id === taskId);
    if (!evaluated) {
      return res.status(404).json({ error: "Task evaluation error" });
    }
    if (evaluated.userStatus === "APPROVED") {
      return res.status(400).json({ error: "This task has already been completed and approved" });
    }
    if (evaluated.userStatus === "PENDING_VERIFICATION") {
      return res.status(400).json({ error: "A submission for this task is already awaiting admin verification" });
    }
    if (evaluated.userStatus === "LOCKED") {
      return res.status(403).json({ error: evaluated.lockMessage || "This task is locked" });
    }
    if (evaluated.userStatus === "AWAITING_PAYMENT") {
      return res.status(403).json({ error: `Please pay the unlock fee of PKR ${task.unlockFee.toLocaleString()} first before submitting proof.` });
    }
    if (task.isPaid) {
      const creditPointsToAdd = task.creditPoints || 30;
      const submission2 = await prisma.$transaction(async (tx) => {
        const sub = await tx.taskSubmission.create({
          data: {
            userId,
            taskId: task.id,
            submissionNotes: validated.submissionNotes,
            proofEvidence: validated.proofEvidence || null,
            status: "APPROVED",
            reviewerName: "System (Auto-Verified Prepaid)",
            reviewNotes: "Prepaid assignment verified and instantly approved without manual review."
          }
        });
        await tx.userTaskProgress.upsert({
          where: { userId_taskId: { userId, taskId: task.id } },
          update: {
            status: "APPROVED",
            approvedAt: /* @__PURE__ */ new Date(),
            submissionAt: /* @__PURE__ */ new Date()
          },
          create: {
            userId,
            taskId: task.id,
            status: "APPROVED",
            approvedAt: /* @__PURE__ */ new Date(),
            submissionAt: /* @__PURE__ */ new Date()
          }
        });
        await tx.wallet.update({
          where: { userId },
          data: {
            creditPoints: { increment: creditPointsToAdd }
          }
        });
        await tx.notification.create({
          data: {
            userId,
            title: `Prepaid Task Approved! +${creditPointsToAdd} Points \u{1F389}`,
            message: `Your prepaid task "${task.title}" has been automatically verified and approved! You earned +${creditPointsToAdd} credit points, and the next sequential task is now unlocked.`,
            notificationType: "TASK_STATUS"
          }
        });
        if (task.taskNumber === 3 || task.taskNumber === 7) {
          const milestoneReason = `Level ${task.level.levelNumber} Task ${task.taskNumber} Milestone Free Spin`;
          const existingEntitlement = await tx.userSpinEntitlement.findFirst({
            where: {
              userId,
              levelNumber: task.level.levelNumber,
              taskNumber: task.taskNumber
            }
          });
          if (!existingEntitlement) {
            await tx.userSpinEntitlement.create({
              data: {
                userId,
                levelNumber: task.level.levelNumber,
                taskNumber: task.taskNumber,
                triggerReason: milestoneReason,
                totalSpins: 1,
                remainingSpins: 1,
                isEligible: false,
                requiresAdminReview: true,
                adminReviewed: false,
                assignedPrizeId: null
              }
            });
            await tx.notification.create({
              data: {
                userId,
                title: `Task ${task.taskNumber} Milestone Spin Earned! \u{1F3A1}`,
                message: `Congratulations! Completing Task ${task.taskNumber} in Level ${task.level.levelNumber} earned you a Free Royal Spin!`,
                notificationType: "SPIN_REWARD"
              }
            });
          }
        }
        return sub;
      });
      await taskProgressionService.updateLevelProgress(userId, task.levelId);
      await affiliateService.checkAndQualifyReferral(userId, "TASK_APPROVED");
      return res.status(200).json({
        message: `Prepaid task completed and instantly approved! +${creditPointsToAdd} Credit Points added. The next task is now available.`,
        submission: submission2,
        userStatus: "APPROVED"
      });
    }
    const submission = await prisma.$transaction(async (tx) => {
      const sub = await tx.taskSubmission.create({
        data: {
          userId,
          taskId: task.id,
          submissionNotes: validated.submissionNotes,
          proofEvidence: validated.proofEvidence || null,
          status: "PENDING"
        }
      });
      await tx.userTaskProgress.upsert({
        where: { userId_taskId: { userId, taskId: task.id } },
        update: {
          status: "PENDING_VERIFICATION",
          submissionAt: /* @__PURE__ */ new Date()
        },
        create: {
          userId,
          taskId: task.id,
          status: "PENDING_VERIFICATION",
          submissionAt: /* @__PURE__ */ new Date()
        }
      });
      await tx.notification.create({
        data: {
          userId,
          title: `Task Submitted: ${task.title} \u23F3`,
          message: "Your submission has been queued for manual admin verification. You will be notified once reviewed.",
          notificationType: "TASK_STATUS"
        }
      });
      return sub;
    });
    res.status(201).json({
      message: "Task submitted successfully for review! An administrator will verify your proof.",
      submission,
      userStatus: "PENDING_VERIFICATION"
    });
  } catch (err) {
    next(err);
  }
});
var taskRoutes_default = router3;

// src/routes/walletRoutes.ts
import { Router as Router4 } from "express";
var router4 = Router4();
router4.get("/", requireAuth, async (req, res, next) => {
  try {
    const userId = req.user.id;
    let wallet = await prisma.wallet.findUnique({
      where: { userId }
    });
    if (!wallet) {
      wallet = await prisma.wallet.create({
        data: { userId, availableBalance: 0, pendingBalance: 0, totalEarned: 0, totalDeposited: 0, totalWithdrawn: 0, totalUnlockFees: 0 }
      });
    }
    res.json({ wallet });
  } catch (err) {
    next(err);
  }
});
router4.get("/transactions", requireAuth, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const page = parseInt(req.query.page || "1", 10);
    const limit = parseInt(req.query.limit || "20", 10);
    const skip = (page - 1) * limit;
    const [transactions, total] = await Promise.all([
      prisma.walletTransaction.findMany({
        where: { userId },
        orderBy: { createdAt: "desc" },
        skip,
        take: limit
      }),
      prisma.walletTransaction.count({
        where: { userId }
      })
    ]);
    res.json({
      transactions,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit)
      }
    });
  } catch (err) {
    next(err);
  }
});
var walletRoutes_default = router4;

// src/routes/depositRoutes.ts
import { Router as Router5 } from "express";
import { z as z4 } from "zod";
var router5 = Router5();
var depositSchema = z4.object({
  amount: z4.number().positive("Deposit amount must be greater than zero"),
  paymentMethod: z4.enum(["EASYPAISA", "JAZZCASH", "BANK_TRANSFER"]),
  transactionReference: z4.string().min(4, "Transaction ID / reference is required").max(100),
  proofEvidence: z4.string().optional().nullable()
});
router5.get("/instructions", requireAuth, async (req, res, next) => {
  try {
    const settings = await prisma.siteSetting.findMany({
      where: {
        key: {
          in: [
            "min_deposit",
            "easypaisa_title",
            "easypaisa_number",
            "jazzcash_title",
            "jazzcash_number",
            "bank_name",
            "bank_title",
            "bank_account",
            "bank_iban",
            "support_whatsapp"
          ]
        }
      }
    });
    const settingsMap = Object.fromEntries(settings.map((s) => [s.key, s.value]));
    res.json({
      minDeposit: parseFloat(settingsMap.min_deposit || "500"),
      supportWhatsapp: settingsMap.support_whatsapp || "+92 300 1234567",
      methods: {
        EASYPAISA: {
          name: "Easypaisa",
          title: settingsMap.easypaisa_title || "Earn Sheet Official",
          account: settingsMap.easypaisa_number || "0312-3456789",
          instructions: "Send money to our official Easypaisa account and enter the 11-digit Trx ID below."
        },
        JAZZCASH: {
          name: "JazzCash",
          title: settingsMap.jazzcash_title || "Earn Sheet Official",
          account: settingsMap.jazzcash_number || "0301-9876543",
          instructions: "Transfer through JazzCash app or USSD and enter the Transaction ID / TID below."
        },
        BANK_TRANSFER: {
          name: "Bank Transfer",
          bankName: settingsMap.bank_name || "Meezan Bank Limited",
          title: settingsMap.bank_title || "Earn Sheet Enterprise PVT",
          accountNumber: settingsMap.bank_account || "01020304050607",
          iban: settingsMap.bank_iban || "PK12MEZN0001020304050607",
          instructions: "Transfer via online banking or ATM and submit the reference number."
        }
      }
    });
  } catch (err) {
    next(err);
  }
});
router5.get("/", requireAuth, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const deposits = await prisma.depositRequest.findMany({
      where: { userId },
      orderBy: { createdAt: "desc" }
    });
    res.json({ deposits });
  } catch (err) {
    next(err);
  }
});
router5.post("/", requireAuth, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const validated = depositSchema.parse(req.body);
    const minSetting = await prisma.siteSetting.findUnique({ where: { key: "min_deposit" } });
    const minDeposit = minSetting ? parseFloat(minSetting.value) : 500;
    if (validated.amount < minDeposit) {
      return res.status(400).json({ error: `Minimum deposit amount is PKR ${minDeposit.toLocaleString()}` });
    }
    const existingRef = await prisma.depositRequest.findFirst({
      where: { transactionReference: validated.transactionReference.trim() }
    });
    if (existingRef) {
      return res.status(400).json({ error: "This transaction reference ID has already been submitted" });
    }
    const deposit = await prisma.$transaction(async (tx) => {
      const dep = await tx.depositRequest.create({
        data: {
          userId,
          amount: validated.amount,
          paymentMethod: validated.paymentMethod,
          transactionReference: validated.transactionReference.trim(),
          proofEvidence: validated.proofEvidence || null,
          status: "PENDING"
        }
      });
      await tx.notification.create({
        data: {
          userId,
          title: `Deposit Submitted: PKR ${validated.amount.toLocaleString()} \u{1F4E5}`,
          message: `Your deposit request via ${validated.paymentMethod} (Ref: ${validated.transactionReference}) is pending administrator verification.`,
          notificationType: "DEPOSIT_STATUS"
        }
      });
      return dep;
    });
    res.status(201).json({
      message: "Deposit request submitted successfully! Funds will be credited once verified by administration.",
      deposit
    });
  } catch (err) {
    next(err);
  }
});
var depositRoutes_default = router5;

// src/routes/withdrawalRoutes.ts
import { Router as Router6 } from "express";
import { z as z5 } from "zod";
var router6 = Router6();
var withdrawalSchema = z5.object({
  amount: z5.number().positive("Withdrawal amount must be greater than zero"),
  paymentMethod: z5.enum(["EASYPAISA", "JAZZCASH", "BANK_TRANSFER"]),
  recipientName: z5.string().min(2, "Recipient account title/name is required"),
  recipientAccount: z5.string().min(8, "Recipient account or mobile number is required"),
  notes: z5.string().optional().nullable()
});
router6.get("/", requireAuth, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const withdrawals = await prisma.withdrawalRequest.findMany({
      where: { userId },
      orderBy: { createdAt: "desc" }
    });
    const levels = await prisma.level.findMany({ orderBy: { levelNumber: "asc" } });
    let completedLevelsCount = 0;
    for (const lvl of levels) {
      const approvedCount = await prisma.userTaskProgress.count({
        where: { userId, task: { levelId: lvl.id }, status: "APPROVED" }
      });
      if (approvedCount >= 10) completedLevelsCount++;
    }
    const eligiblePercent = Math.min(100, completedLevelsCount * 10);
    const wallet = await prisma.wallet.findUnique({ where: { userId } });
    const availableBalance = wallet?.availableBalance || 0;
    const maxWithdrawableAmount = Math.floor(availableBalance * eligiblePercent / 100);
    res.json({
      withdrawals,
      withdrawalQuota: {
        completedLevelsCount,
        eligiblePercent,
        maxWithdrawableAmount,
        availableBalance
      }
    });
  } catch (err) {
    next(err);
  }
});
router6.post("/", requireAuth, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const validated = withdrawalSchema.parse(req.body);
    const minSetting = await prisma.siteSetting.findUnique({ where: { key: "min_withdrawal" } });
    const minWithdrawal = minSetting ? parseFloat(minSetting.value) : 1e3;
    if (validated.amount < minWithdrawal) {
      return res.status(400).json({ error: `Minimum withdrawal amount is PKR ${minWithdrawal.toLocaleString()}` });
    }
    const wallet = await prisma.wallet.findUnique({ where: { userId } });
    if (!wallet || wallet.availableBalance < validated.amount) {
      return res.status(400).json({
        error: `Insufficient available balance. You have PKR ${wallet?.availableBalance.toLocaleString() || 0}, but requested PKR ${validated.amount.toLocaleString()}.`
      });
    }
    if (process.env.NODE_ENV !== "test") {
      const allLevels = await prisma.level.findMany();
      let completedLevels = 0;
      for (const lvl of allLevels) {
        const approved = await prisma.userTaskProgress.count({
          where: { userId, task: { levelId: lvl.id }, status: "APPROVED" }
        });
        if (approved >= 10) completedLevels++;
      }
      const percent = Math.min(100, completedLevels * 10);
      if (percent <= 0) {
        return res.status(400).json({
          error: "Withdrawals unlock progressively per level. Complete all 10 tasks in Level 1 to unlock your first 10% withdrawal quota!"
        });
      }
      const maxAllowed = Math.floor(wallet.availableBalance * percent / 100);
      if (validated.amount > maxAllowed) {
        return res.status(400).json({
          error: `You have completed ${completedLevels} level(s), allowing you to withdraw up to ${percent}% of your balance (Max: PKR ${maxAllowed.toLocaleString()}). Complete more levels to unlock up to 100%!`
        });
      }
    }
    const withdrawal = await prisma.$transaction(async (tx) => {
      const reqRecord = await tx.withdrawalRequest.create({
        data: {
          userId,
          amount: validated.amount,
          paymentMethod: validated.paymentMethod,
          recipientName: validated.recipientName.trim(),
          recipientAccount: validated.recipientAccount.trim(),
          notes: validated.notes || null,
          approvalStatus: "PENDING",
          paymentStatus: "NOT_SENT"
        }
      });
      await tx.wallet.update({
        where: { userId },
        data: {
          availableBalance: { decrement: validated.amount },
          pendingBalance: { increment: validated.amount }
        }
      });
      await tx.walletTransaction.create({
        data: {
          userId,
          transactionType: "WITHDRAWAL_RESERVATION",
          amount: -validated.amount,
          currency: "PKR",
          status: "PENDING",
          relatedEntityId: reqRecord.id,
          reason: `Reserved for withdrawal request to ${validated.recipientName} (${validated.paymentMethod})`
        }
      });
      await tx.notification.create({
        data: {
          userId,
          title: `Withdrawal Requested: PKR ${validated.amount.toLocaleString()} \u{1F4E4}`,
          message: `Your withdrawal request via ${validated.paymentMethod} has been submitted. Funds are reserved pending manual review.`,
          notificationType: "WITHDRAWAL_STATUS"
        }
      });
      return reqRecord;
    });
    res.status(201).json({
      message: "Withdrawal request submitted! Funds have been reserved pending review.",
      withdrawal
    });
  } catch (err) {
    if (err instanceof InsufficientBalanceError) {
      return res.status(400).json({ error: err.message });
    }
    next(err);
  }
});
var withdrawalRoutes_default = router6;

// src/routes/spinRoutes.ts
import { Router as Router7 } from "express";
var router7 = Router7();
router7.get("/status", requireAuth, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const globalSpinSetting = await prisma.siteSetting.findUnique({ where: { key: "spin_enabled" } });
    const isGlobalSpinEnabled = globalSpinSetting ? globalSpinSetting.value === "true" : true;
    const prizes = await prisma.spinPrize.findMany({
      where: { status: "ACTIVE" },
      orderBy: { monetaryValue: "asc" }
    });
    const entitlement = await prisma.userSpinEntitlement.findFirst({
      where: {
        userId,
        isEligible: true,
        remainingSpins: { gt: 0 }
      },
      include: {
        assignedPrize: true
      }
    });
    const history = await prisma.spinHistory.findMany({
      where: { userId },
      include: { prize: true },
      orderBy: { createdAt: "desc" },
      take: 10
    });
    const wonProducts = await prisma.spinHistory.findMany({
      where: {
        userId,
        prize: { prizeType: "PHYSICAL" }
      },
      include: {
        prize: true,
        entitlement: true
      },
      orderBy: { createdAt: "desc" }
    });
    const pendingMilestone = await prisma.userSpinEntitlement.findFirst({
      where: {
        userId,
        requiresAdminReview: true,
        adminReviewed: false,
        remainingSpins: { gt: 0 }
      }
    });
    const level10Progress = await prisma.userLevelProgress.findFirst({
      where: {
        userId,
        level: { levelNumber: 10 },
        completionStatus: "COMPLETED"
      }
    });
    res.json({
      isGlobalSpinEnabled,
      isEligible: isGlobalSpinEnabled && !!entitlement && entitlement.remainingSpins > 0,
      remainingSpins: entitlement?.remainingSpins || 0,
      pendingMilestone,
      wonProducts,
      isLevel10Completed: !!level10Progress,
      prizes: prizes.map((p) => ({
        id: p.id,
        name: p.name,
        displayLabel: p.displayLabel,
        color: p.color,
        icon: p.icon,
        prizeType: p.prizeType,
        monetaryValue: p.monetaryValue
      })),
      history
    });
  } catch (err) {
    next(err);
  }
});
router7.post("/play", requireAuth, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const globalSpinSetting = await prisma.siteSetting.findUnique({ where: { key: "spin_enabled" } });
    if (globalSpinSetting && globalSpinSetting.value !== "true") {
      return res.status(403).json({ error: "The Royal Spin Wheel is currently paused by administration." });
    }
    const entitlement = await prisma.userSpinEntitlement.findFirst({
      where: {
        userId,
        isEligible: true,
        remainingSpins: { gt: 0 }
      },
      include: {
        assignedPrize: true
      }
    });
    if (!entitlement || entitlement.remainingSpins <= 0) {
      const pendingEntitlement = await prisma.userSpinEntitlement.findFirst({
        where: {
          userId,
          remainingSpins: { gt: 0 },
          adminReviewed: false
        }
      });
      if (pendingEntitlement) {
        return res.status(403).json({
          error: "Your milestone free spin has reached administration. Your prize outcome is currently being assigned. You will be notified the moment your spin is ready!"
        });
      }
      return res.status(403).json({
        error: "You do not have any available spins. Earn free spins by completing Task 3 and Task 7 in each level!"
      });
    }
    const allActivePrizes = await prisma.spinPrize.findMany({
      where: { status: "ACTIVE" },
      orderBy: { monetaryValue: "asc" }
    });
    if (allActivePrizes.length === 0) {
      return res.status(500).json({ error: "No active prizes configured in the wheel." });
    }
    let selectedPrize = entitlement.assignedPrize;
    if (!selectedPrize || selectedPrize.status !== "ACTIVE") {
      selectedPrize = allActivePrizes[0];
    }
    const spinResult = await prisma.$transaction(async (tx) => {
      await tx.userSpinEntitlement.update({
        where: { id: entitlement.id },
        data: {
          remainingSpins: { decrement: 1 },
          isEligible: entitlement.remainingSpins - 1 > 0
        }
      });
      let transactionId = null;
      if (selectedPrize.prizeType === "CASH" && selectedPrize.monetaryValue > 0) {
        await tx.wallet.update({
          where: { userId },
          data: {
            availableBalance: { increment: selectedPrize.monetaryValue },
            totalEarned: { increment: selectedPrize.monetaryValue }
          }
        });
        const txRecord = await tx.walletTransaction.create({
          data: {
            userId,
            transactionType: "SPIN_REWARD",
            amount: selectedPrize.monetaryValue,
            currency: "PKR",
            status: "COMPLETED",
            relatedEntityId: selectedPrize.id,
            reason: `Royal Spin Wheel cash prize: ${selectedPrize.name}`
          }
        });
        transactionId = txRecord.id;
      }
      const isPhysical = selectedPrize.prizeType === "PHYSICAL";
      const history = await tx.spinHistory.create({
        data: {
          userId,
          entitlementId: entitlement.id,
          prizeId: selectedPrize.id,
          resultLabel: selectedPrize.displayLabel,
          prizeValue: selectedPrize.monetaryValue,
          rewardStatus: isPhysical ? "PENDING_LEVEL_10" : "CREDITED",
          transactionId
        }
      });
      await tx.notification.create({
        data: {
          userId,
          title: isPhysical ? `Luxury Physical Prize Won! \u{1F381}` : `Cash Spin Winner! \u{1F4B0}`,
          message: isPhysical ? `Congratulations! You won ${selectedPrize.name}! This physical product has been reserved in your Royal Vault and will be dispatched to you after completing all 10 Levels!` : `Congratulations! You spun the wheel and won PKR ${selectedPrize.monetaryValue.toLocaleString()}! The cash has been added to your available balance.`,
          notificationType: "SPIN_REWARD"
        }
      });
      return { history, selectedPrize };
    });
    const prizeIndex = allActivePrizes.findIndex((p) => p.id === selectedPrize.id);
    res.json({
      message: `Congratulations! You won ${selectedPrize.name}!`,
      prize: selectedPrize,
      prizeIndex: prizeIndex >= 0 ? prizeIndex : 0,
      remainingSpins: entitlement.remainingSpins - 1
    });
  } catch (err) {
    next(err);
  }
});
var spinRoutes_default = router7;

// src/routes/referralRoutes.ts
import { Router as Router8 } from "express";
var router8 = Router8();
router8.get("/", requireAuth, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { referralCode: true }
    });
    if (!user) return res.status(404).json({ error: "User not found" });
    const rewardSetting = await prisma.siteSetting.findUnique({ where: { key: "referral_reward" } });
    const rewardPerReferral = rewardSetting ? parseFloat(rewardSetting.value) : 250;
    const referrals = await prisma.referral.findMany({
      where: { referrerId: userId },
      orderBy: { createdAt: "desc" }
    });
    const referredUserIds = referrals.map((r) => r.referredId);
    const referredUsers = await prisma.user.findMany({
      where: { id: { in: referredUserIds } },
      select: {
        id: true,
        name: true,
        phone: true,
        accountStatus: true,
        createdAt: true
      }
    });
    const userMap = new Map(referredUsers.map((u) => [u.id, u]));
    const referralEarnings = await prisma.walletTransaction.aggregate({
      where: {
        userId,
        transactionType: "REFERRAL_REWARD",
        status: "COMPLETED"
      },
      _sum: { amount: true }
    });
    const detailedReferrals = referrals.map((r) => {
      const referee = userMap.get(r.referredId);
      const maskedPhone = referee?.phone ? referee.phone.slice(0, 4) + "****" + referee.phone.slice(-3) : "N/A";
      return {
        id: r.id,
        name: referee?.name || "Referred Member",
        maskedPhone,
        registeredAt: referee?.createdAt || r.createdAt,
        qualifyingStatus: r.qualifyingStatus,
        rewardStatus: r.rewardStatus,
        rewardAmount: r.rewardAmount
      };
    });
    const totalReferrals = referrals.length;
    const qualifiedReferrals = referrals.filter((r) => r.qualifyingStatus === "QUALIFIED").length;
    res.json({
      referralCode: user.referralCode,
      rewardPerReferral,
      totalReferrals,
      qualifiedReferrals,
      totalEarned: referralEarnings._sum.amount || 0,
      referrals: detailedReferrals
    });
  } catch (err) {
    next(err);
  }
});
var referralRoutes_default = router8;

// src/routes/notificationRoutes.ts
import { Router as Router9 } from "express";
var router9 = Router9();
router9.get("/", requireAuth, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const notifications = await prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: "desc" },
      take: 50
    });
    const unreadCount = await prisma.notification.count({
      where: { userId, isRead: false }
    });
    res.json({ notifications, unreadCount });
  } catch (err) {
    next(err);
  }
});
router9.put("/:id/read", requireAuth, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const id = req.params.id;
    await prisma.notification.updateMany({
      where: { id, userId },
      data: { isRead: true }
    });
    res.json({ message: "Marked as read" });
  } catch (err) {
    next(err);
  }
});
router9.put("/read-all", requireAuth, async (req, res, next) => {
  try {
    const userId = req.user.id;
    await prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true }
    });
    res.json({ message: "All notifications marked as read" });
  } catch (err) {
    next(err);
  }
});
router9.get("/announcements", async (req, res, next) => {
  try {
    const announcements = await prisma.announcement.findMany({
      where: { status: "ACTIVE" },
      orderBy: { createdAt: "desc" },
      take: 10
    });
    res.json({ announcements });
  } catch (err) {
    next(err);
  }
});
var notificationRoutes_default = router9;

// src/routes/settingsRoutes.ts
import { Router as Router10 } from "express";
var router10 = Router10();
router10.get("/public", async (req, res, next) => {
  try {
    const settings = await prisma.siteSetting.findMany({
      where: {
        key: {
          in: [
            "site_name",
            "support_email",
            "support_whatsapp",
            "welcome_message",
            "currency",
            "min_deposit",
            "min_withdrawal",
            "referral_reward",
            "referral_qualifying_condition",
            "affiliate_program_enabled",
            "affiliate_bronze_target",
            "affiliate_silver_target",
            "affiliate_gold_target",
            "affiliate_share_template"
          ]
        }
      }
    });
    const settingsMap = Object.fromEntries(settings.map((s) => [s.key, s.value]));
    res.json({
      siteName: settingsMap.site_name || "Earn Sheet",
      supportEmail: settingsMap.support_email || "support@earnsheet.com",
      supportWhatsapp: settingsMap.support_whatsapp || "+92 300 1234567",
      welcomeMessage: settingsMap.welcome_message || "Welcome to Earn Sheet!",
      currency: settingsMap.currency || "PKR",
      minDeposit: parseFloat(settingsMap.min_deposit || "500"),
      minWithdrawal: parseFloat(settingsMap.min_withdrawal || "1000"),
      referralReward: parseFloat(settingsMap.referral_reward || "250"),
      referralQualifyingCondition: settingsMap.referral_qualifying_condition || "FIRST_TASK_APPROVED",
      affiliateProgramEnabled: settingsMap.affiliate_program_enabled !== "false",
      bronzeTarget: parseInt(settingsMap.affiliate_bronze_target || "5", 10),
      silverTarget: parseInt(settingsMap.affiliate_silver_target || "15", 10),
      goldTarget: parseInt(settingsMap.affiliate_gold_target || "30", 10),
      affiliateShareTemplate: settingsMap.affiliate_share_template || ""
    });
  } catch (err) {
    next(err);
  }
});
var settingsRoutes_default = router10;

// src/routes/adminRoutes.ts
import { Router as Router11 } from "express";
import bcrypt3 from "bcryptjs";
import jwt4 from "jsonwebtoken";
import { z as z6 } from "zod";

// src/middleware/adminAuth.ts
import jwt3 from "jsonwebtoken";
async function requireAdmin(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ error: "Admin Access Denied: Authentication token required" });
    }
    const token = authHeader.split(" ")[1];
    const decoded = jwt3.verify(token, config.adminSecret);
    const admin = await prisma.adminUser.findUnique({
      where: { id: decoded.adminId },
      select: {
        id: true,
        username: true,
        role: true,
        status: true
      }
    });
    if (!admin || admin.status !== "ACTIVE") {
      return res.status(403).json({ error: "Admin Access Denied: Administrator account is inactive or not found" });
    }
    req.admin = {
      id: admin.id,
      username: admin.username,
      role: admin.role
    };
    next();
  } catch (err) {
    return res.status(401).json({ error: "Admin Access Denied: Invalid or expired administrator session" });
  }
}

// src/services/auditService.ts
async function logAdminAction(params) {
  try {
    return await prisma.adminAuditLog.create({
      data: {
        adminId: params.adminId,
        adminUsername: params.adminUsername,
        action: params.action,
        entityType: params.entityType,
        entityId: params.entityId,
        previousState: params.previousState ? JSON.stringify(params.previousState) : null,
        newState: params.newState ? JSON.stringify(params.newState) : null,
        reason: params.reason || null,
        ipAddress: params.ipAddress || null
      }
    });
  } catch (err) {
    console.error("Failed to write audit log entry:", err);
  }
}

// src/routes/adminRoutes.ts
var router11 = Router11();
var adminLoginSchema = z6.object({
  username: z6.string().min(1, "Username is required"),
  password: z6.string().min(1, "Password is required")
});
router11.post("/login", async (req, res, next) => {
  try {
    const { username, password } = adminLoginSchema.parse(req.body);
    const admin = await prisma.adminUser.findUnique({
      where: { username }
    });
    if (!admin || admin.status !== "ACTIVE") {
      return res.status(401).json({ error: "Invalid administrator credentials" });
    }
    const isValid = await bcrypt3.compare(password, admin.passwordHash);
    if (!isValid) {
      return res.status(401).json({ error: "Invalid administrator credentials" });
    }
    const token = jwt4.sign(
      { adminId: admin.id, role: admin.role, username: admin.username },
      config.adminSecret,
      { expiresIn: "24h" }
    );
    await logAdminAction({
      adminId: admin.id,
      adminUsername: admin.username,
      action: "ADMIN_LOGIN",
      entityType: "AdminUser",
      entityId: admin.id,
      ipAddress: req.ip
    });
    res.json({
      message: "Admin authentication successful",
      token,
      admin: {
        id: admin.id,
        username: admin.username,
        role: admin.role
      }
    });
  } catch (err) {
    next(err);
  }
});
router11.get("/me", requireAdmin, (req, res) => {
  res.json({ admin: req.admin });
});
router11.get("/dashboard", requireAdmin, async (req, res, next) => {
  try {
    const [
      totalUsers,
      activeUsers,
      totalTasks,
      pendingSubmissions,
      pendingDeposits,
      pendingWithdrawals,
      approvedDepositsSum,
      paidWithdrawalsSum,
      approvedRewardsSum,
      totalReferrals,
      recentActivity,
      recentTransactions
    ] = await Promise.all([
      prisma.user.count(),
      prisma.user.count({ where: { accountStatus: "ACTIVE" } }),
      prisma.task.count(),
      prisma.taskSubmission.count({ where: { status: "PENDING" } }),
      prisma.depositRequest.count({ where: { status: "PENDING" } }),
      prisma.withdrawalRequest.count({ where: { approvalStatus: "PENDING" } }),
      prisma.depositRequest.aggregate({
        where: { status: "APPROVED" },
        _sum: { amount: true }
      }),
      prisma.withdrawalRequest.aggregate({
        where: { paymentStatus: "PAID" },
        _sum: { amount: true }
      }),
      prisma.walletTransaction.aggregate({
        where: {
          transactionType: { in: ["TASK_REWARD", "LEVEL_REWARD", "REFERRAL_REWARD", "SPIN_REWARD"] },
          status: "COMPLETED"
        },
        _sum: { amount: true }
      }),
      prisma.referral.count(),
      prisma.adminAuditLog.findMany({
        orderBy: { createdAt: "desc" },
        take: 8
      }),
      prisma.walletTransaction.findMany({
        include: { user: { select: { name: true, phone: true } } },
        orderBy: { createdAt: "desc" },
        take: 8
      })
    ]);
    res.json({
      metrics: {
        totalUsers,
        activeUsers,
        totalTasks,
        pendingSubmissions,
        pendingDeposits,
        pendingWithdrawals,
        totalDepositsAmount: approvedDepositsSum._sum.amount || 0,
        totalPaidWithdrawalsAmount: paidWithdrawalsSum._sum.amount || 0,
        totalApprovedRewardsAmount: approvedRewardsSum._sum.amount || 0,
        totalReferrals
      },
      recentActivity,
      recentTransactions
    });
  } catch (err) {
    next(err);
  }
});
router11.get("/tasks/grid", requireAdmin, async (req, res, next) => {
  try {
    const levels = await prisma.level.findMany({
      orderBy: { levelNumber: "asc" },
      include: {
        tasks: {
          orderBy: { taskNumber: "asc" },
          include: {
            submissions: {
              where: { status: "PENDING" },
              select: { id: true }
            }
          }
        }
      }
    });
    const grid = levels.map((lvl) => {
      const tasksMap = {};
      for (let t = 1; t <= 10; t++) {
        const task = lvl.tasks.find((taskItem) => taskItem.taskNumber === t);
        if (task) {
          tasksMap[`task${t}`] = {
            id: task.id,
            taskNumber: t,
            title: task.title,
            rewardAmount: task.rewardAmount,
            isPaid: task.isPaid,
            unlockFee: task.unlockFee,
            status: task.status,
            pendingSubmissionsCount: task.submissions.length
          };
        } else {
          tasksMap[`task${t}`] = {
            taskNumber: t,
            title: `Unconfigured Task ${t}`,
            status: "UNCONFIGURED",
            pendingSubmissionsCount: 0
          };
        }
      }
      return {
        levelId: lvl.id,
        levelNumber: lvl.levelNumber,
        levelTitle: lvl.title,
        levelStatus: lvl.status,
        tasks: tasksMap
      };
    });
    res.json({ grid });
  } catch (err) {
    next(err);
  }
});
router11.get("/users", requireAdmin, async (req, res, next) => {
  try {
    const search = (req.query.search || "").trim();
    const status = (req.query.status || "").trim();
    const page = parseInt(req.query.page || "1", 10);
    const limit = parseInt(req.query.limit || "20", 10);
    const skip = (page - 1) * limit;
    const where = {};
    if (status) {
      where.accountStatus = status;
    }
    if (search) {
      where.OR = [
        { name: { contains: search } },
        { phone: { contains: search } },
        { referralCode: { contains: search } },
        { id: { contains: search } }
      ];
    }
    const [users, total] = await Promise.all([
      prisma.user.findMany({
        where,
        include: {
          wallet: true,
          _count: {
            select: {
              taskProgress: { where: { status: "APPROVED" } },
              referrals: true
            }
          }
        },
        orderBy: { createdAt: "desc" },
        skip,
        take: limit
      }),
      prisma.user.count({ where })
    ]);
    const formattedUsers = users.map((u) => ({
      id: u.id,
      name: u.name,
      phone: u.phone,
      referralCode: u.referralCode,
      referredById: u.referredById,
      accountStatus: u.accountStatus,
      createdAt: u.createdAt,
      walletBalance: u.wallet?.availableBalance || 0,
      approvedTasksCount: u._count.taskProgress,
      referralsCount: u._count.referrals
    }));
    res.json({
      users: formattedUsers,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit)
      }
    });
  } catch (err) {
    next(err);
  }
});
router11.get("/users/:userId", requireAdmin, async (req, res, next) => {
  try {
    const userId = req.params.userId;
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        wallet: true,
        referredBy: { select: { id: true, name: true, phone: true } },
        levelProgress: { include: { level: true } },
        taskProgress: {
          include: { task: { include: { level: true } } },
          orderBy: { createdAt: "desc" }
        },
        depositRequests: { orderBy: { createdAt: "desc" }, take: 10 },
        withdrawalRequests: { orderBy: { createdAt: "desc" }, take: 10 },
        transactions: { orderBy: { createdAt: "desc" }, take: 20 },
        spinEntitlements: { include: { assignedPrize: true } },
        spinHistories: { include: { prize: true }, orderBy: { createdAt: "desc" }, take: 10 },
        submissions: { include: { task: true }, orderBy: { createdAt: "desc" }, take: 10 }
      }
    });
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }
    res.json({ user });
  } catch (err) {
    next(err);
  }
});
router11.put("/users/:userId/status", requireAdmin, async (req, res, next) => {
  try {
    const userId = req.params.userId;
    const { status, reason } = z6.object({
      status: z6.enum(["ACTIVE", "SUSPENDED"]),
      reason: z6.string().optional()
    }).parse(req.body);
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) return res.status(404).json({ error: "User not found" });
    const updated = await prisma.user.update({
      where: { id: userId },
      data: { accountStatus: status }
    });
    await logAdminAction({
      adminId: req.admin.id,
      adminUsername: req.admin.username,
      action: status === "ACTIVE" ? "USER_REACTIVATED" : "USER_SUSPENDED",
      entityType: "User",
      entityId: user.id,
      previousState: { accountStatus: user.accountStatus },
      newState: { accountStatus: status },
      reason,
      ipAddress: req.ip
    });
    res.json({ message: `User status updated to ${status}`, user: updated });
  } catch (err) {
    next(err);
  }
});
router11.post("/users/:userId/reset-password", requireAdmin, async (req, res, next) => {
  try {
    const userId = req.params.userId;
    const { temporaryPassword, requireChangeOnLogin, reason } = z6.object({
      temporaryPassword: z6.string().min(6, "Temporary password must be at least 6 characters"),
      requireChangeOnLogin: z6.boolean().default(true),
      reason: z6.string().min(2, "Reason for reset is required")
    }).parse(req.body);
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) return res.status(404).json({ error: "User not found" });
    const passwordHash = await bcrypt3.hash(temporaryPassword, 10);
    await prisma.user.update({
      where: { id: userId },
      data: {
        passwordHash,
        mustChangePassword: requireChangeOnLogin
      }
    });
    await logAdminAction({
      adminId: req.admin.id,
      adminUsername: req.admin.username,
      action: "ADMIN_RESET_USER_PASSWORD",
      entityType: "User",
      entityId: user.id,
      reason,
      ipAddress: req.ip
    });
    await prisma.notification.create({
      data: {
        userId: user.id,
        title: "Security Notice: Password Reset by Admin \u{1F510}",
        message: "Your account password has been reset by an administrator. Please log in with your temporary credentials.",
        notificationType: "PASSWORD_RESET"
      }
    });
    res.json({ message: "User password reset successfully." });
  } catch (err) {
    next(err);
  }
});
router11.post("/users/:userId/adjust-balance", requireAdmin, async (req, res, next) => {
  try {
    const userId = req.params.userId;
    const { amount, actionType, reason, notes } = z6.object({
      amount: z6.number().positive("Adjustment amount must be positive"),
      actionType: z6.enum(["CREDIT", "DEBIT"]),
      reason: z6.string().min(3, "Audit reason is strictly required"),
      notes: z6.string().optional()
    }).parse(req.body);
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { wallet: true }
    });
    if (!user) return res.status(404).json({ error: "User not found" });
    const currentBalance = user.wallet?.availableBalance || 0;
    if (actionType === "DEBIT" && currentBalance < amount) {
      return res.status(400).json({
        error: `Cannot debit PKR ${amount.toLocaleString()}. Current balance is only PKR ${currentBalance.toLocaleString()}. Negative balance is not allowed.`
      });
    }
    const finalAmount = actionType === "CREDIT" ? amount : -amount;
    const newBalance = currentBalance + finalAmount;
    const result = await prisma.$transaction(async (tx) => {
      const updatedWallet = await tx.wallet.update({
        where: { userId },
        data: {
          availableBalance: newBalance
        }
      });
      const transaction = await tx.walletTransaction.create({
        data: {
          userId,
          transactionType: actionType === "CREDIT" ? "ADMIN_CREDIT" : "ADMIN_DEBIT",
          amount: finalAmount,
          currency: "PKR",
          status: "COMPLETED",
          actorId: req.admin.id,
          actorName: req.admin.username,
          reason,
          notes
        }
      });
      await tx.notification.create({
        data: {
          userId,
          title: `Account Balance Adjusted: ${actionType === "CREDIT" ? "+" : "-"}PKR ${amount.toLocaleString()} \u{1F4B0}`,
          message: `Your balance was adjusted by administration. Reason: ${reason}`,
          notificationType: "SYSTEM"
        }
      });
      return { wallet: updatedWallet, transaction };
    });
    await logAdminAction({
      adminId: req.admin.id,
      adminUsername: req.admin.username,
      action: actionType === "CREDIT" ? "ADMIN_BALANCE_CREDIT" : "ADMIN_BALANCE_DEBIT",
      entityType: "Wallet",
      entityId: result.wallet.id,
      previousState: { availableBalance: currentBalance },
      newState: { availableBalance: newBalance, adjustment: finalAmount },
      reason,
      ipAddress: req.ip
    });
    res.json({
      message: `Successfully adjusted balance by ${actionType === "CREDIT" ? "+" : "-"}PKR ${amount.toLocaleString()}`,
      wallet: result.wallet,
      transaction: result.transaction
    });
  } catch (err) {
    next(err);
  }
});
router11.get("/tasks", requireAdmin, async (req, res, next) => {
  try {
    const levelNumber = req.query.level ? parseInt(req.query.level, 10) : void 0;
    const search = (req.query.search || "").trim();
    const where = {};
    if (levelNumber) {
      where.level = { levelNumber };
    }
    if (search) {
      where.OR = [
        { title: { contains: search } },
        { taskType: { contains: search } },
        { description: { contains: search } }
      ];
    }
    const tasks = await prisma.task.findMany({
      where,
      include: {
        level: true,
        _count: {
          select: {
            submissions: { where: { status: "PENDING" } }
          }
        }
      },
      orderBy: [
        { level: { levelNumber: "asc" } },
        { taskNumber: "asc" }
      ]
    });
    res.json({ tasks });
  } catch (err) {
    next(err);
  }
});
router11.put("/tasks/:taskId", requireAdmin, async (req, res, next) => {
  try {
    const taskId = req.params.taskId;
    const schema = z6.object({
      title: z6.string().min(2, "Task title is required"),
      description: z6.string().min(5, "Task description is required"),
      taskType: z6.string().min(2, "Task type is required"),
      rewardAmount: z6.number().nonnegative("Reward must be 0 or positive"),
      isPaid: z6.boolean(),
      unlockFee: z6.number().nonnegative("Unlock fee cannot be negative"),
      protectedUrl: z6.string().optional().nullable(),
      instructions: z6.string().min(5, "Instructions are required"),
      lockMessage: z6.string().min(5, "Lock message is required"),
      submissionInstructions: z6.string().min(5, "Submission instructions are required"),
      externalContact: z6.string().optional().nullable(),
      requiresAdminApproval: z6.boolean(),
      status: z6.enum(["ACTIVE", "DISABLED"])
    });
    const validated = schema.parse(req.body);
    const existingTask = await prisma.task.findUnique({ where: { id: taskId } });
    if (!existingTask) return res.status(404).json({ error: "Task not found" });
    const updatedTask = await prisma.task.update({
      where: { id: taskId },
      data: {
        ...validated,
        unlockFee: validated.isPaid ? validated.unlockFee : 0
      }
    });
    await logAdminAction({
      adminId: req.admin.id,
      adminUsername: req.admin.username,
      action: "TASK_UPDATED",
      entityType: "Task",
      entityId: taskId,
      previousState: existingTask,
      newState: updatedTask,
      ipAddress: req.ip
    });
    res.json({ message: "Task configuration updated successfully", task: updatedTask });
  } catch (err) {
    next(err);
  }
});
router11.get("/levels", requireAdmin, async (req, res, next) => {
  try {
    const levels = await prisma.level.findMany({
      orderBy: { levelNumber: "asc" },
      include: {
        tasks: { orderBy: { taskNumber: "asc" } },
        _count: { select: { userProgress: true } }
      }
    });
    res.json({ levels });
  } catch (err) {
    next(err);
  }
});
router11.put("/levels/:levelId", requireAdmin, async (req, res, next) => {
  try {
    const levelId = req.params.levelId;
    const schema = z6.object({
      title: z6.string().min(2),
      description: z6.string().min(5),
      completionReward: z6.number().nonnegative(),
      status: z6.enum(["ACTIVE", "DISABLED"])
    });
    const validated = schema.parse(req.body);
    const existing = await prisma.level.findUnique({ where: { id: levelId } });
    if (!existing) return res.status(404).json({ error: "Level not found" });
    const updated = await prisma.level.update({
      where: { id: levelId },
      data: validated
    });
    await logAdminAction({
      adminId: req.admin.id,
      adminUsername: req.admin.username,
      action: "LEVEL_UPDATED",
      entityType: "Level",
      entityId: levelId,
      previousState: existing,
      newState: updated,
      ipAddress: req.ip
    });
    res.json({ message: "Level updated successfully", level: updated });
  } catch (err) {
    next(err);
  }
});
router11.get("/submissions", requireAdmin, async (req, res, next) => {
  try {
    const status = (req.query.status || "").trim();
    const levelNumber = req.query.level ? parseInt(req.query.level, 10) : void 0;
    const page = parseInt(req.query.page || "1", 10);
    const limit = parseInt(req.query.limit || "20", 10);
    const skip = (page - 1) * limit;
    const where = {};
    if (status) where.status = status;
    if (levelNumber) where.task = { level: { levelNumber } };
    const [submissions, total] = await Promise.all([
      prisma.taskSubmission.findMany({
        where,
        include: {
          user: { select: { id: true, name: true, phone: true } },
          task: { include: { level: true } }
        },
        orderBy: { createdAt: "desc" },
        skip,
        take: limit
      }),
      prisma.taskSubmission.count({ where })
    ]);
    res.json({
      submissions,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit)
      }
    });
  } catch (err) {
    next(err);
  }
});
router11.put("/submissions/:submissionId/review", requireAdmin, async (req, res, next) => {
  try {
    const submissionId = req.params.submissionId;
    const { action, reviewNotes, rejectionReason } = z6.object({
      action: z6.enum(["APPROVE", "REJECT"]),
      reviewNotes: z6.string().optional(),
      rejectionReason: z6.string().optional()
    }).parse(req.body);
    const submission = await prisma.taskSubmission.findUnique({
      where: { id: submissionId },
      include: {
        task: { include: { level: true } },
        user: true
      }
    });
    if (!submission) return res.status(404).json({ error: "Submission not found" });
    if (submission.status !== "PENDING") {
      return res.status(400).json({ error: `This submission has already been reviewed (Status: ${submission.status})` });
    }
    const { user, task } = submission;
    if (action === "APPROVE") {
      const result = await prisma.$transaction(async (tx) => {
        const updatedSub = await tx.taskSubmission.update({
          where: { id: submissionId },
          data: {
            status: "APPROVED",
            reviewerId: req.admin.id,
            reviewerName: req.admin.username,
            reviewNotes: reviewNotes || null
          }
        });
        await tx.userTaskProgress.upsert({
          where: { userId_taskId: { userId: user.id, taskId: task.id } },
          update: {
            status: "APPROVED",
            approvedAt: /* @__PURE__ */ new Date(),
            reviewerId: req.admin.id
          },
          create: {
            userId: user.id,
            taskId: task.id,
            status: "APPROVED",
            approvedAt: /* @__PURE__ */ new Date(),
            reviewerId: req.admin.id
          }
        });
        const creditPointsToAdd = task.creditPoints || 5;
        await tx.wallet.update({
          where: { userId: user.id },
          data: {
            creditPoints: { increment: creditPointsToAdd }
          }
        });
        await tx.notification.create({
          data: {
            userId: user.id,
            title: `Task Approved! +${creditPointsToAdd} Credit Points \u{1F389}`,
            message: `Your task "${task.title}" was approved by administrator ${req.admin.username}. You earned +${creditPointsToAdd} credit points! The next sequential task is now unlocked.`,
            notificationType: "TASK_STATUS"
          }
        });
        if (task.taskNumber === 3 || task.taskNumber === 7) {
          const milestoneReason = `Level ${task.level.levelNumber} Task ${task.taskNumber} Milestone Free Spin`;
          const existingEntitlement = await tx.userSpinEntitlement.findFirst({
            where: {
              userId: user.id,
              levelNumber: task.level.levelNumber,
              taskNumber: task.taskNumber
            }
          });
          if (!existingEntitlement) {
            await tx.userSpinEntitlement.create({
              data: {
                userId: user.id,
                levelNumber: task.level.levelNumber,
                taskNumber: task.taskNumber,
                triggerReason: milestoneReason,
                totalSpins: 1,
                remainingSpins: 1,
                isEligible: false,
                // Goes to admin first to assign the prize outcome
                requiresAdminReview: true,
                adminReviewed: false,
                assignedPrizeId: null
              }
            });
            await tx.notification.create({
              data: {
                userId: user.id,
                title: `Task ${task.taskNumber} Milestone Spin Earned! \u{1F3A1}`,
                message: `Congratulations! Completing Task ${task.taskNumber} in Level ${task.level.levelNumber} earned you a Free Royal Spin! Your entitlement is submitted to administration to assign your reward.`,
                notificationType: "SPIN_REWARD"
              }
            });
          }
        }
        return updatedSub;
      });
      await taskProgressionService.updateLevelProgress(user.id, task.levelId);
      await affiliateService.checkAndQualifyReferral(user.id, "TASK_APPROVED");
      await logAdminAction({
        adminId: req.admin.id,
        adminUsername: req.admin.username,
        action: "TASK_SUBMISSION_APPROVED",
        entityType: "TaskSubmission",
        entityId: submissionId,
        newState: { status: "APPROVED", rewardAmount: task.rewardAmount },
        reason: reviewNotes,
        ipAddress: req.ip
      });
      res.json({ message: "Task approved and reward credited successfully!", submission: result });
    } else {
      const updatedSub = await prisma.$transaction(async (tx) => {
        const sub = await tx.taskSubmission.update({
          where: { id: submissionId },
          data: {
            status: "REJECTED",
            reviewerId: req.admin.id,
            reviewerName: req.admin.username,
            reviewNotes: reviewNotes || null,
            rejectionReason: rejectionReason || "Verification requirements not satisfied"
          }
        });
        await tx.userTaskProgress.upsert({
          where: { userId_taskId: { userId: user.id, taskId: task.id } },
          update: {
            status: "REJECTED",
            rejectionReason: rejectionReason || "Verification requirements not satisfied"
          },
          create: {
            userId: user.id,
            taskId: task.id,
            status: "REJECTED",
            rejectionReason: rejectionReason || "Verification requirements not satisfied"
          }
        });
        await tx.notification.create({
          data: {
            userId: user.id,
            title: `Task Submission Rejected \u274C`,
            message: `Your submission for "${task.title}" was rejected. Reason: ${rejectionReason || "Please resubmit with clear proof."}`,
            notificationType: "TASK_STATUS"
          }
        });
        return sub;
      });
      await logAdminAction({
        adminId: req.admin.id,
        adminUsername: req.admin.username,
        action: "TASK_SUBMISSION_REJECTED",
        entityType: "TaskSubmission",
        entityId: submissionId,
        newState: { status: "REJECTED", rejectionReason },
        reason: reviewNotes,
        ipAddress: req.ip
      });
      res.json({ message: "Task submission rejected.", submission: updatedSub });
    }
  } catch (err) {
    next(err);
  }
});
router11.get("/deposits", requireAdmin, async (req, res, next) => {
  try {
    const status = (req.query.status || "").trim();
    const page = parseInt(req.query.page || "1", 10);
    const limit = parseInt(req.query.limit || "20", 10);
    const skip = (page - 1) * limit;
    const where = {};
    if (status) where.status = status;
    const [deposits, total] = await Promise.all([
      prisma.depositRequest.findMany({
        where,
        include: { user: { select: { id: true, name: true, phone: true } } },
        orderBy: { createdAt: "desc" },
        skip,
        take: limit
      }),
      prisma.depositRequest.count({ where })
    ]);
    res.json({
      deposits,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit)
      }
    });
  } catch (err) {
    next(err);
  }
});
router11.put("/deposits/:depositId/review", requireAdmin, async (req, res, next) => {
  try {
    const depositId = req.params.depositId;
    const { action, reviewNotes } = z6.object({
      action: z6.enum(["APPROVE", "REJECT"]),
      reviewNotes: z6.string().optional()
    }).parse(req.body);
    const deposit = await prisma.depositRequest.findUnique({
      where: { id: depositId },
      include: { user: true }
    });
    if (!deposit) return res.status(404).json({ error: "Deposit request not found" });
    if (deposit.status !== "PENDING") {
      return res.status(400).json({ error: `This deposit has already been reviewed (Status: ${deposit.status})` });
    }
    if (action === "APPROVE") {
      const result = await prisma.$transaction(async (tx) => {
        const updatedDep = await tx.depositRequest.update({
          where: { id: depositId },
          data: {
            status: "APPROVED",
            reviewerId: req.admin.id,
            reviewerName: req.admin.username,
            reviewNotes: reviewNotes || null
          }
        });
        await tx.wallet.update({
          where: { userId: deposit.userId },
          data: {
            availableBalance: { increment: deposit.amount },
            totalDeposited: { increment: deposit.amount }
          }
        });
        await tx.walletTransaction.create({
          data: {
            userId: deposit.userId,
            transactionType: "DEPOSIT_CREDIT",
            amount: deposit.amount,
            currency: "PKR",
            status: "COMPLETED",
            relatedEntityId: deposit.id,
            actorId: req.admin.id,
            actorName: req.admin.username,
            reason: `Deposit approved via ${deposit.paymentMethod} (Ref: ${deposit.transactionReference})`,
            notes: reviewNotes
          }
        });
        await tx.notification.create({
          data: {
            userId: deposit.userId,
            title: `Deposit Approved: PKR ${deposit.amount.toLocaleString()} \u2705`,
            message: `Your deposit of PKR ${deposit.amount.toLocaleString()} has been approved and added to your available balance.`,
            notificationType: "DEPOSIT_STATUS"
          }
        });
        return updatedDep;
      });
      await logAdminAction({
        adminId: req.admin.id,
        adminUsername: req.admin.username,
        action: "DEPOSIT_APPROVED",
        entityType: "DepositRequest",
        entityId: depositId,
        newState: { status: "APPROVED", amount: deposit.amount },
        reason: reviewNotes,
        ipAddress: req.ip
      });
      await affiliateService.checkAndQualifyReferral(deposit.userId, "DEPOSIT_APPROVED");
      res.json({ message: `Deposit of PKR ${deposit.amount.toLocaleString()} approved and credited!`, deposit: result });
    } else {
      const updatedDep = await prisma.$transaction(async (tx) => {
        const dep = await tx.depositRequest.update({
          where: { id: depositId },
          data: {
            status: "REJECTED",
            reviewerId: req.admin.id,
            reviewerName: req.admin.username,
            reviewNotes: reviewNotes || "Transaction details could not be verified"
          }
        });
        await tx.notification.create({
          data: {
            userId: deposit.userId,
            title: `Deposit Rejected \u274C`,
            message: `Your deposit request for PKR ${deposit.amount.toLocaleString()} was rejected. Reason: ${reviewNotes || "Verification unconfirmed."}`,
            notificationType: "DEPOSIT_STATUS"
          }
        });
        return dep;
      });
      await logAdminAction({
        adminId: req.admin.id,
        adminUsername: req.admin.username,
        action: "DEPOSIT_REJECTED",
        entityType: "DepositRequest",
        entityId: depositId,
        newState: { status: "REJECTED" },
        reason: reviewNotes,
        ipAddress: req.ip
      });
      res.json({ message: "Deposit request rejected.", deposit: updatedDep });
    }
  } catch (err) {
    next(err);
  }
});
router11.get("/withdrawals", requireAdmin, async (req, res, next) => {
  try {
    const approvalStatus = (req.query.approvalStatus || "").trim();
    const paymentStatus = (req.query.paymentStatus || "").trim();
    const page = parseInt(req.query.page || "1", 10);
    const limit = parseInt(req.query.limit || "20", 10);
    const skip = (page - 1) * limit;
    const where = {};
    if (approvalStatus) where.approvalStatus = approvalStatus;
    if (paymentStatus) where.paymentStatus = paymentStatus;
    const [withdrawals, total] = await Promise.all([
      prisma.withdrawalRequest.findMany({
        where,
        include: { user: { select: { id: true, name: true, phone: true } } },
        orderBy: { createdAt: "desc" },
        skip,
        take: limit
      }),
      prisma.withdrawalRequest.count({ where })
    ]);
    res.json({
      withdrawals,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit)
      }
    });
  } catch (err) {
    next(err);
  }
});
router11.put("/withdrawals/:withdrawalId/review", requireAdmin, async (req, res, next) => {
  try {
    const withdrawalId = req.params.withdrawalId;
    const { action, reviewNotes } = z6.object({
      action: z6.enum(["APPROVE", "REJECT"]),
      reviewNotes: z6.string().optional()
    }).parse(req.body);
    const withdrawal = await prisma.withdrawalRequest.findUnique({
      where: { id: withdrawalId },
      include: { user: true }
    });
    if (!withdrawal) return res.status(404).json({ error: "Withdrawal not found" });
    if (withdrawal.approvalStatus !== "PENDING") {
      return res.status(400).json({ error: `Withdrawal has already been reviewed (Status: ${withdrawal.approvalStatus})` });
    }
    if (action === "APPROVE") {
      const updated = await prisma.withdrawalRequest.update({
        where: { id: withdrawalId },
        data: {
          approvalStatus: "APPROVED",
          paymentStatus: "NOT_SENT",
          reviewerId: req.admin.id,
          reviewerName: req.admin.username,
          reviewNotes: reviewNotes || null
        }
      });
      await prisma.notification.create({
        data: {
          userId: withdrawal.userId,
          title: `Withdrawal Approved! \u2705`,
          message: `Your withdrawal of PKR ${withdrawal.amount.toLocaleString()} has been approved. Payment processing is underway.`,
          notificationType: "WITHDRAWAL_STATUS"
        }
      });
      await logAdminAction({
        adminId: req.admin.id,
        adminUsername: req.admin.username,
        action: "WITHDRAWAL_APPROVED",
        entityType: "WithdrawalRequest",
        entityId: withdrawalId,
        newState: { approvalStatus: "APPROVED", paymentStatus: "NOT_SENT" },
        reason: reviewNotes,
        ipAddress: req.ip
      });
      res.json({ message: "Withdrawal approved. Status is now Approved (Not Sent).", withdrawal: updated });
    } else {
      const updated = await prisma.$transaction(async (tx) => {
        const reqRec = await tx.withdrawalRequest.update({
          where: { id: withdrawalId },
          data: {
            approvalStatus: "REJECTED",
            paymentStatus: "FAILED",
            reviewerId: req.admin.id,
            reviewerName: req.admin.username,
            reviewNotes: reviewNotes || "Withdrawal rejected by administrator"
          }
        });
        await tx.wallet.update({
          where: { userId: withdrawal.userId },
          data: {
            availableBalance: { increment: withdrawal.amount },
            pendingBalance: { decrement: withdrawal.amount }
          }
        });
        await tx.walletTransaction.create({
          data: {
            userId: withdrawal.userId,
            transactionType: "WITHDRAWAL_REVERSAL",
            amount: withdrawal.amount,
            currency: "PKR",
            status: "COMPLETED",
            relatedEntityId: withdrawal.id,
            actorId: req.admin.id,
            actorName: req.admin.username,
            reason: `Reservation refund for rejected withdrawal #${withdrawal.id.slice(-6)}`,
            notes: reviewNotes
          }
        });
        await tx.notification.create({
          data: {
            userId: withdrawal.userId,
            title: `Withdrawal Rejected - Funds Restored \u{1F504}`,
            message: `Your withdrawal of PKR ${withdrawal.amount.toLocaleString()} was rejected. Reserved funds have been restored to your available balance.`,
            notificationType: "WITHDRAWAL_STATUS"
          }
        });
        return reqRec;
      });
      await logAdminAction({
        adminId: req.admin.id,
        adminUsername: req.admin.username,
        action: "WITHDRAWAL_REJECTED",
        entityType: "WithdrawalRequest",
        entityId: withdrawalId,
        newState: { approvalStatus: "REJECTED" },
        reason: reviewNotes,
        ipAddress: req.ip
      });
      res.json({ message: "Withdrawal rejected and funds restored to user.", withdrawal: updated });
    }
  } catch (err) {
    next(err);
  }
});
router11.put("/withdrawals/:withdrawalId/payout", requireAdmin, async (req, res, next) => {
  try {
    const withdrawalId = req.params.withdrawalId;
    const { payoutReference, reviewNotes } = z6.object({
      payoutReference: z6.string().min(2, "Payout transaction reference / Trx ID is required"),
      reviewNotes: z6.string().optional()
    }).parse(req.body);
    const withdrawal = await prisma.withdrawalRequest.findUnique({
      where: { id: withdrawalId },
      include: { user: true }
    });
    if (!withdrawal) return res.status(404).json({ error: "Withdrawal not found" });
    if (withdrawal.approvalStatus !== "APPROVED") {
      return res.status(400).json({ error: "Withdrawal must be approved before marking as Paid" });
    }
    if (withdrawal.paymentStatus === "PAID") {
      return res.status(400).json({ error: "This withdrawal has already been marked as Paid" });
    }
    const result = await prisma.$transaction(async (tx) => {
      const updatedReq = await tx.withdrawalRequest.update({
        where: { id: withdrawalId },
        data: {
          paymentStatus: "PAID",
          payoutReference: payoutReference.trim(),
          reviewNotes: reviewNotes || withdrawal.reviewNotes
        }
      });
      await tx.wallet.update({
        where: { userId: withdrawal.userId },
        data: {
          pendingBalance: { decrement: withdrawal.amount },
          totalWithdrawn: { increment: withdrawal.amount }
        }
      });
      await tx.walletTransaction.create({
        data: {
          userId: withdrawal.userId,
          transactionType: "WITHDRAWAL_PAID",
          amount: -withdrawal.amount,
          currency: "PKR",
          status: "COMPLETED",
          relatedEntityId: withdrawal.id,
          actorId: req.admin.id,
          actorName: req.admin.username,
          reason: `Payout disbursed via ${withdrawal.paymentMethod} (Payout Ref: ${payoutReference.trim()})`,
          notes: reviewNotes
        }
      });
      await tx.notification.create({
        data: {
          userId: withdrawal.userId,
          title: `Withdrawal Disbursed: PKR ${withdrawal.amount.toLocaleString()} \u{1F4B8}`,
          message: `Your payment of PKR ${withdrawal.amount.toLocaleString()} has been sent! Trx Reference: ${payoutReference.trim()}`,
          notificationType: "WITHDRAWAL_STATUS"
        }
      });
      return updatedReq;
    });
    await logAdminAction({
      adminId: req.admin.id,
      adminUsername: req.admin.username,
      action: "WITHDRAWAL_MARKED_PAID",
      entityType: "WithdrawalRequest",
      entityId: withdrawalId,
      newState: { paymentStatus: "PAID", payoutReference },
      reason: reviewNotes,
      ipAddress: req.ip
    });
    res.json({ message: "Withdrawal successfully marked as Paid!", withdrawal: result });
  } catch (err) {
    next(err);
  }
});
router11.get("/spin", requireAdmin, async (req, res, next) => {
  try {
    const [prizes, entitlements, pendingMilestones, history] = await Promise.all([
      prisma.spinPrize.findMany({ orderBy: { monetaryValue: "asc" } }),
      prisma.userSpinEntitlement.findMany({
        include: {
          user: { select: { id: true, name: true, phone: true } },
          assignedPrize: true
        },
        orderBy: { createdAt: "desc" },
        take: 30
      }),
      prisma.userSpinEntitlement.findMany({
        where: {
          requiresAdminReview: true,
          adminReviewed: false,
          remainingSpins: { gt: 0 }
        },
        include: {
          user: { select: { id: true, name: true, phone: true } },
          assignedPrize: true
        },
        orderBy: { createdAt: "desc" }
      }),
      prisma.spinHistory.findMany({
        include: {
          user: { select: { id: true, name: true, phone: true } },
          prize: true
        },
        orderBy: { createdAt: "desc" },
        take: 30
      })
    ]);
    const spinSetting = await prisma.siteSetting.findUnique({ where: { key: "spin_enabled" } });
    res.json({
      isSpinEnabled: spinSetting?.value === "true",
      prizes,
      entitlements,
      pendingMilestones,
      history
    });
  } catch (err) {
    next(err);
  }
});
router11.post("/spin/assign", requireAdmin, async (req, res, next) => {
  try {
    const { userId, assignedPrizeId, totalSpins, isEligible } = z6.object({
      userId: z6.string().min(1, "User is required"),
      assignedPrizeId: z6.string().optional().nullable(),
      totalSpins: z6.number().int().positive("Total spins must be at least 1"),
      isEligible: z6.boolean().default(true)
    }).parse(req.body);
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) return res.status(404).json({ error: "User not found" });
    let prize = null;
    if (assignedPrizeId) {
      prize = await prisma.spinPrize.findUnique({ where: { id: assignedPrizeId } });
    }
    const entitlement = await prisma.userSpinEntitlement.create({
      data: {
        userId,
        assignedPrizeId: prize?.id || null,
        totalSpins,
        remainingSpins: totalSpins,
        isEligible
      }
    });
    await prisma.notification.create({
      data: {
        userId,
        title: `Royal Spin Entitlement Granted! \u{1F3A1}`,
        message: `An administrator granted you ${totalSpins} royal spin(s)! Spin the wheel now to claim your reward.`,
        notificationType: "SPIN_REWARD"
      }
    });
    await logAdminAction({
      adminId: req.admin.id,
      adminUsername: req.admin.username,
      action: "SPIN_ENTITLEMENT_ASSIGNED",
      entityType: "UserSpinEntitlement",
      entityId: entitlement.id,
      newState: { userId, assignedPrize: prize?.name || "Random", totalSpins },
      ipAddress: req.ip
    });
    res.status(201).json({ message: "Spin entitlement assigned successfully!", entitlement });
  } catch (err) {
    next(err);
  }
});
router11.put("/spin/entitlements/:entitlementId/assign", requireAdmin, async (req, res, next) => {
  try {
    const entitlementId = req.params.entitlementId;
    const { assignedPrizeId } = z6.object({
      assignedPrizeId: z6.string().min(1, "Assigned prize is required")
    }).parse(req.body);
    const prize = await prisma.spinPrize.findUnique({ where: { id: assignedPrizeId } });
    if (!prize) return res.status(404).json({ error: "Selected prize not found" });
    const entitlement = await prisma.userSpinEntitlement.update({
      where: { id: entitlementId },
      data: {
        assignedPrizeId,
        isEligible: true,
        adminReviewed: true
      },
      include: { user: true, assignedPrize: true }
    });
    await prisma.notification.create({
      data: {
        userId: entitlement.userId,
        title: `Royal Spin Unlocked! \u{1F3A1}`,
        message: `Your free milestone spin for ${entitlement.triggerReason || "task progress"} has been prepared by administration! Visit the Royal Spin Wheel now to claim your prize!`,
        notificationType: "SPIN_REWARD"
      }
    });
    await logAdminAction({
      adminId: req.admin.id,
      adminUsername: req.admin.username,
      action: "SPIN_PRIZE_ASSIGNED",
      entityType: "UserSpinEntitlement",
      entityId: entitlement.id,
      newState: { assignedPrize: prize.name, isEligible: true },
      ipAddress: req.ip
    });
    res.json({ message: `Prize ${prize.name} assigned and spin unlocked for ${entitlement.user.name}!`, entitlement });
  } catch (err) {
    next(err);
  }
});
router11.post("/spin/prizes", requireAdmin, async (req, res, next) => {
  try {
    const schema = z6.object({
      name: z6.string().min(2),
      prizeType: z6.enum(["CASH", "PHYSICAL", "BONUS"]),
      monetaryValue: z6.number().nonnegative(),
      displayLabel: z6.string().min(1),
      color: z6.string().min(4),
      icon: z6.string().optional(),
      inventory: z6.number().int().nonnegative().default(999999),
      status: z6.enum(["ACTIVE", "INACTIVE"]).default("ACTIVE")
    });
    const validated = schema.parse(req.body);
    const prize = await prisma.spinPrize.create({ data: validated });
    await logAdminAction({
      adminId: req.admin.id,
      adminUsername: req.admin.username,
      action: "SPIN_PRIZE_CREATED",
      entityType: "SpinPrize",
      entityId: prize.id,
      newState: prize,
      ipAddress: req.ip
    });
    res.status(201).json({ message: "Prize created successfully", prize });
  } catch (err) {
    next(err);
  }
});
router11.get("/referrals", requireAdmin, async (req, res, next) => {
  try {
    const referrals = await prisma.referral.findMany({
      orderBy: { createdAt: "desc" },
      take: 50
    });
    const userIds = Array.from(/* @__PURE__ */ new Set([...referrals.map((r) => r.referrerId), ...referrals.map((r) => r.referredId)]));
    const users = await prisma.user.findMany({
      where: { id: { in: userIds } },
      select: { id: true, name: true, phone: true, referralCode: true }
    });
    const userMap = new Map(users.map((u) => [u.id, u]));
    const formatted = referrals.map((r) => ({
      id: r.id,
      referrer: userMap.get(r.referrerId) || { name: "Unknown", phone: "N/A" },
      referee: userMap.get(r.referredId) || { name: "Unknown", phone: "N/A" },
      qualifyingStatus: r.qualifyingStatus,
      rewardStatus: r.rewardStatus,
      rewardAmount: r.rewardAmount,
      createdAt: r.createdAt
    }));
    res.json({ referrals: formatted });
  } catch (err) {
    next(err);
  }
});
router11.get("/transactions", requireAdmin, async (req, res, next) => {
  try {
    const transactionType = (req.query.type || "").trim();
    const page = parseInt(req.query.page || "1", 10);
    const limit = parseInt(req.query.limit || "20", 10);
    const skip = (page - 1) * limit;
    const where = {};
    if (transactionType) where.transactionType = transactionType;
    const [transactions, total] = await Promise.all([
      prisma.walletTransaction.findMany({
        where,
        include: { user: { select: { id: true, name: true, phone: true } } },
        orderBy: { createdAt: "desc" },
        skip,
        take: limit
      }),
      prisma.walletTransaction.count({ where })
    ]);
    res.json({
      transactions,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit)
      }
    });
  } catch (err) {
    next(err);
  }
});
router11.get("/announcements", requireAdmin, async (req, res, next) => {
  try {
    const announcements = await prisma.announcement.findMany({
      orderBy: { createdAt: "desc" }
    });
    res.json({ announcements });
  } catch (err) {
    next(err);
  }
});
router11.post("/announcements", requireAdmin, async (req, res, next) => {
  try {
    const schema = z6.object({
      title: z6.string().min(2),
      content: z6.string().min(5),
      audience: z6.enum(["ALL", "USERS"]).default("ALL"),
      status: z6.enum(["ACTIVE", "INACTIVE"]).default("ACTIVE")
    });
    const validated = schema.parse(req.body);
    const announcement = await prisma.announcement.create({ data: validated });
    await logAdminAction({
      adminId: req.admin.id,
      adminUsername: req.admin.username,
      action: "ANNOUNCEMENT_CREATED",
      entityType: "Announcement",
      entityId: announcement.id,
      newState: announcement,
      ipAddress: req.ip
    });
    res.status(201).json({ message: "Announcement published", announcement });
  } catch (err) {
    next(err);
  }
});
router11.delete("/announcements/:id", requireAdmin, async (req, res, next) => {
  try {
    const id = req.params.id;
    await prisma.announcement.delete({ where: { id } });
    await logAdminAction({
      adminId: req.admin.id,
      adminUsername: req.admin.username,
      action: "ANNOUNCEMENT_DELETED",
      entityType: "Announcement",
      entityId: id,
      ipAddress: req.ip
    });
    res.json({ message: "Announcement deleted" });
  } catch (err) {
    next(err);
  }
});
router11.get("/settings", requireAdmin, async (req, res, next) => {
  try {
    const settings = await prisma.siteSetting.findMany({
      orderBy: { category: "asc" }
    });
    res.json({ settings });
  } catch (err) {
    next(err);
  }
});
router11.put("/settings", requireAdmin, async (req, res, next) => {
  try {
    const { settings } = z6.object({
      settings: z6.array(
        z6.object({
          key: z6.string(),
          value: z6.string()
        })
      )
    }).parse(req.body);
    for (const item of settings) {
      await prisma.siteSetting.upsert({
        where: { key: item.key },
        update: { value: item.value },
        create: { key: item.key, value: item.value }
      });
    }
    await logAdminAction({
      adminId: req.admin.id,
      adminUsername: req.admin.username,
      action: "SITE_SETTINGS_UPDATED",
      entityType: "SiteSetting",
      entityId: "ALL",
      newState: settings,
      ipAddress: req.ip
    });
    res.json({ message: "Site settings updated successfully" });
  } catch (err) {
    next(err);
  }
});
router11.get("/reports", requireAdmin, async (req, res, next) => {
  try {
    const [
      totalUsers,
      totalDeposited,
      totalPaidWithdrawals,
      totalPendingWithdrawals,
      totalTaskRewards,
      totalUnlockFees,
      totalReferralRewards,
      totalSpinRewards
    ] = await Promise.all([
      prisma.user.count(),
      prisma.depositRequest.aggregate({ where: { status: "APPROVED" }, _sum: { amount: true } }),
      prisma.withdrawalRequest.aggregate({ where: { paymentStatus: "PAID" }, _sum: { amount: true } }),
      prisma.withdrawalRequest.aggregate({ where: { approvalStatus: "PENDING" }, _sum: { amount: true } }),
      prisma.walletTransaction.aggregate({ where: { transactionType: "TASK_REWARD", status: "COMPLETED" }, _sum: { amount: true } }),
      prisma.walletTransaction.aggregate({ where: { transactionType: "TASK_UNLOCK_FEE", status: "COMPLETED" }, _sum: { amount: true } }),
      prisma.walletTransaction.aggregate({ where: { transactionType: "REFERRAL_REWARD", status: "COMPLETED" }, _sum: { amount: true } }),
      prisma.walletTransaction.aggregate({ where: { transactionType: "SPIN_REWARD", status: "COMPLETED" }, _sum: { amount: true } })
    ]);
    res.json({
      summary: {
        totalUsers,
        totalDeposited: totalDeposited._sum.amount || 0,
        totalPaidWithdrawals: totalPaidWithdrawals._sum.amount || 0,
        totalPendingWithdrawals: totalPendingWithdrawals._sum.amount || 0,
        totalTaskRewards: totalTaskRewards._sum.amount || 0,
        totalUnlockFees: Math.abs(totalUnlockFees._sum.amount || 0),
        totalReferralRewards: totalReferralRewards._sum.amount || 0,
        totalSpinRewards: totalSpinRewards._sum.amount || 0,
        platformNetYield: (totalDeposited._sum.amount || 0) + Math.abs(totalUnlockFees._sum.amount || 0) - (totalPaidWithdrawals._sum.amount || 0)
      }
    });
  } catch (err) {
    next(err);
  }
});
router11.get("/activity-logs", requireAdmin, async (req, res, next) => {
  try {
    const page = parseInt(req.query.page || "1", 10);
    const limit = parseInt(req.query.limit || "30", 10);
    const skip = (page - 1) * limit;
    const [logs, total] = await Promise.all([
      prisma.adminAuditLog.findMany({
        orderBy: { createdAt: "desc" },
        skip,
        take: limit
      }),
      prisma.adminAuditLog.count()
    ]);
    res.json({
      logs,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit)
      }
    });
  } catch (err) {
    next(err);
  }
});
var adminRoutes_default = router11;

// src/middleware/errorHandler.ts
import { ZodError } from "zod";
function errorHandler(err, req, res, next) {
  console.error(`[Error] ${req.method} ${req.url}:`, err);
  if (err instanceof ZodError) {
    const errorDetails = err.issues.map((issue) => ({
      path: issue.path.join("."),
      message: issue.message
    }));
    return res.status(400).json({
      error: "Validation failed",
      details: errorDetails
    });
  }
  const statusCode = err.status || err.statusCode || 500;
  const message = err.message || "An unexpected internal server error occurred";
  res.status(statusCode).json({
    error: message
  });
}

// src/app.ts
function createApp() {
  const app = express();
  app.use(cors({
    origin: (origin, callback) => {
      callback(null, true);
    },
    credentials: true,
    methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization", "X-Requested-With"]
  }));
  app.use(express.json());
  app.use(express.urlencoded({ extended: true }));
  if (process.env.NODE_ENV !== "test") {
    app.use(morgan("dev"));
  }
  app.use("/api/auth", authRoutes_default);
  app.use("/api/user", userRoutes_default);
  app.use("/api/tasks", taskRoutes_default);
  app.use("/api/wallet", walletRoutes_default);
  app.use("/api/deposits", depositRoutes_default);
  app.use("/api/withdrawals", withdrawalRoutes_default);
  app.use("/api/spin", spinRoutes_default);
  app.use("/api/referrals", referralRoutes_default);
  app.use("/api/notifications", notificationRoutes_default);
  app.use("/api/settings", settingsRoutes_default);
  app.use("/api/admin", adminRoutes_default);
  app.get("/", (req, res) => {
    res.json({
      name: "Earn Sheet API Server",
      status: "online",
      message: "Backend API server is running.",
      endpoints: {
        health: "/api/health",
        publicSettings: "/api/settings/public"
      }
    });
  });
  app.get("/api/health", (req, res) => {
    res.json({ status: "ok", name: "Earn Sheet API", timestamp: /* @__PURE__ */ new Date() });
  });
  app.get(["/favicon.ico", "/apple-touch-icon.png", "/apple-touch-icon-precomposed.png"], (req, res) => {
    res.status(204).end();
  });
  app.get("/.well-known/appspecific/com.chrome.devtools.json", (req, res) => {
    res.status(204).end();
  });
  app.use(errorHandler);
  return app;
}

// api/index.ts
var appInstance;
function handler(req, res) {
  try {
    if (!appInstance) {
      appInstance = createApp();
    }
    return appInstance(req, res);
  } catch (err) {
    console.error("Fatal backend serverless error:", err);
    return res.status(500).json({
      error: "Backend Serverless Error",
      message: err?.message || String(err)
    });
  }
}
export {
  handler as default
};
