import { useState, useEffect } from 'react';
import api from '../services/api';
import { useSocket } from '../context/SocketContext';
import { useAuth } from '../context/AuthContext';
import { TrendingUp, Banknote, CreditCard, Award, CheckCircle, Clock, AlertTriangle, Bell } from 'lucide-react';

const fmt = (n) => `₹${Number(n || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}`;
const scoreColor = (s) => s >= 750 ? '#10b981' : s >= 600 ? '#0ea5e9' : s >= 450 ? '#f59e0b' : '#f43f5e';
const scoreLabel = (s) => s >= 750 ? 'Excellent' : s >= 600 ? 'Good' : s >= 450 ? 'Fair' : 'Poor';

function CardHead({ title, icon: Icon, color = 'var(--primary)' }) {
    return (
        <div style={{ display: 'flex', alignItems: 'center', gap: '.6rem', marginBottom: '1rem', paddingBottom: '.75rem', borderBottom: '1px solid var(--border)' }}>
            {Icon && <div style={{ width: 30, height: 30, borderRadius: 8, background: `${color}18`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Icon size={15} color={color} /></div>}
            <span className="fw-700" style={{ fontSize: '.9rem' }}>{title}</span>
        </div>
    );
}

export default function MemberDashboard() {
    const { user } = useAuth();
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);
    const socketRef = useSocket();

    const fetchDash = async () => {
        try { const r = await api.get('/dashboard/member'); setData(r.data.dashboard); }
        finally { setLoading(false); }
    };
    useEffect(() => { fetchDash(); }, []);
    useEffect(() => {
        const s = socketRef?.current;
        if (!s) return;
        const reload = () => fetchDash();
        ['contribution_added', 'repayment_completed', 'credit_score_updated'].forEach(e => s.on(e, reload));
        return () => ['contribution_added', 'repayment_completed', 'credit_score_updated'].forEach(e => s.off(e, reload));
    }, [socketRef]);

    if (loading) return <div className="spinner-center"><div className="spinner" /></div>;
    if (!data) return <p className="text-muted">Failed to load dashboard.</p>;

    const score = data.user.credit_score;
    const scorePct = Math.round(Math.min(100, Math.max(0, ((score - 300) / 600) * 100)));
    const currentMonth = new Date().toISOString().slice(0, 7);
    const initials = data.user.name.split(' ').map(w => w[0]).join('').toUpperCase().slice(0, 2);

    const contrib = data.current_month_contribution;
    const contribStatus = contrib?.status;

    const txBadge = (type) => {
        const m = { contribution: 'badge-success', loan_disbursement: 'badge-warning', repayment: 'badge-info' };
        return <span className={`badge ${m[type] || 'badge-muted'}`}>{type.replace(/_/g, ' ')}</span>;
    };

    return (
        <div>
            {data.announcement && (
                <div style={{
                    background: 'linear-gradient(90deg, #8b5cf6, #a855f7)', padding: '1rem',
                    borderRadius: 12, color: '#fff', marginBottom: '1.5rem',
                    display: 'flex', alignItems: 'center', gap: '1rem',
                    boxShadow: '0 4px 15px rgba(139, 92, 246, 0.25)'
                }}>
                    <Bell size={24} />
                    <div style={{ flex: 1, fontWeight: 500, fontSize: '.95rem', lineHeight: 1.4 }}>
                        {data.announcement}
                    </div>
                </div>
            )}

            {/* ── Hero Welcome Banner ── */}
            <div style={{
                background: 'linear-gradient(135deg, rgba(14,165,233,.08), rgba(37,99,235,.12))',
                border: '1px solid var(--border2)',
                borderRadius: 'var(--radius)', padding: '1.75rem',
                marginBottom: '1.5rem',
                display: 'flex', alignItems: 'center', gap: '1.5rem', flexWrap: 'wrap',
                position: 'relative', overflow: 'hidden',
            }}>
                {/* bg glow */}
                <div style={{ position: 'absolute', top: -50, right: -50, width: 180, height: 180, borderRadius: '50%', background: 'radial-gradient(circle, rgba(14,165,233,.12), transparent 70%)', pointerEvents: 'none' }} />

                {/* Avatar */}
                <div style={{
                    width: 70, height: 70, borderRadius: '50%', flexShrink: 0,
                    background: 'linear-gradient(135deg, #0ea5e9, #2563eb)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    fontSize: '1.5rem', fontWeight: 800, color: '#fff',
                    boxShadow: '0 0 0 3px rgba(14,165,233,.2), 0 6px 20px rgba(37,99,235,.25)',
                }}>{initials}</div>

                {/* Text */}
                <div style={{ flex: 1 }}>
                    <div className="page-title" style={{ marginBottom: '.25rem' }}>
                        Welcome back, {data.user.name.split(' ')[0]}! 👋
                    </div>
                    <div className="page-sub">{data.group_name} · Monthly subscription: {fmt(data.monthly_subscription)}</div>
                </div>

                {/* Score ring */}
                <div style={{ textAlign: 'center', flexShrink: 0 }}>
                    <svg width="72" height="72" viewBox="0 0 72 72">
                        <circle cx="36" cy="36" r="28" fill="none" stroke="var(--border)" strokeWidth="7" />
                        <circle cx="36" cy="36" r="28" fill="none"
                            stroke={scoreColor(score)} strokeWidth="7"
                            strokeDasharray={`${2 * Math.PI * 28}`}
                            strokeDashoffset={`${2 * Math.PI * 28 * (1 - scorePct / 100)}`}
                            strokeLinecap="round"
                            transform="rotate(-90 36 36)"
                            style={{ transition: 'stroke-dashoffset 1s ease' }}
                        />
                        <text x="36" y="40" textAnchor="middle" fontSize="12" fontWeight="800" fill={scoreColor(score)}>{score}</text>
                    </svg>
                    <div style={{ fontSize: '.68rem', color: 'var(--text3)', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '.4px', marginTop: '.2rem' }}>{scoreLabel(score)}</div>
                </div>
            </div>

            {/* ── Stats Row ── */}
            <div className="grid-4 mb-3">
                {[
                    { label: 'Group Fund', value: fmt(data.group_fund), icon: TrendingUp, color: '#0ea5e9' },
                    { label: 'Total Contributed', value: fmt(data.contribution_stats?.total_paid), icon: CreditCard, color: '#10b981', sub: `${data.contribution_stats?.paid_months}/${data.contribution_stats?.total_months} months paid` },
                    { label: 'Active Loan', value: data.active_loan ? fmt(data.active_loan.remaining_balance) : 'None', icon: Banknote, color: '#f59e0b', sub: data.active_loan ? 'Remaining balance' : 'No active loan' },
                    { label: 'Credit Score', value: score, icon: Award, color: scoreColor(score), sub: scoreLabel(score) },
                ].map(({ label, value, icon: Icon, color, sub }) => (
                    <div key={label} className="stat-card">
                        <div className="stat-icon" style={{ background: `${color}18` }}><Icon size={21} color={color} /></div>
                        <div className="stat-body">
                            <div className="stat-label">{label}</div>
                            <div className="stat-value" style={{ fontSize: '1.4rem', color: label === 'Credit Score' ? color : 'var(--text)' }}>{value}</div>
                            {sub && <div className="stat-sub">{sub}</div>}
                        </div>
                    </div>
                ))}
            </div>

            {/* ── Cards Row ── */}
            <div className="grid-2 mb-3">
                {/* This Month Contribution */}
                <div className="card">
                    <CardHead title={`This Month — ${currentMonth}`} icon={CreditCard} />
                    {contrib ? (
                        <div>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '.75rem', marginBottom: '.75rem' }}>
                                {contribStatus === 'paid'
                                    ? <CheckCircle size={28} color="#10b981" />
                                    : contribStatus === 'missed'
                                        ? <AlertTriangle size={28} color="#f43f5e" />
                                        : <Clock size={28} color="#f59e0b" />
                                }
                                <div>
                                    <div className="fw-700" style={{ fontSize: '1.15rem' }}>{fmt(contrib.amount)}</div>
                                    <span className={`badge ${contribStatus === 'paid' ? 'badge-success' : contribStatus === 'missed' ? 'badge-danger' : 'badge-warning'}`}>{contribStatus?.toUpperCase()}</span>
                                </div>
                            </div>
                            {contrib.paid_at && <p className="text-muted text-sm">Paid on {new Date(contrib.paid_at).toLocaleDateString('en-IN')}</p>}
                            {contrib.notes && <p className="text-muted text-sm" style={{ marginTop: '.25rem' }}>Note: {contrib.notes}</p>}
                        </div>
                    ) : (
                        <div style={{ textAlign: 'center', padding: '1.75rem 0', color: 'var(--text2)' }}>
                            <CreditCard size={34} style={{ margin: '0 auto .5rem', opacity: .25 }} />
                            <p className="text-sm">No contribution recorded this month yet</p>
                        </div>
                    )}
                </div>

                {/* Active Loan */}
                <div className="card">
                    <CardHead title="Active Loan" icon={Banknote} color="#f59e0b" />
                    {data.active_loan ? (
                        <>
                            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '.65rem', marginBottom: '.85rem' }}>
                                {[
                                    ['Principal', fmt(data.active_loan.principal)],
                                    ['Total Payable', fmt(data.active_loan.total_payable)],
                                    ['Interest Rate', `${data.active_loan.interest_rate}%`],
                                    ['Due Date', data.active_loan.due_date ? new Date(data.active_loan.due_date).toLocaleDateString('en-IN') : '—'],
                                ].map(([k, v]) => (
                                    <div key={k}>
                                        <div style={{ fontSize: '.68rem', color: 'var(--text3)', textTransform: 'uppercase', letterSpacing: '.4px', fontWeight: 600 }}>{k}</div>
                                        <div className="fw-700" style={{ fontSize: '.9rem', marginTop: '.15rem' }}>{v}</div>
                                    </div>
                                ))}
                            </div>

                            {/* Repaid progress */}
                            <div style={{ background: 'var(--bg3)', borderRadius: 10, padding: '.85rem 1rem', border: '1px solid var(--border)' }}>
                                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '.45rem' }}>
                                    <span className="text-sm text-muted">Remaining</span>
                                    <span className="fw-700" style={{ color: '#f43f5e', fontSize: '.95rem' }}>{fmt(data.active_loan.remaining_balance)}</span>
                                </div>
                                <div style={{ background: 'var(--border)', borderRadius: 99, height: 8, overflow: 'hidden' }}>
                                    <div style={{
                                        width: `${Math.round(((data.active_loan.total_payable - data.active_loan.remaining_balance) / data.active_loan.total_payable) * 100)}%`,
                                        background: 'linear-gradient(90deg, #0ea5e9, #10b981)', height: 8, borderRadius: 99,
                                        transition: 'width .6s ease',
                                    }} />
                                </div>
                                <div style={{ fontSize: '.7rem', color: 'var(--text3)', marginTop: '.3rem' }}>
                                    {Math.round(((data.active_loan.total_payable - data.active_loan.remaining_balance) / data.active_loan.total_payable) * 100)}% repaid
                                </div>
                            </div>
                        </>
                    ) : (
                        <div style={{ textAlign: 'center', padding: '2rem 0', color: 'var(--text2)' }}>
                            <Banknote size={34} style={{ margin: '0 auto .5rem', opacity: .25 }} />
                            <p className="text-sm">No active loan</p>
                        </div>
                    )}
                </div>
            </div>

            {/* ── Recent Activity ── */}
            <div className="card">
                <CardHead title="Recent Activity" icon={TrendingUp} />
                <div className="table-wrap">
                    <table>
                        <thead><tr><th>Type</th><th>Amount</th><th>Description</th><th>Date</th></tr></thead>
                        <tbody>
                            {data.recent_transactions.map(t => (
                                <tr key={t.id}>
                                    <td>{txBadge(t.type)}</td>
                                    <td className="fw-600" style={{ color: t.type === 'loan_disbursement' ? '#f59e0b' : t.type === 'contribution' ? '#10b981' : '#0ea5e9' }}>{fmt(t.amount)}</td>
                                    <td className="text-muted text-sm">{t.description}</td>
                                    <td className="text-muted text-sm">{new Date(t.created_at).toLocaleDateString('en-IN')}</td>
                                </tr>
                            ))}
                            {!data.recent_transactions.length && (
                                <tr><td colSpan={4} style={{ textAlign: 'center', padding: '2rem', color: 'var(--text2)' }}>No activity yet</td></tr>
                            )}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    );
}
