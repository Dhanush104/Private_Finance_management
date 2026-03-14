import { useLocation } from 'react-router-dom';
import { Bell, Menu } from 'lucide-react';
import { useAuth } from '../context/AuthContext';

const titles = {
    '/dashboard': 'Dashboard',
    '/members': 'Member Management',
    '/contributions': 'Contributions',
    '/loans': 'Loan Management',
    '/repayments': 'Repayments',
    '/ledger': 'Transaction Ledger',
    '/settings': 'Group Settings',
    '/my-contributions': 'My Contributions',
    '/my-loans': 'My Loans',
    '/my-profile': 'My Profile',
};

export default function Navbar({ onMenuClick }) {
    const { pathname } = useLocation();
    const { user } = useAuth();
    const title = titles[pathname] || 'Royal Star Boys';

    return (
        <header className="topbar">
            <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                <button className="icon-btn mobile-menu-btn" onClick={onMenuClick} title="Open Menu">
                    <Menu size={20} />
                </button>
                <div>
                    <h1 className="topbar-title">{title}</h1>
                    <p className="topbar-sub">Royal Star Boys • Private Fund Management</p>
                </div>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                <button className="icon-btn" title="Notifications">
                    <Bell size={18} />
                </button>
                <div className="topbar-user">
                    <div className="topbar-avatar">{user?.name?.charAt(0).toUpperCase()}</div>
                    <div>
                        <div style={{ fontSize: '.85rem', fontWeight: 600 }}>{user?.name}</div>
                        <div style={{ fontSize: '.72rem', color: 'var(--text2)', textTransform: 'capitalize' }}>{user?.role}</div>
                    </div>
                </div>
            </div>
        </header>
    );
}
