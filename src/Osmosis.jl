using GLVisualize, GLWindow, Reactive, GeometryTypes, GLAbstraction

const RS    = GLVisualize.ROOT_SCREEN

function y_partition(area, percent)
	amount = percent / 100.0
	p = lift(area) do r
		(Rectangle{Int}(r.x, r.y, 4000, round(Int, r.h*amount)), 
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

const main_screen 	= Screen(RS, area=main_area)
const write_screen 	= Screen(RS, area=write_area)


text_stream = lift(x->"Ima push this so hard\nDude yeah neva now rite?$x\n", fpswhen(RS.inputs[:open], 1.0))

visualize(text_stream.value)

lift(text_stream) do teeext
	#area_handle	= Input(Rectangle{Int}(0,100*length(main_screen.children), main_screen.area.value.w, 100))
	#area  		= lift(area_handle, main_screen.area, main_screen.inputs[:scroll_y]) do h_area, m_area, y
#		Rectangle{Int}(h_area.x, h_area.y+round(Int, y), m_area.w, h_area.h)
#	end
#	new_screen  = Screen(main_screen, area=area)
	#println(text)
	robj = visualize(teeext)
	push!(GLVisualize.ROOT_SCREEN.renderlist, robj)
end



renderloop()
