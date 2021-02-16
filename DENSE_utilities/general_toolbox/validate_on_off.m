function validate_on_off(value, identifier)
  % validate_on_off - Validate the parameter for 'on'/'off' in GUI components
  %
  %  Centralizes the checking of valid values for 'on'/'off' pairs in GUI
  %  components (e.g. Enable, Visible). In newer versions of MATLAB, this is an
  %  enumeration of type matlab.lang.OnOffSwitchState whereas in older versions
  %  this was simply the strings 'on' or 'off'. This helper function helps check
  %  for either properly.
  %
  % USAGE:
  %   validate_on_off(value, identifier)
  %
  % INPUTS:
  %   value:      Any, The value to validate is a valid on/off value
  %   identifier: String, Identifier to use for the error message in case of
  %               validation failure.

  % This Source Code Form is subject to the terms of the Mozilla Public
  % License, v. 2.0. If a copy of the MPL was not distributed with this
  % file, You can obtain one at http://mozilla.org/MPL/2.0/.
  %
  % Copyright (c) 2021 DENSEanalysis Contributors

  % In newer versions of MATLAB, this can be an enumeration
  if isa(value, 'matlab.lang.OnOffSwitchState')
    return
  end

  % In older versions, this was simply a string
  if ~ischar(value) || ~any(strcmpi(value, {'on', 'off'}))
    error(identifier, 'Invalid value; acceptable values are [on|off]')
  end
end