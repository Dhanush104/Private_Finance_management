import { useState, useEffect } from 'react';
import api from '../services/api';
import { Search } from 'lucide-react';

const fmt = (n) => `₹${Number(n || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}`;

export default function LedgerPage() {
    const [transactions, setTransactions] = useState([]);
    const [total, setTotal] = useState(0);
    const [loading, setLoading] = useState(true);
    const [type, setType] = useState('');
    const [page, setPage] = useState(0);
    const limit = 20;

    const fetch = async () => {
        setLoading(true);
        try {
            const params = { limit, offset: page * limit };
            if (type) params.type = type;
            const r = await api.get('/transactions', { params });
            setTransactions(r.data.transactions);
            setTotal(r.data.total);
        } finally { setLoading(false); }
    };
    useEffect(() => { fetch(); }, [type, page]);

    const typeBadge = (t) => {
        const map = { contribution: 'badge-success', loan_disbursement: 'badge-warning', repayment: 'badge-info', adjustment: 'badge-muted' };
        return <span className={`badge ${map[t] || 'badge-muted'}`}>{t.replace(/_/g, ' ')}</span>;
    };

    return (
        <div>
            <div className="page-header">
                <div><h2 className="page-title">Transaction Ledger</h2><p className="page-sub">Immutable record of all financial activity • {total} total entries</p></div>
                <div className="flex gap-2">
                    {['', 'contribution', 'loan_disbursement', 'repayment'].map(t => (
                        <button key={t} className={`btn btn-sm ${type === t ? 'btn-primary' : 'btn-outline'}`} onClick={() => { setType(t); setPage(0); }}>
                            {t ? t.replace(/_/g, ' ') : 'All'}
                        </button>
                    ))}
                </div>
            </div>

            <div className="card">
                {loading ? <div className="spinner-center"><div className="spinner" /></div> : (
                    <>
                        <div className="table-wrap">
                            <table>
                                <thead><tr><th>#</th><th>Type</th><th>Member</th><th>Amount</th><th>Fund After</th><th>Description</th><th>Date & Time</th></tr></thead>
                                <tbody>
                                    {transactions.map(t => (
                                        <tr key={t.id}>
                                            <td className="text-muted text-sm">{t.id}</td>
                                            <td>{typeBadge(t.type)}</td>
                                            <td>{t.member_name || <span className="text-muted">System</span>}</td>
                                            <td className={`fw-600 ${t.type === 'loan_disbursement' ? 'score-poor' : 'score-excellent'}`}>{t.type === 'loan_disbursement' ? '-' : '+'}{fmt(t.amount)}</td>
                                            <td className="fw-600">{fmt(t.group_fund_after)}</td>
                                            <td className="text-muted text-sm" style={{ maxWidth: 220, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{t.description}</td>
                                            <td className="text-muted text-sm">{new Date(t.created_at).toLocaleString('en-IN')}</td>
                                        </tr>
                                    ))}
                                    {!transactions.length && <tr><td colSpan={7} style={{ textAlign: 'center', padding: '2rem', color: 'var(--text2)' }}>No transactions found</td></tr>}
                                </tbody>
                            </table>
                        </div>
                        <div className="flex items-center gap-2 mt-2" style={{ justifyContent: 'flex-end' }}>
                            <button className="btn btn-outline btn-sm" disabled={page === 0} onClick={() => setPage(p => p - 1)}>← Prev</button>
                            <span className="text-muted text-sm">Page {page + 1} of {Math.ceil(total / limit) || 1}</span>
                            <button className="btn btn-outline btn-sm" disabled={(page + 1) * limit >= total} onClick={() => setPage(p => p + 1)}>Next →</button>
                        </div>
                    </>
                )}
            </div>
        </div>
    );
}
