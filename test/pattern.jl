using GLVisualize, GLAbstraction, GLWindow, GeometryTypes, Reactive, ColorTypes, ModernGL

w, r = Screen();
@async r();
cs = cubecamera(w);

cos_01{T}(i::T) = (cos(i)+T(1.5)) / T(2.5)
sin_01{T}(i::T) = (sin(i)+T(1.5)) / T(2.5)
glClearColor(1,1,1,1)

cap(a, lower=0f0, upper=1f0) = min(max(a, lower), upper)

color_update(k::Float32) = RGBA{U8}[RGBA{U8}(
		cos_01((i/2f0-sin(k)))*sin_01((j/2f0+cos(k))) * abs(sin(k)), 
		cos_01(j/2f0)*sin_01(i/2f0) * abs(cos(k)), 
		0.01f0, 
		cap((cos_01((i/2f0-sin(k)))*sin_01((j/2f0+cos(k))) * abs(sin(k))) +
		(cos_01(j/2f0)*sin_01(i/2f0) * abs(cos(k))))
	) for i=0f0:0.1f0:30f0, j=0f0:0.1f0:2f0
]
robj = visualize(lift(color_update, bounce(0f0:0.01f0:100f0)));
view(robj);
bb = robj.boundingbox.value;

view(visualize("random access"), model=translationmatrix(-bb.maximum-bb.minimum));
