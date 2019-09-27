import { withRouter } from 'react-router-dom';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { fetchFruits } from './FruitActions';
import FruitPage from './FruitPage';

const mapStateToProps = state => ({
  loading: state.loading,
  results: state.results,
  errors: state.errors,
});

const mapDispatchToProps = dispatch => bindActionCreators({ fetchFruits }, dispatch);

const ConnectedFruitPage = connect(mapStateToProps, mapDispatchToProps)(FruitPage);
console.log('index.js')
export default withRouter(ConnectedFruitPage);
