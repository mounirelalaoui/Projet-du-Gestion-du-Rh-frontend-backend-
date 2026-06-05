import React from 'react';
import { Filter, X } from 'lucide-react';
import Select from '../ui/Select';
import Button from '../ui/Button';

/**
 * Component to render dynamic filter selects.
 * @param {Object} options - Unique options for each field { field: [{value, label}] }
 * @param {Object} filters - Current filter values { field: value }
 * @param {Function} onFilterChange - Callback function (field, value) => void
 * @param {Function} onReset - Callback to reset all filters
 * @param {Array} fieldsConfig - Optional configuration for labels [{key: 'Affectation', label: 'Lieu d\'affectation'}]
 */
export default function DynamicFilters({ 
  options, 
  filters, 
  onFilterChange, 
  onReset, 
  fieldsConfig = [],
  activeCount = 0
}) {
  if (Object.keys(options).length === 0) return null;

  return (
    <div className="bg-white border border-surface-200 rounded-2xl p-4 shadow-sm mb-6 animate-in fade-in slide-in-from-top-4 duration-300">
      <div className="flex items-center justify-between mb-4 border-b border-surface-100 pb-3">
        <div className="flex items-center gap-2">
          <div className="p-2 bg-primary-50 rounded-lg text-primary-600">
            <Filter size={18} />
          </div>
          <div>
            <h3 className="font-semibold text-slate-800">Filtres Avancés</h3>
            <p className="text-xs text-slate-500">Générés dynamiquement à partir des données</p>
          </div>
        </div>
        
        {activeCount > 0 && (
          <Button 
            variant="secondary" 
            size="sm" 
            onClick={onReset}
            className="text-red-600 hover:text-red-700 hover:bg-red-50 border-red-100"
          >
            <X size={14} className="mr-1.5" />
            Réinitialiser ({activeCount})
          </Button>
        )}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
        {Object.keys(options).map(field => {
          const config = fieldsConfig.find(c => c.key === field);
          const label = config ? config.label : field.charAt(0).toUpperCase() + field.slice(1);
          
          return (
            <Select
              key={field}
              label={label}
              placeholder={`Tous les ${label.toLowerCase()}s`}
              value={filters[field] || ''}
              onChange={(e) => onFilterChange(field, e.target.value)}
              options={options[field]}
              className="w-full"
            />
          );
        })}
      </div>
    </div>
  );
}
