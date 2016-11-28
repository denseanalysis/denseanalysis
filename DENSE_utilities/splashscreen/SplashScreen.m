classdef SplashScreen < hgsetget
    % SplashScreen - Class for creating a splash screen during app loading
    %
    %   Often it is handy to display a splash screen to the user while all
    %   the graphics components of an application load in the background.
    %   This class creates a Java-based splash screen which can display an
    %   image alongside some status text indicating the loading status.
    %
    % USAGE:
    %   S = SplashScreen(...)
    %
    % INPUTS:
    %   Parameter / value pairs to set any of the available property values
    %   during object construction
    %
    % OUTPUTS:
    %   S:  Handle, Handle to the SplashScreen object to be used to control
    %       and modify the display of the SplashScreen. The dialog can be
    %       removed using the delete method.

    % ATTRIBUTION
    %
    % Copyright (c) <2016> Jonathan Suever
    % All rights reserved
    %
    % This software is licensed under the BSD 3-clause license

    properties (Dependent)
        BackgroundColor         % Dialog background color
        BorderColor             % Color of the window border
        BorderWidth             % Width of the window border in pixels
        FontName                % Name of font to use for status text
        FontSize                % Size of font to use for status text
        FontWeight              % Weight of text to use for status text
        ForegroundColor         % Color of font to use for status text
        HorizontalAlignment     % Horizontal position of the icon
        Icon                    % Background Image to display
        Opacity                 % Opacity of the window where 1 is opaque
        Position                % Position of the window in pixels
        Status                  % Text to display in lower left corner
        Size                    % Size of the window
        VerticalAlignment       % Vertical position of the icon
        WindowStyle             % Whether to keep the window on top
    end

    properties (Hidden)
        valign          = 'center';
        halign          = 'center';
        status          = ''
        opacity         = 1;
        splashsize      = subsref(get(0,'defaultfigureposition'), ...
                                  substruct('()', {3:4}));
        bgcolor         = get(0, 'defaultfigurecolor');
        fgcolor         = get(0, 'defaultuicontrolforegroundcolor');
        style           = 'modal';
        icondata        = [];

        % Handles to java objects
        background  % Background image container (JLabel)
        icon        % Background image (ImageIcon)
        border      % Border around the window
        frame       % Main JFrame component
        label       % JLabel containing the status text
        layout      % Layout object for all components
        font        % Font object for the status text
    end

    methods
        function self = SplashScreen(varargin)
            % USAGE:
            %   S = SplashScreen(...)
            %
            % INPUTS:
            %   Parameter / value pairs to set any of the available
            %   property values during object construction
            %
            % OUTPUTS:
            %   S:  Handle, Handle to the SplashScreen object to be used to
            %       control and modify the display of the SplashScreen. The
            %       dialog can be removed using the delete method.

            % Initialize all of the java components first before
            % considering user inputs
            self.frame = javax.swing.JFrame();
            self.label = javax.swing.JLabel('');
            self.font = java.awt.Font('Arial', java.awt.Font.PLAIN, 11);
            self.border = javax.swing.BorderFactory.createLineBorder(java.awt.Color.WHITE, 1);

            self.frame.getContentPane.setBorder(self.border);

            self.layout = java.awt.BorderLayout;
            self.background = javax.swing.JLabel(javax.swing.ImageIcon);
            self.frame.add(self.background);

            layout2 = java.awt.BorderLayout();
            self.background.setLayout(layout2);
            self.background.add(self.label, layout2.SOUTH);

            paddingBorder = javax.swing.border.EmptyBorder(5,5,5,5);
            self.label.setBorder(paddingBorder);

            self.frame.setUndecorated(true);
            self.frame.setDefaultCloseOperation(self.frame.EXIT_ON_CLOSE);

            % Parse the inputs supplied by the user. Allows the user to
            % define any of the properties during construction as parameter
            % / value pairs.
            ip = inputParser();

            % Don't allow the user to specify the position since it's
            % always centered (for now)
            ignore = {'Position'};

            params = properties(self);
            params(ismember(params, ignore)) = [];

            for k = 1:numel(params)
                ip.addParamValue(params{k}, self.(params{k}));
            end

            ip.parse(varargin{:});

            % Center the splash screen in the middle of everything
            try
                set(self, ip.Results);
            catch ME
                % Be sure to delete the current object if there are issues
                % so we don't have lingering JFrames
                delete(self);
                rethrow(ME);
            end

            setappdata(0, 'splashscreen__', [SplashScreen.findall(), self])

            % Finally display the frame
            self.frame.setVisible(true);
        end

        function delete(self)
            self.frame.dispose();
        end

        function getdisp(self)
            disp(orderfields(get(self)));
        end
    end

    methods (Static)

        function splashes = findall()
            % findall - Method for finding all valid SplashScreen instances
            %
            % USAGE:
            %   objs = SplashScreen.findall()
            %
            % OUTPUTS:
            %   objs:   Splash Screen, Array of splash screen objects. If
            %           there are no splash screens, an empty array of
            %           SplashScreen objects is returned.

            splashes = getappdata(0, 'splashscreen__');

            if ~isempty(splashes)
                splashes = splashes(isvalid(splashes));
            else
                splashes = SplashScreen.empty();
            end
        end

        function demo()
            % demo - Small demo splash screen to demonstrate functionality
            %
            %   NOTE: The background graphic was created by Korawan.M from
            %   the Noun Project and was made available under the Creative
            %   Commons 4.0 license.
            %
            % USAGE:
            %   SplashScreen.demo()

            thisdir = fileparts(mfilename('fullpath'));

            % Create the demo splash screen
            obj = SplashScreen('BackgroundColor', [0 0 0], ...
                               'ForegroundColor', [1 1 1], ...
                               'Icon', fullfile(thisdir, 'splash.png'));

            % Update the status message dynamically
            set(obj, 'Status', 'Loading...')
            pause(1)

            set(obj, 'Status', 'Reticulating Splines...')
            pause(1)

            set(obj, 'Status', 'Complete')
            pause(0.5)

            % Fade the dialog out
            for k = 1:100
                obj.Opacity = (100 - k) / 100;
                drawnow
            end

            % Delete the SplashScreen object
            delete(obj)
        end
    end

    methods (Access = 'private')
        function changeBorder(self, width, color)
            % changeBorder - Updates the window border display
            %
            % USAGE:
            %   self.changeBorder(width, color)
            %
            % INPUTS:
            %   width:  Integer, Width of the border specified in pixels
            %
            %   color:  [3 x 1] Array, RGB Color to make the border

            color = num2cell(color);
            color = java.awt.Color(color{:});
            inputs = {color, width};
            matte = javax.swing.BorderFactory.createLineBorder(inputs{:});
            self.frame.getContentPane.setBorder(matte);
        end
    end

    %--- Get / Set Methods ---%
    methods
        function res = get.BackgroundColor(self)
            res = self.bgcolor;
        end

        function res = get.BorderColor(self)
            color = self.border.getLineColor();
            res = [color.getRed, color.getGreen, color.getBlue];
            res = double(res) ./ 255;
        end

        function res = get.BorderWidth(self)
            res = self.border.getThickness;
        end

        function res = get.FontName(self)
            res = char(self.font.getName());
        end

        function res = get.FontSize(self)
            res = self.font.getSize();
        end

        function res = get.FontWeight(self)
            switch self.font.getStyle
                case self.font.BOLD
                    res = 'bold';
                case self.font.PLAIN
                    res = 'normal';
            end
        end

        function res = get.ForegroundColor(self)
            res = self.fgcolor;
        end

        function res = get.HorizontalAlignment(self)
            res = self.halign;
        end

        function res = get.Icon(self)
            res = self.icondata;
        end

        function res = get.Opacity(self)
            res = self.opacity;
        end

        function res = get.Position(self)

            screen = get(0, 'ScreenSize');

            res = [self.frame.getLocation.x, ...
                   screen(4) - self.splashsize(2) - self.frame.getLocation.y, ...
                   self.splashsize(:)'];
        end

        function res = get.Size(self)
            res = self.splashsize;
        end

        function res = get.Status(self)
            res = self.status;
        end

        function res = get.VerticalAlignment(self)
            res = self.valign;
        end

        function res = get.WindowStyle(self)
            res = self.style;
        end

        function set.BackgroundColor(self, val)
            v = num2cell(val);
            self.frame.getContentPane.setBackground(java.awt.Color(v{:}));
            self.bgcolor = val;
        end

        function set.BorderColor(self, val)
            self.changeBorder(self.BorderWidth, val);
        end

        function set.BorderWidth(self, val)
            self.changeBorder(val, self.BorderColor);
        end

        function set.font(self, val)
            self.label.setFont(val);    %#ok
            self.font = val;
        end

        function set.FontName(self, val)
            newfont = java.awt.Font(val, self.font.getStyle, self.FontSize);
            self.font = newfont;
        end

        function set.FontSize(self, val)
            self.font = self.font.deriveFont(val);
        end

        function set.FontWeight(self, val)
            val = lower(val);

            switch val
                case 'bold'
                    newval = self.font.BOLD;
                case 'normal'
                    newval = self.font.PLAIN;
                otherwise
                    error(sprintf('%s:InvalidType', mfilename), ...
                        'Font Weight can only be ''bold'' or ''normal''');
            end

            self.font = self.font.deriveFont(uint8(newval));
        end

        function set.ForegroundColor(self, val)
            tmp = num2cell(val);
            javacol = java.awt.Color(tmp{:});
            self.label.setForeground(javacol);
            self.fgcolor = val;
        end

        function set.HorizontalAlignment(self, val)
            switch lower(val)
                case 'left'
                    val = self.background.LEFT;
                case 'right'
                    val = self.background.RIGHT;
                case 'center'
                    val = self.background.CENTER;
                otherwise
                    error(sprintf('%s:InvalidAlignment', mfilename), ...
                        'Alignment must be ''left'', ''right'', or ''center''');
            end

            self.background.setHorizontalAlignment(val);
            self.halign = lower(val);
        end

        function set.Icon(self, val)
            if isnumeric(val) && ~isempty(val)
                if size(val, 3) == 1
                    val = repmat(val, [1 1 3]);
                end

                tfile = tempname;
                imwrite(val, tfile, 'PNG');

                fid = fopen(tfile, 'rb');
                val = fread(fid);
            end

            self.icondata = val;

            if ~isempty(val)
                icn = javax.swing.ImageIcon(val);
            else
                icn = javax.swing.ImageIcon;
            end
            self.background.setIcon(icn);
        end

        function set.Opacity(self, val)
            com.sun.awt.AWTUtilities.setWindowOpacity(self.frame, val);
            self.opacity = val;
        end

        function set.Size(self, val)
            if ~isnumeric(val) || numel(val) ~= 2
                error(sprintf('%s:InvalidSize', mfilename), ...
                    'Size must be an [1 x 2] Array');
            end

            self.splashsize = val;
            self.frame.setSize(val(1), val(2));
            self.frame.setLocationRelativeTo([]);
        end

        function set.Status(self, val)
            self.label.setText(val)
            self.status = val;
        end

        function set.VerticalAlignment(self, val)
            switch lower(val)
                case 'top'
                    val = self.background.TOP;
                case 'bottom'
                    val = self.background.BOTTOM;
                case 'center'
                    val = self.background.CENTER;
                otherwise
                    error(sprintf('%s:InvalidAlignment', mfilename), ...
                        'Alignment must be ''top'', ''bottom'', or ''center''');
            end

            self.background.setVerticalAlignment(val);
            self.valign = lower(val);
        end

        function set.WindowStyle(self, val)
            switch lower(val)
                case 'normal'
                    self.frame.setAlwaysOnTop(false);
                case 'modal'
                    self.frame.setAlwaysOnTop(true);
                otherwise
                    error(sprintf('%s:InvalidStyle', mfilename), ...
                        'WindowStyle must be either ''normal'' or ''modal''');
            end

            self.style = lower(val);
        end
    end
end
