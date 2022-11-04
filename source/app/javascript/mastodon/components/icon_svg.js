import React from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';


export default class IconSvg extends React.PureComponent {

  static propTypes = {
    svg: PropTypes.string.isRequired,
  };

  svgPaths = {
    "reply": 
    <svg width="24" height="24" viewBox="0 0 135 117" version="1.1" xmlns="http://www.w3.org/2000/svg" class="comment">
       
    </svg>
    ,
    "retruth": 
    <svg width="24" height="24" viewBox="0 0 165 123" version="1.1" xmlns="http://www.w3.org/2000/svg" class="retruth">
   
    </svg>
    ,
    "retruth-active": 
    <svg width="24" height="24" viewBox="0 0 165 123" version="1.1" xmlns="http://www.w3.org/2000/svg" class="retruth-active">
       
    </svg>
    ,
    "love": <svg viewBox="0 0 24 24" aria-hidden="true" class="r-4qtqp9 r-yyyyoo r-1xvli5t r-dnmrzs r-bnwqim r-1plcrui r-lrvibr r-1hdv0qi"></svg>,
    "love-active": <svg xmlns="http://www.w3.org/2000/svg" width="20.098" height="18.914" viewBox="0 0 20.098 18.914">
     
    </svg>
    ,
    "share": <svg viewBox="0 0 24 24" aria-hidden="true" class="r-4qtqp9 r-yyyyoo r-1xvli5t r-dnmrzs r-bnwqim r-1plcrui r-lrvibr r-1hdv0qi"></svg>,
    "verified": <svg viewBox="2.249 1.268 117.913 90.002" xmlns="http://www.w3.org/2000/svg">
     
    </svg>,
    "post":
      <svg viewBox="1.249 1.268 117.913 90.002" xmlns="http://www.w3.org/2000/svg">
        
      </svg>,
    "home":
      <svg viewBox="0 0 24 24" aria-hidden="true" class="r-14j79pv r-4qtqp9 r-yyyyoo r-lwhw9o r-dnmrzs r-bnwqim r-1plcrui r-lrvibr">
        
      </svg>,
    "home-active":
      <svg viewBox="0 0 24 24" aria-hidden="true" class="r-13gxpu9 r-4qtqp9 r-yyyyoo r-lwhw9o r-dnmrzs r-bnwqim r-1plcrui r-lrvibr">
       
      </svg>,
    "notification":
      <svg viewBox="0 0 24 24" aria-hidden="true" class="r-14j79pv r-4qtqp9 r-yyyyoo r-lwhw9o r-dnmrzs r-bnwqim r-1plcrui r-lrvibr">
      
      </svg>,
    "notification-active":
      <svg viewBox="0 0 24 24" aria-hidden="true" class="r-13gxpu9 r-4qtqp9 r-yyyyoo r-lwhw9o r-dnmrzs r-bnwqim r-1plcrui r-lrvibr">
       
      </svg>,
    "search":
      <svg viewBox="0 0 24 24" aria-hidden="true" class="r-14j79pv r-4qtqp9 r-yyyyoo r-lwhw9o r-dnmrzs r-bnwqim r-1plcrui r-lrvibr">
       
      </svg>,
    "search-active":
      <svg viewBox="0 0 24 24" aria-hidden="true" class="r-13gxpu9 r-4qtqp9 r-yyyyoo r-lwhw9o r-dnmrzs r-bnwqim r-1plcrui r-lrvibr">
       
      </svg>,
    "profile":
      <svg viewBox="0 0 24 24" aria-hidden="true" class="r-18jsvk2 r-4qtqp9 r-yyyyoo r-lwhw9o r-dnmrzs r-bnwqim r-1plcrui r-lrvibr">
       
      </svg>,
    "profile-active":
      <svg viewBox="0 0 24 24" aria-hidden="true" class="r-13gxpu9 r-4qtqp9 r-yyyyoo r-lwhw9o r-dnmrzs r-bnwqim r-1plcrui r-lrvibr">
       
      </svg>,
    "ellipsis-h":
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="jss224">
    
   </svg>,
    "ellipsis-h-active":
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="jss224">
     
    </svg>,
    "ellipsis-v":
    <svg width="4px" height="18px" viewBox="0 0 4 18" version="1.1" xmlns="http://www.w3.org/2000/svg" class="ellipsis-v">
       
    </svg>,
    "ellipsis-v-active":
    <svg width="4px" height="18px" viewBox="0 0 4 18" version="1.1" xmlns="http://www.w3.org/2000/svg" class="ellipsis-v-active">
       
    </svg>,
    "fire":
    <svg width="24" height="24" viewBox="0 0 88 108" version="1.1" xmlns="http://www.w3.org/2000/svg" class="fire">
       
    </svg>,
    "fire-active":
    <svg width="24" height="24" viewBox="0 0 80 98" version="1.1" xmlns="http://www.w3.org/2000/svg" class="fire-active">
      
    </svg>,
  };

  render() {
    return (
      this.props.svg in this.svgPaths ? this.svgPaths[this.props.svg] : <svg></svg>
    );
  }

}
