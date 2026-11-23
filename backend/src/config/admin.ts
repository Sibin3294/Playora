export const ADMIN_EMAIL =
  process.env.ADMIN_EMAIL?.trim().toLowerCase() || 'admin@playora.local';
export const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'playora-admin';
export const ADMIN_JWT_SECRET =
  process.env.ADMIN_JWT_SECRET || `${process.env.JWT_SECRET || 'number-hunter-local-secret'}-admin`;
export const ADMIN_JWT_EXPIRES_IN = process.env.ADMIN_JWT_EXPIRES_IN || '12h';
