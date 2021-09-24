import React, { useState, useEffect, useCallback } from 'react';
import PropTypes from 'prop-types';
import useDeepCompareEffect from 'use-deep-compare-effect';
import {
  EmptyState,
  EmptyStateIcon,
  EmptyStateBody,
  Title,
  EmptyStateVariant,
  Button,
  Flex,
  FlexItem,
  Modal,
  ModalVariant,
  Dropdown,
  DropdownItem,
  DropdownToggle,
} from '@patternfly/react-core';
import { CaretDownIcon } from '@patternfly/react-icons';
import { translate as __ } from 'foremanReact/common/I18n';
import { useSelector, useDispatch } from 'react-redux';
import { selectAPIResponse } from 'foremanReact/redux/API/APISelectors';

const EnableTracerModal = ({ isOpen, setIsOpen }) => {
  const title = __('Enable Traces');
  const body = __('Enabling will install the katello-host-tools-tracer package on the host.');
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const toggleDropdownOpen = () => setIsDropdownOpen(prev => !prev);
  const dropdownOptions = [
    __('via remote execution'),
    __('via customized remote execution'),
  ];
  const [selectedOption, setSelectedOption] = useState(dropdownOptions[0]);
  const handleSelect = () => {
    setIsDropdownOpen(false);
  };
  const enableTracer = () => {
    console.log(selectedOption);
    setIsOpen(false);
  }

  const dropdownItems = dropdownOptions.map(text => (
    <DropdownItem key={`option_${text}`} onClick={() => setSelectedOption(text)}>{text}</DropdownItem>
  ));

  return (
    <Modal
      variant={ModalVariant.small}
      title={title}
      width="28em"
      isOpen={isOpen}
      onClose={() => setIsOpen(false)}
      actions={[
        <Button key="enable_button" type="submit" variant="primary" onClick={enableTracer}>{title}</Button>,
        <Button key="cancel_button" variant="link" onClick={() => setIsOpen(false)}>{__('Cancel')}</Button>,
      ]}
    >
      <Flex direction={{ default: 'column' }}>
        <FlexItem>{body}</FlexItem>
        <FlexItem><div>{__('Select a provider to install katello-host-tools-tracer')}</div></FlexItem>
        <FlexItem>
          <Dropdown
            toggle={
              <DropdownToggle
                id="toggle-enable-tracer-modal-dropdown"
                onToggle={toggleDropdownOpen}
                toggleIndicator={CaretDownIcon}
              >
                {selectedOption}
              </DropdownToggle>
            }
            onSelect={handleSelect}
            isOpen={isDropdownOpen}
            dropdownItems={dropdownItems}
            menuAppendTo="parent"
          />
        </FlexItem>
      </Flex>
    </Modal>
  );
};

EnableTracerModal.propTypes = {
  isOpen: PropTypes.bool.isRequired,
  setIsOpen: PropTypes.func.isRequired,
};

export default EnableTracerModal;
