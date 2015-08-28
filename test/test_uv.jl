using GLVisualize, GeometryTypes, GLAbstraction, GLWindow
w, r = Screen()
@async r()
a = GLNormalUVMesh(Cube{Float32}(Vec3f0(0), Vec3f0(1)))
view(visualize(a))
