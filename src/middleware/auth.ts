import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { config } from '../config';
import { prisma } from '../prisma';

export interface AuthenticatedUser {
  id: string;
  phone: string;
  name: string;
  referralCode: string;
  accountStatus: string;
}

export interface AuthRequest extends Request {
  user?: AuthenticatedUser;
}

export async function requireAuth(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Unauthorized: Authentication token is missing' });
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, config.jwtSecret) as { userId: string };

    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: {
        id: true,
        phone: true,
        name: true,
        referralCode: true,
        accountStatus: true,
      },
    });

    if (!user) {
      return res.status(401).json({ error: 'Unauthorized: User no longer exists' });
    }

    if (user.accountStatus === 'SUSPENDED') {
      return res.status(403).json({ error: 'Account suspended. Please contact Earn Sheet support.' });
    }

    req.user = user;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Unauthorized: Invalid or expired token' });
  }
}
