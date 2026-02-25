import { createContext, useContext, useState, useEffect } from 'react';
import api from '../services/api';
import toast from 'react-hot-toast';

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
    const [user, setUser] = useState(() => JSON.parse(localStorage.getItem('rsb_user') || 'null'));
    const [token, setToken] = useState(() => localStorage.getItem('rsb_token') || null);
    const [loading, setLoading] = useState(false);

    useEffect(() => {
        if (token && !user) fetchMe();
    }, []);

    const fetchMe = async () => {
        try {
            const { data } = await api.get('/auth/me');
            setUser(data.user);
            localStorage.setItem('rsb_user', JSON.stringify(data.user));
        } catch {
            logout();
        }
    };

    const login = async (email, password) => {
        setLoading(true);
        try {
            const { data } = await api.post('/auth/login', { email, password });
            localStorage.setItem('rsb_token', data.token);
            localStorage.setItem('rsb_user', JSON.stringify(data.user));
            setToken(data.token);
            setUser(data.user);
            toast.success(`Welcome back, ${data.user.name}!`);
            return data.user;
        } finally {
            setLoading(false);
        }
    };

    const logout = () => {
        localStorage.removeItem('rsb_token');
        localStorage.removeItem('rsb_user');
        setToken(null);
        setUser(null);
    };

    return (
        <AuthContext.Provider value={{ user, token, loading, login, logout, isAdmin: user?.role === 'admin' }}>
            {children}
        </AuthContext.Provider>
    );
};

export const useAuth = () => {
    const ctx = useContext(AuthContext);
    if (!ctx) throw new Error('useAuth must be inside AuthProvider');
    return ctx;
};
