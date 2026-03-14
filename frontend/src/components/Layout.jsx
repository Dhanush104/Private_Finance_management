import Sidebar from './Sidebar';
import Navbar from './Navbar';
import { Outlet } from 'react-router-dom';
import { useState, useEffect } from 'react';
import { useLocation } from 'react-router-dom';

export default function Layout() {
    const [isSidebarOpen, setIsSidebarOpen] = useState(false);
    const location = useLocation();

    // Close sidebar on route change on mobile
    useEffect(() => {
        setIsSidebarOpen(false);
    }, [location.pathname]);

    return (
        <div className="app-layout">
            <Sidebar isOpen={isSidebarOpen} onClose={() => setIsSidebarOpen(false)} />

            {/* Mobile Overlay */}
            {isSidebarOpen && (
                <div
                    className="sidebar-overlay"
                    onClick={() => setIsSidebarOpen(false)}
                />
            )}

            <div className="main-content">
                <Navbar onMenuClick={() => setIsSidebarOpen(true)} />
                <div className="page-content">
                    <Outlet />
                </div>
            </div>
        </div>
    );
}
