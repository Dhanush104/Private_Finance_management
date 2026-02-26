import { Navigate, Outlet } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

function FullSpinner() {
    return <div className="spinner-center" style={{ height: '100vh', background: 'var(--bg)' }}><div className="spinner" /></div>;
}

export const ProtectedRoute = () => {
    const { user, isInitialized } = useAuth();
    if (!isInitialized) return <FullSpinner />;
    return user ? <Outlet /> : <Navigate to="/login" replace />;
};

export const AdminRoute = () => {
    const { user, isInitialized } = useAuth();
    if (!isInitialized) return <FullSpinner />;
    if (!user) return <Navigate to="/login" replace />;
    if (user.role !== 'admin') return <Navigate to="/dashboard" replace />;
    return <Outlet />;
};

export const GuestRoute = () => {
    const { user, isInitialized } = useAuth();
    if (!isInitialized) return <FullSpinner />;
    return !user ? <Outlet /> : <Navigate to="/dashboard" replace />;
};
