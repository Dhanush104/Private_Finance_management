import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { Star, Eye, EyeOff, Lock, Mail, AlertCircle } from 'lucide-react';
import './LoginPage.css';

export default function LoginPage() {
    const { login, loading } = useAuth();
    const navigate = useNavigate();
    const [form, setForm] = useState({ email: '', password: '' });
    const [showPass, setShowPass] = useState(false);
    const [error, setError] = useState('');

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');
        try {
            await login(form.email, form.password);
            navigate('/dashboard');
        } catch (err) {
            setError(err.response?.data?.message || 'Login failed. Please try again.');
        }
    };

    return (
        <div className="login-bg">
            {/* Animated background orbs */}
            <div className="login-orb login-orb-1" />
            <div className="login-orb login-orb-2" />
            <div className="login-orb login-orb-3" />

            <div className="login-card">
                <div className="login-brand">
                    <div className="login-icon">
                        <Star size={26} fill="currentColor" />
                    </div>
                    <h1 className="login-title">Royal Star Boys</h1>
                    <p className="login-sub">Private Community Fund Management</p>
                </div>

                <form onSubmit={handleSubmit} className="login-form">
                    {error && (
                        <div className="login-error">
                            <AlertCircle size={15} />
                            {error}
                        </div>
                    )}

                    <div className="form-group">
                        <label className="form-label">Email Address</label>
                        <div className="input-wrap">
                            <Mail size={15} className="input-icon" />
                            <input
                                type="email" required
                                className="form-control login-input"
                                placeholder="you@royalstarboys.com"
                                value={form.email}
                                onChange={(e) => setForm({ ...form, email: e.target.value })}
                            />
                        </div>
                    </div>

                    <div className="form-group">
                        <label className="form-label">Password</label>
                        <div className="input-wrap">
                            <Lock size={15} className="input-icon" />
                            <input
                                type={showPass ? 'text' : 'password'} required
                                className="form-control login-input"
                                placeholder="••••••••"
                                value={form.password}
                                onChange={(e) => setForm({ ...form, password: e.target.value })}
                            />
                            <button type="button" className="input-eye" onClick={() => setShowPass(!showPass)}>
                                {showPass ? <EyeOff size={15} /> : <Eye size={15} />}
                            </button>
                        </div>
                    </div>

                    <button
                        type="submit"
                        className="btn btn-primary btn-lg login-btn"
                        disabled={loading}
                    >
                        {loading
                            ? <><span className="spinner" style={{ width: 18, height: 18, borderWidth: 2 }} />Signing in…</>
                            : 'Sign In →'
                        }
                    </button>
                </form>

                <p className="login-footer">🔒 Secure member-only access</p>
            </div>
        </div>
    );
}
