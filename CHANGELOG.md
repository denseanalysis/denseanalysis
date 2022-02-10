## [Unreleased]

- Fixes a warning about empty strings in `popupmenu` when loading `segmentmodel.fig`
- Fixes an error in newer versions of MATLAB when exporting images and videos
  caused by the 'HitTest' property not being available on `AnnotationPane`
  graphics objects

## v0.5.2

- Address incompatibility issues with MATLAB R2020b
- Fix a bug in the DENSEanalysis automatic updater
- Moves project master branch to main branch
- Compensate for the hardcopy function being removed from MATLAB

## v0.5.1

- Fixes a bug where LV Long axis contours were not properly converted to binary masks

## v0.5.0

- Support for versions of MATLAB >= R2012b. Support for 2009b - 2012a has
  been removed.
- Adds plugin framework for easy user customization of the interface and
  incorporation of custom post-processing
- Automatic checking for new versions of the DENSEanalysis software
- Improvements to the DENSEdata interface to allow easier interaction
  with underlying data
- Adds keyboard shortcuts to improve productivity: copy, paste, undo, etc.
- Bundles some unit tests with the application to ensure minimal functionality

## v0.4.0

- First open-source version of DENSEanalysis

