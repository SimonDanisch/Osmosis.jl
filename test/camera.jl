using GeometryTypes, ColorTypes
using GeometryTypes, Reactive, GLAbstraction, ModernGL
import Quaternions
using FileIO
using GLVisualize, GLWindow, ModernGL

w, r = glscreen();


area_msg, area3d = x_partition(w.area, 30.0);
screen3D         = Screen(w, area=area3d);
screenMSG        = Screen(w, area=area_msg);

cs = cubecamera(screen3D);


using Benchmarks
function GLVisualize.visualize(b::Benchmarks.Results, i::Float32)
    t = b.samples.elapsed_times
    m = maximum(t)
    l = length(t)
    ps = Point3f0[Point3f0(i/l,1f0-(x/m), 0f0) for (i,x) in enumerate(t)]
    visualize(ps, color=RGBA(0.84f0, 0.851f0, 1f0, 1f0), scale=Vec3f0(0.006), model=translationmatrix(Vec3f0(0,0,i)), primitive=GLNormalMesh(Sphere{Float32}(Point3f0(0), 1f0)))
end
glClearColor(1,1,1,1)



view(visualize(@benchmark(sin(1.9)), 1f0), screen3D);


cos_01{T}(i::T) = (cos(i)+T(1)) / T(2)
sin_01{T}(i::T) = (sin(i)+T(1)) / T(2)

glClearColor(1,1,1,1)

cap(a, lower=0f0, upper=1f0) = min(max(a, lower), upper)

@enum State Waiting WellDone Failed


color_periodic(k::Float32, i::Float32, j::Float32) = RGBA{U8}(
    cos_01((i/2f0-sin(k)))*sin_01((j/2f0+cos(k))) * abs(sin(k)),
    cos_01(j/2f0)*sin_01(i/2f0) * abs(cos(k)),
    0.01f0,
    cap((cos_01((i/2f0-sin(k)))*sin_01((j/2f0+cos(k))) * abs(sin(k))) +
    (cos_01(j/2f0)*sin_01(i/2f0) * abs(cos(k))))
) 

function color_update(done0, k::Float32, done::State)
    done0, image = done0
    if done == Waiting
        return false, RGBA{U8}[color_periodic(k, i, j) for i=0f0:0.1f0:30f0, j=0f0:0.1f0:1f0]
    else
        if done0
            return true, image
        else
            done1 = (isapprox(k, 1f0*pi) && done == WellDone) || (isapprox(k, 0.5f0*pi) && done == Failed)#green
            if done == Failed
                return done1, RGBA{U8}[RGBA{U8}(abs(sin(k)), abs(cos(k)), 0.01f0, abs(sin(k))) for i=0f0:0.1f0:30f0, j=0f0:0.1f0:1f0]
            else
                return done1, RGBA{U8}[RGBA{U8}(abs(sin(k)), abs(cos(k)), 0.01f0, abs(cos(k))) for i=0f0:0.1f0:30f0, j=0f0:0.1f0:1f0]
            end
        end
    end
end

function status_animation(state::Signal{State})
    v0 = RGBA{U8}[color_periodic(0f0, 0f0, 0f0) for i=0f0:0.1f0:30f0, j=0f0:0.1f0:1f0]
    status_img      = foldl(color_update, (false, v0), bounce(0f0:0.01f0*pi:2f0*pi), state)
    animation_done  = lift(first, status_img)
    return dropwhen(animation_done, v0, lift(last, status_img))
end

macro myspawn(expr, f)
    ff = esc(f)
    quote 
    ref = @spawn $(esc(expr))
    @async while true
        if isready(ref)
            $ff(fetch(ref))
            break
        else
            yield()
            sleep(0.001)
        end
    end
    end
end

function visualize_bench(name, s)
    state1  = Input(Waiting)
    ref = @spawn sleep(s)
    @async while true
        if isready(ref)
            push!(state1, rand(Bool) ? WellDone : Failed)
            break
        else
            yield()
            sleep(0.001)
        end
    end
    robj1   = visualize(status_animation(state1))
    robj2   = visualize(name)
    [robj1, robj2]
end



a = [
    visualize(visualize_bench("random access", 2)),
    visualize(visualize_bench("linear index", 25)),
    visualize(visualize_bench("öppöpöpö", 15)),
    visualize(visualize_bench("lol index", 7)),
    visualize(visualize_bench("trolol index", 20))
]

c = visualize(a, gap=5f0)

view(c, screenMSG)


r()



#=
function GLVisualize.visualize(b::Benchmarks.Results, i::Float32)
    t = b.samples.elapsed_times
    m = maximum(t)
    l = length(t)
    ps = Point3f0[Point3f0(i/l,1f0-(x/m), 0f0) for (i,x) in enumerate(t)]
    visualize(ps, color=RGBA(0.84f0, 0.851f0, 1f0, 1f0), scale=Vec3f0(0.006), model=translationmatrix(Vec3f0(0,0,i)), primitive=GLNormalMesh(Sphere{Float32}(Point3f0(0), 1f0)))
end

view(visualize(@benchmark(sin(1.9)), 1f0), screen3D);
benches = Benchmarks.Results[(a = rand(n); inds=rand(1:n, 100); @benchmark(test_bench(a, inds))) for n=100:100:10^6]
=#

