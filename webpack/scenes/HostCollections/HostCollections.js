import React from 'react';
import TableIndexPage from 'foremanReact/components/PF4/TableIndexPage/TableIndexPage';
import { translate as __ } from 'foremanReact/common/I18n';
import { HOST_COLLECTIONS_API_PATH, HOST_COLLECTIONS_KEY } from './constants';

// import PropTypes from 'prop-types';

const HostCollections = () => {
  const columns = {
    name: {
      title: __('Name'),
      isSorted: true,
      wrapper: ({ id, name }) =>
        <a href={`/host_collections/${id}`}>{name}</a>,
    },
    total_hosts: {
      title: __('Hosts'),
      isSorted: false,
      wrapper: ({ total_hosts: totalHosts, name }) => (
        <a href={`/hosts?search=host_collection%20=%20${name}`}>{totalHosts}</a>
      ),
    },
    max_hosts: {
      title: __('Limit'),
      wrapper: ({ max_hosts: maxHosts }) => maxHosts ?? __('Unlimited'),
    },
  };
  return (
    <TableIndexPage
      apiUrl={HOST_COLLECTIONS_API_PATH}
      apiOptions={{ key: HOST_COLLECTIONS_KEY }}
      header={__('Host collections')}
      controller="/katello/api/v2/host_collections"
      creatable
      isDeleteable
      columns={columns}
    />
  );
};

export default HostCollections;

HostCollections.propTypes = {
};

HostCollections.defaultProps = {
};
