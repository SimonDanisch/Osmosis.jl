using ColorTypes
using GeometryTypes, Reactive, GLAbstraction, ModernGL
import Quaternions
using FileIO
using GLVisualize, GLWindow, ModernGL, Colors

w, r = glscreen();


area_msg, area3d = x_partition(w.area, 30.0);
screen3D         = Screen(w, area=area3d);
screenMSG        = Screen(w, area=area_msg);

cs = cubecamera(screen3D);

using Benchmarks
function GLVisualize.visualize(b::Vector{Benchmarks.Statistics{Float64}})
    t = Float64[elem.average_time for elem in b]
    m = maximum(t)
    l = length(t)

    scale_up 	= Vec3f0[Vec3f0(0.02,0.02, (elem.interval[2]-elem.average_time) / m ) for elem in b]
    scale_down  = Vec3f0[Vec3f0(0.02,0.02, (elem.interval[1]-elem.average_time) / m ) for elem in b]

    ps = Point3f0[Point3f0(i*3f0/l, 0f0, 1f0-(x/m)) for (i,x) in enumerate(t)]
    colors 	= map(RGBA{U8}, distinguishable_colors(l, RGB{U8}(0,0,1)))
    	
    robj5 = map(enumerate(b)) do args
    	i, stats = args
    	visualize(
    		Point3f0[Point3f0(0f0, i/l, 1f0-(x/m)) for (i,x) in enumerate(stats.all_samples)], 
    		color=RGBA{Float32}(colors[i]), 
    		scale=Vec3f0(0.01), 
    		model=translationmatrix(Vec3f0(i*3f0/l, 0f0,0f0))
    	)
    end

    robj1 	= visualize(ps, color=colors, scale=Vec3f0(0.03), primitive=GLNormalMesh(Sphere{Float32}(Point3f0(0), 1f0)))
    robj2 	= visualize(robj1[:positions], color=robj1[:color], scale=Texture(scale_up))
    robj3 	= visualize(robj1[:positions], color=robj1[:color], scale=Texture(scale_down))
    robj4 	= visualize(robj1[:positions], color=robj1[:color], scale=Texture(scale_down))
    Context(robj1, robj2, robj3, robj5...)
end
glClearColor(1,1,1,1)

benches = Benchmarks.Results[]

for i=1:20
	try
		push!(benches, @benchmark(rand(i*100)))
	end
end
benchstats = map(Benchmarks.Statistics, benches)

vizz = visualize(benchstats)
view(vizz, screen3D)
view(visualize(boundingbox(vizz).value, :grid), screen3D)

r()