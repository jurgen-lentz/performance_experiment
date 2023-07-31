set I;
set J;
set K;
set L;
set M;

set IK within {I,K};
set IL within {I,L};
set IM within {I,M};
set IJK within {I,J,K};
set IKL within {I,K,L};
set ILM within {I,L,M};

param d {IM} >= 0;

var x {IJK} >= 0;
var y {IKL} >= 0;
var z {ILM} >= 0;

subject to Produce {(i,k) in IK}:
   sum {(i,j,k) in IJK} x[i,j,k] >= sum {(i,k,l) in IKL} y[i,k,l];

subject to Distribute {(i,l) in IL}:
   sum {(i,k,l) in IKL} y[i,k,l] >= sum {(i,l,m) in ILM} z[i,l,m];

subject to Deliver {(i,m) in IM}:
   sum {(i,l,m) in ILM} z[i,l,m] >= d[i,m];