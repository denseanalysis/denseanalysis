/**************************************************************************
QUICKMAX quickly find the value/index of maximum value in a given image
    within the specified mask.  unwrap helper function

MATLAB PROTOTYPE
    [val,ind] = quickmax(double(matrix),logical(mask))

INPUTS
    matrix......matrix to search
    mask........mask of valid search space
 
OUTPUT
    val.........1st maximum value
    ind.........1st maximum index (in MATLAB base-1)
 
USAGE 
    [val,ind] = quickmax(double(matrix),logical(mask))
    search MATRIX at all "true" locations in MASK for the maximum value.
    The max-value is returned as a double in VAL, and the max-index 
    (in MATLAB base-1) is returned as a double in IND. Note the benefits 
    of this function are really  evident at large sizes of MATRIX.

 NOTES
    If no maximum is found (i.e. MASK contains no "true" values, or 
    MATRIX consists entirely of -Inf values), IND returns -1.
 
 WRITTEN BY:  Drew Gilliam
 
 MODIFICATION HISTORY:
    2008.03   Drew Gilliam
        --creation
    2008.10   Drew Gilliam
        --accept double input (rather than single)
        --additional notes
    2009.01   Drew Gilliam
        --unix compatability issues


 This Source Code Form is subject to the terms of the Mozilla Public
 License, v. 2.0. If a copy of the MPL was not distributed with this
 file, You can obtain one at http://mozilla.org/MPL/2.0/.

 Copyright (c) 2016 DENSEanalysis Contributors

 
**************************************************************************/
#include "mex.h"

void mexFunction(int nlhs,       mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
    /* variables */
    double      *matrix;    /* input matrix */
    bool        *mask;      /* input mask */
    mwSize      Ne,Ntf;     /* number of elements */
    mwIndex     k;          /* counter */
    double      *val;       /* maximum value */
    double      *ind;       /* maximum location */
  
    /* load input variables */
    if (mxIsDouble(prhs[0])) {
        matrix = (double*) mxGetData(prhs[0]);
    } else {
        mexErrMsgIdAndTxt("quickmax:inputerror",
            "First input must be double array");
    }
    
    if (mxIsLogical(prhs[1])) {
        mask = (bool*) mxGetData(prhs[1]);
    } else {
        mexErrMsgIdAndTxt("quickmax:inputerror",
            "Second input must be logical array");
    }    
    
    /* length of input variables */
    Ne  = mxGetNumberOfElements(prhs[0]);
    Ntf = mxGetNumberOfElements(prhs[1]);
    
    if (Ne != Ntf) {
        mexErrMsgIdAndTxt("quickmax:inputerror",
            "MATRIX and MASK must be of the same size.");
    }    
    
    /* allocate outputs */
    plhs[0] = mxCreateDoubleScalar(-mxGetInf());
    val = (double*) mxGetData(plhs[0]);
    
    plhs[1] = mxCreateDoubleScalar(-1);
    ind = (double*) mxGetData(plhs[1]);
    
    /* search for valid maximum */
    for (k=0; k<Ne; k++) {        
        if (mask[k] && matrix[k] > *val) {
            *val = (double)matrix[k];
            *ind = (double)k;
        }
    }    
    
    /* convert to MATLAB base-1 on success */
    if (*ind != -1) {
        *ind = *ind + 1;
    }
    
    return;
    
} /* end mexFunction() */
