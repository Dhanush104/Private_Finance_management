import { useState, useEffect } from 'react';
import api from '../services/api';
import { useSocket } from '../context/SocketContext';
import {
    AreaChart, Area, BarChart, Bar, XAxis, YAxis,
    CartesianGrid, Tooltip, ResponsiveContainer, LineChart, Line
} from 'recharts';
import {
    TrendingUp, Users, Banknote, PiggyBank, Star,
    FileText, Calendar, BarChart2, Globe, ArrowUpRight,
    CheckCircle, XCircle, Clock, Zap
} from 'lucide-react';

const fmt = (n) => `₹${Number(n || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}`;
const thisMonth = new Date().toISOString().slice(0, 7);
const thisYear = new Date().getFullYear().toString();

const scoreColor = (s) => s >= 750 ? '#10b981' : s >= 600 ? '#0ea5e9' : s >= 450 ? '#f59e0b' : '#f43f5e';

/* ── Shared tiny components ──────────────────────── */
function ScoreBadge({ score }) {
    return <span style={{ fontWeight: 700, color: scoreColor(score) }}>{score}</span>;
}
function StatusBadge({ status }) {
    const map = { paid: 'badge-success', missed: 'badge-danger', pending: 'badge-warning', not_recorded: 'badge-outline' };
    return <span className={`badge ${map[status] || 'badge-outline'}`}>{status?.replace('_', ' ')}</span>;
}

/* Custom tooltip */
const ChartTip = ({ active, payload, label }) => {
    if (!active || !payload?.length) return null;
    return (
        <div style={{ background: 'var(--bg2)', border: '1px solid var(--border)', borderRadius: 10, padding: '.6rem .9rem', fontSize: '.8rem', boxShadow: '0 4px 18px rgba(0,0,0,.2)' }}>
            <div style={{ fontWeight: 700, marginBottom: '.25rem', color: 'var(--text2)' }}>{label}</div>
            {payload.map(p => (
                <div key={p.name} style={{ color: p.color || 'var(--text)', fontWeight: 600 }}>
                    {`₹${Number(p.value).toLocaleString('en-IN')}`}
                </div>
            ))}
        </div>
    );
};

/* Stat card helper */
function StatCard({ label, value, sub, icon: Icon, color, bg }) {
    return (
        <div className="stat-card">
            {Icon && <div className="stat-icon" style={{ background: bg || `${color}18` }}><Icon size={21} color={color} /></div>}
            <div className="stat-body">
                <div className="stat-label">{label}</div>
                <div className="stat-value" style={{ fontSize: '1.5rem', color }}>{value}</div>
                {sub && <div className="stat-sub">{sub}</div>}
            </div>
        </div>
    );
}

/* Card header helper */
function CardHead({ title, icon: Icon, color = 'var(--primary)' }) {
    return (
        <div style={{ display: 'flex', alignItems: 'center', gap: '.6rem', marginBottom: '1rem', paddingBottom: '.75rem', borderBottom: '1px solid var(--border)' }}>
            {Icon && <div style={{ width: 30, height: 30, borderRadius: 8, background: `${color}18`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Icon size={15} color={color} /></div>}
            <span className="fw-700" style={{ fontSize: '.9rem' }}>{title}</span>
        </div>
    );
}

/* ── OVERVIEW TAB ────────────────────────────────────────────────────────────── */
function OverviewTab({ data }) {
    const stats = [
        { label: 'Group Fund', value: fmt(data.total_fund), icon: PiggyBank, color: '#0ea5e9', sub: data.group_name },
        { label: 'Active Members', value: data.total_members, icon: Users, color: '#10b981', sub: 'Registered members' },
        { label: 'Active Loans', value: data.active_loans, icon: Banknote, color: '#f59e0b', sub: `${data.pending_loans} pending approval` },
        { label: 'Interest Earned', value: fmt(data.total_interest_earned), icon: TrendingUp, color: '#10b981', sub: 'All-time received' },
    ];

    const txBadge = (type) => {
        const m = { contribution: 'badge-success', loan_disbursement: 'badge-warning', repayment: 'badge-info' };
        return <span className={`badge ${m[type] || 'badge-muted'}`}>{type.replace(/_/g, ' ')}</span>;
    };

    return (
        <>
            {/* Stats */}
            <div className="grid-4 mb-3">
                {stats.map(s => <StatCard key={s.label} {...s} />)}
            </div>

            {/* Charts row */}
            <div className="grid-2 mb-3">
                <div className="card">
                    <CardHead title="Monthly Contributions — Last 12 Months" icon={BarChart2} color="#0ea5e9" />
                    <div className="chart-wrap">
                        <ResponsiveContainer width="100%" height="100%">
                            <AreaChart data={data.monthly_contributions}>
                                <defs>
                                    <linearGradient id="cg1" x1="0" y1="0" x2="0" y2="1">
                                        <stop offset="5%" stopColor="#0ea5e9" stopOpacity={0.28} />
                                        <stop offset="95%" stopColor="#0ea5e9" stopOpacity={0} />
                                    </linearGradient>
                                </defs>
                                <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
                                <XAxis dataKey="month_year" tick={{ fontSize: 10, fill: 'var(--text2)' }} />
                                <YAxis tick={{ fontSize: 10, fill: 'var(--text2)' }} />
                                <Tooltip content={<ChartTip />} />
                                <Area type="monotone" dataKey="total" stroke="#0ea5e9" fill="url(#cg1)" strokeWidth={2.5} dot={false} />
                            </AreaChart>
                        </ResponsiveContainer>
                    </div>
                </div>

                {/* Leaderboard */}
                <div className="card">
                    <CardHead title="Credit Score Leaderboard" icon={Star} color="#f59e0b" />
                    {data.credit_leaderboard.map((m, i) => {
                        const medals = ['🥇', '🥈', '🥉'];
                        return (
                            <div key={m.id} style={{
                                display: 'flex', alignItems: 'center', gap: '.85rem',
                                padding: '.6rem .5rem', borderRadius: 9,
                                background: i === 0 ? 'rgba(245,158,11,.06)' : 'transparent',
                                marginBottom: '.2rem', transition: 'background .2s',
                            }}>
                                <span style={{ width: 26, textAlign: 'center', fontSize: i < 3 ? '1rem' : '.8rem', fontWeight: 700, color: 'var(--text2)' }}>
                                    {i < 3 ? medals[i] : `#${i + 1}`}
                                </span>
                                <div style={{ flex: 1 }}>
                                    <div className="fw-600" style={{ fontSize: '.875rem' }}>{m.name}</div>
                                </div>
                                <div style={{ display: 'flex', alignItems: 'center', gap: '.4rem' }}>
                                    <div style={{ width: 64, height: 5, borderRadius: 99, background: 'var(--bg3)', overflow: 'hidden' }}>
                                        <div style={{ width: `${Math.round(((m.credit_score - 300) / 600) * 100)}%`, height: '100%', background: scoreColor(m.credit_score), borderRadius: 99 }} />
                                    </div>
                                    <ScoreBadge score={m.credit_score} />
                                </div>
                            </div>
                        );
                    })}
                </div>
            </div>

            {/* Recent Transactions */}
            <div className="card">
                <CardHead title="Recent Transactions" icon={Zap} color="#0ea5e9" />
                <div className="table-wrap">
                    <table>
                        <thead><tr><th>Type</th><th>Member</th><th>Amount</th><th>Fund After</th><th>Description</th><th>Date</th></tr></thead>
                        <tbody>
                            {data.recent_transactions.map(t => (
                                <tr key={t.id}>
                                    <td>{txBadge(t.type)}</td>
                                    <td className="fw-600">{t.member_name || '—'}</td>
                                    <td className="fw-600" style={{ color: t.type === 'loan_disbursement' ? 'var(--warning)' : 'var(--success)' }}>{fmt(t.amount)}</td>
                                    <td className="text-muted text-sm">{fmt(t.group_fund_after)}</td>
                                    <td className="text-muted text-sm">{t.description}</td>
                                    <td className="text-muted text-sm">{new Date(t.created_at).toLocaleDateString('en-IN')}</td>
                                </tr>
                            ))}
                            {!data.recent_transactions.length && (
                                <tr><td colSpan={6} style={{ textAlign: 'center', padding: '2.5rem', color: 'var(--text2)' }}>No transactions yet</td></tr>
                            )}
                        </tbody>
                    </table>
                </div>
            </div>
        </>
    );
}

/* ── MONTHLY REPORT TAB ──────────────────────────────────────────────────────── */
function MonthlyTab() {
    const [month, setMonth] = useState(thisMonth);
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(false);

    const load = async (m) => {
        setLoading(true);
        try { const r = await api.get(`/dashboard/report/monthly?month=${m}`); setData(r.data); }
        catch (e) { console.error(e); } finally { setLoading(false); }
    };
    useEffect(() => { load(month); }, [month]);
    const s = data?.report?.summary;

    return (
        <div>
            {/* Picker */}
            <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '1.5rem' }}>
                <label className="fw-700" style={{ fontSize: '.875rem' }}>Month:</label>
                <input type="month" className="form-control" style={{ width: 'auto' }} value={month} onChange={e => setMonth(e.target.value)} />
            </div>

            {loading && <div className="spinner-center"><div className="spinner" /></div>}

            {s && (
                <>
                    <div className="grid-4 mb-3">
                        <StatCard label="Collected" value={fmt(s.total_collected)} color="#10b981" icon={CheckCircle} />
                        <StatCard label="Members Paid" value={s.paid_count} color="#0ea5e9" icon={Users} />
                        <StatCard label="Missed" value={s.missed_count} color="#f43f5e" icon={XCircle} />
                        <StatCard label="Repayments" value={fmt(s.total_repaid)} color="#f59e0b" icon={ArrowUpRight} />
                    </div>
                    <div className="grid-2 mb-3">
                        <StatCard label="Loans Disbursed" value={fmt(s.total_disbursed)} color="#f59e0b" sub={`${s.loan_count} loan(s) this month`} />
                        <StatCard label="Interest Collected" value={fmt(s.interest_collected)} color="#10b981" />
                    </div>

                    <div className="card mb-3">
                        <CardHead title={`Member Contribution Status — ${month}`} icon={Users} />
                        <div className="table-wrap">
                            <table>
                                <thead><tr><th>Member</th><th>Amount</th><th>Status</th><th>Paid On</th><th>Notes</th></tr></thead>
                                <tbody>
                                    {data.report.member_contributions.map(m => (
                                        <tr key={m.id}>
                                            <td className="fw-600">{m.name}</td>
                                            <td>{m.amount > 0 ? fmt(m.amount) : '—'}</td>
                                            <td><StatusBadge status={m.status} /></td>
                                            <td className="text-muted text-sm">{m.paid_at ? new Date(m.paid_at).toLocaleDateString('en-IN') : '—'}</td>
                                            <td className="text-muted text-sm">{m.notes || '—'}</td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    </div>

                    {data.report.repayments_received.length > 0 && (
                        <div className="card mb-3">
                            <CardHead title={`Repayments Received — ${month}`} icon={ArrowUpRight} color="#10b981" />
                            <div className="table-wrap">
                                <table>
                                    <thead><tr><th>Member</th><th>Amount</th><th>Principal</th><th>Interest</th><th>Date</th></tr></thead>
                                    <tbody>
                                        {data.report.repayments_received.map(r => (
                                            <tr key={r.id}>
                                                <td className="fw-600">{r.member_name}</td>
                                                <td className="fw-600">{fmt(r.amount)}</td>
                                                <td className="text-muted text-sm">{fmt(r.principal_portion)}</td>
                                                <td style={{ color: '#10b981', fontWeight: 600, fontSize: '.85rem' }}>{fmt(r.interest_portion)}</td>
                                                <td className="text-muted text-sm">{new Date(r.created_at).toLocaleDateString('en-IN')}</td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    )}

                    {data.report.loans_disbursed.length > 0 && (
                        <div className="card">
                            <CardHead title={`Loans Disbursed — ${month}`} icon={Banknote} color="#f59e0b" />
                            <div className="table-wrap">
                                <table>
                                    <thead><tr><th>Member</th><th>Principal</th><th>Duration</th><th>Total Payable</th><th>Status</th></tr></thead>
                                    <tbody>
                                        {data.report.loans_disbursed.map(l => (
                                            <tr key={l.id}>
                                                <td className="fw-600">{l.member_name}</td>
                                                <td>{fmt(l.principal)}</td>
                                                <td>{l.duration_months} months</td>
                                                <td>{fmt(l.total_payable)}</td>
                                                <td><span className={`badge ${l.status === 'active' ? 'badge-warning' : 'badge-success'}`}>{l.status}</span></td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    )}
                </>
            )}
        </div>
    );
}

/* ── YEARLY REPORT TAB ───────────────────────────────────────────────────────── */
function YearlyTab() {
    const [year, setYear] = useState(thisYear);
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(false);
    const years = Array.from({ length: 6 }, (_, i) => (new Date().getFullYear() - i).toString());

    const load = async (y) => {
        setLoading(true);
        try { const r = await api.get(`/dashboard/report/yearly?year=${y}`); setData(r.data); }
        catch (e) { console.error(e); } finally { setLoading(false); }
    };
    useEffect(() => { load(year); }, [year]);
    const s = data?.report?.summary;

    return (
        <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '1.5rem' }}>
                <label className="fw-700" style={{ fontSize: '.875rem' }}>Year:</label>
                <select className="form-control" style={{ width: 'auto' }} value={year} onChange={e => setYear(e.target.value)}>
                    {years.map(y => <option key={y} value={y}>{y}</option>)}
                </select>
            </div>

            {loading && <div className="spinner-center"><div className="spinner" /></div>}

            {s && (
                <>
                    <div className="grid-4 mb-3">
                        <StatCard label="Total Collected" value={fmt(s.total_collected)} color="#10b981" icon={CheckCircle} />
                        <StatCard label="Total Disbursed" value={fmt(s.total_disbursed)} color="#f59e0b" icon={Banknote} />
                        <StatCard label="Total Repaid" value={fmt(s.total_repaid)} color="#0ea5e9" icon={ArrowUpRight} />
                        <StatCard label="Interest Earned" value={fmt(s.total_interest)} color="#10b981" icon={TrendingUp} />
                    </div>

                    <div className="card mb-3">
                        <CardHead title={`Monthly Breakdown — ${year}`} icon={BarChart2} color="#0ea5e9" />
                        <div className="chart-wrap">
                            <ResponsiveContainer width="100%" height="100%">
                                <BarChart data={data.report.monthly_breakdown}>
                                    <defs>
                                        <linearGradient id="bg1" x1="0" y1="0" x2="0" y2="1">
                                            <stop offset="0%" stopColor="#0ea5e9" stopOpacity={1} />
                                            <stop offset="100%" stopColor="#2563eb" stopOpacity={1} />
                                        </linearGradient>
                                    </defs>
                                    <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
                                    <XAxis dataKey="month_year" tick={{ fontSize: 10, fill: 'var(--text2)' }} />
                                    <YAxis tick={{ fontSize: 10, fill: 'var(--text2)' }} />
                                    <Tooltip content={<ChartTip />} />
                                    <Bar dataKey="collected" fill="url(#bg1)" radius={[6, 6, 0, 0]} />
                                </BarChart>
                            </ResponsiveContainer>
                        </div>
                    </div>

                    <div className="card">
                        <CardHead title={`Member-wise Yearly Summary — ${year}`} icon={Users} />
                        <div className="table-wrap">
                            <table>
                                <thead><tr><th>Member</th><th>Total Paid</th><th>Months Paid</th><th>Months Missed</th><th>Credit Score</th></tr></thead>
                                <tbody>
                                    {data.report.member_summary.map(m => (
                                        <tr key={m.id}>
                                            <td className="fw-700">{m.name}</td>
                                            <td className="fw-600" style={{ color: '#10b981' }}>{fmt(m.total_paid)}</td>
                                            <td className="fw-600" style={{ color: '#0ea5e9' }}>{m.months_paid}</td>
                                            <td className="fw-600" style={{ color: m.months_missed > 0 ? '#f43f5e' : 'var(--text2)' }}>{m.months_missed}</td>
                                            <td><ScoreBadge score={m.credit_score} /></td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </>
            )}
        </div>
    );
}

/* ── GROUP REPORT TAB ────────────────────────────────────────────────────────── */
function GroupTab() {
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        api.get('/dashboard/report/group')
            .then(r => setData(r.data.report))
            .catch(console.error)
            .finally(() => setLoading(false));
    }, []);

    if (loading) return <div className="spinner-center"><div className="spinner" /></div>;
    if (!data) return null;
    const a = data.all_time;

    return (
        <div>
            <div className="grid-4 mb-3">
                <StatCard label="Current Fund" value={fmt(data.group.total_fund)} color="#0ea5e9" icon={PiggyBank} />
                <StatCard label="All-time Collections" value={fmt(a.total_contributions)} color="#10b981" icon={CheckCircle} />
                <StatCard label="Total Loaned Out" value={fmt(a.total_loaned)} color="#f59e0b" icon={Banknote} />
                <StatCard label="Interest Earned" value={fmt(a.total_interest_earned)} color="#10b981" icon={TrendingUp} />
            </div>
            <div className="grid-2 mb-3">
                <StatCard label="Total Loans Issued" value={a.total_loans} color="#f59e0b" sub={`${a.active_loans} active • Outstanding: ${fmt(a.outstanding_balance)}`} />
                <StatCard label="Total Repaid" value={fmt(a.total_repaid)} color="#0ea5e9" sub={`Subscription: ${fmt(data.group.monthly_subscription)}/mo • Rate: ${data.group.interest_rate}%`} />
            </div>

            {data.fund_growth.length > 0 && (
                <div className="card mb-3">
                    <CardHead title="Fund Growth Over Time" icon={TrendingUp} color="#10b981" />
                    <div className="chart-wrap">
                        <ResponsiveContainer width="100%" height="100%">
                            <LineChart data={data.fund_growth}>
                                <defs>
                                    <linearGradient id="lg1" x1="0" y1="0" x2="0" y2="1">
                                        <stop offset="5%" stopColor="#10b981" stopOpacity={0.15} />
                                        <stop offset="95%" stopColor="#10b981" stopOpacity={0} />
                                    </linearGradient>
                                </defs>
                                <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
                                <XAxis dataKey="month" tick={{ fontSize: 10, fill: 'var(--text2)' }} />
                                <YAxis tick={{ fontSize: 10, fill: 'var(--text2)' }} />
                                <Tooltip content={<ChartTip />} />
                                <Line type="monotone" dataKey="fund_after" stroke="#10b981" strokeWidth={2.5} dot={false} />
                            </LineChart>
                        </ResponsiveContainer>
                    </div>
                </div>
            )}

            <div className="card">
                <CardHead title="Member Lifetime Summary" icon={Users} />
                <div className="table-wrap">
                    <table>
                        <thead>
                            <tr><th>Member</th><th>Joined</th><th>Contributions</th><th>Paid</th><th>Missed</th><th>Borrowed</th><th>Repaid</th><th>Score</th><th>Status</th></tr>
                        </thead>
                        <tbody>
                            {data.member_lifetimes.map(m => (
                                <tr key={m.id}>
                                    <td className="fw-700">{m.name}</td>
                                    <td className="text-muted text-sm">{m.joined_date ? new Date(m.joined_date).toLocaleDateString('en-IN') : '—'}</td>
                                    <td style={{ color: '#10b981', fontWeight: 600 }}>{fmt(m.lifetime_contributions)}</td>
                                    <td style={{ color: '#0ea5e9', fontWeight: 600 }}>{m.months_paid}</td>
                                    <td style={{ color: m.months_missed > 0 ? '#f43f5e' : 'var(--text2)', fontWeight: 600 }}>{m.months_missed}</td>
                                    <td>{fmt(m.total_borrowed)}</td>
                                    <td>{fmt(m.total_repaid)}</td>
                                    <td><ScoreBadge score={m.credit_score} /></td>
                                    <td><span className={`badge ${m.is_active ? 'badge-success' : 'badge-danger'}`}>{m.is_active ? 'Active' : 'Inactive'}</span></td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    );
}

/* ── MAIN COMPONENT ──────────────────────────────────────────────────────────── */
export default function AdminDashboard() {
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);
    const [activeTab, setActiveTab] = useState('overview');
    const socketRef = useSocket();

    const fetchDash = async () => {
        try { const res = await api.get('/dashboard/admin'); setData(res.data.dashboard); }
        catch (e) { console.error(e); } finally { setLoading(false); }
    };
    useEffect(() => { fetchDash(); }, []);
    useEffect(() => {
        const s = socketRef?.current;
        if (!s) return;
        const reload = () => fetchDash();
        ['contribution_added', 'loan_approved', 'repayment_completed'].forEach(e => s.on(e, reload));
        return () => ['contribution_added', 'loan_approved', 'repayment_completed'].forEach(e => s.off(e, reload));
    }, [socketRef]);

    if (loading) return <div className="spinner-center"><div className="spinner" /></div>;
    if (!data) return <p className="text-muted">Failed to load dashboard.</p>;

    const tabs = [
        { id: 'overview', label: 'Overview', icon: BarChart2 },
        { id: 'monthly', label: 'Monthly Report', icon: Calendar },
        { id: 'yearly', label: 'Yearly Report', icon: FileText },
        { id: 'group', label: 'Group Report', icon: Globe },
    ];

    return (
        <div>
            {/* Page Header */}
            <div className="page-header" style={{ marginBottom: '1.25rem' }}>
                <div>
                    <h2 className="page-title">Admin Dashboard</h2>
                    <p className="page-sub">Analytics & Reports — {data.group_name}</p>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '.5rem', background: 'var(--bg3)', border: '1px solid var(--border)', borderRadius: 10, padding: '.3rem .5rem' }}>
                    <span style={{ width: 8, height: 8, borderRadius: '50%', background: '#10b981', boxShadow: '0 0 5px #10b981', display: 'inline-block' }} />
                    <span className="text-xs text-muted fw-600">Live</span>
                </div>
            </div>

            {/* Premium Tab Bar */}
            <div style={{
                display: 'flex', gap: '.35rem', marginBottom: '1.5rem',
                background: 'var(--bg3)', borderRadius: 12, padding: '.35rem',
                border: '1px solid var(--border)', width: 'fit-content',
            }}>
                {tabs.map(({ id, label, icon: Icon }) => {
                    const active = activeTab === id;
                    return (
                        <button key={id} onClick={() => setActiveTab(id)} style={{
                            display: 'flex', alignItems: 'center', gap: '.4rem',
                            padding: '.5rem 1rem', borderRadius: 9,
                            border: active ? '1px solid var(--border2)' : '1px solid transparent',
                            cursor: 'pointer', fontSize: '.84rem', fontWeight: active ? 700 : 500,
                            background: active ? 'var(--bg2)' : 'transparent',
                            color: active ? 'var(--primary)' : 'var(--text2)',
                            boxShadow: active ? 'var(--shadow-sm)' : 'none',
                            transition: 'all .2s', fontFamily: 'inherit',
                        }}>
                            <Icon size={14} />
                            {label}
                        </button>
                    );
                })}
            </div>

            {activeTab === 'overview' && <OverviewTab data={data} socketRef={socketRef} />}
            {activeTab === 'monthly' && <MonthlyTab />}
            {activeTab === 'yearly' && <YearlyTab />}
            {activeTab === 'group' && <GroupTab />}
        </div>
    );
}
