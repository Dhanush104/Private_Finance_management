import { useState, useEffect } from 'react';
import api from '../services/api';
import { Save, Plus } from 'lucide-react';
import toast from 'react-hot-toast';
import { useAuth } from '../context/AuthContext';

export default function SettingsPage() {
    const { user } = useAuth();
    const isAdmin = user?.role === 'admin';
    const [config, setConfig] = useState({ group_name: '', monthly_subscription: '', interest_rate: '', announcement: '' });
    const [saving, setSaving] = useState(false);
    const [publishing, setPublishing] = useState(false);

    const [addForm, setAddForm] = useState({ amount: '', description: '' });
    const [adding, setAdding] = useState(false);

    const [debitForm, setDebitForm] = useState({ amount: '', description: '', date: '' });
    const [debiting, setDebiting] = useState(false);

    useEffect(() => {
        api.get('/group').then(r => setConfig({
            group_name: r.data.config.group_name,
            monthly_subscription: r.data.config.monthly_subscription,
            interest_rate: r.data.config.interest_rate,
            announcement: r.data.config.announcement || '',
        }));
    }, []);

    const handleSubmit = async (e) => {
        e.preventDefault(); setSaving(true);
        try {
            await api.put('/group', {
                group_name: config.group_name,
                monthly_subscription: Number(config.monthly_subscription),
                interest_rate: Number(config.interest_rate),
            });
            toast.success('Group settings updated!');
        } catch (err) { toast.error(err.response?.data?.message || 'Error'); }
        finally { setSaving(false); }
    };

    const handleAddFunds = async (e) => {
        e.preventDefault();
        setAdding(true);
        try {
            await api.post('/group/add-funds', { amount: Number(addForm.amount), description: addForm.description });
            toast.success('Funds added successfully!');
            setAddForm({ amount: '', description: '' });
        } catch (err) { toast.error(err.response?.data?.message || 'Error'); }
        finally { setAdding(false); }
    };

    const handleDebitFunds = async (e) => {
        e.preventDefault();
        setDebiting(true);
        try {
            await api.post('/group/debit-funds', { amount: Number(debitForm.amount), description: debitForm.description, date: debitForm.date || undefined });
            toast.success('Funds debited successfully!');
            setDebitForm({ amount: '', description: '', date: '' });
        } catch (err) { toast.error(err.response?.data?.message || 'Error'); }
        finally { setDebiting(false); }
    };

    const handlePublishAnnouncement = async (e) => {
        e.preventDefault(); setPublishing(true);
        try {
            await api.put('/group/announcement', { announcement: config.announcement });
            toast.success('Announcement published globally!');
        } catch (err) { toast.error(err.response?.data?.message || 'Error publishing'); }
        finally { setPublishing(false); }
    };

    return (
        <div>
            <div className="page-header">
                <div><h2 className="page-title">Group Settings</h2><p className="page-sub">Configure your private fund group parameters</p></div>
            </div>

            <div style={{ maxWidth: 520 }}>
                <div className="card">
                    <form onSubmit={handleSubmit}>
                        <div className="form-group">
                            <label className="form-label">Group Name</label>
                            <input required className="form-control" value={config.group_name}
                                onChange={e => setConfig({ ...config, group_name: e.target.value })} />
                        </div>
                        <div className="form-group">
                            <label className="form-label">Monthly Subscription (₹)</label>
                            <input type="number" required min="1" step="0.01" className="form-control"
                                value={config.monthly_subscription}
                                onChange={e => setConfig({ ...config, monthly_subscription: e.target.value })} />
                            <small className="text-muted text-sm">Amount each member must contribute monthly</small>
                        </div>
                        <div className="form-group">
                            <label className="form-label">Simple Interest Rate (%)</label>
                            <input type="number" required min="0" max="100" step="0.01" className="form-control"
                                value={config.interest_rate}
                                onChange={e => setConfig({ ...config, interest_rate: e.target.value })} />
                            <small className="text-muted text-sm">SI = (P × R × T) / 100  — applied per loan duration</small>
                        </div>
                        <button type="submit" className="btn btn-primary" disabled={saving}><Save size={16} />{saving ? 'Saving...' : 'Save Settings'}</button>
                    </form>
                </div>

                {isAdmin && (
                    <div className="card mt-2">
                        <h3 style={{ fontWeight: 700, marginBottom: '.75rem' }}>Add Funds to Group Pool</h3>
                        <p className="text-muted text-sm mb-3">Manually inject capital into the group fund. This will be logged in the ledger.</p>
                        <form onSubmit={handleAddFunds}>
                            <div className="form-group">
                                <label className="form-label">Amount (₹)</label>
                                <input type="number" required min="1" step="1" className="form-control"
                                    value={addForm.amount}
                                    onChange={e => setAddForm({ ...addForm, amount: e.target.value })} />
                            </div>
                            <div className="form-group">
                                <label className="form-label">Description / Source</label>
                                <input required className="form-control" placeholder="e.g. Bank Interest, Late Fee Penalty Pool, etc."
                                    value={addForm.description}
                                    onChange={e => setAddForm({ ...addForm, description: e.target.value })} />
                            </div>
                            <button type="submit" className="btn btn-primary" style={{ background: '#10b981', borderColor: '#10b981' }} disabled={adding}>
                                <Plus size={16} />{adding ? 'Adding...' : 'Add Funds'}
                            </button>
                        </form>
                    </div>
                )}

                {isAdmin && (
                    <div className="card mt-2">
                        <h3 style={{ fontWeight: 700, marginBottom: '.75rem', color: '#f43f5e' }}>Debit Funds from Group Pool</h3>
                        <p className="text-muted text-sm mb-3">Withdraw capital from the group fund.</p>
                        <form onSubmit={handleDebitFunds}>
                            <div className="form-group">
                                <label className="form-label">Amount (₹)</label>
                                <input type="number" required min="1" step="1" className="form-control"
                                    value={debitForm.amount}
                                    onChange={e => setDebitForm({ ...debitForm, amount: e.target.value })} />
                            </div>
                            <div className="grid-2">
                                <div className="form-group">
                                    <label className="form-label">Date (Optional)</label>
                                    <input type="date" className="form-control"
                                        value={debitForm.date}
                                        onChange={e => setDebitForm({ ...debitForm, date: e.target.value })} />
                                </div>
                                <div className="form-group">
                                    <label className="form-label">Reason / Purpose</label>
                                    <input required className="form-control" placeholder="e.g. Withdrawal, Expense..."
                                        value={debitForm.description}
                                        onChange={e => setDebitForm({ ...debitForm, description: e.target.value })} />
                                </div>
                            </div>
                            <button type="submit" className="btn btn-primary" style={{ background: '#f43f5e', borderColor: '#f43f5e' }} disabled={debiting}>
                                {debiting ? 'Debiting...' : 'Debit Funds'}
                            </button>
                        </form>
                    </div>
                )}

                <div className="card mt-2">
                    <h3 style={{ fontWeight: 700, marginBottom: '.75rem' }}>Credit Score Rules</h3>
                    {[
                        { event: 'On-time monthly contribution', delta: '+10', col: '#10b981' },
                        { event: 'Missed contribution', delta: '−15', col: '#ef4444' },
                        { event: 'Early full loan repayment', delta: '+20', col: '#10b981' },
                        { event: 'Delayed repayment', delta: '−25', col: '#ef4444' },
                    ].map(r => (
                        <div key={r.event} className="flex items-center gap-3" style={{ padding: '.5rem 0', borderBottom: '1px solid var(--border)' }}>
                            <span style={{ fontWeight: 700, color: r.col, minWidth: 36 }}>{r.delta}</span>
                            <span className="text-sm">{r.event}</span>
                        </div>
                    ))}
                    <small className="text-muted text-sm mt-1" style={{ display: 'block' }}>Range: 300 (poor) – 900 (excellent). Starting score: 500</small>
                </div>

                {isAdmin && (
                    <div className="card mt-2">
                        <h3 style={{ fontWeight: 700, marginBottom: '.75rem', color: '#8b5cf6' }}>Global Announcement</h3>
                        <p className="text-muted text-sm mb-3">Broadcast a message to all members. It will appear at the top of their dashboards. Clear the text to remove the announcement.</p>
                        <form onSubmit={handlePublishAnnouncement}>
                            <div className="form-group">
                                <textarea className="form-control" rows="3" placeholder="Write announcement here..."
                                    value={config.announcement}
                                    onChange={e => setConfig({ ...config, announcement: e.target.value })} />
                            </div>
                            <button type="submit" className="btn btn-primary" style={{ background: '#8b5cf6', borderColor: '#8b5cf6' }} disabled={publishing}>
                                {publishing ? 'Publishing...' : 'Publish Announcement'}
                            </button>
                        </form>
                    </div>
                )}
            </div>
        </div>
    );
}
