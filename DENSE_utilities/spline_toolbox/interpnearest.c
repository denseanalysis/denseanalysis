/**************************************************************************
INTERPNEAREST


 This Source Code Form is subject to the terms of the Mozilla Public
 License, v. 2.0. If a copy of the MPL was not distributed with this
 file, You can obtain one at http://mozilla.org/MPL/2.0/.

 Copyright (c) 2016 DENSEanalysis Contributors


**************************************************************************/
#include <stdlib.h>
#include <math.h>
#include "mex.h"

void mexFunction(int nlhs,       mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
    /* inputs & outputs */
    double *P,*C,*Cval,c;
    double *Pval;
    double *Pidx;
    
    /* output idx flag */
    bool flagidx;
    
    /* sizes */
    mwSize Np,Nc,Nd,Nv;
     
    /* counters */
    mwIndex ic,ip,k;
        
    /* distance calculations */
    double csq,d,dsq,mindsq;
    mwIndex idx;
    bool tf;
    
    /* not-a-number */
    double nan;
      
    nan = mxGetNaN();
    
    
    /* Check for proper number of input and output arguments */    
    if (nrhs != 4) {
         mexErrMsgIdAndTxt("interpnearest:invalidInput",
            "4 input arguments required.");
    } 
    if (nlhs!=1 && nlhs!=2) {
        mexErrMsgIdAndTxt("interpnearest:invalidInput",
            "1-2 output arguments required.");
    }
    flagidx = (nlhs==2);
    
    
    /* "points" input */
    if (!mxIsDouble(prhs[0]) || mxGetNumberOfDimensions(prhs[0]) != 2) {
        mexErrMsgIdAndTxt("interpnearest:invalidInput",
            "'points' must be an [NxD] matrix of doubles.");
    }	
    P = (double*) mxGetPr(prhs[0]);
    Np = mxGetM(prhs[0]);
    Nd = mxGetN(prhs[0]);
 
    
    /* "centers" input */
    if (!mxIsDouble(prhs[1]) || mxGetNumberOfDimensions(prhs[1]) != 2 || 
        mxGetN(prhs[1]) != Nd) {
        mexErrMsgIdAndTxt("interpnearest:invalidInput",
            "'centers' must be an [MxD] matrix of doubles.");
    }	
    C = (double*) mxGetPr(prhs[1]);
    Nc = mxGetM(prhs[1]);
    
    
    /* "values" input */
    if (!mxIsDouble(prhs[2]) || mxGetNumberOfDimensions(prhs[2]) != 2 || 
        mxGetM(prhs[2]) != Nc) {
        mexErrMsgIdAndTxt("interpnearest:invalidInput",
            "'values' must be an [MxV] matrix of doubles.");
    }	
    Cval = (double*) mxGetPr(prhs[2]);
    Nv = mxGetN(prhs[2]);

    
    /* "c" input */    
    if (!mxIsDouble(prhs[3]) || mxGetNumberOfElements(prhs[3]) != 1) {
        mexErrMsgIdAndTxt("interpnearest:invalidInput",
            "Support radius must be a nonzero scalar double.");
    }	
    c = (double) mxGetScalar(prhs[3]);
    csq = c*c;    
    
    if (c<=0) {
        mexErrMsgIdAndTxt("interpnearest:invalidInput",
            "Support radius must be a nonzero scalar double."); 
    }
            
    
    /* allocate output matrices */
    plhs[0] = mxCreateDoubleMatrix(Np,Nv,mxREAL);
    Pval = (double*) mxGetPr(plhs[0]);
    
    if (flagidx) {
        plhs[1] = mxCreateDoubleMatrix(Np,1,mxREAL);
        Pidx = (double*) mxGetPr(plhs[1]);
    }

    /*
    for (ip=0; ip<Np; ip++) {
        for (k=0; k<Nv; k++) {
            Pval[ip+Np*k] = nan;
        }
    }

    Pval[1] = 10;
    */
 
    /* iterate through each point */
    for (ip=0; ip<Np; ip++) {
        mindsq = csq;
        tf = false;
        
        /* locate center closest to point */
        for (ic=0; ic<Nc; ic++) {
            
            /* distance calculation */
            dsq = 0;
            for (k=0; k<Nd; k++) {
                d = P[ip+Np*k] - C[ic+Nc*k];
                dsq += d*d; 
            }

            /* save value if smaller than current minimum*/
            if (dsq < mindsq) { 
                mindsq = dsq;
                idx = ic;
                tf  = true;
                if (dsq==0) {break;}
            }     
        }       

        /* save Cval at index "idx" to Pval */
        if (tf) {            
            if (flagidx) {
                Pidx[ip] = (double) idx+1;
            }
            for (k=0; k<Nv; k++) {
                Pval[ip+Np*k] = Cval[idx+Nc*k]; 
            }
        } else {            
            if (flagidx) {
                Pidx[ip] = 0;            
            }
            for (k=0; k<Nv; k++) {
                Pval[ip+Np*k] = nan;
            }
        }

    }
    
    return;
    
} /* end mexFunction() */


/**************************************************************************
  END OF FILE
**************************************************************************/
