import React, { useCallback } from 'react';
import PropTypes from 'prop-types';
import { useDispatch } from 'react-redux';
import { STATUS } from 'foremanReact/constants';
import { noop } from 'foremanReact/common/helpers';
import { useForemanSettings } from 'foremanReact/Root/Context/ForemanContext';
import useDeepCompareEffect from 'use-deep-compare-effect';
import { PaginationVariant, Flex, FlexItem } from '@patternfly/react-core';

import PageControls from './PageControls';
import MainTable from './MainTable';
import { getPageStats } from './helpers';
import Search from '../../components/Search';
import SelectAllCheckbox from '../SelectAllCheckbox';
import { orgId } from '../../services/api';

/* Patternfly 4 table wrapper */
const TableWrapper = ({
  actionButtons,
  children,
  metadata,
  fetchItems,
  autocompleteEndpoint,
  foremanApiAutoComplete,
  searchQuery,
  updateSearchQuery,
  additionalListeners,
  activeFilters,
  displaySelectAllCheckbox,
  selectAll,
  selectNone,
  selectPage,
  areAllRowsSelected,
  areAllRowsOnPageSelected,
  selectedCount,
  ...allTableProps
}) => {
  const dispatch = useDispatch();
  const foremanPerPage = useForemanSettings().perPage || 20;
  // setting pagination to local state so it doesn't disappear when page reloads
  // const [perPage, setPerPage] = useState(Number(metadata?.per_page ?? foremanPerPage));
  const perPage = Number(metadata?.per_page ?? foremanPerPage);
  const page = Number(metadata?.page ?? 1);
  const total = Number(metadata?.subtotal ?? 0);
  // const [page, setPage] = useState(Number(metadata?.page ?? 1));
  // const [total, setTotal] = useState(Number(metadata?.subtotal ?? 0));
  const { pageRowCount } = getPageStats({ total, page, perPage });
  const rowsCount = metadata?.subtotal ?? 0;
  const totalCount = metadata?.total ?? 0;
  const unresolvedStatus = !!allTableProps?.status && allTableProps.status !== STATUS.RESOLVED;
  const unresolvedStatusOrNoRows = unresolvedStatus || rowsCount === 0;
  const searchNotUnderway = !(searchQuery || activeFilters);
  const paginationParams = useCallback(() =>
    ({ per_page: perPage, page, subtotal: total }), [perPage, page, total]);
  const spawnFetch = useCallback((paginationData) => {
    // The search component will update the search query when a search is performed, listen for that
    // and perform the search so we can be sure the searchQuery is updated when search is performed.
    const fetchWithParams = (allParams = {}) => {
      dispatch(fetchItems({ ...(paginationData ?? paginationParams()), ...allParams }));
    };
    if (searchQuery || activeFilters) {
      // Reset page back to 1 when filter or search changes
      fetchWithParams({ search: searchQuery, page: 1 });
    } else {
      fetchWithParams();
    }
  }, [
    activeFilters,
    dispatch,
    fetchItems,
    paginationParams,
    searchQuery,
  ]);

  useDeepCompareEffect(() => {
    spawnFetch();
  }, [spawnFetch, page, perPage, paginationParams]);

  const getAutoCompleteParams = search => ({
    endpoint: autocompleteEndpoint,
    params: {
      organization_id: orgId(),
      search,
    },
  });

  // If the new page wouldn't exist because of a perPage change,
  // we should set the current page to the last page.
  const validatePagination = (data) => {
    const mergedData = { ...paginationParams(), ...data };
    const { subtotal: newTotal, page: requestedPage, per_page: newPerPage } = mergedData;
    const { lastPage } = getPageStats({
      total: newTotal,
      page: requestedPage,
      perPage: newPerPage,
    });
    const result = {};
    if (newTotal) result.total = Number(newTotal);
    if (requestedPage) {
      const newPage = (requestedPage > lastPage) ? lastPage : requestedPage;
      result.page = Number(newPage);
    }
    if (newPerPage) result.per_page = Number(newPerPage);
    return result;
  };

  const onPaginationUpdate = (updatedPagination) => {
    spawnFetch(validatePagination(updatedPagination));
  };

  return (
    <>
      <Flex>
        {displaySelectAllCheckbox &&
          <FlexItem alignSelf={{ default: 'alignSelfCenter' }}>
            <SelectAllCheckbox
              selectAll={selectAll}
              selectNone={selectNone}
              selectPage={selectPage}
              selectedCount={selectedCount}
              pageRowCount={pageRowCount}
              totalCount={totalCount}
              areAllRowsSelected={areAllRowsSelected()}
              areAllRowsOnPageSelected={areAllRowsOnPageSelected()}
            />
          </FlexItem>
        }
        <FlexItem>
          <Search
            isDisabled={unresolvedStatusOrNoRows && searchNotUnderway}
            patternfly4
            onSearch={search => updateSearchQuery(search)}
            getAutoCompleteParams={getAutoCompleteParams}
            foremanApiAutoComplete={foremanApiAutoComplete}
          />
        </FlexItem>
        <FlexItem>
          {actionButtons}
        </FlexItem>
        <PageControls
          variant={PaginationVariant.top}
          total={total}
          page={page}
          perPage={perPage}
          onPaginationUpdate={onPaginationUpdate}
        />
      </Flex>
      <MainTable
        searchIsActive={!!searchQuery}
        activeFilters={activeFilters}
        rowsCount={rowsCount}
        {...allTableProps}
      >
        {children}
      </MainTable>
      <Flex>
        <PageControls
          variant={PaginationVariant.bottom}
          total={total}
          page={page}
          perPage={perPage}
          onPaginationUpdate={onPaginationUpdate}
        />
      </Flex>
    </>
  );
};

TableWrapper.propTypes = {
  searchQuery: PropTypes.string.isRequired,
  updateSearchQuery: PropTypes.func.isRequired,
  fetchItems: PropTypes.func.isRequired,
  metadata: PropTypes.shape({
    total: PropTypes.number,
    page: PropTypes.oneOfType([
      PropTypes.number,
      PropTypes.string, // The API can sometimes return strings
    ]),
    subtotal: PropTypes.oneOfType([
      PropTypes.number,
      PropTypes.string, // The API can sometimes return strings
    ]),
    per_page: PropTypes.oneOfType([
      PropTypes.number,
      PropTypes.string,
    ]),
    search: PropTypes.string,
  }),
  autocompleteEndpoint: PropTypes.string.isRequired,
  foremanApiAutoComplete: PropTypes.bool,
  actionButtons: PropTypes.node,
  children: PropTypes.node,
  // additionalListeners are anything that can trigger another API call, e.g. a filter
  additionalListeners: PropTypes.arrayOf(PropTypes.oneOfType([
    PropTypes.number,
    PropTypes.string,
    PropTypes.bool,
  ])),
  activeFilters: PropTypes.bool,
  displaySelectAllCheckbox: PropTypes.bool,
  selectedCount: PropTypes.number,
  selectAll: PropTypes.func,
  selectNone: PropTypes.func,
  selectPage: PropTypes.func,
  areAllRowsSelected: PropTypes.func,
  areAllRowsOnPageSelected: PropTypes.func,
};

TableWrapper.defaultProps = {
  metadata: { subtotal: 0 },
  children: null,
  additionalListeners: [],
  activeFilters: false,
  foremanApiAutoComplete: false,
  actionButtons: null,
  displaySelectAllCheckbox: false,
  selectedCount: 0,
  selectAll: noop,
  selectNone: noop,
  selectPage: noop,
  areAllRowsSelected: noop,
  areAllRowsOnPageSelected: noop,
};

export default TableWrapper;
