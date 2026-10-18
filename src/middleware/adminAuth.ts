import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { config } from '../config';
import { prisma } from '../prisma';

export interface AuthenticatedAdmin {
  id: string;
  username: string;
  role: string;
}

export interface AdminAuthRequest extends Request {
  admin?: AuthenticatedAdmin;
}

export async function requireAdmin(req: AdminAuthRequest, res: Response, next: NextFunction) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Admin Access Denied: Authentication token required' });
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, config.adminSecret) as { adminId: string; role: string };

    const admin = await prisma.adminUser.findUnique({
      where: { id: decoded.adminId },
      select: {
        id: true,
        username: true,
        role: true,
        status: true,
      },
    });

    if (!admin || admin.status !== 'ACTIVE') {
      return res.status(403).json({ error: 'Admin Access Denied: Administrator account is inactive or not found' });
    }

    req.admin = {
      id: admin.id,
      username: admin.username,
      role: admin.role,
    };
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Admin Access Denied: Invalid or expired administrator session' });
  }
}
