import timeit
import pandas as pd
import numpy as np
from amplpy import AMPL
import itertools
import operator


########## AMPL ##########
def run_ampl(I, J, K, L, M, IJK, JKL, KLM, solve, repeats, number):

    setup = {
        "I": I,
        "J": J,
        "K": K,
        "L": L,
        "M": M,
        "IJK": IJK,
        "JKL": JKL,
        "KLM": KLM,
        "solve": solve,
        "model_function": ampl,
    }
    r = timeit.repeat(
        "model_function(I, J, K, L, M, IJK, JKL, KLM, solve)",
        repeat=repeats,
        number=number,
        globals=setup,
    )

    result = pd.DataFrame(
        {
            "I": [len(I)],
            "Language": ["AMPL"],
            "MinTime": [np.min(r)],
            "MeanTime": [np.mean(r)],
            "MedianTime": [np.median(r)],
        }
    )
    return result


def ampl(I, J, K, L, M, IJK, JKL, KLM, solve):
    ampl = AMPL()
    ampl.read("IJKLM/IJKLM.mod")

    ampl.set["I"] = I
    ampl.set["J"] = J
    ampl.set["K"] = K
    ampl.set["L"] = L
    ampl.set["M"] = M
    ampl.set["IJK"] = IJK
    ampl.set["JKL"] = JKL
    ampl.set["KLM"] = KLM

    if solve:
        ampl.option["solver"] = "gurobi"
        ampl.option["solver_msg"] = 0
        ampl.option["gurobi_options"] = "outlev=0 timelimit=0"
        ampl.solve()
