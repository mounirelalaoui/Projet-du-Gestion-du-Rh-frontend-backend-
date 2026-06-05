import { useState, useEffect, useOptimistic, useTransition } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { Plus, Search, Filter, Pencil, Trash2, FileSpreadsheet, Download, RotateCcw, ChevronDown, Calendar, Type } from 'lucide-react';
import MainLayout from '../../components/layout/MainLayout';
import Card from '../../components/ui/Card';
import Button from '../../components/ui/Button';
import Modal from '../../components/ui/Modal';
import Table from '../../components/ui/Table';
import Input from '../../components/ui/Input';
import Select from '../../components/ui/Select';
import PageHeader from '../../components/common/PageHeader';
import ConfirmDialog from '../../components/common/ConfirmDialog';
import ExcelImportModal from '../../components/common/ExcelImportModal';
import { Loader } from '../../components/common/index';
import { toast } from '../../components/ui/Toast';
import { absenceService, personnelService } from '../../services/crudServices';
import { exportExcel } from '../../services/ExcelService';
import { formatDate } from '../../utils/helpers';

const TYPE_STYLES = {
  justifiée:    'badge badge-green',
  injustifiée:  'badge badge-red',
  'en attente': 'badge badge-yellow',
};
const TYPES = [
  { value: 'justifiée',   label: 'Justifiée' },
  { value: 'injustifiée', label: 'Injustifiée' },
  { value: 'en attente',  label: 'En attente' },
];
const EMPTY = { idPersonnel: '', date_absence: '', motif: '', type: 'en attente' };
const toArray = (result) => Array.isArray(result) ? result : result?.data || [];

function FilterSearch({ value, onChange }) {
  return (
    <div className="flex flex-col gap-1.5 min-w-[200px] flex-1">
      <label className="flex items-center gap-1.5 text-[10px] font-bold text-slate-400 uppercase tracking-widest px-1">
        <Search size={11} />
        Recherche
      </label>
      <div className="relative">
        <input
          type="search"
          placeholder="Nom de l'employé..."
          value={value}
          onChange={onChange}
          className="w-full text-sm font-medium text-slate-700 bg-surface-50 border border-surface-200 rounded-xl px-3 py-2.5 outline-none
            hover:border-primary-300 focus:border-primary-400 focus:bg-white focus:ring-2 focus:ring-primary-100
            transition-all duration-200"
        />
      </div>
    </div>
  );
}

function FilterSelect({ label, icon: Icon, value, onChange, options, placeholder }) {
  return (
    <div className="flex flex-col gap-1.5 min-w-[170px] flex-1">
      <label className="flex items-center gap-1.5 text-[10px] font-bold text-slate-400 uppercase tracking-widest px-1">
        <Icon size={11} />
        {label}
      </label>
      <div className="relative">
        <select
          value={value}
          onChange={onChange}
          className="w-full appearance-none text-sm font-medium text-slate-700 bg-surface-50 border border-surface-200 rounded-xl px-3 py-2.5 pr-8 outline-none
            hover:border-primary-300 focus:border-primary-400 focus:bg-white focus:ring-2 focus:ring-primary-100
            transition-all duration-200 cursor-pointer"
        >
          <option value="">{placeholder}</option>
          {options.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>
        <ChevronDown size={13} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
      </div>
    </div>
  );
}

function FilterDate({ dateFilter, onChange }) {
  return (
    <div className="flex flex-col gap-1.5 min-w-[170px] flex-1">
      <label className="flex items-center gap-1.5 text-[10px] font-bold text-slate-400 uppercase tracking-widest px-1">
        <Calendar size={11} />
        Date
      </label>
      <input
        type="date"
        value={dateFilter}
        onChange={onChange}
        className="w-full text-sm font-medium text-slate-700 bg-surface-50 border border-surface-200 rounded-xl px-3 py-2.5 outline-none
          hover:border-primary-300 focus:border-primary-400 focus:bg-white focus:ring-2 focus:ring-primary-100 transition-all duration-200"
      />
    </div>
  );
}

export default function AbsencesPage() {
  const location = useLocation();
  const navigate = useNavigate();
  const [items, setItems]             = useState([]);
  const [personnels, setPersonnels]   = useState([]);
  const [loading, setLoading]         = useState(true);
  const [isPending, startTransition]  = useTransition();
  const [formOpen, setFormOpen]       = useState(false);
  const [editTarget, setEditTarget]   = useState(null);
  const [form, setForm]               = useState(EMPTY);
  const [errors, setErrors]           = useState({});
  const [saving, setSaving]           = useState(false);
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [importOpen, setImportOpen]   = useState(false);

  const [search, setSearch]           = useState('');
  const [typeFilter, setTypeFilter]   = useState('');
  const [dateFilter, setDateFilter]   = useState('');

  useEffect(() => {
    let cancelled = false;
    (async () => {
      setLoading(true);
      try {
        const [absRes, persRes] = await Promise.all([
          absenceService.getAll(),
          personnelService.getAll({ per_page: 1000 })
        ]);
        if (!cancelled) {
          setItems(toArray(absRes));
          setPersonnels(toArray(persRes));
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => { cancelled = true; };
  }, []);

  const [optimisticItems, removeOptimistic] = useOptimistic(
    items, (current, id) => current.filter(i => i.id !== id)
  );

  const filtered = optimisticItems
    .filter(i => !search     || (i.employe || '').toLowerCase().includes(search.toLowerCase()))
    .filter(i => !typeFilter || i.type === typeFilter)
    .filter(i => !dateFilter || i.date_absence === dateFilter);

  const stats = {
    total:       optimisticItems.length,
    justifiee:   optimisticItems.filter(i => i.type === 'justifiée').length,
    injustifiee: optimisticItems.filter(i => i.type === 'injustifiée').length,
    attente:     optimisticItems.filter(i => i.type === 'en attente').length,
  };

  const openCreate = () => { setEditTarget(null); setForm(EMPTY); setErrors({}); setFormOpen(true); };
  const openEdit   = (item) => { 
    setEditTarget(item); 
    setForm({ 
      idPersonnel: item.idPersonnel, 
      date_absence: item.date_absence, 
      motif: item.motif, 
      type: item.type || 'en attente' 
    }); 
    setErrors({}); 
    setFormOpen(true); 
  };

  useEffect(() => {
    if (!location.state?.openCreate) return;
    openCreate();
    navigate(location.pathname, { replace: true, state: null });
  }, [location.pathname, location.state, navigate]);

  const handleChange = ({ target: { name, value } }) => {
    setForm(prev => ({ ...prev, [name]: value }));
    if (errors[name]) setErrors(prev => ({ ...prev, [name]: '' }));
  };

  const validate = (f) => {
    const e = {};
    if (!f.idPersonnel)  e.idPersonnel  = 'Sélectionnez un employé.';
    if (!f.date_absence) e.date_absence = 'Obligatoire.';
    if (!f.motif)        e.motif        = 'Obligatoire.';
    return e;
  };

  const handleSave = async (e) => {
    e.preventDefault();
    const errs = validate(form);
    if (Object.keys(errs).length) { setErrors(errs); return; }
    setSaving(true);
    try {
      if (editTarget) {
        const res = await absenceService.update(editTarget.id, form);
        setItems(prev => prev.map(i => i.id === editTarget.id ? (res?.data || res) : i));
        toast.success('Absence mise à jour.');
      } else {
        const res = await absenceService.create(form);
        setItems(prev => [...prev, res?.data || res]);
        toast.success('Absence enregistrée.');
      }
      setFormOpen(false);
    } catch {
      toast.error("Erreur lors de l'enregistrement.");
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = () => {
    if (!deleteTarget) return;
    const isAll = deleteTarget === 'ALL';
    const targetId = isAll ? null : deleteTarget.id;

    startTransition(async () => {
      if (!isAll) removeOptimistic(targetId);
      setDeleteTarget(null);

      try {
        if (isAll) {
          await absenceService.removeAll();
          setItems([]);
          toast.success('Toutes les absences ont été supprimées.');
        } else {
          await absenceService.remove(targetId);
          setItems(prev => prev.filter(i => i.id !== targetId));
          toast.success('Absence supprimée.');
        }
      } catch {
        const res = await absenceService.getAll();
        setItems(toArray(res));
        toast.error(isAll ? 'Erreur lors de la suppression massive.' : 'Erreur lors de la suppression.');
      }
    });
  };

  const handleImport = async (rows) => {
    let count = 0;
    for (const row of rows) {
      // Find personnel by matricule if possible
      const p = personnels.find(pers => pers.matricule === row.matricule);
      if (!p) continue;
      const res = await absenceService.create({ 
        idPersonnel: p.id, 
        date_absence: row.date_absence || row.date, 
        motif: row.motif || 'Import Excel',
        type: row.type || 'en attente' 
      });
      setItems(prev => [...prev, res?.data || res]);
      count++;
    }
    toast.success(`${count} absence(s) importée(s).`);
  };

  const COLUMNS = [
    { key: 'employe',      header: 'Employé', render: v => <span className="font-medium">{v}</span> },
    { key: 'date_absence', header: 'Date',    render: v => formatDate(v) },
    { key: 'type',         header: 'Type',    render: v => <span className={TYPE_STYLES[v] || 'badge badge-gray'}>{v || '—'}</span> },
    { key: 'motif',        header: 'Motif',   render: v => <span className="text-xs text-slate-500">{v || '—'}</span> },
    {
      key: '_actions', header: '', width: '80px',
      render: (_, row) => (
        <div className="flex gap-1">
          <button onClick={() => openEdit(row)} className="p-1.5 rounded-lg text-slate-400 hover:text-amber-600 hover:bg-amber-50 transition-colors"><Pencil size={13} /></button>
          <button onClick={() => setDeleteTarget(row)} className="p-1.5 rounded-lg text-slate-400 hover:text-red-600 hover:bg-red-50 transition-colors"><Trash2 size={13} /></button>
        </div>
      ),
    },
  ];

  const resetFilters = () => { setSearch(''); setTypeFilter(''); setDateFilter(''); };
  const activeFilterCount = [search, typeFilter, dateFilter].filter(Boolean).length;

  const personnelOptions = personnels.map(p => ({ 
    value: p.id, 
    label: `${(p.nom || '').toUpperCase()} ${(p.prenom || '')} (${p.matricule || '—'})` 
  }));

  return (
    <MainLayout>
      <PageHeader title="Absences" subtitle="Suivi des absences du personnel"
        actions={
          <div className="flex gap-2">
            <Button variant="secondary" onClick={() => exportExcel(filtered, 'absence', 'absences.xlsx')}><Download size={15} />Exporter</Button>
            <Button variant="secondary" onClick={() => setImportOpen(true)}><FileSpreadsheet size={15} />Importer</Button>
            {items.length > 0 && (
              <Button variant="danger" onClick={() => setDeleteTarget('ALL')} className="bg-red-50 text-red-600 hover:bg-red-100 hover:text-red-700 border-red-200">
                <Trash2 size={15} /> Tout supprimer
              </Button>
            )}
            <Button onClick={openCreate}><Plus size={15} />Déclarer</Button>
          </div>
        }
      />

      {/* Stats */}
      <div className="flex flex-wrap gap-3 mb-4">
        {[
          { label: 'Total',        value: stats.total,       cls: 'bg-slate-100 text-slate-700' },
          { label: 'Justifiées',   value: stats.justifiee,   cls: 'bg-emerald-100 text-emerald-700' },
          { label: 'Injustifiées', value: stats.injustifiee, cls: 'bg-red-100 text-red-700' },
          { label: 'En attente',   value: stats.attente,     cls: 'bg-amber-100 text-amber-700' },
        ].map(({ label, value, cls }) => (
          <div key={label} className={`flex items-center gap-2 px-3 py-1.5 rounded-xl text-xs font-semibold ${cls}`}>
            <span className="text-base font-bold">{value}</span> {label}
          </div>
        ))}
      </div>

      {/* Filter bar */}
      <div className="bg-white border border-surface-200 rounded-2xl shadow-sm mb-5 overflow-hidden">
        {/* Header bar */}
        <div className="flex items-center justify-between px-4 py-3 border-b border-surface-100">
          <div className="flex items-center gap-2.5">
            <div className="w-7 h-7 bg-primary-50 rounded-lg flex items-center justify-center">
              <Filter size={14} className="text-primary-600" />
            </div>
            <span className="text-sm font-semibold text-slate-800">Filtres Avancés</span>
            {activeFilterCount > 0 && (
              <span className="inline-flex items-center justify-center w-5 h-5 bg-primary-600 text-white text-[10px] font-bold rounded-full">
                {activeFilterCount}
              </span>
            )}
          </div>
          <div className="flex items-center gap-3">
            <span className="text-xs text-slate-400 font-medium bg-surface-100 px-2.5 py-1 rounded-lg">
              {filtered.length} résultat{filtered.length !== 1 ? 's' : ''}
            </span>
            {activeFilterCount > 0 && (
              <button
                onClick={resetFilters}
                className="flex items-center gap-1.5 text-xs font-semibold text-red-500 hover:text-red-600 px-2.5 py-1.5 rounded-lg hover:bg-red-50 transition-all"
              >
                <RotateCcw size={11} />
                Réinitialiser
              </button>
            )}
          </div>
        </div>

        {/* Filters row */}
        <div className="flex flex-wrap gap-4 p-4">
          <FilterSearch value={search} onChange={e => setSearch(e.target.value)} />
          <FilterSelect
            label="Type"
            icon={Type}
            value={typeFilter}
            onChange={e => setTypeFilter(e.target.value)}
            options={TYPES}
            placeholder="Tous types"
          />
          <FilterDate
            dateFilter={dateFilter}
            onChange={e => setDateFilter(e.target.value)}
          />
        </div>
      </div>

      <Card padding={false}>
        {loading ? <Loader /> : (
          <div style={{ opacity: isPending ? 0.6 : 1, transition: 'opacity 0.15s' }}>
            <Table data={filtered} columns={COLUMNS} emptyMessage="Aucune absence enregistrée." />
          </div>
        )}
      </Card>

      <Modal isOpen={formOpen} onClose={() => setFormOpen(false)}
        title={editTarget ? "Modifier l'absence" : 'Déclarer une absence'} size="md">
        <form onSubmit={handleSave} className="flex flex-col gap-4">
          <Select label="Employé" name="idPersonnel" value={form.idPersonnel} onChange={handleChange} options={personnelOptions} error={errors.idPersonnel} required />
          <Input label="Date de l&apos;absence" name="date_absence" type="date" value={form.date_absence} onChange={handleChange} error={errors.date_absence} required />
          <Select label="Type" name="type" value={form.type} onChange={handleChange} options={TYPES} />
          <div className="flex flex-col gap-1.5">
            <label className="text-sm font-medium text-slate-700">Motif</label>
            <textarea name="motif" value={form.motif} onChange={handleChange} rows={3} className="input-field resize-none" placeholder="Motif…" />
          </div>
          <div className="flex justify-end gap-3 pt-2 border-t border-surface-200">
            <Button variant="secondary" type="button" onClick={() => setFormOpen(false)}>Annuler</Button>
            <Button type="submit" loading={saving}>Enregistrer</Button>
          </div>
        </form>
      </Modal>
      <ExcelImportModal isOpen={importOpen} onClose={() => setImportOpen(false)}
        schemaType="absence" entityLabel="les absences" onImport={handleImport} />

      <ConfirmDialog isOpen={!!deleteTarget} onClose={() => setDeleteTarget(null)}
        onConfirm={handleDelete} loading={isPending} 
        title={deleteTarget === 'ALL' ? "Tout supprimer" : "Supprimer cette absence"}
        message={
          deleteTarget === 'ALL'
            ? "Êtes-vous sûr de vouloir supprimer toutes les absences ? Cette action est irréversible."
            : deleteTarget ? `Supprimer l'absence de ${deleteTarget.employe} ?` : ''
        } />
    </MainLayout>
  );
}
