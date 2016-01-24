function x=lsequal(A,b,B,d)
%LSEQUAL Linear Least Squares with Equality Constraints.
% LSEQUAL(A,b,B,d) returns the linear least squares solution x to the
% linear system of equations A*x = b, with added linear equality
% constraints described by B*x = d. That is, LSEQUAL minimizes the sum of
% squared errors (b - A*X)'*(b - A*X), subject to B*x = d.
% A is M-by-N, b is M-by-1
% B is P-by-N, d is P-by-1
%
% B must have full rank, i.e., the constraints must be independent.
%
% See also SLASH, LSCOV, LSQNONNEG, QR.

% Reference:
% "Least Squares with Equality Constraints,"
% Geodezija Irkantografija 2002, Nr. 28. S. 3-6. 1392-1541.
% Author: Kai Borre
% Aalborg University
% Department of Communication Technology
% Denmark

% D.C. Hanselman, University of Maine, Orono, ME 04469
% masteringmatlab@yahoo.com
% Mastering MATLAB 7
% 2005-01-14, revised 2006-06-26

% NEW ADDITION - ignore
if nargin == 2 || (isempty(B)&&isempty(d))
    x = A\b;
    return
end


if nargin~=4
   error('Four Input Parameters Required: LSEQUAL(A,b,B,d).')
end
[rA,cA]=size(A);
[rb,cb]=size(b);
[rB,cB]=size(B);
[rd,cd]=size(d);

if (rA~=rb)
   error('Rows of A and b Must be Equal.')
elseif rB~=rd
   error('Rows of B and d Must be Equal.')
elseif cA~=cB
   error('Columns of A and B Must be Equal.')
% elseif (cb>1)||(cd>1)
%    error('Columns of y and d Must be One.')
elseif rB>=cA
   error('Too Many Constraints or Not Enough Unknowns.')
end

[QB,RB]=qr(B');
Ro=RB(1:rB,:);

% should be max(abs(diag(Ro)))
if sum(abs(diag(Ro))<abs(Ro(1)).*rB.*eps(class(Ro)))
   error('Constraints in B Must be Independent.')
end
AQB=A*QB;
A1=AQB(:,1:rB);
A2=AQB(:,rB+1:end);
y=Ro'\d;
z=A2\(b-A1*y);
x=QB*[y;z];
