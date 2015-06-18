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
println("3")

function parse_multi(source)
    str = strip(source)
    #parse file, does not check if the program is correct or not!
    #Just linewise check.
    i = start(str)
    exprs = []
    while !done(str, i)
        ex, i = parse(str, i, raise=false)
        push!(exprs, ex)
    end
    return exprs
end

function save_eval(source)
    exprsns = parse_multi(source)
    last_val = "empty"
    for expr in exprsns
        if expr.head != :error
            try
                last_val = eval(Main, expr)
            catch e
                last_val = string(e)
            end
        else
            last_val = string(expr)
        end
    end
    return last_val
end
println("4")
zeroposition{T}(r::Rectangle{T}) = Rectangle(zero(T), zero(T), r.w, r.h)


function OnToxFriendRequest(tox::Ptr{Tox}, public_key::Ptr{Uint8}, message::Ptr{Uint8}, length::Csize_t, user_data::Ptr{Void})
    tox_friend_add_norequest(tox, ToxPublicKey(public_key))
    println("Accepted a friend request.")
    nothing
end
function OnToxFriendMessage(tox::Ptr{Tox}, friend_number::Uint32, typ::TOX_MESSAGE_TYPE, message::Ptr{Uint8}, message_length::Csize_t, user_data::Ptr{Void})
    global MESSAGES
    msg = utf8(message, message_length)
    push!(MESSAGES, Message(true, RGBA(1f0,0.2f0,0.5f0,0.7f0), msg))
    nothing
end