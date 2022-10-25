import React, { useState } from 'react';
import {
  Card,
  CardHeader,
  CardTitle,
  CardBody,
  Flex,
  FlexItem,
  GridItem,
  ToggleGroup,
  ToggleGroupItem,
  Tooltip,
} from '@patternfly/react-core';
import { OutlinedQuestionCircleIcon, ExclamationTriangleIcon } from '@patternfly/react-icons';
import { translate as __ } from 'foremanReact/common/I18n';
import { propsToCamelCase } from 'foremanReact/common/helpers';
import PropTypes from 'prop-types';
import { ChartPie } from '@patternfly/react-charts';
import { ErrataMapper } from '../../../../components/Errata';
import { hostIsRegistered } from '../hostDetailsHelpers';
import { TranslatedAnchor } from '../../../Table/components/TranslatedPlural';
import EmptyStateMessage from '../../../Table/EmptyStateMessage';
import './ErrataOverviewCard.scss';

const statusContemplation = (errataStatus) => {
  // from backend errata_status.rb:
  // NEEDED_SECURITY_ERRATA = 3
  // NEEDED_ERRATA = 2
  // UNKNOWN = 1
  // UP_TO_DATE = 0
  const neededErrata = ([2, 3].includes(Number(errataStatus)));
  const allUpToDate = (errataStatus === 0);
  const otherErrataStatus = (!allUpToDate && !neededErrata);

  return {
    neededErrata,
    allUpToDate,
    otherErrataStatus,
  };
};

function HostInstallableErrata({
  id, errataCounts, errataStatus, errataCategory, errataStatusLabel,
}) {
  const counts = errataCategory === 'applicable' ? errataCounts.applicable : errataCounts;
  const show = errataCategory === 'applicable' ? 'all' : 'installable';
  const errataTotal = counts.total;
  const errataSecurity = counts.security;
  const errataBug = counts.bugfix;
  const errataEnhance = counts.enhancement;
  const { neededErrata, allUpToDate, otherErrataStatus } = statusContemplation(errataStatus);
  const chartData = [{
    w: 'security advisories', x: 'security', y: errataSecurity, z: errataTotal,
  }, {
    w: 'bug fixes', x: 'bugfix', y: errataBug, z: errataTotal,
  }, {
    w: 'enhancements', x: 'enhancement', y: errataEnhance, z: errataTotal,
  }];
  return (
    <CardBody>
      {allUpToDate &&
        <EmptyStateMessage
          title={__('All errata up-to-date')}
          body={__('No action required')}
          happy
        />
      }
      {otherErrataStatus &&
        <EmptyStateMessage
          title={null}
          body={errataStatusLabel}
          customIcon={ExclamationTriangleIcon}
          secondaryActionTitle={__('Enable repository sets')}
          secondaryActionLink="#/Content/Repository%20sets?show=all"
          showSecondaryAction
        />
      }
      {neededErrata &&
        <Flex direction="column">
          <FlexItem>
            <TranslatedAnchor
              id="errata-card-total-count"
              href={`#/Content/errata?show=${show}`}
              count={errataTotal}
              plural="errata"
              singular="erratum"
              ariaLabel={`${errataTotal} total errata`}
            />
          </FlexItem>
          <Flex flexWrap={{ xl: 'nowrap' }} direction="row" alignItems={{ default: 'alignItemsCenter' }}>
            <div className="piechart-overflow" style={{ overflow: 'visible', minWidth: '140px', maxHeight: '155px' }}>
              <div className="erratachart" style={{ minWidth: '300px', minHeight: '300px' }}>
                <ChartPie
                  ariaDesc="errataChart"
                  data={chartData}
                  constrainToVisibleArea
                  labels={({ datum }) => `${datum.y} ${datum.w}`}
                  padding={{
                    bottom: 20,
                    left: 20,
                    right: 140,
                    top: 20,
                  }}
                  width={250}
                  height={130}
                />
              </div>
            </div>
            <div className="erratalegend" style={{ minWidth: '140px' }}>
              <FlexItem>
                <ErrataMapper data={chartData} id={id} errataCategory={errataCategory} />
              </FlexItem>
            </div>
          </Flex>
        </Flex>
      }
    </CardBody>
  );
}

const ErrataToggleGroupItem = ({
  text, tooltipText, isSelected, onChange,
}) => (
  <ToggleGroupItem
    text={
      <>
        {text}
        <Tooltip
          content={tooltipText}
          position="top"
          enableFlip
        >
          <OutlinedQuestionCircleIcon style={{ marginBottom: '-2px', marginLeft: '0.3rem' }} color="gray" />
        </Tooltip>
      </>
    }
    isSelected={isSelected}
    onChange={onChange}
  />
);

ErrataToggleGroupItem.propTypes = {
  text: PropTypes.string.isRequired,
  tooltipText: PropTypes.string.isRequired,
  isSelected: PropTypes.bool.isRequired,
  onChange: PropTypes.func.isRequired,
};

const ErrataOverviewCard = ({ hostDetails }) => {
  const hostPopulated = (hostIsRegistered({ hostDetails }) &&
    !!hostDetails.content_facet_attributes);

  const [errataCategory, setErrataCategory] = useState('applicable');
  if (!hostPopulated) return null;
  const {
    id: hostId,
    errata_status: errataStatus,
    errata_status_label: errataStatusLabel,
  } = hostDetails;
  const { neededErrata } = statusContemplation(errataStatus);
  return (
    <GridItem rowSpan={1} md={6} lg={4} xl2={3} >
      <Card ouiaId="errata-card">
        <CardHeader>
          <Flex spaceItems={{ default: 'spaceItemsXl' }}>
            <CardTitle>{__('Errata')}</CardTitle>
            {neededErrata &&
              <ToggleGroup isCompact>
                <ErrataToggleGroupItem
                  text={__('Applicable')}
                  tooltipText={__('Applicable errata are errata that apply to at least one package installed on the host.')}
                  isSelected={errataCategory === 'applicable'}
                  onChange={selected => selected && setErrataCategory('applicable')}
                />
                <ErrataToggleGroupItem
                  text={__('Installable')}
                  tooltipText={__('Installable errata are applicable errata that are available in the host\'s content view and lifecycle environment.')}
                  isSelected={errataCategory === 'installable'}
                  onChange={selected => selected && setErrataCategory('installable')}
                />
              </ToggleGroup>
            }
          </Flex>
        </CardHeader>
        <HostInstallableErrata
          {...propsToCamelCase(hostDetails.content_facet_attributes)}
          id={hostId}
          errataCategory={errataCategory}
          errataStatus={errataStatus}
          errataStatusLabel={errataStatusLabel}
        />
      </Card>
    </GridItem>
  );
};

HostInstallableErrata.propTypes = {
  id: PropTypes.number.isRequired,
  errataCounts: PropTypes.shape({
    bugfix: PropTypes.number,
    enhancement: PropTypes.number,
    security: PropTypes.number,
    total: PropTypes.number,
    applicable: PropTypes.shape({
      bugfix: PropTypes.number,
      enhancement: PropTypes.number,
      security: PropTypes.number,
    }),
  }).isRequired,
  errataStatus: PropTypes.number,
  errataStatusLabel: PropTypes.string,
  errataCategory: PropTypes.string,
};

HostInstallableErrata.defaultProps = {
  errataStatus: undefined,
  errataStatusLabel: __('Unknown errata status'),
  errataCategory: 'applicable',
};

ErrataOverviewCard.propTypes = {
  hostDetails: PropTypes.shape({
    content_facet_attributes: PropTypes.shape({}),
    id: PropTypes.number,
    errata_status: PropTypes.number,
    errata_status_label: PropTypes.string,
  }),
};

ErrataOverviewCard.defaultProps = {
  hostDetails: {},
};

export default ErrataOverviewCard;
