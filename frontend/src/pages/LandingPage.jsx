import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import {
    Star, Eye, EyeOff, Lock, Mail, AlertCircle, X,
    Shield, TrendingUp, Users, Zap, ChevronRight, Award, PiggyBank
} from 'lucide-react';
import './LandingPage.css';

/* ── Login Modal ─────────────────────────────────────────────────── */
function LoginModal({ onClose }) {
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
        <div className="lp-modal-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
            <div className="lp-modal">
                {/* Close */}
                <button className="lp-modal-close" onClick={onClose} aria-label="Close">
                    <X size={18} />
                </button>

                {/* Brand */}
                <div className="lp-modal-brand">
                    <div className="lp-modal-icon">
                        <Star size={22} fill="currentColor" />
                    </div>
                    <div>
                        <div className="lp-modal-title">Sign In</div>
                        <div className="lp-modal-sub">Royal Star Boys Portal</div>
                    </div>
                </div>

                {error && (
                    <div className="lp-modal-error">
                        <AlertCircle size={14} />
                        {error}
                    </div>
                )}

                <form onSubmit={handleSubmit}>
                    <div className="lp-field">
                        <label>Email Address</label>
                        <div className="lp-input-wrap">
                            <Mail size={15} className="lp-input-icon" />
                            <input
                                type="email" required
                                placeholder="you@royalstarboys.com"
                                value={form.email}
                                onChange={(e) => setForm({ ...form, email: e.target.value })}
                            />
                        </div>
                    </div>
                    <div className="lp-field">
                        <label>Password</label>
                        <div className="lp-input-wrap">
                            <Lock size={15} className="lp-input-icon" />
                            <input
                                type={showPass ? 'text' : 'password'} required
                                placeholder="••••••••"
                                value={form.password}
                                onChange={(e) => setForm({ ...form, password: e.target.value })}
                            />
                            <button type="button" className="lp-eye" onClick={() => setShowPass(!showPass)}>
                                {showPass ? <EyeOff size={14} /> : <Eye size={14} />}
                            </button>
                        </div>
                    </div>
                    <button type="submit" className="lp-submit-btn" disabled={loading}>
                        {loading
                            ? <><span className="lp-spinner" /> Signing in…</>
                            : <>Sign In <ChevronRight size={16} /></>
                        }
                    </button>
                </form>

                <p className="lp-modal-footer">🔒 Secure member-only access</p>
            </div>
        </div>
    );
}

/* ── Landing Page ────────────────────────────────────────────────── */
const features = [
    { icon: PiggyBank, color: '#0ea5e9', title: 'Group Fund Management', desc: 'Track and grow your collective fund with full transparency and real-time updates.' },
    { icon: TrendingUp, color: '#10b981', title: 'Monthly Contributions', desc: 'Automated contribution tracking with status reports for every member every month.' },
    { icon: Zap, color: '#f59e0b', title: 'Simple Interest Loans', desc: 'Apply for loans from the group fund with transparent interest calculations.' },
    { icon: Award, color: '#f43f5e', title: 'Credit Score System', desc: 'Build your credit score by staying consistent with contributions and repayments.' },
    { icon: Shield, color: '#7c3aed', title: 'Secure & Private', desc: 'Member-only access with role-based permissions. Your data stays in your group.' },
    { icon: Users, color: '#0ea5e9', title: 'Admin Controls', desc: 'Full admin dashboard with member management, reports, and group settings.' },
];

const stats = [
    { value: '100%', label: 'Transparent' },
    { value: 'Real-time', label: 'Updates' },
    { value: '3-tier', label: 'Reports' },
    { value: 'Secure', label: 'Access' },
];

export default function LandingPage() {
    const [showLogin, setShowLogin] = useState(false);

    return (
        <div className="lp-root">
            {/* Animated background */}
            <div className="lp-bg-orb lp-orb-1" />
            <div className="lp-bg-orb lp-orb-2" />
            <div className="lp-bg-orb lp-orb-3" />
            <div className="lp-grid-overlay" />

            {/* Navbar */}
            <nav className="lp-nav">
                <div className="lp-nav-brand">
                    <div className="lp-nav-icon"><Star size={18} fill="currentColor" /></div>
                    <span>Royal Star Boys</span>
                </div>
                <button className="lp-nav-btn" onClick={() => setShowLogin(true)}>
                    Member Login <ChevronRight size={14} />
                </button>
            </nav>

            {/* Hero */}
            <section className="lp-hero">
                <div className="lp-badge">
                    <span className="lp-badge-dot" />
                    Private Community Fund
                </div>
                <h1 className="lp-hero-title">
                    Manage Your Group's
                    <span className="lp-hero-accent"> Financial Future</span>
                    <br />Together.
                </h1>
                <p className="lp-hero-sub">
                    A secure, transparent platform for private group fund management —
                    contributions, loans, repayments, and real-time reports all in one place.
                </p>
                <div className="lp-hero-btns">
                    <button className="lp-btn-primary" onClick={() => setShowLogin(true)}>
                        Sign In to Portal <ChevronRight size={16} />
                    </button>
                    <a href="#features" className="lp-btn-ghost">Explore Features</a>
                </div>

                {/* Stats strip */}
                <div className="lp-stats">
                    {stats.map(({ value, label }) => (
                        <div key={label} className="lp-stat">
                            <div className="lp-stat-value">{value}</div>
                            <div className="lp-stat-label">{label}</div>
                        </div>
                    ))}
                </div>
            </section>

            {/* Features */}
            <section className="lp-features" id="features">
                <div className="lp-section-label">What We Offer</div>
                <h2 className="lp-section-title">Everything your group needs</h2>
                <div className="lp-features-grid">
                    {features.map(({ icon: Icon, color, title, desc }) => (
                        <div key={title} className="lp-feature-card">
                            <div className="lp-feature-icon" style={{ background: `${color}18`, border: `1px solid ${color}30` }}>
                                <Icon size={22} color={color} />
                            </div>
                            <div className="lp-feature-title">{title}</div>
                            <div className="lp-feature-desc">{desc}</div>
                        </div>
                    ))}
                </div>
            </section>

            {/* CTA */}
            <section className="lp-cta">
                <div className="lp-cta-card">
                    <h2 className="lp-cta-title">Ready to take control?</h2>
                    <p className="lp-cta-sub">Sign in to your Royal Star Boys portal and see your group's financial health in real time.</p>
                    <button className="lp-btn-primary" onClick={() => setShowLogin(true)}>
                        Sign In Now <ChevronRight size={16} />
                    </button>
                </div>
            </section>

            {/* Footer */}
            <footer className="lp-footer">
                <div className="lp-nav-brand">
                    <div className="lp-nav-icon"><Star size={14} fill="currentColor" /></div>
                    <span>Royal Star Boys</span>
                </div>
                <p>Private Community Fund Management · Member access only</p>
            </footer>

            {/* Login Modal */}
            {showLogin && <LoginModal onClose={() => setShowLogin(false)} />}
        </div>
    );
}
