// Edit this page to show the fruits table
import React, { Component } from 'react';
import PropTypes from 'prop-types';
import { Table as ForemanTable } from 'foremanReact/components/common/table';
import { columns } from './FruitTableSchema';

class FruitPage extends Component {
  componentDidMount() {
    // Fetch data here
    console.log('fruitsDidMount')
    this.props.fetchFruits();
  }

  render() {
    const { results } = this.props;
    return (
      <ForemanTable
        rows={results}
        columns={columns}
      />
    );
  }
}

FruitPage.propTypes = {
  fetchFruits: PropTypes.func.isRequired,
  results: PropTypes.arrayOf(PropTypes.object),
};

FruitPage.defaultProps = {
  results: [],
};


export default FruitPage;
