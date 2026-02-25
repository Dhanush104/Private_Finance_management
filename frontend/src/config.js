// Central API base URL — uses Vite proxy in dev, env var in production
export const API_BASE = import.meta.env.VITE_API_URL || '/api';
export const SOCKET_URL = import.meta.env.VITE_SOCKET_URL || window.location.origin;
