function html = markdown2html(markdown)
    % markdown2html - Simple function for converting markdown to HTML
    %
    %   For now, this function only really handles links, newlines, and
    %   bold content.
    %
    % USAGE:
    %   html = markdown2html(markdown)
    %
    % INPUTS:
    %   markdown:   String, Markdown-formatted string to parse
    %
    % OUTPUTS:
    %   html:       String, HTML-formatted version of the input string

    % This Source Code Form is subject to the terms of the Mozilla Public
    % License, v. 2.0. If a copy of the MPL was not distributed with this
    % file, You can obtain one at http://mozilla.org/MPL/2.0/.
    %
    % Copyright (c) 2016 DENSEanalysis Contributors

    % Replace all bolded content
    html = regexprep(markdown, '\*{2}(.*?)\*{2}', '<b>$1</b>');

    % Now look for links with alt text
    % [text](link)
    pattern = '\[(.*?)\]\((.*?)\)';
    html = regexprep(html, pattern, '<a href="$2">$1</a>');

    % Now identify plain links
    pattern = '<(http.*?)>';
    html = regexprep(html, pattern, '<a href="$1">$1</a>');

    html = regexprep(html, '\n', '<br>');


    html = strcat('<html>', html, '</html>');
end
