#input args :: outputDir rep correlationType noiseType

using HDF5, JLD
using QR, HD
using Mosek
using Distributions

# input arguments
dataDir = ARGS[1]
outDir = ARGS[2]
rep = int(ARGS[3])
corType = int(ARGS[4])
noiseType = int(ARGS[5])

# random seed
srand(rep)

data = load("$(dataDir)/data/data_rep_$(rep)_cor_$(corType)_noise_$(noiseType).jld")
X = data["X"]
Y = data["Y"]
s = data["s"]
beta = data["beta"]

indNZ = find(beta)

n, p = size(X)

solver = MosekSolver(LOG=0,
                     OPTIMIZER=MSK_OPTIMIZER_FREE_SIMPLEX,
                     PRESOLVE_USE=MSK_PRESOLVE_MODE_OFF)
qr_problem = QRProblem(solver, X[:, indNZ], Y)

# solves penalized quantile regression
lambdaArr = [0.0]
tauArr = [0.1:0.02:0.9]
qr_tau_path = cell(length(tauArr))
indTau = 0
for tau=tauArr
  indTau = indTau + 1
  println("tau = $(tau) --> $(indTau)/$(length(tauArr))")
  qr_tau_path[indTau] = compute_qr_path!(qr_problem, lambdaArr, tau; max_hat_s=50)
end

save("$(outDir)/path_rep_$(rep)_cor_$(corType)_noise_$(noiseType)_refit.jld",
     "qr_tau_path", qr_tau_path
     )

