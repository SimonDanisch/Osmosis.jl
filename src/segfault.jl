using Reactive, GLAbstraction, Meshes, MeshIO, GeometryTypes, ColorTypes, GLWindow, FileIO, ModernGL, GLFW


w = createwindow("test", 1000, 1000)

function collect_for_gl{T <: HomogenousMesh}(m::T)
    result = Dict{Symbol, Any}()
    attribs = attributes(m)
    @materialize! vertices, faces = attribs
    result[:vertices]   = GLBuffer(vertices)
    result[:faces]      = indexbuffer(faces)
    for (field, val) in attribs
        if field in [:texturecoordinates, :normals, :attribute_id]
            result[field] = GLBuffer(val)
        else
            result[field] = Texture(val)
        end
    end
    result
end
function test(_, screen)
	data      = rand(Float32, 32,32)
    camera    = screen.perspectivecam
    sourcedir = Pkg.dir("GLVisualize", "src")
    shaderdir = joinpath(sourcedir, "shader")
    data = merge(Dict(
        :y_scale        => Texture(data),
        :color          => Texture(RGBAU8[rgbaU8(1,0,0,1), rgbaU8(1,1,0,1), rgbaU8(0,1,0,1), rgbaU8(0,1,1,1), rgbaU8(0,0,1,1)]),
        :projection     => camera.projection,
        :viewmodel      => camera.view,
        :grid_min       => Vec2(-1,1),
        :grid_max       => Vec2(-1,1),
        :scale          => Vec3(0.2),
        :norm           => Vec2(-1, 1)

    ), collect_for_gl(GLNormalMesh(Cube(Vec3(0), Vec3(1.0)))))

    program = TemplateProgram(File(shaderdir, "util.vert"), 
        File(shaderdir, "meshgrid.vert"), 
        File(shaderdir, "standard.frag")
    )

    robj = RenderObject(data, program)

end

const renderlist = Any[]
while w.inputs[:open].value
    robj = test(0, w)
    push!(renderlist, robj)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    render(renderlist)
    GLFW.SwapBuffers(w.nativewindow)
    GLFW.PollEvents()
    yield()
end

GLFW.Terminate()



