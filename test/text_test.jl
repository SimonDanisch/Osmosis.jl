using GLVisualize

robj = visualize("trololololololo\n"^10)
view(robj, method=:orthographic_pixel)

renderloop()