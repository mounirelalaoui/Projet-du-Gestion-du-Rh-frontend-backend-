/* global CustomEvent */
import { useState } from 'react';
import {
  CalendarDays, CalendarRange, FileSpreadsheet, Plus,
  Sparkles, Clock
} from 'lucide-react';
import MainLayout from '../../components/layout/MainLayout';
import Button from '../../components/ui/Button';
import PlanningExcelImportButton from '../../components/ui/PlanningExcelImportButton';
import { toast } from '../../components/ui/Toast';
import api from '../../services/api';
import EmploiWeeklyShell from './EmploiWeeklyShell';
import EmploiMonthlyShell from './EmploiMonthlyShell';
import { TimetableProvider, useTimetable } from '../../context/TimetableContext';

const VIEWS = [
  { key: 'hebdomadaire', label: 'Vue Hebdomadaire', icon: CalendarDays },
  { key: 'mensuel',      label: 'Vue Mensuelle',    icon: CalendarRange },
];

export default function EmploiUnifie() {
  return (
    <TimetableProvider>
      <EmploiUnifieContent />
    </TimetableProvider>
  );
}

function EmploiUnifieContent() {
  const [view, setView] = useState('hebdomadaire');
  const { seances } = useTimetable();

  const nbCours   = seances.filter(s => s.type === 'cours').length;
  const nbTP      = seances.filter(s => s.type === 'tp').length;
  const nbExamens = seances.filter(s => s.type === 'examen').length;

  const handleExcelImport = async (rows, headers) => {
    toast.info('Importation et synchronisation en cours...');
    try {
      const response = await api.post('/seances/import', {
        seances: rows,
        debug_headers: headers,
      });
      toast.success(response.data?.message || 'Séances importées avec succès.');
      window.dispatchEvent(new CustomEvent('seances-updated'));
    } catch (err) {
      const errorMsg = err.response?.data?.message || err.message;
      toast.error(`Erreur serveur: ${errorMsg}`);
    }
  };

  return (
    <MainLayout>
      {/* ── Premium Page Header ──────────────────────────────── */}
      <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-primary-700 via-primary-600 to-primary-500 p-6 mb-6 shadow-lg">
        {/* Decorative blobs */}
        <div className="absolute -top-8 -right-8 w-40 h-40 bg-white/5 rounded-full blur-2xl pointer-events-none" />
        <div className="absolute bottom-0 left-20 w-32 h-32 bg-white/5 rounded-full blur-xl pointer-events-none" />

        <div className="relative flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div className="flex items-center gap-4">
            <div className="flex-shrink-0 w-12 h-12 bg-white/15 backdrop-blur-sm rounded-xl flex items-center justify-center border border-white/20">
              <CalendarDays size={24} className="text-white" />
            </div>
            <div>
              <div className="flex items-center gap-2 mb-0.5">
                <h1 className="text-xl font-bold text-white tracking-tight">Emploi du Temps</h1>
                <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-white/15 text-white text-[10px] font-semibold rounded-full border border-white/20">
                  <Sparkles size={9} /> LIVE
                </span>
              </div>
              <p className="text-white/70 text-sm">Planification hebdomadaire et mensuelle</p>
            </div>
          </div>

          {/* Action buttons */}
          <div className="flex items-center gap-3 flex-wrap">
            <PlanningExcelImportButton onImport={handleExcelImport} />
            <button
              onClick={() => window.dispatchEvent(new CustomEvent('open-add-session'))}
              className="flex items-center gap-2 px-4 py-2.5 bg-white text-primary-700 text-sm font-semibold rounded-xl hover:bg-white/90 active:scale-95 transition-all shadow-sm"
            >
              <Plus size={16} />
              Ajouter une séance
            </button>
          </div>
        </div>

        {/* ── Stats row ──────────────────────────────────────── */}
        <div className="relative mt-5 grid grid-cols-2 sm:grid-cols-4 gap-3">
          {[
            { label: 'Séances', value: seances.length, icon: CalendarDays, bg: 'bg-white/10', text: 'text-white' },
            { label: 'Cours',   value: nbCours,        icon: CalendarDays, bg: 'bg-green-400/20',  text: 'text-green-100' },
            { label: 'TP',      value: nbTP,           icon: Clock,        bg: 'bg-blue-400/20',   text: 'text-blue-100' },
            { label: 'Examens', value: nbExamens,      icon: Sparkles,     bg: 'bg-red-400/20',    text: 'text-red-100' },
          ].map(({ label, value, icon: Icon, bg, text }) => (
            <div key={label} className={`${bg} backdrop-blur-sm rounded-xl px-4 py-3 border border-white/10 flex items-center gap-3`}>
              <div className="w-8 h-8 bg-white/10 rounded-lg flex items-center justify-center flex-shrink-0">
                <Icon size={15} className={text} />
              </div>
              <div>
                <p className="text-2xl font-bold text-white leading-none">{value}</p>
                <p className={`text-xs mt-0.5 font-medium ${text} opacity-80`}>{label}</p>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* ── View switcher ────────────────────────────────────── */}
      <div className="flex items-center gap-2 mb-5">
        <div className="flex items-center p-1 bg-white border border-surface-200 rounded-xl shadow-sm">
          {VIEWS.map(({ key, label, icon: Icon }) => (
            <button
              key={key}
              onClick={() => setView(key)}
              className={`flex items-center gap-2 px-5 py-2 rounded-lg text-sm font-semibold transition-all duration-200
                ${view === key
                  ? 'bg-primary-600 text-white shadow-md shadow-primary-600/25'
                  : 'text-slate-500 hover:text-slate-700 hover:bg-surface-50'}`}
            >
              <Icon size={15} />
              {label}
            </button>
          ))}
        </div>

        <div className="ml-auto flex items-center gap-2 text-xs text-slate-400">
          <div className="w-2 h-2 bg-emerald-400 rounded-full animate-pulse" />
          Données en temps réel
        </div>
      </div>

      {/* ── Active view ──────────────────────────────────────── */}
      <div className="animate-fadeIn" key={view}>
        {view === 'hebdomadaire' ? <EmploiWeeklyShell /> : <EmploiMonthlyShell />}
      </div>
    </MainLayout>
  );
}
