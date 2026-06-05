import { useLocation, useNavigate } from 'react-router-dom';
import { Search, Bell, ChevronDown } from 'lucide-react';
import { useAuth } from '../../hooks/useAuth';
import NotificationPanel from '../common/NotificationPanel';
import { UserAvatar } from '../../pages/Profile/ProfilePage';

const PAGE_TITLES = {
  '/dashboard':              { title: 'Tableau de bord',    sub: 'Vue d\'ensemble des activités' },
  '/personnels':             { title: 'Gestion du Personnel', sub: 'Administratifs, formateurs et vacataires' },
  '/conges':                 { title: 'Congés',               sub: 'Suivi des congés du personnel' },
  '/absences':               { title: 'Absences',             sub: 'Registre des absences' },
  '/emploi-du-temps':        { title: 'Emploi du Temps',      sub: 'Planification hebdomadaire et mensuelle' },
  '/emploi-du-temps/import': { title: 'Import Planning',      sub: 'Importation du fichier Excel' },
  '/users':                  { title: 'Utilisateurs',         sub: 'Gestion des comptes utilisateurs' },
  '/profile':                { title: 'Mon Profil',           sub: 'Paramètres et informations personnelles' },
};

const TODAY = new Date().toLocaleDateString('fr-FR', {
  weekday: 'long', day: 'numeric', month: 'long', year: 'numeric'
});

export default function Navbar() {
  const { user }    = useAuth();
  const { pathname} = useLocation();
  const navigate    = useNavigate();

  const base    = '/' + pathname.split('/')[1];
  const pageInfo = PAGE_TITLES[pathname] || PAGE_TITLES[base] || { title: 'OFPPT RH', sub: '' };
  const name    = user?.name || user?.nom || 'Utilisateur';
  const role    = user?.role || 'Administrateur';

  return (
    <header className="h-[64px] bg-white flex items-center justify-between px-6 flex-shrink-0 z-10"
      style={{ borderBottom: '1px solid rgba(0,0,0,0.06)', boxShadow: '0 1px 0 rgba(0,0,0,0.04)' }}>
      {/* Left: Page info */}
      <div className="min-w-0">
        <h1 className="text-[15px] font-bold text-slate-800 leading-none tracking-tight truncate">{pageInfo.title}</h1>
        <p className="text-[11px] text-slate-400 mt-0.5 hidden sm:block">{TODAY}</p>
      </div>

      {/* Right: actions */}
      <div className="flex items-center gap-2 flex-shrink-0">
        {/* Search */}
        <div className="hidden md:flex items-center gap-2 rounded-xl px-3 py-2 w-52 text-sm text-slate-400 cursor-text transition-all
          border border-surface-200 bg-surface-50 hover:bg-white hover:border-primary-300 focus-within:border-primary-400 focus-within:bg-white focus-within:ring-2 focus-within:ring-primary-100">
          <Search size={13} className="flex-shrink-0" />
          <input
            type="search"
            placeholder="Rechercher..."
            className="bg-transparent outline-none text-slate-600 text-sm w-full placeholder-slate-400"
          />
        </div>

        {/* Notifications */}
        <NotificationPanel />

        {/* Divider */}
        <div className="w-px h-6 bg-surface-200 hidden md:block" />

        {/* Avatar → Profile */}
        <button
          onClick={() => navigate('/profile')}
          className="flex items-center gap-2.5 hover:opacity-90 transition-opacity pl-1"
          title="Mon profil"
        >
          <UserAvatar name={name} size="md" />
          <div className="hidden md:block text-left">
            <p className="text-[13px] font-semibold text-slate-800 leading-none">{name}</p>
            <p className="text-[11px] text-slate-400 mt-0.5">{role}</p>
          </div>
          <ChevronDown size={13} className="hidden md:block text-slate-400" />
        </button>
      </div>
    </header>
  );
}
