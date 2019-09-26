// Add Redux reducers here
import { GET_FRUITS_SUCCESS, GET_FRUITS_REQUEST, GET_FRUITS_FAILURE, SET_FRUITS } from './FruitConstants';

const defaultState = {
  loading: false,
  results: [],
};

export default (state = defaultState, action) => {
  switch (action.type) {
    case GET_FRUITS_SUCCESS:
      return state.merge({
        loading: false,
      });
    case GET_FRUITS_REQUEST:
      return state.merge({
        loading: true,
      });
    case GET_FRUITS_FAILURE:
      return state.merge({
        loading: false,
        error: action.error,
      });
    case SET_FRUITS:
      return state.merge({
        results: action.payload,
      });
    default:
      return state;
  }
};
