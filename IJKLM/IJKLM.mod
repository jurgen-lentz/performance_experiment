set I;
set J;
set K;
set L;
set M;

set IJK within {I,J,K};
set JKL within {J,K,L};
set KLM within {K,L,M};

var x {(i,j,k) in IJK, (j,k,l) in JKL, (k,l,m) in KLM} >= 0;

subject to IJKLMconstr {i in I}:
   sum {(i,j,k) in IJK} sum {(j,k,l) in JKL} sum {(k,l,m) in KLM} x[i,j,k,l,m] >= 0;
