import React, { useContext } from 'react';
import { useForemanOrganization } from 'foremanReact/Root/Context/ForemanContext';
import { ForemanActionsBarContext } from 'foremanReact/components/HostDetails/ActionsBar';
import { useForemanModal } from 'foremanReact/components/ForemanModal/ForemanModalHooks';
import BulkChangeHostCVModal from './BulkChangeHostCVModal';

const BulkChangeHostCVModalScene = () => {
  const orgId = useForemanOrganization()?.id;
  const { selectedCount, fetchBulkParams } = useContext(ForemanActionsBarContext);
  const { modalOpen, setModalClosed } = useForemanModal({ id: 'bulk-change-cv-modal' });

  if (!orgId) return null;


  return (
    <BulkChangeHostCVModal
      key="bulk-change-cv-modal"
      selectedCount={selectedCount}
      fetchBulkParams={fetchBulkParams}
      isOpen={modalOpen}
      closeModal={setModalClosed}
      orgId={orgId}
    />

  );
};

export default BulkChangeHostCVModalScene;
