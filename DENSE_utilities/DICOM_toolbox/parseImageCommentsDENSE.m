function varargout = parseImageCommentsDENSE(str, dcm)

%PARSEIMAGECOMMENTSDENSE parse ImageComments field of DENSE file
%
%INPUTS
%   str....ImageComments string
%   dcm....DICOM Header
%
%OUTPUTS
%   id.....parsed DENSE identifier string. Valid outputs are:
%       [],'unknown',
%       'mag.overall','mag.x','mag.y','mag.z',
%       'pha.x','pha.y','pha.z'
%   data...parsed DENSE data structure, with the following fields:
%       Type.........identifier string
%       Index........image index
%       Number.......number of images in sequence
%       Partition....for 3D data, [partition index, number of partitions]
%       Scale........scale parameter    (phase-only)
%       EncFreq......encoding frequency (phase-only)
%       SwapFlag.....swap flag
%       NegFlag......negate flags
%
%USAGE
%
%   ID = PARSEIMAGECOMMENTSDENSE(STR) parse the DENSE identifier string
%   from the 'ImageComment' DICOM field string STR.
%
%
%NOTES ON IMAGECOMMENTS
%
%   The expected form of a DENSE 'ImageComments' field is as such:
%     • phase data     -> ['DENSE x-enc pha - Scale:1.00 EncFreq:0.10 '...
%       'Rep:0/1 Slc:0/1 Par:0/1 Phs:0/47 RCswap:1 RCSflip:0/1/0']
%     • magnitude data -> ['DENSE overall mag - Rep:0/1 Slc:0/1 '...
%       'Par:0/1 Phs:46/47 RCswap:1 RCSflip:0/1/0']
%
%   We accept the following non case-sensitive DENSE indentifiers
%   (where '*' represents any set of characters):
%     'DENSE*x*mag', 'DENSE*y*mag', 'DENSE*z*mag', 'DENSE*overall*mag'
%     'DENSE*x*pha', 'DENSE*y*pha', 'DENSE*z*pha',
%
%   The ID of strings that begin with 'DENSE' but do not match the
%   known 'ImageComments' structure will be 'unknown'. This is meant to
%   identify DICOM data that should be DENSE, but cannot be parsed.
%

% This Source Code Form is subject to the terms of the Mozilla Public
% License, v. 2.0. If a copy of the MPL was not distributed with this
% file, You can obtain one at http://mozilla.org/MPL/2.0/.
%
% Copyright (c) 2016 DENSEanalysis Contributors

%% WRITTEN BY: Drew Gilliam
%MODIFICATION HISTORY:
%   2009.02     Drew Gilliam
%     --creation
%   2009.11     Drew Gilliam
%     --partition output



    %% IDENTIFY FILE TYPE
    % the 'id' output is empty if not a DENSE IC string,

    % check for single input
    narginchk(1, 2);

    % check for string
    if isempty(str) || ~ischar(str)
        id = '';
        data = [];
        return
    end

    % ignore case
    str = lower(str);

    if ~exist('dcm', 'var')
        dcm = struct();
    end

    if ~isfield(dcm, 'SequenceName')
        seq = '';
    else
        seq = dcm.SequenceName;
    end

    % Check the sequence
    if strwcmpi(seq, 'dense2d1_*')
        [varargout{1:nargout}] = parseImageCommentsEPIDENSE(str, dcm);
    else
        [varargout{1:nargout}] = parseImageCommentsSpiralDENSE(str, dcm);
    end
end

function [id, data] = parseImageCommentsEPIDENSE(str, dcm)
    % NOTES: For now, there is only a 2D EPI DENSE acquisition so we can
    %        safely ignore 3D cases

    % DENSE PE-enc pha - ResiFac:1.0000 EncFreq:0.10cyc/mm Phs:11/13 SlcInfoBfNormOrien: PosV:[27.3184,-8.37659,2.67394] RowV:[-0.970907,0.0785646,0.226201] ColV:[0.18521,0.845144,0.501427] NormV:[0.151778,-0.528734,0.835107] Swap:1

    if     strwcmpi(str, 'dense*pe-enc*mag*')
        id = 'mag.y';
    elseif strwcmpi(str, 'dense*ro-enc*mag*')
        id = 'mag.x';
    elseif strwcmpi(str, 'dense*pe-enc*pha*')
        id = 'pha.y';
    elseif strwcmpi(str, 'dense*ro-enc*pha*')
        id = 'pha.x';
    else
        id = 'unknown';
        data = [];
        return;
    end

    data = struct(...
        'Type',         id, ... % identifier
        'Index',        [], ... % image index
        'Number',       [], ... % number of images in sequence
        'Partition',    [1 1], ... % 3D partition index
        'Scale',        [], ... % scale parameter (phase-only)
        'EncFreq',      [], ... % encoding frequency (phase-only)
        'SwapFlag',     [], ... % swap flag
        'NegFlag',      []);

    % Now actually parse the comment contents
    cnt = zeros(1, 6);
    [scale,     cnt(1)] = findvals(str, 'resifac:', '%f', 1);
    [encfreq,   cnt(2)] = findvals(str, 'encfreq:', '%fcyc/mm', 1);
    [phs,       cnt(3)] = findvals(str, 'phs:', '%d%*c%d', 2);
    [rcswap,    cnt(4)] = findvals(str, 'swap:', '%d', 1);
    [rowvec,    cnt(5)] = findvals(str, 'rowv:', '[%f,%f,%f]', 3);
    [colvec,    cnt(6)] = findvals(str, 'colv:', '[%f,%f,%f]', 3);

    if strwcmpi(id, 'pha*')
        tf = all(cnt(2:6) == [1 2 1 3 3]);
    else
        tf = all(cnt(3:6) == [2 1 3 3]);
    end

    if ~tf
        id = 'unknown';
        data = [];
        return;
    end

    if nargout > 1
        idx = double(phs(1));
        nbr = double(phs(2));

        if isempty(scale) && strwcmpi(id, 'pha*')
            scale = 1.0;
        else
            scale = double(scale);
        end

        encfreq = double(encfreq);
        rcswap = logical(rcswap);

        IOP = round(dcm.ImageOrientationPatient * 1000);
        row = round(rowvec(:) * 1000);
        col = round(colvec(:) * 1000);

        % Check that the row vector is equal to the IOP
        if isequal(abs(IOP(1:3)), abs(row)) && isequal(abs(IOP(4:6)), abs(col))
            % No flip required
            rcswap = false;
        elseif isequal(abs(IOP(4:6)), abs(row)) && isequal(abs(IOP(1:3)), abs(col))
            rcswap = true;
            [rowvec, colvec] = deal(colvec, rowvec);
        else
            error('Orientation vectors do not match the data')
        end

        % Figure out if we need to negate any of the displacements
        neg = false(1, 3);
        neg(1) = ~isequal(sign(rowvec(:)), sign(dcm.ImageOrientationPatient(1:3)));
        neg(2) = ~isequal(sign(colvec(:)), sign(dcm.ImageOrientationPatient(4:6)));

        data = struct(...
            'Type',         id, ...
            'Index',        idx, ...
            'Number',       nbr, ...
            'Partition',    [1 1], ...
            'Scale',        scale, ...
            'EncFreq',      encfreq, ...
            'SwapFlag',     rcswap, ...
            'NegFlag',      neg);
    end
end

function [id, data] = parseImageCommentsSpiralDENSE(str, varargin)

    % find valid identifier
    if strwcmpi(str,'dense*')
        if     strwcmpi(str,'dense*overall*mag*')
            id = 'mag.overall';
        elseif strwcmpi(str,'dense*x*mag*')
            id = 'mag.x';
        elseif strwcmpi(str,'dense*y*mag*')
            id = 'mag.y';
        elseif strwcmpi(str,'dense*z*mag*')
            id = 'mag.z';
        elseif strwcmpi(str,'dense*x*pha*')
            id = 'pha.x';
        elseif strwcmpi(str,'dense*y*pha*')
            id = 'pha.y';
        elseif strwcmpi(str,'dense*z*pha*')
            id = 'pha.z';
        else
            id = 'unknown';
            data = [];
            return;
        end
    else
        id = '';
        data = [];
        return
    end


    % default output
    data = struct(...
        'Type',      id,...  % identifier
        'Index',     [],...  % image index
        'Number',    [],...  % number of images in sequence
        'Partition', [],...  % 3D partition index
        'Scale',     [],...  % scale parameter (phase-only)
        'EncFreq',   [],...  % encoding frequency (phase-only)
        'SwapFlag',  [],...  % swap flag
        'NegFlag',   []);    % negate flag


%     DENSE x-enc pha - Scale:1.000000 EncFreq:0.10 Rep:0/1 Slc:0/1 Par:0/1 Phs:46/47 RCswap:1 RCSflip:0/1/0

    % parsed values
    cnt = zeros(1,8);
    [scale,   cnt(1)] = findvals(str,'scale:','%f',1);
    [encfreq, cnt(2)] = findvals(str,'encfreq:','%f',1);
    [rep,     cnt(3)] = findvals(str,'rep:','%d%*c%d',2);
    [slc,     cnt(4)] = findvals(str,'slc:','%d%*c%d',2);
    [par,     cnt(5)] = findvals(str,'par:','%d%*c%d',2);
    [phs,     cnt(6)] = findvals(str,'phs:','%d%*c%d',2);
    [rcswap,  cnt(7)] = findvals(str,'rcswap:','%d',1);
    [rcsflip, cnt(8)] = findvals(str,'rcsflip:','%d%*c%d%*c%d',3);

    % check for expected number of outputs parsed
    if strwcmpi(id,'pha')
        tf = all(cnt([2 6 7 8]) == [1 2 1 3]);
    else
        tf = all(cnt([6 7 8]) == [2 1 3]);
    end

    if ~tf
        id = 'unknown';
        data = [];
        return;
    end

    % successful parsing!
    if nargout > 1

        % ensure outputs of the expected class
        idx = double(phs(1))+1;
        nbr = double(phs(2));

        if isempty(scale) && strwcmpi(id,'pha*')
            scale = 1.0;
        else
            scale = double(scale);
        end

        encfreq = double(encfreq);
        rcswap = logical(rcswap);
        rcsflip = logical(rcsflip(:)');

        if cnt(3)==2
            rep = double(rep) + [1 0];
        else
            rep = [1 1];
        end

        if cnt(4)==2
            slc = double(slc) + [1 0];
        else
            slc = [1 1];
        end

        if cnt(5)==2
            par = double(par) + [1 0];
        else
            par = [1 1];
        end


        % save to output structure
        data = struct(...
            'Type',      id,     ...
            'Index',     idx,    ...
            'Number',    nbr,    ...
            'Partition', par,    ...
            'Scale',     scale,  ...
            'EncFreq',   encfreq,...
            'SwapFlag',  rcswap, ...
            'NegFlag',   rcsflip);
    end
end


%% HELPER FUNCTION: FIND VALUES IN STRING
function [vals,cnt] = findvals(str,id,fmt,sz)
% str....search string
% id.....string identifier (e.g. 'EncFreq')
% fmt....expected value format
% sz.....number of values to read
% vals...returned values
% cnt....number of values found

    % default outputs
    vals = [];
    cnt = 0;

    % locate id string
    idx = strfind(str,lower(id));
    if isempty(idx), return; end

    % parse values
    buf = str(idx(1):end);
    [vals,cnt] = sscanf(buf,[id fmt],sz);
    vals = vals(:)';

end


%% END OF FILE=============================================================
