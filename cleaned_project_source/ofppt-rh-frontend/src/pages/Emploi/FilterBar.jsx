import { useState, useEffect, useMemo } from 'react';
import { Filter, Building2, User, Users, GraduationCap, RotateCcw, ChevronDown } from 'lucide-react';
import { etablissementService, personnelService, specialiteService } from '../../services/crudServices';

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
          {options.map((opt, idx) => (
            <option key={`${opt?.displayName ?? opt}-${idx}`} value={opt?.displayName ?? opt}>
              {opt?.displayName ?? opt}
            </option>
          ))}
        </select>
        <ChevronDown size={13} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
      </div>
    </div>
  );
}

export default function FilterBar({ data = [], filters, onFilterChange, onReset }) {
  const [dbData, setDbData] = useState({ etablissements: [], personnels: [], specialites: [] });

  useEffect(() => {
    (async () => {
      try {
        const [etabs, pers, specs] = await Promise.all([
          etablissementService.getAll(),
          personnelService.getAll({ per_page: 1000 }),
          specialiteService.getAll(),
        ]);
        setDbData({
          etablissements: Array.isArray(etabs) ? etabs : (etabs.data || []),
          personnels:     Array.isArray(pers)  ? pers  : (pers.data  || []),
          specialites:    Array.isArray(specs) ? specs : (specs.data || []),
        });
      } catch (err) {
        console.error('Error fetching filter data:', err);
      }
    })();
  }, []);

  const options = useMemo(() => {
    const etabs = dbData.etablissements;
    let filteredPersonnels = dbData.personnels.filter(p => p.type_personnel === 'formateur');
    if (filters.etablissement) {
      const selectedEtab = etabs.find(e => e.nom === filters.etablissement);
      if (selectedEtab) filteredPersonnels = filteredPersonnels.filter(p => p.idEtab === selectedEtab.idEtab);
    }
    const formateurs = filteredPersonnels
      .map(p => ({ id: p.idPersonnel, displayName: `${(p.nom || '').toUpperCase()} ${(p.prenom || '')}` }))
      .sort((a, b) => a.displayName.localeCompare(b.displayName));

    return {
      etablissements: [...new Set(etabs.map(e => (e.nom || '').trim()).filter(Boolean))].sort(),
      formateurs: Array.from(new Map(formateurs.filter(f => f.displayName.trim()).map(f => [f.displayName, f])).values()),
      grades:     [...new Set(dbData.personnels.map(p => (p.grade || '').trim()).filter(Boolean))].sort(),
      groupes:    [...new Set(data.map(item => (item.groupe || item._raw?.groupe || '').trim()).filter(Boolean))].sort(),
    };
  }, [dbData, filters.etablissement, data]);

  const activeFilterCount = Object.values(filters).filter(Boolean).length;

  return (
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
            {data.length} séance{data.length !== 1 ? 's' : ''}
          </span>
          {activeFilterCount > 0 && (
            <button
              onClick={onReset}
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
        <FilterSelect
          label="Établissement"
          icon={Building2}
          value={filters.etablissement || ''}
          onChange={e => onFilterChange('etablissement', e.target.value)}
          options={options.etablissements}
          placeholder="Tous les établissements"
        />
        <FilterSelect
          label="Formateur"
          icon={User}
          value={filters.formateur || ''}
          onChange={e => onFilterChange('formateur', e.target.value)}
          options={options.formateurs}
          placeholder="Tous les formateurs"
        />
        <FilterSelect
          label="Groupe"
          icon={Users}
          value={filters.groupe || ''}
          onChange={e => onFilterChange('groupe', e.target.value)}
          options={options.groupes}
          placeholder="Tous les groupes"
        />
        <FilterSelect
          label="Grade"
          icon={GraduationCap}
          value={filters.grade || ''}
          onChange={e => onFilterChange('grade', e.target.value)}
          options={options.grades}
          placeholder="Tous les grades"
        />
      </div>
    </div>
  );
}
