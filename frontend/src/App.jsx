import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import { useEffect } from 'react';
import { AuthProvider } from './context/AuthContext';
import { SocketProvider } from './context/SocketContext';
import { useThemeStore } from './store/themeStore';
import { ProtectedRoute, AdminRoute, GuestRoute } from './components/ProtectedRoute';
import Layout from './components/Layout';

// Pages
import LoginPage from './pages/LoginPage';

import AdminDashboard from './pages/AdminDashboard';
import MembersPage from './pages/MembersPage';
import ContributionsPage from './pages/ContributionsPage';
import LoansPage from './pages/LoansPage';
import RepaymentsPage from './pages/RepaymentsPage';
import LedgerPage from './pages/LedgerPage';
import SettingsPage from './pages/SettingsPage';
import MemberDashboard from './pages/MemberDashboard';
import MyContributionsPage from './pages/MyContributionsPage';
import MyLoansPage from './pages/MyLoansPage';
import MyProfilePage from './pages/MyProfilePage';

function ThemeInit() {
  const { dark } = useThemeStore();
  useEffect(() => {
    document.documentElement.classList.toggle('dark', dark);
  }, [dark]);
  return null;
}

function DashboardRouter() {
  // Render appropriate dashboard based on role
  const user = JSON.parse(localStorage.getItem('rsb_user') || 'null');
  if (!user) return <Navigate to="/login" replace />;
  return user.role === 'admin' ? <AdminDashboard /> : <MemberDashboard />;
}

export default function App() {
  return (
    <AuthProvider>
      <SocketProvider>
        <ThemeInit />
        <Toaster
          position="top-right"
          toastOptions={{
            style: {
              background: 'var(--bg2)',
              color: 'var(--text)',
              border: '1px solid var(--border)',
              borderRadius: '12px',
              fontSize: '.875rem',
              fontWeight: 500,
              boxShadow: '0 8px 32px rgba(0,0,0,.15)',
              padding: '.75rem 1rem',
            },
            success: { iconTheme: { primary: '#10b981', secondary: '#fff' } },
            error: { iconTheme: { primary: '#ef4444', secondary: '#fff' } },
            duration: 4000,
          }}
        />
        <BrowserRouter>
          <Routes>
            {/* Guest only */}
            <Route element={<GuestRoute />}>
              <Route path="/login" element={<LoginPage />} />
              <Route path="/" element={<Navigate to="/login" replace />} />
            </Route>

            {/* Protected layout */}
            <Route element={<ProtectedRoute />}>
              <Route element={<Layout />}>
                <Route path="/dashboard" element={<DashboardRouter />} />

                {/* Admin only */}
                <Route element={<AdminRoute />}>
                  <Route path="/members" element={<MembersPage />} />
                  <Route path="/repayments" element={<RepaymentsPage />} />
                  <Route path="/ledger" element={<LedgerPage />} />
                  <Route path="/settings" element={<SettingsPage />} />
                </Route>

                {/* Shared pages */}
                <Route path="/contributions" element={<ContributionsPage />} />
                <Route path="/loans" element={<LoansPage />} />

                {/* Member specific views */}
                <Route path="/my-contributions" element={<MyContributionsPage />} />
                <Route path="/my-loans" element={<MyLoansPage />} />
                <Route path="/my-profile" element={<MyProfilePage />} />
              </Route>
            </Route>

            <Route path="*" element={<Navigate to="/dashboard" replace />} />
          </Routes>
        </BrowserRouter>
      </SocketProvider>
    </AuthProvider>
  );
}
