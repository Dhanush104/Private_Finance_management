import { createContext, useContext, useEffect, useRef } from 'react';
import { io } from 'socket.io-client';
import { SOCKET_URL } from '../config';
import { useAuth } from './AuthContext';

const SocketContext = createContext(null);

export const SocketProvider = ({ children }) => {
    const { token } = useAuth();
    const socketRef = useRef(null);

    useEffect(() => {
        if (!token) return;
        const socket = io(SOCKET_URL, { auth: { token }, transports: ['websocket', 'polling'] });
        socketRef.current = socket;
        return () => socket.disconnect();
    }, [token]);

    return (
        <SocketContext.Provider value={socketRef}>
            {children}
        </SocketContext.Provider>
    );
};

export const useSocket = () => useContext(SocketContext);
