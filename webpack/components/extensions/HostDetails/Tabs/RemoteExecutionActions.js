import { API_OPERATIONS, post } from 'foremanReact/redux/API';
import { REX_JOB_INVOCATIONS_KEY, REX_FEATURES } from './RemoteExecutionConstants';
import { foremanApi } from '../../../../services/api';
import { getResponseErrorMsgs } from '../../../../utils/helpers';
import { renderTaskStartedToast } from '../../../../scenes/Tasks/helpers';

const errorToast = (error) => {
  const message = getResponseErrorMsgs(error.response);
  return message;
};

const baseParams = ({ feature, hostname, inputs = {} }) => ({
  job_invocation: {
    feature,
    inputs,
    search_query: `name ^ (${hostname})`,
  },
});

const katelloPackageInstallParams = ({ hostname, packageName }) =>
  baseParams({
    hostname,
    inputs: { package: packageName },
    feature: REX_FEATURES.KATELLO_PACKAGE_INSTALL,
  });

const katelloServiceRestartParams = ({ hostname, helper }) =>
  baseParams({
    hostname,
    inputs: { helper },
    feature: REX_FEATURES.KATELLO_SERVICE_RESTART,
  });

export const installPackage = ({ hostname, packageName }) => post({
  type: API_OPERATIONS.POST,
  key: REX_JOB_INVOCATIONS_KEY,
  url: foremanApi.getApiUrl('/job_invocations'),
  params: katelloPackageInstallParams({ hostname, packageName }),
  handleSuccess: response => renderTaskStartedToast({
    humanized: { action: `Install ${packageName} on ${hostname}` },
    id: response?.data?.dynflow_task?.id,
  }),
  errorToast: error => errorToast(error),
});

export const restartService = ({ hostname, helper }) => post({
  type: API_OPERATIONS.POST,
  key: REX_JOB_INVOCATIONS_KEY,
  url: foremanApi.getApiUrl('/job_invocations'),
  params: katelloServiceRestartParams({ hostname, helper }),
  handleSuccess: response => renderTaskStartedToast({
    humanized: { action: `Restart traces on ${hostname}` },
    id: response?.data?.dynflow_task?.id,
  }),
  errorToast: error => errorToast(error),
});
