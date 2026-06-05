import { useState, useMemo } from 'react';

/**
 * Hook to manage dynamic filtering of data.
 * @param {Array} initialData - The raw data to filter.
 * @param {Array} fields - Array of strings representing the keys to extract unique values from for filters.
 * @returns {Object} - { filteredData, filters, setFilter, options, resetFilters, activeFilterCount }
 */
export default function useDynamicFilters(initialData = [], fields = []) {
  // Current filter values: { fieldName: value }
  const [filters, setFilters] = useState(() => {
    const initial = {};
    fields.forEach(field => initial[field] = '');
    return initial;
  });

  // Extract unique options for each field from the data
  const options = useMemo(() => {
    const opts = {};
    fields.forEach(field => {
      const uniqueValues = [...new Set(initialData.map(item => item[field]).filter(Boolean))].sort();
      opts[field] = uniqueValues.map(val => ({ value: val, label: val }));
    });
    return opts;
  }, [initialData, fields]);

  // Apply filters to data
  const filteredData = useMemo(() => {
    return initialData.filter(item => {
      return Object.entries(filters).every(([field, value]) => {
        if (!value) return true;
        return String(item[field]).toLowerCase() === String(value).toLowerCase();
      });
    });
  }, [initialData, filters]);

  const setFilter = (field, value) => {
    setFilters(prev => ({ ...prev, [field]: value }));
  };

  const resetFilters = () => {
    const cleared = {};
    fields.forEach(f => cleared[f] = '');
    setFilters(cleared);
  };

  const activeFilterCount = Object.values(filters).filter(Boolean).length;

  return {
    filteredData,
    filters,
    setFilter,
    options,
    resetFilters,
    activeFilterCount
  };
}
