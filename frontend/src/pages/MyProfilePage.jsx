import { useState, useEffect } from 'react';
import api from '../services/api';
import { useSocket } from '../context/SocketContext';
import { useAuth } from '../context/AuthContext';
import {
    Mail, Phone, Calendar, Shield, Star,
    TrendingUp, CheckCircle, XCircle, Award, Clock
} from 'lucide-react';

const scoreColor = (s) => s >= 750 ? '#10b981' : s >= 600 ? '#0ea5e9' : s >= 450 ? '#f59e0b' : '#f43f5e';
const scoreLabel = (s) => s >= 750 ? 'Excellent' : s >= 600 ? 'Good' : s >= 450 ? 'Fair' : 'Poor';
const scoreClass = (s) => s >= 750 ? 'score-excellent' : s >= 600 ? 'score-good' : s >= 450 ? 'score-fair' : 'score-poor';

const fmt = (n) => `₹${Number(n || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}`;

export default function MyProfilePage() {
    const { user: authUser } = useAuth();
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);
    const socketRef = useSocket();

    const loadUser = async () => {
        try { const r = await api.get('/auth/me'); setUser(r.data.user); }
        finally { setLoading(false); }
    };
    useEffect(() => { loadUser(); }, []);
    useEffect(() => {
        const s = socketRef?.current;
        if (!s) return;
        s.on('credit_score_updated', loadUser);
        return () => s.off('credit_score_updated', loadUser);
    }, [socketRef]);

    if (loading) return <div className="spinner-center"><div className="spinner" /></div>;
    if (!user) return <p className="text-muted text-center mt-3">Failed to load profile.</p>;

    const score = user.credit_score;
    const pct = Math.round(Math.min(100, Math.max(0, ((score - 300) / 600) * 100)));
    const initials = user.name.split(' ').map(w => w[0]).join('').toUpperCase().slice(0, 2);

    const infoRows = [
        { icon: Mail, label: 'Email', value: user.email },
        { icon: Phone, label: 'Phone', value: user.phone || '—' },
        { icon: Calendar, label: 'Joined', value: user.joined_date ? new Date(user.joined_date).toLocaleDateString('en-IN', { day: '2-digit', month: 'long', year: 'numeric' }) : '—' },
        { icon: Clock, label: 'Member Since', value: new Date(user.created_at).toLocaleDateString('en-IN', { day: '2-digit', month: 'long', year: 'numeric' }) },
        { icon: Shield, label: 'Role', value: user.role },
    ];

    const tips = [
        { good: true, text: 'Pay contributions on time', delta: '+10 pts' },
        { good: true, text: 'Repay loans early', delta: '+20 pts' },
        { good: false, text: 'Missed contribution', delta: '−15 pts' },
        { good: false, text: 'Late loan repayment', delta: '−25 pts' },
    ];

    return (
        <div>
            {/* Hero Banner */}
            <div style={{
                background: 'linear-gradient(135deg, rgba(14,165,233,.08), rgba(37,99,235,.12))',
                border: '1px solid var(--border2)',
                borderRadius: 'var(--radius)',
                padding: '2rem',
                marginBottom: '1.5rem',
                display: 'flex', alignItems: 'center', gap: '1.75rem',
                flexWrap: 'wrap',
                position: 'relative', overflow: 'hidden',
            }}>
                {/* background glow */}
                <div style={{
                    position: 'absolute', top: -60, right: -60,
                    width: 200, height: 200, borderRadius: '50%',
                    background: 'radial-gradient(circle, rgba(14,165,233,.12), transparent 70%)',
                    pointerEvents: 'none',
                }} />

                {/* Avatar */}
                <div style={{
                    width: 88, height: 88, borderRadius: '50%', flexShrink: 0,
                    background: 'linear-gradient(135deg, #0ea5e9, #2563eb)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    fontSize: '2rem', fontWeight: 800, color: '#fff',
                    boxShadow: '0 0 0 4px rgba(14,165,233,.2), 0 8px 28px rgba(37,99,235,.3)',
                }}>{initials}</div>

                {/* Info */}
                <div style={{ flex: 1 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '.65rem', flexWrap: 'wrap', marginBottom: '.35rem' }}>
                        <h2 style={{ fontSize: '1.5rem', fontWeight: 800, letterSpacing: '-.02em' }}>{user.name}</h2>
                        <span className={`badge ${user.role === 'admin' ? 'badge-info' : 'badge-primary'}`}>{user.role}</span>
                        <span className={`badge ${user.is_active ? 'badge-success' : 'badge-danger'}`}>
                            {user.is_active ? 'Active' : 'Inactive'}
                        </span>
                    </div>
                    <div style={{ color: 'var(--text2)', fontSize: '.875rem', marginBottom: '1rem' }}>{user.email}</div>
                    <div style={{ display: 'flex', gap: '1.5rem', flexWrap: 'wrap' }}>
                        <div>
                            <div style={{ fontSize: '.7rem', color: 'var(--text3)', textTransform: 'uppercase', letterSpacing: '.5px', fontWeight: 600 }}>Credit Score</div>
                            <div style={{ fontSize: '1.35rem', fontWeight: 800, color: scoreColor(score) }}>{score} <span style={{ fontSize: '.8rem', fontWeight: 600 }}>({scoreLabel(score)})</span></div>
                        </div>
                        <div>
                            <div style={{ fontSize: '.7rem', color: 'var(--text3)', textTransform: 'uppercase', letterSpacing: '.5px', fontWeight: 600 }}>Member Since</div>
                            <div style={{ fontSize: '1rem', fontWeight: 700 }}>{new Date(user.created_at).getFullYear()}</div>
                        </div>
                    </div>
                </div>

                {/* Score ring preview */}
                <div style={{ textAlign: 'center', flexShrink: 0 }}>
                    <svg width="90" height="90" viewBox="0 0 90 90">
                        <circle cx="45" cy="45" r="36" fill="none" stroke="var(--border)" strokeWidth="8" />
                        <circle cx="45" cy="45" r="36" fill="none"
                            stroke={scoreColor(score)} strokeWidth="8"
                            strokeDasharray={`${2 * Math.PI * 36}`}
                            strokeDashoffset={`${2 * Math.PI * 36 * (1 - pct / 100)}`}
                            strokeLinecap="round"
                            transform="rotate(-90 45 45)"
                            style={{ transition: 'stroke-dashoffset 1s ease, stroke .3s' }}
                        />
                        <text x="45" y="49" textAnchor="middle" fontSize="15" fontWeight="800" fill={scoreColor(score)}>{score}</text>
                    </svg>
                    <div style={{ fontSize: '.7rem', color: 'var(--text3)', marginTop: '.25rem', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '.5px' }}>Score</div>
                </div>
            </div>

            {/* Details + Credit Score */}
            <div className="grid-2" style={{ gap: '1.25rem' }}>

                {/* Info Card */}
                <div className="card">
                    <div style={{ display: 'flex', alignItems: 'center', gap: '.65rem', marginBottom: '1.25rem' }}>
                        <div style={{ width: 34, height: 34, borderRadius: 10, background: 'rgba(14,165,233,.1)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                            <Shield size={17} color="#0ea5e9" />
                        </div>
                        <div className="fw-700" style={{ fontSize: '.95rem' }}>Account Details</div>
                    </div>
                    <div>
                        {infoRows.map(({ icon: Icon, label, value }) => (
                            <div key={label} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '.7rem 0', borderBottom: '1px solid var(--border)' }}>
                                <div style={{ display: 'flex', alignItems: 'center', gap: '.55rem', color: 'var(--text2)', fontSize: '.85rem' }}>
                                    <Icon size={14} />
                                    {label}
                                </div>
                                <div className="fw-600" style={{ fontSize: '.875rem', textTransform: label === 'Role' ? 'capitalize' : 'none' }}>{value}</div>
                            </div>
                        ))}
                        {/* Status row */}
                        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '.7rem 0' }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '.55rem', color: 'var(--text2)', fontSize: '.85rem' }}>
                                <Star size={14} />
                                Account Status
                            </div>
                            <span className={`badge ${user.is_active ? 'badge-success' : 'badge-danger'}`}>
                                {user.is_active ? 'Active Member' : 'Inactive'}
                            </span>
                        </div>
                    </div>
                </div>

                {/* Credit Score Card */}
                <div className="card">
                    <div style={{ display: 'flex', alignItems: 'center', gap: '.65rem', marginBottom: '1.25rem' }}>
                        <div style={{ width: 34, height: 34, borderRadius: 10, background: `${scoreColor(score)}18`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                            <Award size={17} color={scoreColor(score)} />
                        </div>
                        <div className="fw-700" style={{ fontSize: '.95rem' }}>Credit Score</div>
                    </div>

                    {/* Big score + bar */}
                    <div style={{ textAlign: 'center', marginBottom: '1.5rem' }}>
                        <div style={{ fontSize: '4.5rem', fontWeight: 900, color: scoreColor(score), lineHeight: 1, letterSpacing: '-.04em' }}>{score}</div>
                        <div style={{ fontSize: '.9rem', fontWeight: 700, color: scoreColor(score), marginTop: '.2rem' }}>{scoreLabel(score)}</div>
                        <div style={{ fontSize: '.75rem', color: 'var(--text3)', marginTop: '.15rem' }}>out of 900</div>

                        {/* Progress bar */}
                        <div style={{ background: 'var(--bg3)', borderRadius: 99, height: 10, margin: '1.1rem auto 0', maxWidth: 280, overflow: 'hidden', border: '1px solid var(--border)' }}>
                            <div style={{
                                width: `${pct}%`, height: '100%', borderRadius: 99,
                                background: `linear-gradient(90deg, #f43f5e 0%, #f59e0b 45%, #10b981 100%)`,
                                transition: 'width .8s cubic-bezier(.22,1,.36,1)',
                            }} />
                        </div>
                        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '.68rem', color: 'var(--text3)', maxWidth: 280, margin: '.4rem auto 0', fontWeight: 500 }}>
                            <span>300 Poor</span><span>600 Good</span><span>900 Excellent</span>
                        </div>
                    </div>

                    <hr className="divider" />

                    {/* Score tips */}
                    <div className="section-label" style={{ marginBottom: '.75rem' }}>How to improve your score</div>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '.5rem' }}>
                        {tips.map(({ good, text, delta }) => (
                            <div key={text} style={{
                                display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                                padding: '.55rem .75rem', borderRadius: '10px',
                                background: good ? 'rgba(16,185,129,.07)' : 'rgba(244,63,94,.06)',
                                border: `1px solid ${good ? 'rgba(16,185,129,.15)' : 'rgba(244,63,94,.12)'}`,
                            }}>
                                <div style={{ display: 'flex', alignItems: 'center', gap: '.5rem', fontSize: '.82rem', color: 'var(--text2)' }}>
                                    {good
                                        ? <CheckCircle size={14} color="#10b981" />
                                        : <XCircle size={14} color="#f43f5e" />
                                    }
                                    {text}
                                </div>
                                <span style={{ fontSize: '.75rem', fontWeight: 700, color: good ? '#10b981' : '#f43f5e' }}>{delta}</span>
                            </div>
                        ))}
                    </div>
                </div>
            </div>
        </div>
    );
}
