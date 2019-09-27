// Put redux actions here
import api from '../../services/api';
import { GET_FRUITS_SUCCESS, GET_FRUITS_REQUEST, GET_FRUITS_FAILURE, SET_FRUITS } from './FruitConstants';

// export const fetchFruits = () => console.log('fetchFruits')
// eslint-disable-next-line import/prefer-default-export
export const fetchFruits = () => async (dispatch) => {
  console.log('FRUITTTTTTT')
  dispatch({ type: GET_FRUITS_REQUEST });

  try {
    const { data } = await api.get('/fruits', {});
    dispatch({
      type: GET_FRUITS_SUCCESS,
    });
    return dispatch({
      type: SET_FRUITS,
      response: data,
    });
  } catch (error) {
    return dispatch({
      type: GET_FRUITS_FAILURE,
      result: error,
    });
  }
};
