// web/gis_calendar.js
// Google Identity Services Token Client for Calendar Access
// Uses Google Identity Services GIS 2.0 for token-based OAuth 2.0

// Global state for token management
window.gisCalendarState = {
  tokenClient: null,
  accessToken: null,
  tokenExpiresAt: null,
  pendingRequest: null
};

/**
 * Initialize the GIS Token Client
 * @param {string} clientId - Your OAuth 2.0 Client ID
 * @param {string} scope - Space-separated scopes (e.g., "https://www.googleapis.com/auth/calendar.events")
 * @param {string} callbackId - Unique identifier for this instance
 */
window.gisInitTokenClient = function(clientId, scope, callbackId) {
  // Store the scope for later use
  window.gisCalendarState.scope = scope;
  window.gisCalendarState.callbackId = callbackId;

  // Initialize the token client
  window.gisCalendarState.tokenClient = google.accounts.oauth2.initTokenClient({
    client_id: clientId,
    scope: scope,
    callback: function(response) {
      window.gisHandleTokenResponse(response, callbackId);
    },
    error_callback: function(error) {
      window.gisHandleError(error, callbackId);
    }
  });

  console.log('GIS Token Client initialized with callbackId:', callbackId);
};

/**
 * Request an access token with user consent
 * @param {boolean} requestConsent - If true, will prompt for consent; if false, uses incremental auth
 */
window.gisRequestCalendarToken = function(requestConsent, callbackId) {
  if (!window.gisCalendarState.tokenClient) {
    const error = { error: 'TOKEN_CLIENT_NOT_INITIALIZED', message: 'Token client not initialized' };
    window.gisHandleError(error, callbackId);
    return;
  }

  // Store pending request info
  window.gisCalendarState.pendingRequest = {
    requestConsent: requestConsent,
    callbackId: callbackId,
    timestamp: Date.now()
  };

  // If not requesting consent, use incremental authorization with prompt=none
  if (!requestConsent && window.gisCalendarState.accessToken) {
    // Check if token is still valid (with 5 minute buffer)
    const now = Date.now();
    if (window.gisCalendarState.tokenExpiresAt && 
        window.gisCalendarState.tokenExpiresAt > now + 300000) {
      // Token is still valid, return it immediately
      window.gisCalendarState.pendingRequest = null;
      window.gisHandleTokenResponse({
        access_token: window.gisCalendarState.accessToken,
        expires_in: (window.gisCalendarState.tokenExpiresAt - now) / 1000
      }, callbackId);
      return;
    }
  }

  // Configure the client based on whether we want consent
  if (requestConsent) {
    // First time: request consent
    window.gisCalendarState.tokenClient.callback = function(response) {
      window.gisHandleTokenResponse(response, callbackId);
    };
  } else {
    // Subsequent requests: use incremental authorization
    // Note: prompt=none may fail if user needs to re-consent
    window.gisCalendarState.tokenClient.callback = function(response) {
      // If this fails due to consent required, caller should retry with requestConsent=true
      window.gisHandleTokenResponse(response, callbackId);
    };
  }

  // Request the token
  try {
    window.gisCalendarState.tokenClient.requestAccessToken({ prompt: requestConsent ? 'consent' : 'none' });
  } catch (e) {
    console.error('Error requesting token:', e);
    // If prompt=none fails, try with consent
    if (!requestConsent) {
      console.log('Retrying with consent...');
      window.gisCalendarState.tokenClient.requestAccessToken({ prompt: 'consent' });
    } else {
      window.gisHandleError({ error: 'REQUEST_FAILED', message: e.message }, callbackId);
    }
  }
};

/**
 * Handle successful token response
 * @param {Object} response - OAuth 2.0 token response
 */
window.gisHandleTokenResponse = function(response, callbackId) {
  console.log('Token response received:', response.access_token ? 'Token received' : 'No token');
  
  if (response.access_token) {
    // Store the token
    window.gisCalendarState.accessToken = response.access_token;
    window.gisCalendarState.tokenExpiresAt = Date.now() + (response.expires_in * 1000);
    
    // Send token back to Flutter using the callback channel
    if (window.flutterChannel && window.flutterChannel[callbackId]) {
      window.flutterChannel[callbackId].postMessage({
        type: 'GIS_TOKEN_SUCCESS',
        accessToken: response.access_token,
        expiresIn: response.expires_in,
        callbackId: callbackId
      });
    }
  } else {
    // Token may have been returned in the hash fragment (old method)
    console.log('No access_token in response, checking for error...');
    window.gisHandleError({ 
      error: 'NO_TOKEN', 
      message: 'No access token in response' 
    }, callbackId);
  }
};

/**
 * Handle token errors
 * @param {Object} error - Error object from GIS
 */
window.gisHandleError = function(error, callbackId) {
  console.error('GIS Error:', error);
  
  // Determine error type and send appropriate message
  let errorType = 'UNKNOWN';
  let errorMessage = error.message || 'Unknown error occurred';
  
  if (error.error === 'popup_closed' || 
      error.error === 'access_denied' ||
      error.type === 'popup_failed_to_open') {
    errorType = 'USER_CANCELLED';
    errorMessage = 'User cancelled the sign-in popup';
  } else if (error.error === 'network_error' || 
             error.error === 'NetworkError' ||
             error.type === 'network_error') {
    errorType = 'NETWORK_ERROR';
    errorMessage = 'Network error occurred. Please check your connection.';
  } else if (error.error === 'invalid_client' || 
             error.error === 'idpiframe_initialization_failed') {
    errorType = 'CONFIG_ERROR';
    errorMessage = 'Configuration error. Please check OAuth settings.';
  } else if (error.error === 'consent_required' || 
             error.error === 'interaction_required' ||
             error.error === 'opt_out_of_tos') {
    errorType = 'CONSENT_REQUIRED';
    errorMessage = 'User consent required. Please try again.';
  } else if (error.error === 'TOKEN_CLIENT_NOT_INITIALIZED') {
    errorType = 'NOT_INITIALIZED';
    errorMessage = 'Token client not initialized. Call gisInitTokenClient first.';
  }
  
  // Send error back to Flutter
  if (window.flutterChannel && window.flutterChannel[callbackId]) {
    window.flutterChannel[callbackId].postMessage({
      type: 'GIS_TOKEN_ERROR',
      errorType: errorType,
      errorMessage: errorMessage,
      originalError: JSON.stringify(error),
      callbackId: callbackId
    });
  }
};

/**
 * Check if we have a valid token
 * @returns {boolean} True if token is valid and not expired
 */
window.gisHasValidToken = function() {
  if (!window.gisCalendarState.accessToken) {
    return false;
  }
  // Check expiration with 5 minute buffer
  const now = Date.now();
  return window.gisCalendarState.tokenExpiresAt && 
         window.gisCalendarState.tokenExpiresAt > now + 300000;
};

/**
 * Get the current access token (or null if expired)
 * @returns {string|null} Current access token
 */
window.gisGetAccessToken = function() {
  if (window.gisHasValidToken()) {
    return window.gisCalendarState.accessToken;
  }
  return null;
};

/**
 * Clear stored token (for logout or refresh)
 */
window.gisClearToken = function() {
  window.gisCalendarState.accessToken = null;
  window.gisCalendarState.tokenExpiresAt = null;
  
  // Optionally revoke the token
  if (window.gisCalendarState.accessToken) {
    google.accounts.oauth2.revoke(window.gisCalendarState.accessToken, function() {
      console.log('Token revoked');
    });
  }
};

// Make functions globally available
window.gisInitTokenClient = window.gisInitTokenClient;
window.gisRequestCalendarToken = window.gisRequestCalendarToken;
window.gisHasValidToken = window.gisHasValidToken;
window.gisGetAccessToken = window.gisGetAccessToken;
window.gisClearToken = window.gisClearToken;
window.gisHandleTokenResponse = window.gisHandleTokenResponse;
window.gisHandleError = window.gisHandleError;

console.log('GIS Calendar module loaded');
