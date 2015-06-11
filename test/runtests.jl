function visualize_def(grid, t, kw_args=Dict())
    println("def: ", myid())
end
function teeest(_)
	data = rand(10^6)
	for i=1:10
		sin(data+data)
	end
	visualize_def(rand(Float32, 10,10), 1)
end
println("start: ", myid())
t = Timer(teeest)
start_timer(t, 0, 1)
for i=1:10
	println("for: ", myid())
	sleep(1)
end
stop_timer(t)
