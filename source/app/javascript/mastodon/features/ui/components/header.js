import React from 'react';
import { NavLink, withRouter } from 'react-router-dom';
import { injectIntl } from 'react-intl';

import LogoFull from 'mastodon/components/logo_full';


export default @injectIntl
@withRouter
class Header extends React.PureComponent {

  render() {

    return (
      <div className='header__wrapper'>
        <div className="logo-wrapper">
          <NavLink className='logo-link' to='/timelines/home' data-preview-title-id='column.home' data-preview-icon='home' ><LogoFull /></NavLink>
        </div>
        <div id='tabs-bar__portal' />
      </div>
    );
  }

}
