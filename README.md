## DENSEanalysis: Cine DENSE Processing Software ##

This software was developed in MATLAB to provide a user-friendly way of
processing **d**isplacement **en**coding with **s**timulated **e**choes (DENSE)
image data. Currently, the software supports analysis of 2D cine DENSE images;
however, a beta version will be released in the coming months that supports
full biventricular 3D analysis.

### Getting Started

#### System Requirements

The current stable version (0.4.0) of *DENSEanalysis* requires:

* MATLAB (R2009b through R2014a)
* MATLAB Image Processing Toolbox
* MATLAB Curve Fitting Toolbox (Spline Toolbox in later versions)
* MATLAB C-Compiler

#### Configuration of Mex Compiler

If you have never compiled a MATLAB mex file on your current machine, you will
want to configure the MATLAB environment to be able to perform the compilation.
To do this you'll want to run

    mex -setup

This will lead you through a series of steps where MATLAB will detect all
compilers installed on your machine and ask you to select the appropriate
installer.

#### Removal of Previous Installations

If you have previously installed *DENSEanalysis*, make sure to remove any
existing entries in your path that point to that installation of
*DENSEanalysis* and restart MATLAB

To do this you can either type the following command into MATLAB

    pathtool

Or if you wish, you can select **Set Path** from the **File** menu.

Either of these will bring up the path dialog in which you can select the
folders to remove.

#### Download Software

The latest stable release of *DENSEanalysis* can be downloaded
[here](https://github.com/denseanalysis/denseanalysis/releases/latest) either
as a .zip or .tar.gz archive.

> If you wish to use a bleeding-edge version of DENSEanalysis or you
wish to contribute to DENSEanalysis, you can go to the DENSEanalysis [Github
page](https://github.com/denseanalysis/denseanalysis) and download the source
as needed.

Once downloaded, you'll want to extract the contents of the archive to a
directory of your choice on your machine.

Launch MATLAB and change folders to where you extracted the *DENSEanalysis*
software and run the `DENSEsetup` script to finish the installation of the
software.

    cd('path/to/DENSEanalysis')
    DENSEsetup

#### Running *DENSEanalysis* Programs

*DENSEanalysis* is launched by simply typing the following command within the
MATLAB command window

    DENSEanalysis

Similarly, *DENSEms* (Multi-Slice DENSE analysis) can be launched by using the
following command

    DENSEms

#### Additional Documentation

Additional information, including screenshots and examples, can be found at the
following locations


* [DENSEanalysis manual]({{ site.baseurl }}docs/DENSEanalysis_manual.pdf)
* [DENSEms manual]({{ site.baseurl }}docs/DENSEms_manual.pdf)
* [RV features manual]({{ site.baseurl }}/docs/RV_manual.pdf)


### Attribution

If you have used the *DENSEanalysis* software for your research or it has
influenced your work, we ask that you include the following relevant citations
in your work.

>Spottiswoode, B. S., Zhong, X., Hess, a T., Kramer, C. M., Meintjes, E. M., Mayosi, B. M., & Epstein, F. H. (2007). Tracking myocardial motion from cine DENSE images using spatiotemporal phase unwrapping and temporal fitting. IEEE Transactions on Medical Imaging, 26(1), 15–30. http://doi.org/10.1109/TMI.2006.884215

>Gilliam, A.D., Suever, J.D., and contributors (2016). DENSEanalysis. Retrieved from https://github.com/denseanalysis/denseanalysis

### Contributing

We welcome contributions from any members of the DENSE user community. Feel
free to [submit a pull
request](https://github.com/denseanalysis/denseanalysis/compare?expand=1) with
your contributions. Please see the [CONTRIBUTING
file](https://github.com/denseanalysis/denseanalysis/blob/master/CONTRIBUTING.md)
for guidelines for contributing to *DENSEanalysis*.

Our contributors include:

* [Andrew Gilliam](http://www.adgilliam.com/) (Original Creator)
* [Jonathan Suever](https://github.com/suever) (Maintainer)
