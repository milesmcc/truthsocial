import React from 'react';
import PropTypes from 'prop-types';
import { NavLink, withRouter } from 'react-router-dom';
import { injectIntl } from 'react-intl';
import { debounce } from 'lodash';
import { isUserTouching } from '../../../is_mobile';
import NotificationsCounterIcon from './notifications_counter_icon';
import IconSvg from 'mastodon/components/icon_svg';
import { connect } from 'react-redux';
import ImmutablePropTypes from 'react-immutable-proptypes';
import { List as ImmutableList } from 'immutable';

const mapStateToProps = state => {
  const me = state.getIn(['meta', 'me']);

  return {
    account: state.getIn(['accounts', me]),
  }
}

export const links = [
  <NavLink className='tabs-bar__link' to='/timelines/home' data-preview-title-id='column.home' data-preview-icon='home' ><IconSvg id='home' /></NavLink>,
  <NavLink className='tabs-bar__link' to='/notifications' data-preview-title-id='column.notifications' data-preview-icon='bell' ><NotificationsCounterIcon id='notification' /></NavLink>,
  <NavLink className='tabs-bar__link optional' to='/search' data-preview-title-id='tabs_bar.search' data-preview-icon='bell' ><IconSvg id='search' /></NavLink>,
];

export function getIndex (path) {
  return links.findIndex(link => link.props.to === path);
}

export function getLink (index) {
  return links[index].props.to;
}

export default @withRouter @injectIntl @connect(mapStateToProps)
class TabsBar extends React.PureComponent {
  
  static propTypes = {
    account: ImmutablePropTypes.map.isRequired,
    intl: PropTypes.object.isRequired,
    history: PropTypes.object.isRequired,
  }

  componentDidMount() {
      this.links = ImmutableList(links).push(<NavLink className='tabs-bar__link' to={`/accounts/${this.props.account.get('id')}`} data-preview-title-id='getting_started.heading' data-preview-icon='bars' ><IconSvg id='profile'  /></NavLink>);
  }

  setRef = ref => {
    this.node = ref;
  }

  handleClick = (e) => {
    // Only apply optimization for touch devices, which we assume are slower
    // We thus avoid the 250ms delay for non-touch devices and the lag for touch devices
    if (isUserTouching()) {
      e.preventDefault();
      e.persist();

      requestAnimationFrame(() => {
        const tabs = Array(...this.node.querySelectorAll('.tabs-bar__link'));
        const currentTab = tabs.find(tab => tab.classList.contains('active'));
        const nextTab = tabs.find(tab => tab.contains(e.target));
        const nodeChildren = Array(...this.node.childNodes)
        const nextTabIndex = nodeChildren.indexOf(nextTab)
        const nextTabComponent = this.links.get(nextTabIndex)
        const { props: { to } } = nextTabComponent;

        if (currentTab !== nextTab) {
          if (currentTab) {
            currentTab.classList.remove('active');
          }

          const listener = debounce(() => {
            nextTab.removeEventListener('transitionend', listener);
            this.props.history.push(to);
          }, 50);

          nextTab.addEventListener('transitionend', listener);
          nextTab.classList.add('active');
        }
      });
    }

  }

  render () {
    const { intl: { formatMessage } } = this.props;
    const currentPathname = this.props.location.pathname;
    if (!this.links) return null;
    return (
      <div className='tabs-bar__wrapper'>
        <nav className='tabs-bar' ref={this.setRef}>
          {this.links.map(link => React.cloneElement(
            link,
            { key: link.props.to, onClick: this.handleClick, 'aria-label': formatMessage({ id: link.props['data-preview-title-id'] }) },
            [React.cloneElement(link.props.children, {key: link.props.to, svg: link.props.children.props.id + (currentPathname == link.props.to ? '-active' : '')})]
          ))}

        </nav>
      </div>
    );
  }

}
// svg={this.props.svg + (this.props.active ? "-active" : "")}