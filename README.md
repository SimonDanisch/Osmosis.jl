# Osmosis

[![Build Status](https://travis-ci.org/SimonDanisch/Osmosis.jl.svg?branch=master)](https://travis-ci.org/SimonDanisch/Osmosis.jl)

install script:

```Julia

Pkg.clone("https://github.com/SimonDanisch/FixedSizeArrays.jl.git")
Pkg.checkout("FixedSizeArrays", "master")

Pkg.clone("https://github.com/JuliaGeometry/GeometryTypes.jl.git")
Pkg.checkout("GeometryTypes", "master")

Pkg.clone("https://github.com/SimonDanisch/ColorTypes.jl.git")
Pkg.checkout("ColorTypes", "master")

Pkg.clone("https://github.com/JuliaIO/ImageIO.jl.git")
Pkg.checkout("ImageIO", "master")

Pkg.clone("https://github.com/JuliaIO/ImageMagick.jl.git")
Pkg.checkout("ImageMagick", "master")
Pkg.build("ImageMagick")

Pkg.clone("https://github.com/JuliaIO/WavefrontObj.jl.git")
Pkg.checkout("WavefrontObj", "master")

Pkg.clone("https://github.com/JuliaGPU/AbstractGPUArray.jl.git")
Pkg.checkout("AbstractGPUArray", "master")

Pkg.clone("https://github.com/JuliaGeometry/Packing.jl.git")
Pkg.checkout("Packing", "master")

Pkg.clone("https://github.com/JuliaIO/FileIO.jl.git")
Pkg.checkout("FileIO", "master")

Pkg.clone("https://github.com/JuliaIO/MeshIO.jl.git")
Pkg.checkout("MeshIO", "master")

Pkg.clone("https://github.com/jhasse/FreeType.jl")
Pkg.checkout("FreeType", "master")

Pkg.clone("https://github.com/SimonDanisch/FreeTypeAbstraction.jl")
Pkg.checkout("FreeTypeAbstraction", "master")

Pkg.clone("https://github.com/JuliaGL/GLVisualize.jl.git")
Pkg.checkout("GLWindow", "text_editing")

Pkg.add("GLWindow")
Pkg.checkout("GLWindow", "julia04")

Pkg.add("GLAbstraction")
Pkg.checkout("GLAbstraction", "texture_buffer")

Pkg.add("ModernGL")
Pkg.checkout("ModernGL", "master")

Pkg.add("Reactive")
Pkg.checkout("Reactive", "master")

Pkg.add("GLFW")
Pkg.checkout("GLFW", "julia04")

Pkg.add("Compat")
Pkg.checkout("Compat", "master")


Pkg.add("Meshes")
Pkg.checkout("Meshes", "meshes2.0")



```