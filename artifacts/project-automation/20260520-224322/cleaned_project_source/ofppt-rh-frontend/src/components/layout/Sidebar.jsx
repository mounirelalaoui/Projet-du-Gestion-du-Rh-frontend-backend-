import { NavLink } from 'react-router-dom';
import {
  LayoutDashboard, Users, CalendarDays, CalendarX,
  UserCog, LogOut, ChevronLeft, Menu, CalendarRange,
  FileSpreadsheet, UserCircle, Sparkles,
} from 'lucide-react';
import { useState } from 'react';
import { useAuth } from '../../hooks/useAuth';
import { getInitials } from '../../utils/helpers';
import { ROLES } from '../../utils/constants';

const NAV_SECTIONS = [
  {
    title: 'Principal',
    links: [
      { to: '/dashboard',       label: 'Tableau de bord', icon: LayoutDashboard },
      { to: '/personnels',      label: 'Personnel',        icon: Users },
    ],
  },
  {
    title: 'Gestion',
    links: [
      { to: '/conges',          label: 'Congés',           icon: CalendarDays },
      { to: '/absences',        label: 'Absences',         icon: CalendarX },
    ],
  },
  {
    title: 'Planning',
    links: [
      { to: '/emploi-du-temps',        label: 'Emploi du Temps',  icon: CalendarRange },
      { to: '/emploi-du-temps/import', label: 'Import Planning',   icon: FileSpreadsheet },
    ],
  },
  {
    title: 'Admin',
    adminOnly: true,
    links: [
      { to: '/users',  label: 'Utilisateurs', icon: UserCog, adminOnly: true },
    ],
  },
  {
    title: 'Compte',
    links: [
      { to: '/profile', label: 'Mon Profil', icon: UserCircle },
    ],
  },
];

export default function Sidebar() {
  const [collapsed, setCollapsed] = useState(false);
  const { user, logout } = useAuth();
  const isAdmin = user?.role === ROLES.DIRECTEUR_COMPLEXE;

  const sections = NAV_SECTIONS.filter(s => !s.adminOnly || isAdmin).map(s => ({
    ...s,
    links: s.links.filter(l => !l.adminOnly || isAdmin),
  }));

  return (
    <aside
      className={`${collapsed ? 'w-[68px]' : 'w-[230px]'} flex-shrink-0 flex flex-col transition-all duration-300 ease-in-out h-screen sticky top-0 overflow-hidden`}
      style={{
        background: 'linear-gradient(180deg, #0f172a 0%, #1e293b 100%)',
        borderRight: '1px solid rgba(255,255,255,0.06)',
      }}
    >
      {/* ── Logo / Header ─────────────────────────────────── */}
      <div className={`flex items-center ${collapsed ? 'justify-center px-4' : 'justify-between px-4'} py-5 flex-shrink-0`}
        style={{ borderBottom: '1px solid rgba(255,255,255,0.06)' }}>
        {!collapsed && (
          <div className="flex items-center gap-2.5 min-w-0">
            <div className="w-8 h-8 rounded-xl flex items-center justify-center flex-shrink-0 relative"
              style={{ background: 'linear-gradient(135deg, #3b82f6, #6366f1)' }}>
              <Sparkles size={14} className="text-white" />
              {/* Glow */}
              <div className="absolute inset-0 rounded-xl blur-md opacity-50"
                style={{ background: 'linear-gradient(135deg, #3b82f6, #6366f1)' }} />
            </div>
            <div className="min-w-0">
              <p className="text-white font-bold text-sm leading-none tracking-tight">OFPPT</p>
              <p className="text-slate-400 text-[10px] mt-0.5 font-medium tracking-widest uppercase">Gestion RH</p>
            </div>
          </div>
        )}
        <button
          onClick={() => setCollapsed(!collapsed)}
          className="flex-shrink-0 p-1.5 rounded-lg text-slate-500 hover:text-white transition-colors"
          style={{ background: 'rgba(255,255,255,0.05)' }}
        >
          {collapsed ? <Menu size={15} /> : <ChevronLeft size={15} />}
        </button>
      </div>

      {/* ── Navigation ─────────────────────────────────────── */}
      <nav className="flex-1 overflow-y-auto py-3 px-2.5 flex flex-col gap-0.5"
        style={{ scrollbarWidth: 'none' }}>
        {sections.map(section => (
          <div key={section.title}>
            {!collapsed && section.title && (
              <p className="text-[9px] font-bold tracking-[0.15em] uppercase text-slate-600 px-2 pt-4 pb-1.5 first:pt-1">
                {section.title}
              </p>
            )}
            {collapsed && <div className="my-1 h-px mx-1" style={{ background: 'rgba(255,255,255,0.06)' }} />}
            {section.links.map(({ to, label, icon: Icon }) => (
              <NavLink
                key={to}
                to={to}
                end={to === '/dashboard'}
                title={collapsed ? label : undefined}
                className={({ isActive }) =>
                  `flex items-center gap-3 px-2.5 py-2 rounded-xl text-[13px] font-medium transition-all duration-150 group relative
                  ${collapsed ? 'justify-center' : ''}
                  ${isActive
                    ? 'text-white'
                    : 'text-slate-400 hover:text-white'}`
                }
                style={({ isActive }) => isActive ? {
                  background: 'linear-gradient(135deg, rgba(59,130,246,0.25), rgba(99,102,241,0.15))',
                  boxShadow: 'inset 0 0 0 1px rgba(99,102,241,0.25)',
                } : {}}
              >
                {({ isActive }) => (
                  <>
                    <div className={`flex-shrink-0 w-7 h-7 rounded-lg flex items-center justify-center transition-all duration-150
                      ${isActive
                        ? 'bg-blue-500/20 text-blue-400'
                        : 'text-slate-500 group-hover:bg-white/5 group-hover:text-slate-300'}`}>
                      <Icon size={15} />
                    </div>
                    {!collapsed && <span className="truncate">{label}</span>}
                    {isActive && !collapsed && (
                      <div className="ml-auto w-1.5 h-1.5 rounded-full bg-blue-400 flex-shrink-0" />
                    )}
                  </>
                )}
              </NavLink>
            ))}
          </div>
        ))}
      </nav>

      {/* ── User footer ─────────────────────────────────────── */}
      <div className="px-2.5 py-3 flex-shrink-0" style={{ borderTop: '1px solid rgba(255,255,255,0.06)' }}>
        {!collapsed && (
          <div className="flex items-center gap-2.5 px-2.5 py-2.5 mb-2 rounded-xl"
            style={{ background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.07)' }}>
            <div className="w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0 text-xs font-bold text-white"
              style={{ background: 'linear-gradient(135deg, #3b82f6, #6366f1)' }}>
              {getInitials(user?.nom || user?.name || 'U')}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-white text-xs font-semibold truncate leading-none">
                {user?.nom || user?.name || 'Utilisateur'}
              </p>
              <p className="text-slate-500 text-[10px] truncate mt-0.5">{user?.email || ''}</p>
            </div>
          </div>
        )}
        <button
          onClick={logout}
          title={collapsed ? 'Déconnexion' : undefined}
          className={`flex items-center gap-2.5 w-full px-2.5 py-2 rounded-xl text-[13px] font-medium text-red-400 hover:text-red-300 transition-all duration-150
            ${collapsed ? 'justify-center' : ''}`}
          style={{ background: 'transparent' }}
          onMouseEnter={e => e.currentTarget.style.background = 'rgba(239,68,68,0.08)'}
          onMouseLeave={e => e.currentTarget.style.background = 'transparent'}
        >
          <LogOut size={15} className="flex-shrink-0" />
          {!collapsed && <span>Déconnexion</span>}
        </button>
      </div>
    </aside>
  );
}