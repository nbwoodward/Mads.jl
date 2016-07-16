import Mads
import Gadfly
md = Mads.loadmadsfile("models/internal-polynomial.mads")

if !isdir("bayes_results")
	mkdir("bayes_results")
end

info("Bayesian analysis with different initial parameter sets and observation weights (standard deviation errors)")
info("Bayesian analysis for the initial parameter guesses:")
for w = (1000000, 1000, 1)
	Mads.setobsweights!(md, w)
	mcmcchain = Mads.bayessampling(md; nsteps=10000, burnin=1000, thinning=1, seed=2016)
	Mads.scatterplotsamples(md, mcmcchain.value', "bayes_results/bayes_init_w$w.png")
	o = Mads.forward(md, mcmcchain.value)
	n = length(o)
	o = hcat(map(i->collect(values(o[i])), 1:n)...)'
	Mads.spaghettiplot(md, o, filename="bayes_results/bayes_init_w$(w)_spaghetti.png")
	@printf "Init: Observation Weight %d StdDev %f ->`o5` prediction: min = %f max = %f\n" w 1/w min(o[:,5]...) max(o[:,5]...)
	f = Gadfly.plot(x=o[:,5], Gadfly.Guide.xlabel("o5"), Gadfly.Geom.histogram())
	Gadfly.draw(Gadfly.PNG("bayes_results/bayes_init_w$(w)_o5.png", 6Gadfly.inch, 4Gadfly.inch), f)
end
pinit = Dict(zip(Mads.getparamkeys(md), Mads.getparamsinit(md)))

n = 100
info("Calibration using $n random initial guesses for model parameters")
r = Mads.calibraterandom(md, n, all=true, seed=2016, save_results=false)
pnames = collect(keys(r[1,3]))
p = hcat(map(i->collect(values(r[i,3])), 1:n)...)'
np = length(pnames)
info("Identify the 3 different global optima with different model parameter estimates")

ind_n0 = abs(p[:,4]) .< 0.1
in0 = find(ind_n0 .== true)[1]
ind_n1 = abs(p[:,4]-1) .< 0.1
in1 = find(ind_n1 .== true)[1]
ind_n01 = !(ind_n0 | ind_n1)
in01 = find(ind_n01 .== true)[1]
pinit = Dict(zip(Mads.getparamkeys(md), Mads.getparamsinit(md)))
p = ["n0", "n1", "n01"]
v = [in0, in1, in01]

info("Bayesian analysis for the 3 different global optima")
for i = 1:3
	Mads.setparamsinit!(md, r[v[i],3])
	for w = (1000000, 1000, 1)
		Mads.setobsweights!(md, w)
		mcmcchain = Mads.bayessampling(md; nsteps=10000, burnin=1000, thinning=1, seed=2016)
		Mads.scatterplotsamples(md, mcmcchain.value', "bayes_results/bayes_opt_$(p[i])_w$w.png")
		o = Mads.forward(md, mcmcchain.value)
		n = length(o)
		o = hcat(map(i->collect(values(o[i])), 1:n)...)'
		Mads.spaghettiplot(md, o, filename="bayes_results/bayes_opt_$(p[i])_w$(w)_spaghetti.png")
		@printf "O%-3s: Observation Weight %d StdDev %f -> `o5` prediction: min = %f max = %f\n" p[i] w 1/w min(o[:,5]...) max(o[:,5]...)
		f = Gadfly.plot(x=o[:,5], Gadfly.Guide.xlabel("o5"), Gadfly.Geom.histogram())
		Gadfly.draw(Gadfly.PNG("bayes_results/bayes_opt_$(p[i])_w$(w)_o5.png", 6Gadfly.inch, 4Gadfly.inch), f)
	end
end
Mads.setparamsinit!(md, pinit)