/**************************************************************************
KMATRIX2 thin hyper-plate spline helper function for calculating 
    (Euclidean distance)^2 between points
    Note there is NO ERROR CHECKING for speed.  Improper inputs may cause 
    segmenation faults and other unknown behaviors.
 
MATLAB PROTOTYPE
    K = kmatrix2(double(A),double(B),double(effdist),logical(SPARSE));

INPUTS
    A..........1st set of 3D points (Na x 2)
    B..........2nd set of 3D points (Nb x 2)
    effdist....effective distance (see USAGE)
    SPARSE.....sparse flag (for large data matricies)
 
OUTPUT
    K..........(euclidean distance).^2 at every A/B combo (Na x Nb)
 
USAGE
    K = kmatrix2(double(A),double(B),double(effdist),logical(SPARSE))
    calculates the (euclidean distances).^2 between the 3D point matrices 
    A and B, at every combination of A and B.  A is considered the rows 
    of the output matrix K, while B is the columns.  Points whose distance 
    is less than the EFFDIST parameter will return 0 in the K-matrix. For 
    large sets of points, one may input a positive SPARSE flag which will 
    allocate and fill the K matrix as sparse. Note the SPARSE flag is only 
    useful when used in conjuction with the EFFDIST parameter.

 WRITTEN BY:  Drew Gilliam
 
 MODIFICATION HISTORY:
    2009.04   Drew Gilliam
        --creation


 This Source Code Form is subject to the terms of the Mozilla Public
 License, v. 2.0. If a copy of the MPL was not distributed with this
 file, You can obtain one at http://mozilla.org/MPL/2.0/.

 Copyright (c) 2016 DENSEanalysis Contributors



**************************************************************************/
#include <stdlib.h>
#include <math.h>
#include "mex.h"

#define PERCENT_SPARSE_START 0.20
#define PERCENT_SPARSE_ADD   0.10


void mexFunction(int nlhs,       mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
    /* inputs & outputs */
    double *A,*B;              /* input matrices (Nx2) */
    double *K;                 /* output matrix */
    
    /* size variables */
    unsigned int Na,Nb;        
     
    /* counters & pointers */
    double *xa,*ya;
    double *xb,*yb;
    unsigned int *irs, *jcs;
    unsigned int i,j,k;
        
    /* distance calculations */
    double dx,dy,dsq;
    
    /* load input variables */
    A = (double*) mxGetPr(prhs[0]);    
    B = (double*) mxGetPr(prhs[1]);  
       
    /* input A length and pointers */
    Na = mxGetM(prhs[0]);
    xa = &A[0];
    ya = &A[Na];
    
    /* input B length and pointers */
    Nb = mxGetM(prhs[1]);
    xb = &B[0];
    yb = &B[Nb];

    /* allocate output matrix */
    plhs[0] = mxCreateNumericMatrix(Na,Nb,mxDOUBLE_CLASS,mxREAL);
    K = (double*)mxGetPr(plhs[0]);

    /* iterate through distance combinations */
    for (j=0; j<Nb; j++) {
        for (i=0; i<Na; i++) {           
            dx = xa[i] - xb[j];
            dy = ya[i] - yb[j];
            dsq = dx*dx + dy*dy;
            if (dsq>0.0) {
                K[i + Na*j] = dsq * log(dsq);
            }
        }
    }
    
    return;
    
} /* end mexFunction() */



/**************************************************************************
  END OF FILE
**************************************************************************/
