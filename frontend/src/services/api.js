import axios from 'axios';
import { API_BASE } from '../config';

const api = axios.create({ baseURL: API_BASE });

// Attach JWT token to every request
api.interceptors.request.use((config) => {
    const token = localStorage.getItem('rsb_token');
    if (token) config.headers.Authorization = `Bearer ${token}`;
    return config;
});

// Handle 401 globally - clear session
api.interceptors.response.use(
    (res) => res,
    (err) => {
        if (err.response?.status === 401) {
            localStorage.removeItem('rsb_token');
            localStorage.removeItem('rsb_user');
            window.location.href = '/login';
        }
        return Promise.reject(err);
    }
);

export default api;
