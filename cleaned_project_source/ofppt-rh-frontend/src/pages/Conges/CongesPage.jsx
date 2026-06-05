import { useState, useEffect, useOptimistic, useTransition } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { Plus, Search, Filter, Pencil, Trash2, FileSpreadsheet, Download, RotateCcw, ChevronDown, Calendar, Type, Activity } from 'lucide-react';
import MainLayout from '../../components/layout/MainLayout';
import Card from '../../components/ui/Card';
import Button from '../../components/ui/Button';
import Modal from '../../components/ui/Modal';
import Table from '../../components/ui/Table';
import Input from '../../components/ui/Input';
import Select from '../../components/ui/Select';
import PlanningExcelImportButton from '../../components/ui/PlanningExcelImportButton';
import PageHeader from '../../components/common/PageHeader';
import ConfirmDialog from '../../components/common/ConfirmDialog';
import ExcelImportModal from '../../components/common/ExcelImportModal';
import { Loader } from '../../components/common/index';
import api from '../../services/api';
import { toast } from '../../components/ui/Toast';
import { congeService, personnelService } from '../../services/crudServices';
import { exportExcel } from '../../services/ExcelService';
import { formatDate, daysBetween } from '../../utils/helpers';

const STATUT_STYLES = {
  en_attente: 'badge badge-yellow',
  approuvé:   'badge badge-green',
  refusé:     'badge badge-red',
};
const TYPES_CONGE = [
  { value: 'Congé Annuel',       label: 'Congé Annuel' },
  { value: 'Congé Maladie',      label: 'Congé Maladie' },
  { value: 'Congé Maternité',    label: 'Congé Maternité' },
  { value: 'Congé Exceptionnel', label: 'Congé Exceptionnel' },
  { value: 'Congé Sans Solde',   label: 'Congé Sans Solde' },
];
const STATUTS = [
  { value: 'en_attente', label: 'En attente' },
  { value: 'approuvé',   label: 'Approuvé' },
  { value: 'refusé',     label: 'Refusé' },
];
const EMPTY = { idPersonnel: '', type_conge: 'Congé Annuel', date_debut: '', date_fin: '', motif: '', statut: 'en_attente' };
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

function FilterDateRange({ dateFrom, dateTo, onFromChange, onToChange }) {
  return (
    <div className="flex flex-col gap-1.5 min-w-[280px] flex-1">
      <label className="flex items-center gap-1.5 text-[10px] font-bold text-slate-400 uppercase tracking-widest px-1">
        <Calendar size={11} />
        Période
      </label>
      <div className="flex items-center gap-2">
        <input
          type="date"
          value={dateFrom}
          onChange={onFromChange}
          className="flex-1 text-sm font-medium text-slate-700 bg-surface-50 border border-surface-200 rounded-xl px-3 py-2.5 outline-none
            hover:border-primary-300 focus:border-primary-400 focus:bg-white focus:ring-2 focus:ring-primary-100 transition-all duration-200"
        />
        <span className="text-slate-400 text-xs font-medium">à</span>
        <input
          type="date"
          value={dateTo}
          onChange={onToChange}
          className="flex-1 text-sm font-medium text-slate-700 bg-surface-50 border border-surface-200 rounded-xl px-3 py-2.5 outline-none
            hover:border-primary-300 focus:border-primary-400 focus:bg-white focus:ring-2 focus:ring-primary-100 transition-all duration-200"
        />
      </div>
    </div>
  );
}

export default function CongesPage() {
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

  // Filters
  const [search, setSearch]           = useState('');
  const [statutFilter, setStatutFilter] = useState('');
  const [typeFilter, setTypeFilter]   = useState('');
  const [dateFrom, setDateFrom]       = useState('');
  const [dateTo, setDateTo]           = useState('');

  useEffect(() => {
    let cancelled = false;
    (async () => {
      setLoading(true);
      try {
        const [congRes, persRes] = await Promise.all([
          congeService.getAll(),
          personnelService.getAll({ per_page: 1000 })
        ]);
        if (!cancelled) {
          setItems(toArray(congRes));
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
    .filter(i => !search       || (i.employe || '').toLowerCase().includes(search.toLowerCase()))
    .filter(i => !statutFilter || i.statut === statutFilter)
    .filter(i => !typeFilter   || i.type_conge === typeFilter)
    .filter(i => !dateFrom     || i.date_debut >= dateFrom)
    .filter(i => !dateTo       || i.date_fin   <= dateTo);

  const stats = {
    total:     optimisticItems.length,
    attente:   optimisticItems.filter(i => i.statut === 'en_attente').length,
    approuve:  optimisticItems.filter(i => i.statut === 'approuvé').length,
    refuse:    optimisticItems.filter(i => i.statut === 'refusé').length,
  };

  const openCreate = () => { setEditTarget(null); setForm(EMPTY); setErrors({}); setFormOpen(true); };
  const openEdit   = (item) => { 
    setEditTarget(item); 
    setForm({ 
      idPersonnel: item.idPersonnel, 
      type_conge: item.type_conge, 
      date_debut: item.date_debut, 
      date_fin: item.date_fin, 
      motif: item.motif || '', 
      statut: item.statut || 'en_attente' 
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
    if (!f.idPersonnel) e.idPersonnel = 'Sélectionnez un employé.';
    if (!f.type_conge)  e.type_conge  = 'Obligatoire.';
    if (!f.date_debut)  e.date_debut  = 'Obligatoire.';
    if (!f.date_fin)    e.date_fin    = 'Obligatoire.';
    if (f.date_debut && f.date_fin && f.date_debut > f.date_fin)
      e.date_fin = 'La date de fin doit être après la date de début.';
    return e;
  };

  const handleSave = async (e) => {
    e.preventDefault();
    const errs = validate(form);
    if (Object.keys(errs).length) { setErrors(errs); return; }
    setSaving(true);
    try {
      if (editTarget) {
        const res = await congeService.update(editTarget.id, form);
        setItems(prev => prev.map(i => i.id === editTarget.id ? (res?.data || res) : i));
        toast.success('Congé mis à jour.');
      } else {
        const res = await congeService.create(form);
        setItems(prev => [...prev, res?.data || res]);
        toast.success('Demande de congé créée.');
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
          await congeService.removeAll();
          setItems([]);
          toast.success('Tous les congés ont été supprimés.');
        } else {
          await congeService.remove(targetId);
          setItems(prev => prev.filter(i => i.id !== targetId));
          toast.success('Congé supprimé.');
        }
      } catch {
        const res = await congeService.getAll();
        setItems(toArray(res));
        toast.error(isAll ? 'Erreur lors de la suppression massive.' : 'Erreur lors de la suppression.');
      }
    });
  };

  const handleImport = async (rows) => {
    let count = 0;
    for (const row of rows) {
      const p = personnels.find(pers => pers.matricule === row.matricule || pers.matricule === row.employe || pers.nom === row.employe);
      if (!p) continue;
      const res = await congeService.create({ 
        idPersonnel: p.id, 
        type_conge: row.typeConge || row.type_conge || row.type || 'Congé Annuel',
        date_debut: row.date_debut || row.dateDebut || row.debut,
        date_fin: row.date_fin || row.dateFin || row.fin,
        statut: row.statut || 'en_attente' 
      });
      setItems(prev => [...prev, res?.data || res]);
      count++;
    }
    toast.success(`${count} congé(s) importé(s).`);
  };

  const handlePlanningImport = async (rows) => {
    toast.info("Importation du planning en cours...");
    try {
      const response = await api.post('/import-planning', { plannings: rows });
      toast.success(response.data?.message || 'Planning importé avec succès');
      const res = await congeService.getAll();
      setItems(toArray(res));
    } catch (err) {
      const errorMsg = err.response?.data?.errors?.[0] || err.message;
      toast.error(`Erreur d'importation: ${errorMsg}`);
    }
  };

  const COLUMNS = [
    { key: 'employe',   header: 'Employé', render: v => <span className="font-medium">{v}</span> },
    { key: 'type_conge', header: 'Type' },
    { key: 'date_debut', header: 'Début',   render: v => formatDate(v) },
    { key: 'date_fin',   header: 'Fin',     render: v => formatDate(v) },
    { key: 'nbJours',   header: 'Jours',   render: (_, r) => r.date_debut && r.date_fin ? daysBetween(r.date_debut, r.date_fin) : '—' },
    { key: 'statut',    header: 'Statut',  render: v => <span className={STATUT_STYLES[v] || 'badge badge-gray'}>{v || '—'}</span> },
    {
      key: '_actions', header: '', width: '90px',
      render: (_, row) => (
        <div className="flex gap-1">
          <button onClick={() => openEdit(row)} className="p-1.5 rounded-lg text-slate-400 hover:text-amber-600 hover:bg-amber-50 transition-colors"><Pencil size={13} /></button>
          <button onClick={() => setDeleteTarget(row)} className="p-1.5 rounded-lg text-slate-400 hover:text-red-600 hover:bg-red-50 transition-colors"><Trash2 size={13} /></button>
        </div>
      ),
    },
  ];

  const resetFilters = () => { setSearch(''); setStatutFilter(''); setTypeFilter(''); setDateFrom(''); setDateTo(''); };
  const activeFilterCount = [search, statutFilter, typeFilter, dateFrom, dateTo].filter(Boolean).length;

  const personnelOptions = personnels.map(p => ({ 
    value: p.id, 
    label: `${(p.nom || '').toUpperCase()} ${(p.prenom || '')} (${p.matricule || '—'})` 
  }));

  return (
    <MainLayout>
      <PageHeader title="Congés" subtitle="Gestion des demandes de congé"
        actions={
          <div className="flex gap-2">
            <Button variant="secondary" onClick={() => exportExcel(filtered, 'conge', 'conges.xlsx')}><Download size={15} />Exporter</Button>
            <PlanningExcelImportButton onImport={handlePlanningImport} />
            <Button variant="secondary" onClick={() => setImportOpen(true)}><FileSpreadsheet size={15} />Importer Standard</Button>
            {items.length > 0 && (
              <Button variant="danger" onClick={() => setDeleteTarget('ALL')} className="bg-red-50 text-red-600 hover:bg-red-100 hover:text-red-700 border-red-200">
                <Trash2 size={15} /> Tout supprimer
              </Button>
            )}
            <Button onClick={openCreate}><Plus size={15} />Nouvelle demande</Button>
          </div>
        }
      />

      {/* Stats pills */}
      <div className="flex flex-wrap gap-3 mb-4">
        {[
          { label: 'Total',      value: stats.total,   cls: 'bg-slate-100 text-slate-700' },
          { label: 'En attente', value: stats.attente, cls: 'bg-amber-100 text-amber-700' },
          { label: 'Approuvés',  value: stats.approuve,cls: 'bg-emerald-100 text-emerald-700' },
          { label: 'Refusés',    value: stats.refuse,  cls: 'bg-red-100 text-red-700' },
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
            label="Statut"
            icon={Activity}
            value={statutFilter}
            onChange={e => setStatutFilter(e.target.value)}
            options={STATUTS}
            placeholder="Tous statuts"
          />
          <FilterSelect
            label="Type"
            icon={Type}
            value={typeFilter}
            onChange={e => setTypeFilter(e.target.value)}
            options={TYPES_CONGE}
            placeholder="Tous types"
          />
          <FilterDateRange
            dateFrom={dateFrom}
            dateTo={dateTo}
            onFromChange={e => setDateFrom(e.target.value)}
            onToChange={e => setDateTo(e.target.value)}
          />
        </div>
      </div>

      <Card padding={false}>
        {loading ? <Loader /> : (
          <div style={{ opacity: isPending ? 0.6 : 1, transition: 'opacity 0.15s' }}>
            <Table data={filtered} columns={COLUMNS} emptyMessage="Aucune demande de congé trouvée." />
          </div>
        )}
      </Card>

      {/* Form modal */}
      <Modal isOpen={formOpen} onClose={() => setFormOpen(false)}
        title={editTarget ? 'Modifier le congé' : 'Nouvelle demande de congé'} size="md">
        <form onSubmit={handleSave} className="flex flex-col gap-4">
          <Select label="Employé" name="idPersonnel" value={form.idPersonnel} onChange={handleChange} options={personnelOptions} error={errors.idPersonnel} required />
          <div className="grid grid-cols-2 gap-4">
            <Select label="Type de congé" name="type_conge" value={form.type_conge} onChange={handleChange}
              options={TYPES_CONGE} error={errors.type_conge} required />
            <Select label="Statut" name="statut" value={form.statut} onChange={handleChange} options={STATUTS} />
            <Input label="Date de début" name="date_debut" type="date" value={form.date_debut} onChange={handleChange} error={errors.date_debut} required />
            <Input label="Date de fin"   name="date_fin"   type="date" value={form.date_fin}   onChange={handleChange} error={errors.date_fin}   required />
          </div>
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
        schemaType="conge" entityLabel="les congés" onImport={handleImport} />

      <ConfirmDialog isOpen={!!deleteTarget} onClose={() => setDeleteTarget(null)}
        onConfirm={handleDelete} loading={isPending} 
        title={deleteTarget === 'ALL' ? "Tout supprimer" : "Supprimer ce congé"}
        message={
          deleteTarget === 'ALL'
            ? "Êtes-vous sûr de vouloir supprimer tous les congés ? Cette action est irréversible."
            : deleteTarget ? `Supprimer la demande de congé de ${deleteTarget.employe} ?` : ''
        } />
    </MainLayout>
  );
}
