import { useState, useEffect } from 'react';
import api from '../services/api';
import { UserPlus, X, KeyRound, ToggleLeft, ToggleRight, Trash2, Edit, ShieldCheck } from 'lucide-react';
import toast from 'react-hot-toast';

const initialForm = { name: '', email: '', password: '', phone: '', role: 'member', joined_date: '' };

export default function MembersPage() {
    const [members, setMembers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [modal, setModal] = useState(false);
    const [editModal, setEditModal] = useState(false);
    const [pwdModal, setPwdModal] = useState(false);
    const [form, setForm] = useState(initialForm);
    const [selectedMember, setSelectedMember] = useState(null);
    const [saving, setSaving] = useState(false);

    const fetchMembers = async () => {
        try { const r = await api.get('/members'); setMembers(r.data.members); }
        finally { setLoading(false); }
    };
    useEffect(() => { fetchMembers(); }, []);

    const handleSubmit = async (e) => {
        e.preventDefault(); setSaving(true);
        try {
            await api.post('/members', { ...form, joined_date: form.joined_date || undefined });
            toast.success('Member created!');
            setModal(false); setForm(initialForm); fetchMembers();
        } catch (err) { toast.error(err.response?.data?.message || 'Error creating member'); }
        finally { setSaving(false); }
    };

    const handleUpdate = async (e) => {
        e.preventDefault(); setSaving(true);
        try {
            await api.put(`/members/${selectedMember.id}`, {
                name: selectedMember.name,
                phone: selectedMember.phone,
                is_active: selectedMember.is_active,
                joined_date: selectedMember.joined_date
            });
            toast.success('Member updated!');
            setEditModal(false); fetchMembers();
        } catch (err) { toast.error(err.response?.data?.message || 'Error updating member'); }
        finally { setSaving(false); }
    };

    const handleResetPassword = async (e) => {
        e.preventDefault(); setSaving(true);
        try {
            await api.put(`/members/${selectedMember.id}/password`, { password: selectedMember.newPassword });
            toast.success('Password reset successfully!');
            setPwdModal(false);
        } catch (err) { toast.error(err.response?.data?.message || 'Error resetting password'); }
        finally { setSaving(false); }
    };

    const handleDelete = async (id, name) => {
        if (!window.confirm(`Are you sure you want to PERMANENTLY delete ${name}? This action cannot be undone.`)) return;
        try {
            await api.delete(`/members/${id}`);
            toast.success('Member deleted');
            fetchMembers();
        } catch (err) { toast.error(err.response?.data?.message || 'Error deleting member'); }
    };

    const toggleActive = async (m) => {
        try {
            await api.put(`/members/${m.id}`, { name: m.name, phone: m.phone, is_active: m.is_active ? 0 : 1, joined_date: m.joined_date });
            toast.success(`${m.name} ${m.is_active ? 'deactivated' : 'activated'}`);
            fetchMembers();
        } catch { toast.error('Failed to update member'); }
    };

    const scoreColor = (s) => s >= 750 ? '#10b981' : s >= 600 ? '#6366f1' : s >= 450 ? '#f59e0b' : '#ef4444';

    return (
        <div>
            <div className="page-header">
                <div><h2 className="page-title">Members</h2><p className="page-sub">Manage group members and their accounts</p></div>
                <button className="btn btn-primary" onClick={() => setModal(true)}><UserPlus size={16} /> Add Member</button>
            </div>

            <div className="card">
                {loading ? <div className="spinner-center"><div className="spinner" /></div> : (
                    <div className="table-wrap">
                        <table>
                            <thead><tr><th>Name</th><th>Email</th><th>Phone</th><th>Role</th><th>Credit Score</th><th>Joined</th><th>Status</th><th>Actions</th></tr></thead>
                            <tbody>
                                {members.map(m => (
                                    <tr key={m.id}>
                                        <td><div className="fw-600">{m.name}</div></td>
                                        <td className="text-muted text-sm">{m.email}</td>
                                        <td className="text-muted text-sm">{m.phone || '—'}</td>
                                        <td><span className={`badge ${m.role === 'admin' ? 'badge-info' : 'badge-muted'}`}>{m.role}</span></td>
                                        <td><span className="fw-700" style={{ color: scoreColor(m.credit_score) }}>{m.credit_score}</span></td>
                                        <td className="text-muted text-sm">{m.joined_date ? new Date(m.joined_date).toLocaleDateString('en-IN') : '—'}</td>
                                        <td>
                                            <span className={`badge ${m.is_active ? 'badge-success' : 'badge-danger'}`}>
                                                {m.is_active ? 'Active' : 'Inactive'}
                                            </span>
                                        </td>
                                        <td>
                                            <div style={{ display: 'flex', gap: '.5rem' }}>
                                                <button className="btn btn-outline btn-sm" onClick={() => toggleActive(m)} title="Toggle status">
                                                    {m.is_active ? <ToggleRight size={15} color="#10b981" /> : <ToggleLeft size={15} />}
                                                </button>
                                                <button className="btn btn-outline btn-sm" onClick={() => { setSelectedMember({ ...m }); setEditModal(true); }} title="Edit member">
                                                    <Edit size={15} color="#6366f1" />
                                                </button>
                                                <button className="btn btn-outline btn-sm" onClick={() => { setSelectedMember({ ...m, newPassword: '' }); setPwdModal(true); }} title="Reset Password">
                                                    <KeyRound size={15} color="#f59e0b" />
                                                </button>
                                                <button className="btn btn-outline btn-sm" onClick={() => handleDelete(m.id, m.name)} title="Delete member">
                                                    <Trash2 size={15} color="#ef4444" />
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                ))}
                                {!members.length && <tr><td colSpan={8} style={{ textAlign: 'center', padding: '2rem', color: 'var(--text2)' }}>No members yet. Add one!</td></tr>}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>

            {/* Add Member Modal */}
            {modal && (
                <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && setModal(false)}>
                    <div className="modal">
                        <div className="modal-header">
                            <span className="modal-title">Add New Member</span>
                            <button className="modal-close" onClick={() => setModal(false)}><X size={20} /></button>
                        </div>
                        <form onSubmit={handleSubmit}>
                            <div className="grid-2">
                                <div className="form-group">
                                    <label className="form-label">Full Name *</label>
                                    <input required className="form-control" value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} placeholder="John Doe" />
                                </div>
                                <div className="form-group">
                                    <label className="form-label">Email *</label>
                                    <input type="email" required className="form-control" value={form.email} onChange={e => setForm({ ...form, email: e.target.value })} placeholder="john@email.com" />
                                </div>
                                <div className="form-group">
                                    <label className="form-label">Password *</label>
                                    <input type="password" required minLength={6} className="form-control" value={form.password} onChange={e => setForm({ ...form, password: e.target.value })} placeholder="Min 6 chars" />
                                </div>
                                <div className="form-group">
                                    <label className="form-label">Phone</label>
                                    <input className="form-control" value={form.phone} onChange={e => setForm({ ...form, phone: e.target.value })} placeholder="+91 99999 99999" />
                                </div>
                                <div className="form-group">
                                    <label className="form-label">Role</label>
                                    <select className="form-control" value={form.role} onChange={e => setForm({ ...form, role: e.target.value })}>
                                        <option value="member">Member</option>
                                        <option value="admin">Admin</option>
                                    </select>
                                </div>
                                <div className="form-group">
                                    <label className="form-label">Joined Date</label>
                                    <input type="date" className="form-control" value={form.joined_date} onChange={e => setForm({ ...form, joined_date: e.target.value })} />
                                </div>
                            </div>
                            <div style={{ display: 'flex', gap: '.75rem', marginTop: '.5rem' }}>
                                <button type="button" className="btn btn-outline w-full" onClick={() => setModal(false)}>Cancel</button>
                                <button type="submit" className="btn btn-primary w-full" disabled={saving}>{saving ? 'Creating...' : 'Create Member'}</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* Edit Member Modal */}
            {editModal && selectedMember && (
                <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && setEditModal(false)}>
                    <div className="modal">
                        <div className="modal-header">
                            <span className="modal-title">Edit Member: {selectedMember.name}</span>
                            <button className="modal-close" onClick={() => setEditModal(false)}><X size={20} /></button>
                        </div>
                        <form onSubmit={handleUpdate}>
                            <div className="form-group">
                                <label className="form-label">Full Name *</label>
                                <input required className="form-control" value={selectedMember.name} onChange={e => setSelectedMember({ ...selectedMember, name: e.target.value })} />
                            </div>
                            <div className="form-group">
                                <label className="form-label">Phone</label>
                                <input className="form-control" value={selectedMember.phone || ''} onChange={e => setSelectedMember({ ...selectedMember, phone: e.target.value })} />
                            </div>
                            <div className="form-group">
                                <label className="form-label">Joined Date</label>
                                <input type="date" className="form-control" value={selectedMember.joined_date ? selectedMember.joined_date.split('T')[0] : ''} onChange={e => setSelectedMember({ ...selectedMember, joined_date: e.target.value })} />
                            </div>
                            <div className="form-group">
                                <label className="form-label">Status</label>
                                <select className="form-control" value={selectedMember.is_active} onChange={e => setSelectedMember({ ...selectedMember, is_active: parseInt(e.target.value) })}>
                                    <option value={1}>Active</option>
                                    <option value={0}>Inactive</option>
                                </select>
                            </div>
                            <div style={{ display: 'flex', gap: '.75rem', marginTop: '.5rem' }}>
                                <button type="button" className="btn btn-outline w-full" onClick={() => setEditModal(false)}>Cancel</button>
                                <button type="submit" className="btn btn-primary w-full" disabled={saving}>{saving ? 'Saving...' : 'Update Member'}</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* Reset Password Modal */}
            {pwdModal && selectedMember && (
                <div className="modal-overlay" onClick={(e) => e.target === e.currentTarget && setPwdModal(false)}>
                    <div className="modal">
                        <div className="modal-header">
                            <span className="modal-title">Reset Password: {selectedMember.name}</span>
                            <button className="modal-close" onClick={() => setPwdModal(false)}><X size={20} /></button>
                        </div>
                        <form onSubmit={handleResetPassword}>
                            <div className="form-group">
                                <label className="form-label">New Password *</label>
                                <input type="password" required minLength={6} className="form-control" value={selectedMember.newPassword} onChange={e => setSelectedMember({ ...selectedMember, newPassword: e.target.value })} placeholder="Enter new password" />
                            </div>
                            <div style={{ display: 'flex', gap: '.75rem', marginTop: '.5rem' }}>
                                <button type="button" className="btn btn-outline w-full" onClick={() => setPwdModal(false)}>Cancel</button>
                                <button type="submit" className="btn btn-primary w-full" disabled={saving}>{saving ? 'Resetting...' : 'Reset Password'}</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}
