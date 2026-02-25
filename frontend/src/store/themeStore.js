import { create } from 'zustand';

export const useThemeStore = create((set) => ({
    dark: localStorage.getItem('rsb_theme') === 'dark',
    toggle: () => set((s) => {
        const next = !s.dark;
        localStorage.setItem('rsb_theme', next ? 'dark' : 'light');
        document.documentElement.classList.toggle('dark', next);
        return { dark: next };
    }),
}));
