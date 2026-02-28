import { useState, useEffect } from 'react';
import api from '../services/api';
import { PlusCircle, X, CreditCard, CheckCircle, XCircle, Clock, TrendingUp, Calendar } from 'lucide-react';
import toast from 'react-hot-toast';
import { useAuth } from '../context/AuthContext';

const fmt = (n) => `₹${Number(n || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}`;
const thisMonth = new Date().toISOString().slice(0, 7);

function StatusBadge({ status }) {
    const map = { paid: 'badge-success', pending: 'badge-warning', missed: 'badge-danger', not_recorded: 'badge-outline' };
    return <span className={`badge ${map[status] || 'badge-outline'}`}>{status?.replace('_', ' ')}</span>;
}

function StatusIcon({ status }) {
    if (status === 'paid') return <CheckCircle size={16} color="#10b981" />;
    if (status === 'missed') return <XCircle size={16} color="#f43f5e" />;
    return <Clock size={16} color="#f59e0b" />;
}

export default function MyContributionsPage() {
    const { user } = useAuth();
    const [contribs, setContribs] = useState([]);
    const [stats, setStats] = useState({});
    const [loading, setLoading] = useState(true);
    const [modal, setModal] = useState(false);
    const [saving, setSaving] = useState(false);
    const [config, setConfig] = useState(null);
    const [form, setForm] = useState({ month_year: thisMonth, amount: '', notes: '' });

    const fetchData = async () => {
        try {
            const [c, d, g] = await Promise.all([
                api.get('/contributions'),
                api.get('/dashboard/member'),
                api.get('/group'),
            ]);
            setContribs(c.data.contributions.filter(contribution => contribution.user_id === user?.id));
            setStats(d.data.dashboard.contribution_stats || {});
            setConfig(g.data.config);
            if (g.data.config) setForm(f => ({ ...f, amount: g.data.config.monthly_subscription }));
        } finally { setLoading(false); }
    };
    useEffect(() => { fetchData(); }, []);

    const handleSubmit = async (e) => {
        e.preventDefault(); setSaving(true);
        try {
            await api.post('/contributions', { ...form, amount: Number(form.amount) });
            toast.success('Contribution recorded!');
            setModal(false); fetchData();
        } catch (err) {
            toast.error(err.response?.data?.message || 'Error recording contribution');
        } finally { setSaving(false); }
    };

    const paid = stats.paid_months || 0;
    const total = stats.total_months || 0;
    const missed = total - paid;
    const payRate = total > 0 ? Math.round((paid / total) * 100) : 0;

    return (
        <div>
            {/* Header */}
            <div className="page-header">
                <div>
                    <h2 className="page-title">My Contributions</h2>
                    <p className="page-sub">Your monthly contribution history</p>
                </div>
                <button className="btn btn-primary" onClick={() => setModal(true)}>
                    <PlusCircle size={16} /> Record Contribution
                </button>
            </div>

            {/* Stats */}
            <div className="grid-3 mb-3">
                <div className="stat-card">
                    <div className="stat-icon" style={{ background: 'rgba(16,185,129,.12)' }}><TrendingUp size={21} color="#10b981" /></div>
                    <div className="stat-body">
                        <div className="stat-label">Total Paid</div>
                        <div className="stat-value" style={{ color: '#10b981' }}>{fmt(stats.total_paid)}</div>
                        <div className="stat-sub">Lifetime contributions</div>
                    </div>
                </div>
                <div className="stat-card">
                    <div className="stat-icon" style={{ background: 'rgba(14,165,233,.12)' }}><CheckCircle size={21} color="#0ea5e9" /></div>
                    <div className="stat-body">
                        <div className="stat-label">Months Paid</div>
                        <div className="stat-value" style={{ color: '#0ea5e9' }}>{paid} <span style={{ fontSize: '.9rem', color: 'var(--text2)', fontWeight: 500 }}>/ {total}</span></div>
                        {/* tiny progress */}
                        <div style={{ marginTop: '.4rem', background: 'var(--border)', borderRadius: 99, height: 5, overflow: 'hidden', maxWidth: 100 }}>
                            <div style={{ width: `${payRate}%`, background: '#0ea5e9', height: '100%', borderRadius: 99, transition: 'width .5s' }} />
                        </div>
                    </div>
                </div>
                <div className="stat-card">
                    <div className="stat-icon" style={{ background: missed > 0 ? 'rgba(244,63,94,.10)' : 'rgba(16,185,129,.10)' }}>
                        {missed > 0 ? <XCircle size={21} color="#f43f5e" /> : <CheckCircle size={21} color="#10b981" />}
                    </div>
                    <div className="stat-body">
                        <div className="stat-label">Missed</div>
                        <div className="stat-value" style={{ color: missed > 0 ? '#f43f5e' : '#10b981' }}>{missed}</div>
                        <div className="stat-sub">{missed === 0 ? 'Perfect record! 🎉' : 'month(s) not paid'}</div>
                    </div>
                </div>
            </div>

            {/* Table Card */}
            <div className="card">
                <div style={{ display: 'flex', alignItems: 'center', gap: '.6rem', marginBottom: '1rem', paddingBottom: '.75rem', borderBottom: '1px solid var(--border)' }}>
                    <div style={{ width: 30, height: 30, borderRadius: 8, background: 'rgba(14,165,233,.1)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        <Calendar size={15} color="#0ea5e9" />
                    </div>
                    <span className="fw-700" style={{ fontSize: '.9rem' }}>Contribution History</span>
                </div>
                {loading ? (
                    <div className="spinner-center"><div className="spinner" /></div>
                ) : (
                    <div className="table-wrap">
                        <table>
                            <thead><tr><th>Month</th><th>Amount</th><th>Status</th><th>Paid On</th><th>Notes</th></tr></thead>
                            <tbody>
                                {contribs.map(c => (
                                    <tr key={c.id}>
                                        <td>
                                            <div style={{ display: 'flex', alignItems: 'center', gap: '.5rem' }}>
                                                <StatusIcon status={c.status} />
                                                <span className="fw-600">{c.month_year}</span>
                                            </div>
                                        </td>
                                        <td className="fw-600" style={{ color: c.status === 'paid' ? '#10b981' : 'var(--text)' }}>
                                            {c.amount > 0 ? fmt(c.amount) : '—'}
                                        </td>
                                        <td><StatusBadge status={c.status} /></td>
                                        <td className="text-muted text-sm">{c.paid_at ? new Date(c.paid_at).toLocaleDateString('en-IN') : '—'}</td>
                                        <td className="text-muted text-sm">{c.notes || '—'}</td>
                                    </tr>
                                ))}
                                {!contribs.length && (
                                    <tr><td colSpan={5} style={{ textAlign: 'center', padding: '3rem', color: 'var(--text2)' }}>
                                        <CreditCard size={36} style={{ margin: '0 auto .75rem', opacity: .2, display: 'block' }} />
                                        No contributions recorded yet
                                    </td></tr>
                                )}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>

            {/* Record Contribution Modal */}
            {modal && (
                <div className="modal-overlay" onClick={e => e.target === e.currentTarget && setModal(false)}>
                    <div className="modal">
                        <div className="modal-header">
                            <div style={{ display: 'flex', alignItems: 'center', gap: '.65rem' }}>
                                <div style={{ width: 36, height: 36, borderRadius: 10, background: 'rgba(16,185,129,.12)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                    <CreditCard size={17} color="#10b981" />
                                </div>
                                <div>
                                    <div className="modal-title">Record Contribution</div>
                                    {config && <div style={{ fontSize: '.72rem', color: 'var(--text3)' }}>Fixed: {fmt(config.monthly_subscription)}/month</div>}
                                </div>
                            </div>
                            <button className="modal-close" onClick={() => setModal(false)}><X size={18} /></button>
                        </div>

                        <form onSubmit={handleSubmit}>
                            <div className="form-group">
                                <label className="form-label">Month *</label>
                                <input
                                    required type="month" className="form-control"
                                    value={form.month_year}
                                    onChange={e => setForm({ ...form, month_year: e.target.value })}
                                />
                            </div>
                            <div className="form-group">
                                <label className="form-label">Amount (₹) *</label>
                                <input
                                    type="number" required min="1" className="form-control"
                                    value={form.amount} readOnly={!!config}
                                    onChange={e => setForm({ ...form, amount: e.target.value })}
                                />
                                {config && <small className="text-muted">Fixed monthly subscription — cannot be changed</small>}
                            </div>
                            <div className="form-group">
                                <label className="form-label">Notes <span className="text-muted">(optional)</span></label>
                                <input
                                    className="form-control" value={form.notes} placeholder="e.g. Online transfer"
                                    onChange={e => setForm({ ...form, notes: e.target.value })}
                                />
                            </div>
                            <div style={{ display: 'flex', gap: '.75rem', marginTop: '1.25rem' }}>
                                <button type="button" className="btn btn-outline w-full" onClick={() => setModal(false)}>Cancel</button>
                                <button type="submit" className="btn btn-primary w-full" disabled={saving}>
                                    {saving ? <><span className="btn-spinner" /> Recording…</> : 'Record Payment'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}
