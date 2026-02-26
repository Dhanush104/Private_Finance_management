import { useState, useEffect } from 'react';
import api from '../services/api';
import { PlusCircle, X, CheckCircle, XCircle } from 'lucide-react';
import toast from 'react-hot-toast';
import { useAuth } from '../context/AuthContext';

const thisMonth = new Date().toISOString().slice(0, 7);

export default function ContributionsPage() {
    const { user } = useAuth();
    const isAdmin = user?.role === 'admin';
    const [contribs, setContribs] = useState([]);
    const [members, setMembers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [modal, setModal] = useState(false);
    const [form, setForm] = useState({ user_id: '', month_year: thisMonth, amount: '', status: 'paid', notes: '' });
    const [saving, setSaving] = useState(false);
    const [config, setConfig] = useState(null);

    const fetchAll = async () => {
        try {
            const [cRes, mRes, gRes] = await Promise.all([
                api.get('/contributions'), api.get('/members'), api.get('/group')
            ]);
            setContribs(cRes.data.contributions);
            setMembers(mRes.data.members.filter(m => m.is_active));
            setConfig(gRes.data.config);
            if (gRes.data.config) setForm(f => ({ ...f, amount: gRes.data.config.monthly_subscription }));
        } finally { setLoading(false); }
    };
    useEffect(() => { fetchAll(); }, []);

    const handleSubmit = async (e) => {
        e.preventDefault(); setSaving(true);
        try {
            await api.post('/contributions', { ...form, user_id: Number(form.user_id), amount: Number(form.amount) });
            toast.success('Contribution recorded!');
            setModal(false); fetchAll();
        } catch (err) { toast.error(err.response?.data?.message || 'Error'); }
        finally { setSaving(false); }
    };

    const statusBadge = (s) => {
        const map = { paid: 'badge-success', pending: 'badge-warning', missed: 'badge-danger', rejected: 'badge-outline' };
        return <span className={`badge ${map[s] || 'badge-outline'}`}>{s}</span>;
    };

    const approve = async (id) => {
        try { await api.post(`/contributions/${id}/approve`); toast.success('Contribution approved!'); fetchAll(); }
        catch (err) { toast.error(err.response?.data?.message || 'Error'); }
    };
    const reject = async (id) => {
        if (!confirm('Reject this contribution?')) return;
        try { await api.post(`/contributions/${id}/reject`); toast.success('Contribution rejected'); fetchAll(); }
        catch (err) { toast.error(err.response?.data?.message || 'Error'); }
    };

    return (
        <div>
            <div className="page-header">
                <div><h2 className="page-title">Contributions</h2><p className="page-sub">Monthly subscription: {config ? `₹${config.monthly_subscription}` : '...'}</p></div>
                <button className="btn btn-primary" onClick={() => setModal(true)}><PlusCircle size={16} /> Record Contribution</button>
            </div>

            <div className="card">
                {loading ? <div className="spinner-center"><div className="spinner" /></div> : (
                    <div className="table-wrap">
                        <table>
                            <thead><tr><th>Member</th><th>Month</th><th>Amount</th><th>Status</th><th>Paid At</th><th>Notes</th>{isAdmin && <th>Actions</th>}</tr></thead>
                            <tbody>
                                {contribs.map(c => (
                                    <tr key={c.id}>
                                        <td className="fw-600">{c.member_name}</td>
                                        <td>{c.month_year}</td>
                                        <td className="fw-600">₹{Number(c.amount).toLocaleString('en-IN')}</td>
                                        <td>{statusBadge(c.status)}</td>
                                        <td className="text-muted text-sm">{c.paid_at ? new Date(c.paid_at).toLocaleDateString('en-IN') : '—'}</td>
                                        <td className="text-muted text-sm">{c.notes || '—'}</td>
                                        {isAdmin && (
                                            <td>
                                                {c.status === 'pending' ? (
                                                    <div style={{ display: 'flex', gap: '.4rem' }}>
                                                        <button onClick={() => approve(c.id)} style={{ display: 'flex', alignItems: 'center', gap: '.3rem', padding: '.3rem .6rem', borderRadius: 7, background: 'rgba(16,185,129,.12)', border: '1px solid rgba(16,185,129,.25)', color: '#10b981', cursor: 'pointer', fontSize: '.78rem', fontWeight: 700, fontFamily: 'inherit' }} title="Approve">
                                                            <CheckCircle size={13} /> Approve
                                                        </button>
                                                        <button onClick={() => reject(c.id)} style={{ display: 'flex', alignItems: 'center', gap: '.3rem', padding: '.3rem .6rem', borderRadius: 7, background: 'rgba(244,63,94,.08)', border: '1px solid rgba(244,63,94,.2)', color: '#f43f5e', cursor: 'pointer', fontSize: '.78rem', fontWeight: 700, fontFamily: 'inherit' }} title="Reject">
                                                            <XCircle size={13} /> Reject
                                                        </button>
                                                    </div>
                                                ) : <span className="text-muted text-sm">—</span>}
                                            </td>
                                        )}
                                    </tr>
                                ))}
                                {!contribs.length && <tr><td colSpan={isAdmin ? 7 : 6} style={{ textAlign: 'center', padding: '2rem', color: 'var(--text2)' }}>No contributions recorded yet</td></tr>}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>

            {modal && (
                <div className="modal-overlay" onClick={e => e.target === e.currentTarget && setModal(false)}>
                    <div className="modal">
                        <div className="modal-header">
                            <span className="modal-title">Record Contribution</span>
                            <button className="modal-close" onClick={() => setModal(false)}><X size={20} /></button>
                        </div>
                        <form onSubmit={handleSubmit}>
                            <div className="form-group">
                                <label className="form-label">Member *</label>
                                <select required className="form-control" value={form.user_id} onChange={e => setForm({ ...form, user_id: e.target.value })}>
                                    <option value="">Select member</option>
                                    {members.map(m => <option key={m.id} value={m.id}>{m.name}</option>)}
                                </select>
                            </div>
                            <div className="grid-2">
                                <div className="form-group">
                                    <label className="form-label">Month (YYYY-MM) *</label>
                                    <input required className="form-control" value={form.month_year} onChange={e => setForm({ ...form, month_year: e.target.value })} placeholder="2025-01" pattern="\d{4}-\d{2}" />
                                </div>
                                <div className="form-group">
                                    <label className="form-label">Amount (₹) *</label>
                                    <input type="number" required min="1" className="form-control" value={form.amount} onChange={e => setForm({ ...form, amount: e.target.value })} />
                                </div>
                            </div>
                            <div className="form-group">
                                <label className="form-label">Status</label>
                                <select className="form-control" value={form.status} onChange={e => setForm({ ...form, status: e.target.value })}>
                                    <option value="paid">Paid</option>
                                    <option value="pending">Pending</option>
                                    <option value="missed">Missed</option>
                                </select>
                            </div>
                            <div className="form-group">
                                <label className="form-label">Notes</label>
                                <input className="form-control" value={form.notes} onChange={e => setForm({ ...form, notes: e.target.value })} placeholder="Optional note" />
                            </div>
                            <div style={{ display: 'flex', gap: '.75rem' }}>
                                <button type="button" className="btn btn-outline w-full" onClick={() => setModal(false)}>Cancel</button>
                                <button type="submit" className="btn btn-primary w-full" disabled={saving}>{saving ? 'Saving...' : 'Record'}</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}
