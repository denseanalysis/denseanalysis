# MarkdownPanel
Control which displays markdown as HTML within a MATLAB control
 
------
This control utilizes the [Showdown javascript library][1] to convert
markdown into HTML and then uses MATLAB's own `HTMLBrowserPanel` to
display this HTML.
 
It behaves like any other graphics object within MATLAB in that all
properties can either be set upon object construction
 
    h = MarkdownPanel('Parent', figure, 'Content', '# Hello World!');
 
Or after object creation using the returned handle
 
    h = MarkdownPanel();
    h.Parent = gcf;
    set(h, 'Position', [0, 0, 0.5, 0.5])
 
To set the actual Markdown content, use the 'Content' property. You
can provide *either* a string, or a cell array of strings which will
automatically create a multi-line entry
 
    set(h, 'Content', '#Hello World')
    set(h, 'Content', {'#Hello World', 'This is a test...'})
 
------
**Usage**
 
    panel = MarkdownPanel();
 
**Outputs**
 
  `panel`,    Graphics Object, The graphics handle that can be used
              to manipulate the appearance of the control
 
------
**Demo**
 
A demo application has been bundled with this code to show how to use
some of the features. To run this demo, simply type the following
into the MATLAB console.
 
    MarkdownPanel.demo()

![Markdown Demo Application][4]
 
------
**Attribution**
 
Copyright (c) <2016> [Jonathan Suever][2].  
All rights reserved
 
This software is licensed under the [BSD license][3]
 
[1]: https://github.com/showdownjs/showdown
[2]: https://github.com/suever
[3]: https://github.com/suever/MarkdownPanel/blob/master/LICENSE
[4]: https://cdn.rawgit.com/suever/MarkdownPanel/master/MarkdownPanel.png

