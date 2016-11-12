x0 = [.5, .5]
xs = [0. 0.; 0. 1.; 1. 0.; 1. 1.; 0.500001 0.5]
zs = [-20., .6, .4, 1., 20.]
variogram(x1, x2) = Mads.sphericalvariogram(norm(x1 - x2), 3.14, 1., 0.001)
println(Mads.krige(x0, xs, zs, variogram))
variogram(x1, x2) = Mads.exponentialvariogram(norm(x1 - x2), 3.14, 1., 0.001)
println(Mads.krige(x0, xs, zs, variogram))
variogram(x1, x2) = Mads.gaussianvariogram(norm(x1 - x2), 3.14, 1., 0.001)
println(Mads.krige(x0, xs, zs, variogram))

x0 = [.5 .5; .49 .49; .01 .01; .99 1.; 0. 1.; 1. 0.]
xs = [0. 0.; 0. 1.; 1. 0.; 1. 1.; 0.500001 0.5]
zs = [-20., .6, .4, 1., 20.]
mycov = h->Kriging.sphericalcov(h, krigingparams[1], krigingparams[2])
variogram(x1, x2) = Mads.sphericalcov(norm(x1 - x2), 3.14, 1., 0.001)
println(Mads.krige(x0, xs, zs, variogram))
variogram(x1, x2) = Mads.expcov(norm(x1 - x2), 3.14, 1., 0.001)
println(Mads.krige(x0, xs, zs, variogram))
variogram(x1, x2) = Mads.gaussiancov(norm(x1 - x2), 3.14, 1., 0.001)
println(Mads.krige(x0, xs, zs, variogram))