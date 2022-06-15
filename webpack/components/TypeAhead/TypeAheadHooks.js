import { useState } from 'react';

export const useSearchInputValue = (onSearch, initialInputValue) => {
  const [inputValue, setInputValue] = useState(initialInputValue ?? '');

  const clearSearch = () => {
    setInputValue('');
    onSearch('');
  };

  return {
    inputValue,
    setInputValue,
    clearSearch,
  };
};

export default useSearchInputValue;
