/**************************************************************************
QUICKFIND search logical matrix in specified order for first "true" value
    unwrapping helper function
 
MATLAB PROTOTYPE
    ind = quickfind(logical(tf),uint32(idx))

INPUTS
    tf..........logical matrix to search
    idx.........search index order (in MATLAB base-1)
 
OUTPUT
    ind.........first "true" index found (in MATLAB base-1)
 
USAGE 
    ind = quickfind(logical(tf),uint32(idx))
    search the logical TF in the index order specified by IDX 
    (in MATLAB base-1) for the first "true" value. We return the result 
    as a double in IND. Note the benefits of this function are really 
    evident at large sizes of TF.
 
 NOTES
    If TF contains all "false" values, IND returns -1.
 
 WRITTEN BY:  Drew Gilliam
 
 MODIFICATION HISTORY:
    2008.03   Drew Gilliam
        --creation
    2008.10   Drew Gilliam
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
    bool        *tf;          /* input matrix */
    uint32_T    *idx;         /* ordered indices (base-1) */
    mwSize      Ntf,Nidx;     /* number of elements */
    double      *idxout;      /* returned location */
    mwIndex     k;            /* counter */
  
    
    /* load input variables */
    if (mxIsLogical(prhs[0])) {
        tf = (bool*) mxGetData(prhs[0]);
    } else {
        mexErrMsgIdAndTxt("quickfind:inputerror",
            "First input must be logical array.");
    }
    
    if (mxGetClassID(prhs[1]) == mxUINT32_CLASS) {
        idx = (uint32_T*) mxGetData(prhs[1]);  
    } else {
        mexErrMsgIdAndTxt("quickfind:inputerror",
            "Second input must be uint32 array.");
    }  
   
    /* length of input variables */
    Ntf  = mxGetNumberOfElements(prhs[0]);
    Nidx = mxGetNumberOfElements(prhs[1]);
    
    /* allocate outputs */
    plhs[0] = mxCreateDoubleScalar(-1);
    idxout  = (double*) mxGetData(plhs[0]);
    
    /* search for first valid tf value */
    for (k=0; k<Nidx; k++) {

        /* check for valid index */
        if ((idx[k] < 1) || (Ntf < idx[k])) {
            mexErrMsgIdAndTxt("quickfind:indexerror",
                "IDX indices must be within the matrix TF.");
        }
        
        /* check tf at this index (convert base-1 to base-0) */
        if (tf[idx[k]-1]) {
            *idxout = idx[k];
            break;
        }
    }    
    
    return;
    
} /* end mexFunction() */
