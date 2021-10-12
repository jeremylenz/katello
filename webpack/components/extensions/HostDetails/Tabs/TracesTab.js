import React, { useState, useCallback } from 'react';
import { Skeleton, Button, Split, SplitItem, ActionList, ActionListItem, Dropdown,
  DropdownItem, KebabToggle } from '@patternfly/react-core';
import { translate as __ } from 'foremanReact/common/I18n';
import { TableVariant, Thead, Tbody, Tr, Th, Td } from '@patternfly/react-table';
import { useSelector, useDispatch } from 'react-redux';
import { selectAPIResponse } from 'foremanReact/redux/API/APISelectors';
import { urlBuilder } from 'foremanReact/common/urlHelpers';
import EnableTracerEmptyState from './EnableTracerEmptyState';
import TableWrapper from '../../../Table/TableWrapper';
import { useSelectionSet } from '../../../Table/TableHooks';
import { getHostTraces, resolveHostTraces } from './HostTracesActions';
import { selectHostTracesStatus } from './HostTracesSelectors';
import { resolveTraceUrl } from './customizedRexUrlHelpers';
import './TracesTab.scss';

const TracesTab = () => {
  const [searchQuery, updateSearchQuery] = useState('');
  const hostDetails = useSelector(state => selectAPIResponse(state, 'HOST_DETAILS'));
  const dispatch = useDispatch();
  const {
    id: hostId,
    name: hostname,
    content_facet_attributes: contentFacetAttributes,
  } = hostDetails;
  const showEnableTracer = (contentFacetAttributes?.katello_tracer_installed === false);
  const emptyContentTitle = __('This host currently does not have traces.');
  const emptyContentBody = __('Add traces by applying updates on this host.');
  const emptySearchTitle = __('No matching traces found');
  const emptySearchBody = __('Try changing your search settings.');
  const fetchItems = useCallback(
    params =>
      (hostId ? getHostTraces(hostId, params) : null),
    [hostId],
  );
  const [isBulkActionOpen, setIsBulkActionOpen] = useState(false);
  const toggleBulkAction = () => setIsBulkActionOpen(prev => !prev);
  const response = useSelector(state => selectAPIResponse(state, 'HOST_TRACES'));
  const { results, ...meta } = response;
  const {
    selectOne, isSelected, selectionSet: selectedTraces, ...selectAll
  } = useSelectionSet(results, meta);

  const onBulkRestartApp = (ids) => {
    dispatch(resolveHostTraces(hostId, { trace_ids: [...ids] }));
    selectedTraces.clear();
    const params = { page: meta.page, per_page: meta.per_page, search: meta.search };
    dispatch(getHostTraces(hostId, params));
  };

  const assembleHelpers = (traceData) => {
    const traces = new Set(traceData.map(tr => tr.effective_helper));
    if (traces.has('reboot')) return 'reboot';
    traces.delete(null);
    return [...traces].join(',');
  };

  const bulkCustomizedRexUrl = (traceIds) => {
    if (!results) return '';
    const traces = results.filter(trace => traceIds.has(trace.id));
    const helpers = assembleHelpers(traces);
    return resolveTraceUrl({ hostname, helper: helpers });
  };

  const onRestartApp = id => onBulkRestartApp([id]);

  const dropdownItems = [
    <DropdownItem isDisabled={!selectedTraces.size} aria-label="bulk_rex" key="bulk_rex" component="button" onClick={() => onBulkRestartApp(selectedTraces)}>
      {__('Restart via remote execution')}
    </DropdownItem>,
    <DropdownItem isDisabled={!selectedTraces.size} aria-label="bulk_rex_customized" key="bulk_rex_customized" component="a" href={bulkCustomizedRexUrl(selectedTraces)}>
      {__('Restart via customized remote execution')}
    </DropdownItem>,
  ];

  const actionButtons = (
    <Split hasGutter>
      <SplitItem>
        <ActionList isIconList>
          <ActionListItem>
            <Button
              variant="secondary"
              isDisabled={!selectedTraces.size}
              onClick={() => onBulkRestartApp(selectedTraces)}
            >
              {__('Restart app')}
            </Button>
          </ActionListItem>
          <ActionListItem>
            <Dropdown
              toggle={<KebabToggle aria-label="bulk_actions" onToggle={toggleBulkAction} />}
              isOpen={isBulkActionOpen}
              isPlain
              dropdownItems={dropdownItems}
            />
          </ActionListItem>
        </ActionList>
      </SplitItem>
    </Split>

  );
  const status = useSelector(state => selectHostTracesStatus(state));
  // const selectAll = () => {
  //   // leaving blank until we can implement selectAll Katello-wide
  // };
  if (showEnableTracer) return <EnableTracerEmptyState />;

  if (!hostId) return <Skeleton />;

  /* eslint-disable max-len */
  return (
    <div id="traces-tab">
      <h3>{__('Tracer helps administrators identify applications that need to be restarted after a system is patched.')}</h3>
      <TableWrapper
        actionButtons={actionButtons}
        searchQuery={searchQuery}
        emptyContentBody={emptyContentBody}
        emptyContentTitle={emptyContentTitle}
        emptySearchBody={emptySearchBody}
        emptySearchTitle={emptySearchTitle}
        updateSearchQuery={updateSearchQuery}
        fetchItems={fetchItems}
        autocompleteEndpoint={`/hosts/${hostId}/traces/auto_complete_search`}
        foremanApiAutoComplete
        displaySelectAllCheckbox
        rowsCount={results?.length}
        variant={TableVariant.compact}
        status={status}
        metadata={meta}
        {...selectAll}
      >
        <Thead>
          <Tr>
            <Th key="select_checkbox" />
            <Th>{__('Application')}</Th>
            <Th>{__('Type')}</Th>
            <Th>{__('Helper')}</Th>
            <Th key="action_menu" />
          </Tr>
        </Thead>
        <Tbody>
          {results?.map((result, rowIndex) => {
          const {
            id,
            application,
            helper,
            app_type: appType,
            reboot_required: rebootRequired,
          } = result;
          let rowDropdownItems = [
            { title: 'Restart via remote execution', onClick: () => onRestartApp(id) },
            {
              component: 'a', href: resolveTraceUrl({ hostname, helper, rebootRequired }), title: 'Restart via customized remote execution',
            },
          ];
          if (appType === 'session') {
            rowDropdownItems = [
              { isDisabled: true, title: __('Traces that require logout cannot be restarted remotely') },
            ];
          }
          return (
            <Tr key={id} >
              <Td select={{
                disable: appType === 'session',
                props: {
                  'aria-label': `check-${application}`,
                },
                isSelected: isSelected(id),
                onSelect: (event, selected) => selectOne(selected, id),
                rowIndex,
                variant: 'checkbox',
              }}
              />
              <Td>{application}</Td>
              <Td>{appType}</Td>
              <Td>{helper}</Td>
              <Td
                actions={{
                  items: rowDropdownItems,
                }}
              />
            </Tr>
          );
         })
         }
          </Tbody>
        </TableWrapper>
      </div>
    </div>
  );
};
/* eslint-enable max-len */
export default TracesTab;
