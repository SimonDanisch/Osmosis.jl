using GLVisualize, FileIO, ImageIO
robj = visualize(file"nasa.jpg")
println(robj[:preferred_camera])
view(robj)
renderloop()