import { useState, useEffect } from 'react';
import api from '../services/api';
import { PlusCircle, X } from 'lucide-react';
import toast from 'react-hot-toast';
import { useSocket } from '../context/SocketContext';

const fmt = (n) => `₹${Number(n || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}`;

export default function RepaymentsPage() {
    const [repayments, setRepayments] = useState([]);
    const [activeLoans, setActiveLoans] = useState([]);
    const [loading, setLoading] = useState(true);
    const [modal, setModal] = useState(false);
    const [form, setForm] = useState({ loan_id: '', amount: '', months: '', notes: '' });
    const [selectedLoan, setSelectedLoan] = useState(null);
    const [saving, setSaving] = useState(false);
    const socketRef = useSocket();

    const fetchAll = async () => {
        try {
            const [rRes, lRes, gRes] = await Promise.all([api.get('/repayments'), api.get('/loans'), api.get('/group')]);
            setRepayments(rRes.data.repayments);
            setActiveLoans(lRes.data.loans.filter(l => l.status === 'active'));
            // Cache interest rate from group config for live previews
            if (!window.gConfig) window.gConfig = gRes.data.config.interest_rate;
        } finally { setLoading(false); }
    };
    useEffect(() => { fetchAll(); }, []);
    useEffect(() => {
        const s = socketRef?.current;
        if (!s) return;
        s.on('repayment_completed', fetchAll);
        return () => s.off('repayment_completed', fetchAll);
    }, [socketRef]);

    const handleLoanChange = (e) => {
        const id = Number(e.target.value);
        const loan = activeLoans.find(l => l.id === id);
        setSelectedLoan(loan || null);
        setForm(f => ({ ...f, loan_id: id, amount: '', months: '' }));
    };

    const handleSubmit = async (e) => {
        e.preventDefault(); setSaving(true);
        try {
            const r = await api.post('/repayments', { loan_id: Number(form.loan_id), amount: Number(form.amount), months: Number(form.months), notes: form.notes });
            toast.success(r.data.loan_closed ? '✅ Loan fully repaid and closed!' : 'Repayment recorded!');
            setModal(false); setForm({ loan_id: '', amount: '', months: '', notes: '' }); setSelectedLoan(null);
            fetchAll();
        } catch (err) { toast.error(err.response?.data?.message || 'Error'); }
        finally { setSaving(false); }
    };

    return (
        <div>
            <div className="page-header">
                <div><h2 className="page-title">Repayments</h2><p className="page-sub">Record loan repayments — interest returns to group fund automatically</p></div>
                <button className="btn btn-primary" onClick={() => setModal(true)}><PlusCircle size={16} /> Record Repayment</button>
            </div>

            <div className="card">
                {loading ? <div className="spinner-center"><div className="spinner" /></div> : (
                    <div className="table-wrap">
                        <table>
                            <thead><tr><th>Member</th><th>Loan Principal</th><th>Amount Paid</th><th>Principal Portion</th><th>Interest Portion</th><th>Date</th><th>Notes</th></tr></thead>
                            <tbody>
                                {repayments.map(r => (
                                    <tr key={r.id}>
                                        <td className="fw-600">{r.member_name}</td>
                                        <td>{fmt(r.loan_principal)}</td>
                                        <td className="fw-600" style={{ color: '#10b981' }}>{fmt(r.amount)}</td>
                                        <td>{fmt(r.principal_portion)}</td>
                                        <td style={{ color: '#6366f1' }}>{fmt(r.interest_portion)}</td>
                                        <td className="text-muted text-sm">{new Date(r.created_at).toLocaleDateString('en-IN')}</td>
                                        <td className="text-muted text-sm">{r.notes || '—'}</td>
                                    </tr>
                                ))}
                                {!repayments.length && <tr><td colSpan={7} style={{ textAlign: 'center', padding: '2rem', color: 'var(--text2)' }}>No repayments recorded</td></tr>}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>

            {modal && (
                <div className="modal-overlay" onClick={e => e.target === e.currentTarget && setModal(false)}>
                    <div className="modal">
                        <div className="modal-header">
                            <span className="modal-title">Record Repayment</span>
                            <button className="modal-close" onClick={() => setModal(false)}><X size={20} /></button>
                        </div>
                        <form onSubmit={handleSubmit}>
                            <div className="form-group">
                                <label className="form-label">Active Loan *</label>
                                <select required className="form-control" value={form.loan_id} onChange={handleLoanChange}>
                                    <option value="">Select active loan</option>
                                    {activeLoans.map(l => (
                                        <option key={l.id} value={l.id}>{l.member_name} — {fmt(l.remaining_balance)} remaining</option>
                                    ))}
                                </select>
                            </div>
                            {selectedLoan && (
                                <div style={{ background: 'var(--bg3)', borderRadius: 8, padding: '.75rem 1rem', marginBottom: '1rem', fontSize: '.85rem' }}>
                                    <div className="flex gap-3"><span className="text-muted">Principal Disbursed:</span><strong>{fmt(selectedLoan.principal)}</strong></div>
                                    {form.months ? (
                                        <>
                                            <div className="flex gap-3"><span className="text-muted">Calculated Interest ({form.months}mo):</span><strong style={{ color: '#f59e0b' }}>{fmt(Number(selectedLoan.principal) * (window.gConfig || 0) * Number(form.months) / 100)}</strong></div>
                                            <div className="flex gap-3"><span className="text-muted">Total Payable:</span><strong style={{ color: '#ef4444' }}>{fmt(Number(selectedLoan.principal) + (Number(selectedLoan.principal) * (window.gConfig || 0) * Number(form.months) / 100))}</strong></div>
                                        </>
                                    ) : (
                                        <div className="text-muted text-sm mt-1"><em>Enter months below to calculate remaining interest</em></div>
                                    )}
                                </div>
                            )}
                            <div className="grid-2">
                                <div className="form-group">
                                    <label className="form-label">Duration (months) *</label>
                                    <input type="number" required min="0" max="120" className="form-control" value={form.months} onChange={e => setForm({ ...form, months: e.target.value })} placeholder="e.g. 3" />
                                </div>
                                <div className="form-group">
                                    <label className="form-label">Amount Paid (₹) *</label>
                                    <input type="number" required min="1" step="0.01" className="form-control" value={form.amount} onChange={e => setForm({ ...form, amount: e.target.value })} />
                                </div>
                            </div>
                            <div className="form-group">
                                <label className="form-label">Notes</label>
                                <input className="form-control" value={form.notes} onChange={e => setForm({ ...form, notes: e.target.value })} placeholder="Optional note" />
                            </div>
                            <div className="flex gap-2">
                                <button type="button" className="btn btn-outline w-full" onClick={() => setModal(false)}>Cancel</button>
                                <button type="submit" className="btn btn-primary w-full" disabled={saving}>{saving ? 'Saving...' : 'Record Repayment'}</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}
