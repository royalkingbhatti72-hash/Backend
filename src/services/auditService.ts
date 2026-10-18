import { prisma } from '../prisma';

interface AuditLogParams {
  adminId?: string;
  adminUsername: string;
  action: string;
  entityType: string;
  entityId: string;
  previousState?: any;
  newState?: any;
  reason?: string;
  ipAddress?: string;
}

export async function logAdminAction(params: AuditLogParams) {
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
        ipAddress: params.ipAddress || null,
      },
    });
  } catch (err) {
    console.error('Failed to write audit log entry:', err);
  }
}
