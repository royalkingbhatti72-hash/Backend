import { prisma } from '../prisma';

export interface AffiliateSettings {
  referralReward: number;
  qualifyingCondition: 'FIRST_TASK_APPROVED' | 'LEVEL_1_COMPLETED' | 'FIRST_DEPOSIT_COMPLETED' | 'INSTANT_ON_REGISTRATION';
  affiliateProgramEnabled: boolean;
  bronzeTarget: number;
  silverTarget: number;
  goldTarget: number;
  shareTemplate: string;
  autoPayout: boolean;
  antiFraudEnabled: boolean;
}

export const affiliateService = {
  /**
   * Fetches current affiliate and referral program settings from database
   */
  async getSettings(): Promise<AffiliateSettings> {
    const keys = [
      'referral_reward',
      'referral_qualifying_condition',
      'affiliate_program_enabled',
      'affiliate_bronze_target',
      'affiliate_silver_target',
      'affiliate_gold_target',
      'affiliate_share_template',
      'affiliate_auto_payout',
      'affiliate_anti_fraud',
    ];

    const settings = await prisma.siteSetting.findMany({
      where: { key: { in: keys } },
    });

    const map = Object.fromEntries(settings.map((s) => [s.key, s.value]));

    return {
      referralReward: parseFloat(map.referral_reward || '250'),
      qualifyingCondition: (map.referral_qualifying_condition as any) || 'FIRST_TASK_APPROVED',
      affiliateProgramEnabled: map.affiliate_program_enabled !== 'false',
      bronzeTarget: parseInt(map.affiliate_bronze_target || '5', 10),
      silverTarget: parseInt(map.affiliate_silver_target || '15', 10),
      goldTarget: parseInt(map.affiliate_gold_target || '30', 10),
      shareTemplate:
        map.affiliate_share_template ||
        '👑 Join Earn Street with my exclusive invite code {CODE} and earn daily cash rewards on tasks! Register here: {LINK}',
      autoPayout: map.affiliate_auto_payout !== 'false',
      antiFraudEnabled: map.affiliate_anti_fraud !== 'false',
    };
  },

  /**
   * Called when a user registers with a referrer code
   */
  async handleNewRegistration(referrerId: string, refereeId: string) {
    const settings = await this.getSettings();
    if (!settings.affiliateProgramEnabled) return;

    // Check anti-fraud if same IP or device (if available)
    if (referrerId === refereeId) return;

    const isInstant = settings.qualifyingCondition === 'INSTANT_ON_REGISTRATION';

    if (isInstant) {
      // Qualify and award ONLY 1 Free Spin (no cash profit)
      await prisma.$transaction(async (tx) => {
        await tx.referral.upsert({
          where: { referrerId_referredId: { referrerId, referredId: refereeId } },
          update: {
            qualifyingStatus: 'QUALIFIED',
            rewardStatus: 'CREDITED',
            rewardAmount: 0,
          },
          create: {
            referrerId,
            referredId: refereeId,
            qualifyingStatus: 'QUALIFIED',
            rewardStatus: 'CREDITED',
            rewardAmount: 0,
          },
        });

        // Award 1 Free Spin to referrer
        await tx.userSpinEntitlement.create({
          data: {
            userId: referrerId,
            triggerReason: `Qualified Referral Reward (New Partner ${refereeId})`,
            totalSpins: 1,
            remainingSpins: 1,
            isEligible: true,
            requiresAdminReview: false,
            adminReviewed: true,
          },
        });

        await tx.notification.create({
          data: {
            userId: referrerId,
            title: `Qualified Referral: 1 Free Spin Unlocked! 🎰`,
            message: `A new partner registered with your code and qualified! You earned 1 Free Royal Spin.`,
            notificationType: 'SPIN_REWARD',
          },
        });
      });

      await this.checkAmbassadorMilestones(referrerId);
    } else {
      // Record referral relationship in PENDING state awaiting qualification event.
      // Unqualified users yield NO reward and 0 monetary profit.
      await prisma.referral.upsert({
        where: { referrerId_referredId: { referrerId, referredId: refereeId } },
        update: {
          qualifyingStatus: 'PENDING',
          rewardStatus: 'PENDING',
          rewardAmount: 0,
        },
        create: {
          referrerId,
          referredId: refereeId,
          qualifyingStatus: 'PENDING',
          rewardStatus: 'PENDING',
          rewardAmount: 0,
        },
      });
    }
  },

  /**
   * Evaluates qualification criteria when events occur:
   * 'TASK_APPROVED' | 'LEVEL_1_COMPLETED' | 'DEPOSIT_APPROVED'
   */
  async checkAndQualifyReferral(
    refereeUserId: string,
    triggerType: 'TASK_APPROVED' | 'LEVEL_1_COMPLETED' | 'DEPOSIT_APPROVED'
  ) {
    const settings = await this.getSettings();
    if (!settings.affiliateProgramEnabled) return;

    // Find pending referral for this referee
    const referral = await prisma.referral.findFirst({
      where: {
        referredId: refereeUserId,
        qualifyingStatus: 'PENDING',
      },
    });

    if (!referral) return;

    // Check condition matching
    let shouldQualify = false;
    if (settings.qualifyingCondition === 'FIRST_TASK_APPROVED' && triggerType === 'TASK_APPROVED') {
      shouldQualify = true;
    } else if (settings.qualifyingCondition === 'LEVEL_1_COMPLETED' && triggerType === 'LEVEL_1_COMPLETED') {
      shouldQualify = true;
    } else if (settings.qualifyingCondition === 'FIRST_DEPOSIT_COMPLETED' && triggerType === 'DEPOSIT_APPROVED') {
      shouldQualify = true;
    }

    if (!shouldQualify) return;

    const referrerId = referral.referrerId;

    // Execute atomic qualification and award ONLY 1 Free Spin (no cash profit)
    await prisma.$transaction(async (tx) => {
      // 1. Mark referral QUALIFIED and CREDITED
      await tx.referral.update({
        where: { id: referral.id },
        data: {
          qualifyingStatus: 'QUALIFIED',
          rewardStatus: 'CREDITED',
          rewardAmount: 0,
        },
      });

      // 2. Award 1 Free Spin to referrer (no monetary wallet credit)
      await tx.userSpinEntitlement.create({
        data: {
          userId: referrerId,
          triggerReason: `Qualified Referral Reward (Partner ${referral.referredId})`,
          totalSpins: 1,
          remainingSpins: 1,
          isEligible: true,
          requiresAdminReview: false,
          adminReviewed: true,
        },
      });

      // 3. Send notification to referrer
      await tx.notification.create({
        data: {
          userId: referrerId,
          title: `Partner Qualified: 1 Free Spin Earned! 🎰`,
          message: `Your referred partner has qualified! You have earned 1 Free Spin on the Lucky Wheel. Head over to the Spin page to play!`,
          notificationType: 'SPIN_REWARD',
        },
      });
    });

    // Check milestone upgrade for referrer
    await this.checkAmbassadorMilestones(referrerId);
  },

  /**
   * Checks Ambassador tier thresholds (Silver, Gold) and awards milestone perks
   */
  async checkAmbassadorMilestones(referrerId: string) {
    const settings = await this.getSettings();
    const qualifiedCount = await prisma.referral.count({
      where: {
        referrerId,
        qualifyingStatus: 'QUALIFIED',
      },
    });

    // Milestone: Silver Ambassador reached (Award 1 Free Milestone Spin)
    if (qualifiedCount >= settings.silverTarget) {
      const entitlementReason = `Silver Ambassador Milestone (${settings.silverTarget} Qualified Partners)`;
      const existingSpin = await prisma.userSpinEntitlement.findFirst({
        where: {
          userId: referrerId,
          triggerReason: entitlementReason,
        },
      });

      if (!existingSpin) {
        await prisma.userSpinEntitlement.create({
          data: {
            userId: referrerId,
            triggerReason: entitlementReason,
            totalSpins: 1,
            remainingSpins: 1,
            isEligible: false, // Goes to admin for prize assignment
            requiresAdminReview: true,
            adminReviewed: false,
          },
        });

        await prisma.notification.create({
          data: {
            userId: referrerId,
            title: `Silver Ambassador Rank Achieved! 🥈`,
            message: `Congratulations! You have reached ${settings.silverTarget} qualified partners and unlocked Silver Ambassador status plus a Free Royal Milestone Spin!`,
            notificationType: 'SPIN_REWARD',
          },
        });
      }
    }

    // Milestone: Gold Ambassador reached (Award 3 Free Milestone Spins - no cash bonus)
    if (qualifiedCount >= settings.goldTarget) {
      const goldSpinReason = `Gold Ambassador Milestone (${settings.goldTarget} Qualified Partners)`;
      const existingSpin = await prisma.userSpinEntitlement.findFirst({
        where: {
          userId: referrerId,
          triggerReason: goldSpinReason,
        },
      });

      if (!existingSpin) {
        await prisma.userSpinEntitlement.create({
          data: {
            userId: referrerId,
            triggerReason: goldSpinReason,
            totalSpins: 3,
            remainingSpins: 3,
            isEligible: true,
            requiresAdminReview: false,
            adminReviewed: true,
          },
        });

        await prisma.notification.create({
          data: {
            userId: referrerId,
            title: `Gold Ambassador Crowned! +3 Free Spins Awarded 👑`,
            message: `Incredible achievement! You reached ${settings.goldTarget} qualified partners, earning Gold Ambassador rank and 3 Free Royal Spins!`,
            notificationType: 'SPIN_REWARD',
          },
        });
      }
    }
  },
};
