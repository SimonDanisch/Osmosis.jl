
function under(robj1, robj2, direction, gap=0f0)
    bb1 = robj1.boundingbox.value;
    bb2 = robj2.boundingbox.value;
    position1 = minimum(bb1)
    position2 = minimum(bb2)
    position2_upper = maximum(bb2)
    to_move = -(position2_upper-position1)
    robj2[:model] = lift(*, translationmatrix(to_move.*direction + Vec3f0(gap).*direction),  robj2[:model])
end
under_x(robj1, robj2, gap=0f0) = under(robj1, robj2, unit(Vec3f0, 1), gap)
under_y(robj1, robj2, gap=0f0) = under(robj1, robj2, unit(Vec3f0, 2), gap)
under_z(robj1, robj2, gap=0f0) = under(robj1, robj2, unit(Vec3f0, 3), gap)

function align_left(robj1, robj2, gap=0f0)
    bb1 = robj1.boundingbox.value;
    bb2 = robj2.boundingbox.value;
    position1 = minimum(bb1)
    position2 = minimum(bb2)
    to_move = (position2-position1)
    robj2[:model] = lift(*, translationmatrix(Vec3f0(-to_move[1],0,0)),  robj2[:model])
end