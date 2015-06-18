function parse_multi(source)
	str = strip(source)
	#parse file, does not check if the program is correct or not!
	#Just linewise check.
	i = start(str)
	exprs = []
	while !done(str, i)
		if str[i] == '#' 
			println("this is a comment, $i")
		end
		ex, i = parse(str, i, raise=false)
		push!(exprs, ex)
	end
	return exprs
end


test = "
generate_particles(N,x,i) = Point3f(
	sin(i+x/20f0),
	cos(i+x/20f0), 
	(2x/N)+i/10f0
)
update_particles(i, N) 		= Point3f[generate_particles(N,x, i) for x=1:N]
particle_color(positions) 	= RGBAU8[RGBAU8(((cos(pos.x)+1)/2),0.0,((sin(pos.y)+1)/2),  1.0f0) for pos in positions]

function particle_data(N)
	locations 	= lift(update_particles, bounce(1f0:0.1f0:10f0), N)
	colors 		= lift(particle_color, locations)
	(locations, :color=>colors)
end
particle_data(1024)
"

ast = parse_multi(test)
println(ast)
