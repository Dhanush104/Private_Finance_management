import { useState, useEffect } from 'react';
import api from '../services/api';
import { CheckCircle, XCircle, Banknote, Clock, TrendingUp, AlertCircle, Filter, PlusCircle, X } from 'lucide-react';
import toast from 'react-hot-toast';
import { useSocket } from '../context/SocketContext';
import { useAuth } from '../context/AuthContext';

const fmt = (n) => `₹${Number(n || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}`;

function StatusBadge({ status }) {
    const map = { pending: 'badge-warning', active: 'badge-success', closed: 'badge-outline', rejected: 'badge-danger' };
    return <span className={`badge ${map[status] || 'badge-outline'}`}>{status}</span>;
}

export default function LoansPage() {
    const { user } = useAuth();
    const isAdmin = user?.role === 'admin';
    const [loans, setLoans] = useState([]);
    const [loading, setLoading] = useState(true);
    const [filter, setFilter] = useState('all');
    const [modal, setModal] = useState(false);
    const [members, setMembers] = useState([]);
    const [config, setConfig] = useState(null);
    const [form, setForm] = useState({ principal: '', duration_months: '1', purpose: '', user_id: '' });
    const [saving, setSaving] = useState(false);
    const [preview, setPreview] = useState(null);
    const socketRef = useSocket();

    const fetchLoans = async () => {
        try {
            const [lRes, gRes] = await Promise.all([
                api.get('/loans'),
                api.get('/group')
            ]);
            setLoans(lRes.data.loans);
            setConfig(gRes.data.config);

            if (isAdmin) {
                const mRes = await api.get('/members');
                setMembers(mRes.data.users.filter(usr => usr.role !== 'admin' || usr.id === user.id));
            }
        }
        finally { setLoading(false); }
    };
    useEffect(() => { fetchLoans(); }, []);
    useEffect(() => {
        const s = socketRef?.current;
        if (!s) return;
        s.on('loan_approved', fetchLoans);
        return () => s.off('loan_approved', fetchLoans);
    }, [socketRef]);

    const approve = async (id) => {
        try { await api.post(`/loans/${id}/approve`); toast.success('Loan approved & disbursed!'); fetchLoans(); }
        catch (err) { toast.error(err.response?.data?.message || 'Error'); }
    };
    const reject = async (id) => {
        if (!confirm('Reject this loan request?')) return;
        try { await api.post(`/loans/${id}/reject`); toast.success('Loan rejected'); fetchLoans(); }
        catch (err) { toast.error(err.response?.data?.message || 'Error'); }
    };

    const filtered = filter === 'all' ? loans : loans.filter(l => l.status === filter);

    /* Quick summary counts */
    const counts = { pending: 0, active: 0, closed: 0, rejected: 0 };
    loans.forEach(l => { if (counts[l.status] !== undefined) counts[l.status]++; });
    const totalActive = loans.filter(l => l.status === 'active').reduce((s, l) => s + Number(l.remaining_balance), 0);
    const totalDisbursed = loans.reduce((s, l) => s + Number(l.principal), 0);

    const filterTabs = ['all', 'pending', 'active', 'closed', 'rejected'];
    const filterColors = { pending: '#f59e0b', active: '#10b981', closed: 'var(--text2)', rejected: '#f43f5e', all: 'var(--primary)' };

    /* Repaid % for active loans */
    const repaidPct = (l) => l.total_payable > 0
        ? Math.round(((l.total_payable - l.remaining_balance) / l.total_payable) * 100)
        : 0;

    const calcPreview = () => {
        if (!config || !form.principal || !form.duration_months) { setPreview(null); return; }
        const P = Number(form.principal), R = config.interest_rate, T = Number(form.duration_months);
        const SI = (P * R * T) / 100;
        const perMonth = (P * R) / 100;
        setPreview({ interest: SI, total: P + SI, perMonth: perMonth });
    };
    useEffect(() => { calcPreview(); }, [form.principal, form.duration_months, config]);

    const handleSubmit = async (e) => {
        e.preventDefault(); setSaving(true);
        if (!form.user_id) {
            toast.error('Please select a member');
            setSaving(false);
            return;
        }
        try {
            await api.post('/loans', { principal: Number(form.principal), duration_months: Number(form.duration_months), purpose: form.purpose, user_id: Number(form.user_id) });
            toast.success('Loan recorded! Awaiting your approval.');
            setModal(false); setForm({ principal: '', duration_months: '1', purpose: '', user_id: '' }); fetchLoans();
        } catch (err) { toast.error(err.response?.data?.message || 'Error'); }
        finally { setSaving(false); }
    };

    return (
        <div>
            {/* Header */}
            <div className="page-header">
                <div>
                    <h2 className="page-title">Loan Management</h2>
                    <p className="page-sub">Review, approve and track all member loans</p>
                </div>
                {isAdmin && (
                    <button className="btn btn-primary" onClick={() => setModal(true)}>
                        <PlusCircle size={16} /> Record Loan
                    </button>
                )}
            </div>

            {/* Summary stat cards */}
            <div className="grid-4 mb-3">
                <div className="stat-card">
                    <div className="stat-icon" style={{ background: 'rgba(14,165,233,.12)' }}><Banknote size={21} color="#0ea5e9" /></div>
                    <div className="stat-body">
                        <div className="stat-label">Total Disbursed</div>
                        <div className="stat-value" style={{ color: '#0ea5e9' }}>{fmt(totalDisbursed)}</div>
                        <div className="stat-sub">{loans.length} loan(s) total</div>
                    </div>
                </div>
                <div className="stat-card">
                    <div className="stat-icon" style={{ background: 'rgba(245,158,11,.12)' }}><Clock size={21} color="#f59e0b" /></div>
                    <div className="stat-body">
                        <div className="stat-label">Pending Approval</div>
                        <div className="stat-value" style={{ color: '#f59e0b' }}>{counts.pending}</div>
                        <div className="stat-sub">{counts.pending ? 'Awaiting your review' : 'All clear'}</div>
                    </div>
                </div>
                <div className="stat-card">
                    <div className="stat-icon" style={{ background: 'rgba(16,185,129,.12)' }}><TrendingUp size={21} color="#10b981" /></div>
                    <div className="stat-body">
                        <div className="stat-label">Active Loans</div>
                        <div className="stat-value" style={{ color: '#10b981' }}>{counts.active}</div>
                        <div className="stat-sub">Outstanding: {fmt(totalActive)}</div>
                    </div>
                </div>
                <div className="stat-card">
                    <div className="stat-icon" style={{ background: 'rgba(244,63,94,.08)' }}><AlertCircle size={21} color="#f43f5e" /></div>
                    <div className="stat-body">
                        <div className="stat-label">Rejected</div>
                        <div className="stat-value" style={{ color: 'var(--text2)' }}>{counts.rejected}</div>
                        <div className="stat-sub">{counts.closed} closed out</div>
                    </div>
                </div>
            </div>

            {/* Table Card */}
            <div className="card">
                {/* Card header + filter pills */}
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '1rem', paddingBottom: '.75rem', borderBottom: '1px solid var(--border)', flexWrap: 'wrap', gap: '.75rem' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '.6rem' }}>
                        <div style={{ width: 30, height: 30, borderRadius: 8, background: 'rgba(14,165,233,.1)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                            <Banknote size={15} color="#0ea5e9" />
                        </div>
                        <span className="fw-700" style={{ fontSize: '.9rem' }}>All Loans</span>
                    </div>

                    {/* Filter pills */}
                    <div style={{ display: 'flex', gap: '.35rem', background: 'var(--bg3)', borderRadius: 10, padding: '.3rem', border: '1px solid var(--border)' }}>
                        {filterTabs.map(f => (
                            <button key={f} onClick={() => setFilter(f)} style={{
                                padding: '.3rem .75rem', borderRadius: 7, border: 'none',
                                cursor: 'pointer', fontSize: '.78rem', fontWeight: filter === f ? 700 : 500,
                                background: filter === f ? 'var(--bg2)' : 'transparent',
                                color: filter === f ? filterColors[f] : 'var(--text2)',
                                boxShadow: filter === f ? 'var(--shadow-sm)' : 'none',
                                fontFamily: 'inherit', textTransform: 'capitalize',
                                border: filter === f ? '1px solid var(--border)' : '1px solid transparent',
                                transition: 'all .18s',
                            }}>
                                {f}{f !== 'all' && counts[f] > 0 && <span style={{ marginLeft: '.3rem', opacity: .7 }}>({counts[f]})</span>}
                            </button>
                        ))}
                    </div>
                </div>

                {loading ? (
                    <div className="spinner-center"><div className="spinner" /></div>
                ) : (
                    <div className="table-wrap">
                        <table>
                            <thead>
                                <tr>
                                    <th>Member</th>
                                    <th>Principal</th>
                                    <th>Interest</th>
                                    <th>Total Payable</th>
                                    <th>Remaining</th>
                                    <th>Progress</th>
                                    <th>Duration</th>
                                    <th>Due Date</th>
                                    <th>Status</th>
                                    {isAdmin && <th>Actions</th>}
                                </tr>
                            </thead>
                            <tbody>
                                {filtered.map(l => {
                                    const pct = repaidPct(l);
                                    return (
                                        <tr key={l.id}>
                                            <td>
                                                <div className="fw-700">{l.member_name}</div>
                                                {l.purpose && <div className="text-muted text-sm">{l.purpose}</div>}
                                            </td>
                                            <td className="fw-600">{fmt(l.principal)}</td>
                                            <td>
                                                <span style={{ color: '#10b981', fontWeight: 600 }}>{fmt(l.dynamic_interest_amount ?? l.interest_amount)}</span>
                                                <span className="text-muted text-sm"> ({l.interest_rate}%, {l.monthsElapsed ?? l.duration_months} mo.)</span>
                                            </td>
                                            <td className="fw-600">{fmt(l.dynamic_total_payable ?? l.total_payable)}</td>
                                            <td>
                                                <span className="fw-700" style={{ color: (l.dynamic_remaining_balance ?? l.remaining_balance) > 0 && l.status === 'active' ? '#f43f5e' : 'var(--text2)' }}>
                                                    {fmt(l.dynamic_remaining_balance ?? l.remaining_balance)}
                                                </span>
                                            </td>
                                            {/* Repayment progress bar */}
                                            <td style={{ minWidth: 90 }}>
                                                {l.status !== 'pending' && l.status !== 'rejected' ? (
                                                    <div>
                                                        <div style={{ background: 'var(--bg3)', borderRadius: 99, height: 6, overflow: 'hidden', marginBottom: '.2rem', border: '1px solid var(--border)' }}>
                                                            <div style={{ width: `${pct}%`, background: pct === 100 ? '#10b981' : 'linear-gradient(90deg,#0ea5e9,#10b981)', height: '100%', borderRadius: 99 }} />
                                                        </div>
                                                        <div style={{ fontSize: '.68rem', color: 'var(--text3)', fontWeight: 600 }}>{pct}% repaid</div>
                                                    </div>
                                                ) : <span className="text-muted text-sm">—</span>}
                                            </td>
                                            <td className="text-sm">{l.duration_months} mo.</td>
                                            <td className="text-muted text-sm">{l.due_date ? new Date(l.due_date).toLocaleDateString('en-IN') : '—'}</td>
                                            <td><StatusBadge status={l.status} /></td>
                                            {isAdmin && (
                                                <td>
                                                    {l.status === 'pending' ? (
                                                        <div style={{ display: 'flex', gap: '.4rem' }}>
                                                            <button
                                                                onClick={() => approve(l.id)}
                                                                style={{ display: 'flex', alignItems: 'center', gap: '.3rem', padding: '.3rem .6rem', borderRadius: 7, background: 'rgba(16,185,129,.12)', border: '1px solid rgba(16,185,129,.25)', color: '#10b981', cursor: 'pointer', fontSize: '.78rem', fontWeight: 700, fontFamily: 'inherit' }}
                                                                title="Approve"
                                                            >
                                                                <CheckCircle size={13} /> Approve
                                                            </button>
                                                            <button
                                                                onClick={() => reject(l.id)}
                                                                style={{ display: 'flex', alignItems: 'center', gap: '.3rem', padding: '.3rem .6rem', borderRadius: 7, background: 'rgba(244,63,94,.08)', border: '1px solid rgba(244,63,94,.2)', color: '#f43f5e', cursor: 'pointer', fontSize: '.78rem', fontWeight: 700, fontFamily: 'inherit' }}
                                                                title="Reject"
                                                            >
                                                                <XCircle size={13} /> Reject
                                                            </button>
                                                        </div>
                                                    ) : <span className="text-muted text-sm">—</span>}
                                                </td>
                                            )}
                                        </tr>
                                    );
                                })}
                                {!filtered.length && (
                                    <tr><td colSpan={isAdmin ? 10 : 9} style={{ textAlign: 'center', padding: '3rem', color: 'var(--text2)' }}>
                                        <Banknote size={36} style={{ margin: '0 auto .75rem', opacity: .2, display: 'block' }} />
                                        No {filter === 'all' ? '' : filter} loans found
                                    </td></tr>
                                )}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>

            {modal && (
                <div className="modal-overlay" onClick={e => e.target === e.currentTarget && setModal(false)}>
                    <div className="modal">
                        <div className="modal-header">
                            <span className="modal-title">Record a Loan</span>
                            <button className="modal-close" onClick={() => setModal(false)}><X size={20} /></button>
                        </div>
                        <form onSubmit={handleSubmit}>
                            <div className="form-group">
                                <label className="form-label">Member *</label>
                                <select required className="form-control" value={form.user_id} onChange={e => setForm({ ...form, user_id: e.target.value })}>
                                    <option value="">Select a member...</option>
                                    {members.map(m => (
                                        <option key={m.id} value={m.id}>{m.name}</option>
                                    ))}
                                </select>
                            </div>
                            <div className="grid-2">
                                <div className="form-group">
                                    <label className="form-label">Principal Amount (₹) *</label>
                                    <input type="number" required min="1" className="form-control" value={form.principal} onChange={e => setForm({ ...form, principal: e.target.value })} />
                                </div>
                                <div className="form-group">
                                    <label className="form-label">Duration (months) *</label>
                                    <input type="number" required min="1" max="60" className="form-control" value={form.duration_months} onChange={e => setForm({ ...form, duration_months: e.target.value })} />
                                </div>
                            </div>
                            <div className="form-group">
                                <label className="form-label">Purpose</label>
                                <input className="form-control" value={form.purpose} onChange={e => setForm({ ...form, purpose: e.target.value })} placeholder="Brief reason for loan" />
                            </div>
                            {preview && (
                                <div style={{ background: 'var(--bg3)', borderRadius: 8, padding: '.75rem 1rem', marginBottom: '1rem', fontSize: '.875rem' }}>
                                    <div className="fw-600 mb-1">Loan Preview <span className="text-muted" style={{ fontWeight: 400 }}>(SI = P × R × T / 100)</span></div>
                                    <div className="flex gap-3"><span className="text-muted">Interest Rate:</span><strong>{config?.interest_rate}% per month</strong></div>
                                    <div className="flex gap-3"><span className="text-muted">Per Month Interest:</span><strong style={{ color: '#8b5cf6' }}>{fmt(preview.perMonth)}</strong></div>
                                    <div className="flex gap-3"><span className="text-muted">Total Interest Amount:</span><strong style={{ color: '#f59e0b' }}>{fmt(preview.interest)}</strong></div>
                                    <div className="flex gap-3"><span className="text-muted">Total Payable:</span><strong style={{ color: '#ef4444' }}>{fmt(preview.total)}</strong></div>
                                </div>
                            )}
                            <div className="flex gap-2">
                                <button type="button" className="btn btn-outline w-full" onClick={() => setModal(false)}>Cancel</button>
                                <button type="submit" className="btn btn-primary w-full" disabled={saving}>{saving ? 'Recording...' : 'Record Request'}</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}
