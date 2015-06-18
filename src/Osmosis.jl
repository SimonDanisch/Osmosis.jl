using GLVisualize, GLWindow, Reactive, GeometryTypes, GLAbstraction

const RS    = GLVisualize.ROOT_SCREEN

function y_partition(area, percent)
	amount = percent / 100.0
	p = lift(area) do r
		(Rectangle{Int}(r.x, r.y, r.w, round(Int, r.h*amount)), 
			Rectangle{Int}(r.x, round(Int, r.h*amount), r.w, round(Int, r.h*(1-amount))))
	end
	return lift(first, p), lift(last, p)
end
function x_partition(area, percent)
	amount = percent / 100.0
	p = lift(area) do r
		(Rectangle{Int}(r.x, r.y, round(Int, r.w*amount), r.h ), 
			Rectangle{Int}(round(Int, r.w*amount), r.y, round(Int, r.w*(1-amount)), r.h))
	end
	return lift(first, p), lift(last, p)
end

main_area, write_area = y_partition(RS.area, 20.0)

const write_screen 	= Screen(RS, area=main_area)
const main_screen 	= Screen(RS, area=write_area)
function fixedscreen(parent, area)
	inputs = parent.inputs
	area = lift(intersect, parent.area, area)
	children = Screen[]
	#checks if mouse is inside screen
	insidescreen = lift(inputs[:mouseposition]) do mpos
		isinside(area.value, mpos...) && !any(children) do screen 
			isinside(screen.area.value, mpos...)
		end
	end
	wsize = lift(x->Vector4(x.x, x.y, x.w, x.h), area)
	ocamera = OrthographicCamera(			
		wsize,
		Input(eye(Mat4)),	
		Input(-1000f0), # nearclip
		Input(1000f0)	# farclip
	)
	camera_input = merge(inputs, Dict(
		:mouseposition 	=> keepwhen(insidescreen, Vector2(0.0), inputs[:mouseposition]), 
		:scroll_x 		=> keepwhen(insidescreen, 0.0, 			inputs[:scroll_x]), 
		:scroll_y 		=> keepwhen(insidescreen, 0.0, 			inputs[:scroll_y]), 
		:window_size 	=> lift(x->Vector4(x.x, x.y, x.w, x.h), area)
	))
	pcamera = PerspectiveCamera(camera_input, Vec3(2), Vec3(0))
    screen = Screen(area, parent, children, camera_input, RenderObject[], Input(true), parent.hasfocus, pcamera, ocamera, parent.nativewindow)
	push!(parent.children, screen)
	screen
end

text_stream 		= lift(x->"Ima push this so hard\nDude yeah neva now rite?$x\n", fpswhen(RS.inputs[:open], 1.0))
const scroll_window = foldl(+, 0.0, main_screen.inputs[:scroll_y])
visualize(text_stream.value, screen=write_screen)
lift(text_stream) do teeext
	area_handle	= Input(Rectangle{Int}(0,200*length(main_screen.children), main_screen.area.value.w, 180))
	area  		= lift(area_handle, main_screen.area, scroll_window) do h_area, m_area, y
		Rectangle{Int}(h_area.x, h_area.y+(round(Int, y)*50), m_area.w, h_area.h)
	end
	
	new_screen  = fixedscreen(main_screen, area)
	robj 		= visualize(teeext, screen=new_screen)

	view(visualize(lift(x->Rectangle(0,0,x.w, x.h), area), screen=new_screen), new_screen)
	view(robj, new_screen)
	nothing
end



renderloop()
