using JuMP
using JSON
using DataFrames
using BenchmarkTools
using Gurobi

function read_tuple_list(filename)
    return [tuple(x...) for x in JSON.parsefile(filename)]
end

function read_fixed_data()
    N = open(JSON.parse, "supply_chain/data/data_N.json")
    return N
end

function read_variable_data(n)
    IK = read_tuple_list("supply_chain/data/data_IK_$n.json")
    IL = read_tuple_list("supply_chain/data/data_IL_$n.json")
    IM = read_tuple_list("supply_chain/data/data_IM_$n.json")
    IJK = read_tuple_list("supply_chain/data/data_IJK_$n.json")
    IKL = read_tuple_list("supply_chain/data/data_IKL_$n.json")
    ILM = read_tuple_list("supply_chain/data/data_ILM_$n.json")
    d = read_tuple_list("supply_chain/data/data_D_$n.json")
    D = Dict()
    for (i, m, value) in d
        D[(i, m)] = value
    end
    return IK, IL, IM, IJK, IKL, ILM, D
end

function convert_to_dict(IK, IL, IM, IJK, IKL, ILM)
    ik_ijk = Dict()
    ik_ikl = Dict()
    for (i, k) in IK
        ik_ijk_list = []
        ik_ikl_list = []
        for (ii, j, kk) in IJK
            if ii == i && kk == k
                push!(ik_ijk_list, (i, j, k))
            end
        end
        for (ii, kk, l) in IKL
            if ii == i && kk == k
                push!(ik_ikl_list, (i, k, l))
            end
        end
        ik_ijk[(i, k)] = ik_ijk_list
        ik_ikl[(i, k)] = ik_ikl_list
    end

    il_ikl = Dict()
    il_ilm = Dict()
    for (i, l) in IL
        il_ikl_list = []
        il_ilm_list = []
        for (ii, k, ll) in IKL
            if ii == i && ll == l
                push!(il_ikl_list, (i, k, l))
            end
        end
        for (ii, ll, m) in ILM
            if ii == i && ll == l
                push!(il_ilm_list, (i, l, m))
            end
        end
        il_ikl[(i, l)] = il_ikl_list
        il_ilm[(i, l)] = il_ilm_list
    end

    im_ilm = Dict()
    for (i,m) in IM
        im_ilm_list = []
        for (ii,l,mm) in ILM
            if ii==i && mm ==m
                push!(im_ilm_list, (i,l,m))
            end
        end
        im_ilm[(i,m)] = im_ilm_list
    end

    return ik_ijk, ik_ikl, il_ikl, il_ilm, im_ilm
end

function intuitive_jump(IK, IL, IM, IJK, IKL, ILM, D, solve)
    model = Model()

    @variable(model, x[IJK] >= 0)
    @variable(model, y[IKL] >= 0)
    @variable(model, z[ILM] >= 0)

    @constraint(model, production[(i, k) in IK], sum(
        x[(i, j, k)] for (ii, j, kk) in IJK if ii == i && kk == k
    ) >= sum(y[(i, k, l)] for (ii, kk, l) in IKL if ii == i && kk == k)
    )

    @constraint(model, transport[(i, l) in IL], sum(
        y[(i, k, l)] for (ii, k, ll) in IKL if ii == i && ll == l
    ) >= sum(z[(i, l, m)] for (ii, ll, m) in ILM if ii == i && ll == l))

    @constraint(model, demand[(i, m) in IM], sum(
        z[(i, l, m)] for (ii, l, mm) in ILM if ii == i && mm == m
    ) >= D[i, m])

    # write_to_file(model, "int.lp")

    if solve == "True"
        set_silent(model)
        set_optimizer(model, Gurobi.Optimizer)
        set_time_limit_sec(model, 0)
        optimize!(model)
    end
end

function jump(IK, IL, IM, IJK, IKL, ILM, IK_IJK, IK_IKL, IL_IKL, IL_ILM, IM_ILM, D, solve)
    model = if solve == "True"
        direct_model(Gurobi.Optimizer())
    else
        Model()
    end

    set_string_names_on_creation(model, false)

    @variable(model, x[IJK] >= 0)
    @variable(model, y[IKL] >= 0)
    @variable(model, z[ILM] >= 0)

    for (i, k) in IK
        @constraint(model,
            sum(
                x[ijk] for ijk in IK_IJK[(i, k)]
            ) >= sum(y[ikl] for ikl in IK_IKL[(i, k)]))
    end

    for (i, l) in IL
        @constraint(model, sum(
            y[ikl] for ikl in IL_IKL[(i, l)]
        ) >= sum(z[ilm] for ilm in IL_ILM[(i, l)]))
    end

    for (i, m) in IM
        @constraint(model, sum(
            z[ilm] for ilm in IM_ILM[(i,m)]
        ) >= D[i, m])
    end

    if solve == "True"
        set_silent(model)
        set_time_limit_sec(model, 60.0)
        optimize!(model)
    end
end

# solve = false
# samples = 2
# evals = 1
# time_limit = 5

solve = ARGS[1]
samples = parse(Int64, ARGS[2])
evals = parse(Int64, ARGS[3])
time_limit = parse(Int64, ARGS[4])

N = read_fixed_data()

t = DataFrame(I=Int[], Language=String[], MinTime=Float64[], MeanTime=Float64[], MedianTime=Float64[])
tt = DataFrame(I=Int[], Language=String[], MinTime=Float64[], MeanTime=Float64[], MedianTime=Float64[])

for n in N
    IK, IL, IM, IJK, IKL, ILM, D = read_variable_data(n)
    IK_IJK, IK_IKL, IL_IKL, IL_ILM, IM_ILM = convert_to_dict(IK, IL, IM, IJK, IKL, ILM)

    if maximum(t.MinTime; init=0) < time_limit
        r = @benchmark jump($IK, $IL, $IM, $IJK, $IKL, $ILM, $IK_IJK, $IK_IKL, $IL_IKL, $IL_ILM, $IM_ILM, $D, $solve) samples = samples evals = evals
        push!(t, (n, "JuMP", minimum(r.times) / 1e9, mean(r.times) / 1e9, median(r.times) / 1e9))
        println("JuMP done $n in $(round(minimum(r.times) / 1e9, digits=2))s")
    end

    if maximum(tt.MinTime; init=0) < time_limit
        rr = @benchmark intuitive_jump($IK, $IL, $IM, $IJK, $IKL, $ILM, $D, $solve) samples = samples evals = evals
        push!(tt, (n, "Intuitive JuMP", minimum(rr.times) / 1e9, mean(rr.times) / 1e9, median(rr.times) / 1e9))
        println("Intuitive JuMP done $n in $(round(minimum(rr.times) / 1e9, digits=2))s")
    end
end

if solve == "True"
    file = "supply_chain/results/jump_results_solve.json"
    file2 = "supply_chain/results/intuitive_jump_results_solve.json"
else
    file = "supply_chain/results/jump_results_model.json"
    file2 = "supply_chain/results/intuitive_jump_results_model.json"
end

open(file, "w") do f
    JSON.print(f, t, 4)
end

open(file2, "w") do f
    JSON.print(f, tt, 4)
end

println("JuMP done")
