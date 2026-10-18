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
        '👑 Join Earn Sheet with my exclusive invite code {CODE} and earn daily cash rewards on tasks! Register here: {LINK}',
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
      // Qualify and payout immediately
      await prisma.$transaction(async (tx) => {
        await tx.referral.upsert({
          where: { referrerId_referredId: { referrerId, referredId: refereeId } },
          update: {
            qualifyingStatus: 'QUALIFIED',
            rewardStatus: 'CREDITED',
            rewardAmount: settings.referralReward,
          },
          create: {
            referrerId,
            referredId: refereeId,
            qualifyingStatus: 'QUALIFIED',
            rewardStatus: 'CREDITED',
            rewardAmount: settings.referralReward,
          },
        });

        await tx.wallet.update({
          where: { userId: referrerId },
          data: {
            availableBalance: { increment: settings.referralReward },
            totalEarned: { increment: settings.referralReward },
          },
        });

        await tx.walletTransaction.create({
          data: {
            userId: referrerId,
            transactionType: 'REFERRAL_REWARD',
            amount: settings.referralReward,
            currency: 'PKR',
            status: 'COMPLETED',
            relatedEntityId: refereeId,
            reason: `Referral commission for registering new partner`,
          },
        });

        await tx.notification.create({
          data: {
            userId: referrerId,
            title: `Referral Bonus Credited! +PKR ${settings.referralReward.toLocaleString()} 🎉`,
            message: `A new partner registered with your code! PKR ${settings.referralReward.toLocaleString()} has been credited directly to your cash wallet balance.`,
            notificationType: 'WALLET_TRANSACTION',
          },
        });
      });

      await this.checkAmbassadorMilestones(referrerId);
    } else {
      // Record referral relationship in PENDING state awaiting qualification event
      await prisma.referral.upsert({
        where: { referrerId_referredId: { referrerId, referredId: refereeId } },
        update: {
          qualifyingStatus: 'PENDING',
          rewardStatus: 'PENDING',
          rewardAmount: settings.referralReward,
        },
        create: {
          referrerId,
          referredId: refereeId,
          qualifyingStatus: 'PENDING',
          rewardStatus: 'PENDING',
          rewardAmount: settings.referralReward,
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

    const rewardAmount = settings.referralReward || 250;
    const referrerId = referral.referrerId;

    // Execute atomic qualification and wallet payout
    await prisma.$transaction(async (tx) => {
      // 1. Mark referral QUALIFIED and CREDITED
      await tx.referral.update({
        where: { id: referral.id },
        data: {
          qualifyingStatus: 'QUALIFIED',
          rewardStatus: 'CREDITED',
          rewardAmount,
        },
      });

      // 2. Credit referrer's wallet
      await tx.wallet.update({
        where: { userId: referrerId },
        data: {
          availableBalance: { increment: rewardAmount },
          totalEarned: { increment: rewardAmount },
        },
      });

      // 3. Create wallet transaction
      await tx.walletTransaction.create({
        data: {
          userId: referrerId,
          transactionType: 'REFERRAL_REWARD',
          amount: rewardAmount,
          currency: 'PKR',
          status: 'COMPLETED',
          relatedEntityId: referral.id,
          reason: `Referral commission for qualifying partner (Criteria: ${settings.qualifyingCondition})`,
        },
      });

      // 4. Send notification to referrer
      await tx.notification.create({
        data: {
          userId: referrerId,
          title: `Partner Qualified! +PKR ${rewardAmount.toLocaleString()} Credited 🎉`,
          message: `Your referred partner has met the qualification criteria! PKR ${rewardAmount.toLocaleString()} has been credited to your available wallet balance.`,
          notificationType: 'WALLET_TRANSACTION',
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

    // Milestone: Gold Ambassador reached (Award PKR 5,000 Milestone Bonus)
    if (qualifiedCount >= settings.goldTarget) {
      const goldBonusReason = `Gold Ambassador Milestone Bonus (${settings.goldTarget} Qualified Partners)`;
      const existingBonus = await prisma.walletTransaction.findFirst({
        where: {
          userId: referrerId,
          reason: goldBonusReason,
        },
      });

      if (!existingBonus) {
        await prisma.$transaction(async (tx) => {
          const goldBonusAmount = 5000;
          await tx.wallet.update({
            where: { userId: referrerId },
            data: {
              availableBalance: { increment: goldBonusAmount },
              totalEarned: { increment: goldBonusAmount },
            },
          });

          await tx.walletTransaction.create({
            data: {
              userId: referrerId,
              transactionType: 'REFERRAL_REWARD',
              amount: goldBonusAmount,
              currency: 'PKR',
              status: 'COMPLETED',
              reason: goldBonusReason,
            },
          });

          await tx.notification.create({
            data: {
              userId: referrerId,
              title: `Gold Ambassador Crowned! +PKR 5,000 Cash Bonus 👑`,
              message: `Incredible achievement! You reached ${settings.goldTarget} qualified partners, earning Gold Ambassador rank and a PKR 5,000 royal milestone reward!`,
              notificationType: 'WALLET_TRANSACTION',
            },
          });
        });
      }
    }
  },
};
