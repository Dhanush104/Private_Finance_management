import { NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { useThemeStore } from '../store/themeStore';
import {
    LayoutDashboard, Users, CreditCard, Banknote, RefreshCw,
    BookOpen, Settings, LogOut, Star, ChevronRight, Moon, Sun, X
} from 'lucide-react';
import './Sidebar.css';

const adminLinks = [
    { to: '/dashboard', icon: LayoutDashboard, label: 'Dashboard' },
    { to: '/members', icon: Users, label: 'Members' },
    { to: '/contributions', icon: CreditCard, label: 'Contributions' },
    { to: '/loans', icon: Banknote, label: 'Loans' },
    { to: '/repayments', icon: RefreshCw, label: 'Repayments' },
    { to: '/ledger', icon: BookOpen, label: 'Ledger' },
    { to: '/settings', icon: Settings, label: 'Settings' },
];

const memberLinks = [
    { to: '/dashboard', icon: LayoutDashboard, label: 'Dashboard' },
    { to: '/contributions', icon: CreditCard, label: 'Contributions' },
    { to: '/loans', icon: Banknote, label: 'Loans' },
    { to: '/my-contributions', icon: CreditCard, label: 'My Contributions' },
    { to: '/my-loans', icon: Banknote, label: 'My Loans' },
    { to: '/my-profile', icon: Users, label: 'My Profile' },
];

export default function Sidebar({ isOpen, onClose }) {
    const { user, logout, isAdmin } = useAuth();
    const { dark, toggle } = useThemeStore();
    const navigate = useNavigate();
    const links = isAdmin ? adminLinks : memberLinks;

    const handleLogout = () => { logout(); navigate('/login'); };

    return (
        <aside className={`sidebar ${isOpen ? 'open' : ''}`}>
            <div className="sidebar-brand">
                <div className="brand-icon"><Star size={20} fill="currentColor" /></div>
                <div>
                    <div className="brand-name">Royal Star Boys</div>
                    <div className="brand-sub">Fund Management</div>
                </div>
                {/* Mobile Close Button */}
                <button className="mobile-close-btn" onClick={onClose}>
                    <X size={20} />
                </button>
            </div>

            <nav className="sidebar-nav">
                <div className="nav-section-label">Navigation</div>
                {links.map(({ to, icon: Icon, label }) => (
                    <NavLink key={to} to={to} className={({ isActive }) => `nav-link${isActive ? ' active' : ''}`}>
                        <Icon size={18} />
                        <span>{label}</span>
                        <ChevronRight size={14} className="nav-arrow" />
                    </NavLink>
                ))}
            </nav>

            <div className="sidebar-footer">
                <button className="theme-btn" onClick={toggle} title="Toggle theme">
                    {dark ? <Sun size={16} /> : <Moon size={16} />}
                    <span>{dark ? 'Light Mode' : 'Dark Mode'}</span>
                </button>

                <div className="user-chip">
                    <div className="user-avatar">{user?.name?.charAt(0).toUpperCase()}</div>
                    <div>
                        <div className="user-name">{user?.name}</div>
                        <div className="user-role">{user?.role}</div>
                    </div>
                </div>

                <button className="logout-btn" onClick={handleLogout}>
                    <LogOut size={16} /> Sign Out
                </button>
            </div>
        </aside>
    );
}
