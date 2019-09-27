import { withRouter } from 'react-router-dom';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import * as fruitActions from './FruitActions';
import FruitPage from './FruitPage';

const mapStateToProps = state => ({
  loading: state.katello.fruits.loading,
  results: state.katello.fruits.results,
  errors: state.katello.fruits.errors,
});

const actions = {
  ...fruitActions,
};

const mapDispatchToProps = dispatch => bindActionCreators(actions, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(withRouter(FruitPage));
