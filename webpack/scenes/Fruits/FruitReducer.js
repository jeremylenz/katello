// Add Redux reducers here
import Immutable from 'seamless-immutable';
import { GET_FRUITS_SUCCESS, GET_FRUITS_REQUEST, GET_FRUITS_FAILURE, SET_FRUITS } from './FruitConstants';

const defaultState = Immutable({
  loading: false,
  results: [],
});

// eslint-disable-next-line import/prefer-default-export
export const fruits = (state = defaultState, action) => {
  switch (action.type) {
    case GET_FRUITS_SUCCESS:
      return state.merge({
        loading: false,
      });
    case GET_FRUITS_REQUEST:
      console.log('FRUITREDUCER')
      return state.merge({
        loading: true,
      });
    case GET_FRUITS_FAILURE:
      return state.merge({
        loading: false,
        errors: action.error,
      });
    case SET_FRUITS: {
      const { results } = action.response;
      return state.merge({
        results,
      });
    }
    default:
      return state;
  }
};
