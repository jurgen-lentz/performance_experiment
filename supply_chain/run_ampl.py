import timeit
import pandas as pd
import numpy as np
from amplpy import AMPL


########## AMPL ##########
def run_ampl(I, J, K, L, M, IK, IL, IM, IJK, IKL, ILM, D, solve, repeats, number):
    setup = {
        "I": I,
        "J": J,
        "K": K,
        "L": L,
        "M": M,
        "IK": IK,
        "IL": IL,
        "IM": IM,
        "IJK": IJK,
        "IKL": IKL,
        "ILM": ILM,
        "D": D,
        "solve": solve,
        "model_function": ampl,
    }
    r = timeit.repeat(
        "model_function(I, J, K, L, M, IK, IL, IM, IJK, IKL, ILM, D, solve)",
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


def ampl(I, J, K, L, M, IK, IL, IM, IJK, IKL, ILM, d, solve):
    ampl = AMPL()
    ampl.read("supply_chain/supply_chain.mod")

    ampl.set["I"] = I
    ampl.set["J"] = J
    ampl.set["K"] = K
    ampl.set["L"] = L
    ampl.set["M"] = M
    ampl.set["IK"] = IK
    ampl.set["IL"] = IL
    ampl.set["IM"] = IM
    ampl.set["IJK"] = IJK
    ampl.set["IKL"] = IKL
    ampl.set["ILM"] = ILM

    ampl.param["d"] = d#{
        #key: value
        #for key, value in d.items():
    #}

    if solve:
        ampl.option["solver"] = "gurobi"
        ampl.option["solver_msg"] = 0
        ampl.option["gurobi_options"] = "outlev=0 timelimit=0"
        ampl.solve()
