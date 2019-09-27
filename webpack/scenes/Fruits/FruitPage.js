// Edit this page to show the fruits table
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { Table as ForemanTable } from 'foremanReact/components/common/table';
import { columns } from './FruitTableSchema';

const FruitPage = (props) => {
  const { results } = props;

  useEffect(() => {
    if (!results.length) props.fetchFruits();
  }, [props.fetchFruits, results.length]);

  return (
    <ForemanTable
      rows={results}
      columns={columns}
    />
  );
};

FruitPage.propTypes = {
  fetchFruits: PropTypes.func.isRequired,
  results: PropTypes.arrayOf(PropTypes.object),
};

FruitPage.defaultProps = {
  results: [],
};


export default FruitPage;
