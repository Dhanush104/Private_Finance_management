// Central API base URL — uses Vite proxy in dev, env var in production
export const API_BASE = import.meta.env.VITE_API_URL || 'https://private-finanace-management-api.onrender.com/api';
export const SOCKET_URL = import.meta.env.VITE_SOCKET_URL || 'https://private-finanace-management-api.onrender.com';
