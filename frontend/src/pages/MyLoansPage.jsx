import { useState, useEffect } from 'react';
import api from '../services/api';
import { Banknote, X, PlusCircle } from 'lucide-react';
import toast from 'react-hot-toast';
import { useAuth } from '../context/AuthContext';

const fmt = (n) => `₹${Number(n || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}`;

export default function MyLoansPage() {
    const { user } = useAuth();
    const [loans, setLoans] = useState([]);
    const [loading, setLoading] = useState(true);
    const [modal, setModal] = useState(false);
    const [config, setConfig] = useState(null);
    const [form, setForm] = useState({ principal: '', duration_months: '1', purpose: '' });
    const [saving, setSaving] = useState(false);
    const [preview, setPreview] = useState(null);

    const fetchAll = async () => {
        try {
            const [l, g] = await Promise.all([api.get('/loans'), api.get('/group')]);
            setLoans(l.data.loans.filter(loan => loan.user_id === user?.id));
            setConfig(g.data.config);
        } finally { setLoading(false); }
    };
    useEffect(() => { fetchAll(); }, []);

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
        try {
            await api.post('/loans', { principal: Number(form.principal), duration_months: Number(form.duration_months), purpose: form.purpose });
            toast.success('Loan request submitted!');
            setModal(false); setForm({ principal: '', duration_months: '1', purpose: '' }); fetchAll();
        } catch (err) { toast.error(err.response?.data?.message || 'Error'); }
        finally { setSaving(false); }
    };

    const statusBadge = (s) => {
        const m = { pending: 'badge-warning', active: 'badge-success', closed: 'badge-muted', rejected: 'badge-danger' };
        return <span className={`badge ${m[s]}`}>{s}</span>;
    };

    return (
        <div>
            <div className="page-header">
                <div><h2 className="page-title">My Loans</h2><p className="page-sub">Request and track your loans</p></div>
                <button className="btn btn-primary" onClick={() => setModal(true)}><PlusCircle size={16} /> Request Loan</button>
            </div>

            <div className="card">
                {loading ? <div className="spinner-center"><div className="spinner" /></div> : (
                    <div className="table-wrap">
                        <table>
                            <thead><tr><th>Principal</th><th>Interest</th><th>Total Payable</th><th>Remaining</th><th>Duration</th><th>Due Date</th><th>Status</th><th>Purpose</th></tr></thead>
                            <tbody>
                                {loans.map(l => (
                                    <tr key={l.id}>
                                        <td className="fw-600">{fmt(l.principal)}</td>
                                        <td>{fmt(l.dynamic_interest_amount || l.interest_amount)} <span className="text-muted text-sm">({l.interest_rate}%)</span></td>
                                        <td>{fmt(l.dynamic_total_payable || l.total_payable)}</td>
                                        <td><span style={{ fontWeight: 700, color: (l.dynamic_remaining_balance || l.remaining_balance) > 0 ? '#ef4444' : '#10b981' }}>{fmt(l.dynamic_remaining_balance ?? l.remaining_balance)}</span></td>
                                        <td>{l.duration_months} mo.</td>
                                        <td className="text-muted text-sm">{l.due_date ? new Date(l.due_date).toLocaleDateString('en-IN') : '—'}</td>
                                        <td>{statusBadge(l.status)}</td>
                                        <td className="text-muted text-sm">{l.purpose || '—'}</td>
                                    </tr>
                                ))}
                                {!loans.length && <tr><td colSpan={8} style={{ textAlign: 'center', padding: '2rem', color: 'var(--text2)' }}>No loan requests yet</td></tr>}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>

            {modal && (
                <div className="modal-overlay" onClick={e => e.target === e.currentTarget && setModal(false)}>
                    <div className="modal">
                        <div className="modal-header">
                            <span className="modal-title">Request a Loan</span>
                            <button className="modal-close" onClick={() => setModal(false)}><X size={20} /></button>
                        </div>
                        <form onSubmit={handleSubmit}>
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
                                <button type="submit" className="btn btn-primary w-full" disabled={saving}>{saving ? 'Submitting...' : 'Submit Request'}</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}
