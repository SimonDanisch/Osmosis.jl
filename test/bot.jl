
println("11")
using Toxcore

println("12")
using GLVisualize

println("13")
using GLWindow

println("14")
using Reactive

println("15")
using GeometryTypes

println("16")
using GLAbstraction

println("17")
using ColorTypes

println("18")
using FileIO

println("19")
using ImageIO

println("10")
println("1")
type JuliaBot
    quit::Bool
    svg_file_bytes::Vector{Uint8}
end

function JuliaBot()
    JuliaBot(false, [])
end

bot = JuliaBot()

global const MESSAGES = Input(utf8("hello\n"))

const RS    = GLVisualize.ROOT_SCREEN
println("2")
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
        if str[i] == '#' 
            println("this is a comment, $i")
        end
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

function handle_message(yoffset, text, scroll_window, main_screen)
    yoffset -= 50
    if startswith(text, "jl\"") && endswith(text, "\"")
        value           = save_eval(text[4:end-1])
        value           = applicable(visualize, value) ? value : string(value)
        robj            = visualize(value)
        screen_height   = 600
    else
        robj            = visualize(text, preferred_camera=:fixed_pixel)
        bb              = robj.boundingbox.value
        width           = bb.max - bb.min
        text_height     = round(Int, width.y)
        robj[:model]    = translationmatrix(Vec3(50, text_height+40, 0))
        screen_height   = text_height+100
    end
    yoffset -= screen_height
    area = lift(main_screen.area, scroll_window) do m_area, y
        Rectangle(130, yoffset+(round(Int, y)*50), m_area.w-200, screen_height)
    end
    new_screen = Screen(main_screen, area=area)
    view(visualize(lift(zeroposition, area), color=RGBA(1f0,1f0,1f0,0.6f0)), new_screen, method=:fixed_pixel)
    view(robj, new_screen)
    yoffset
end


println("5")
function OnToxFileChunkRequest(tox::Ptr{Tox}, friend_number::Uint32, file_number::Uint32, position::Uint64, chunk_length::Csize_t, user_data::Ptr{Void})
    global bot

    chunk_length = max(chunk_length, length(bot.svg_file_bytes)-position)
    data = bot.svg_file_bytes[position+1:position+chunk_length]

    if tox_file_send_chunk(tox, friend_number, file_number, position, data)
        println("File chunk send.")
    else
        println("Failed to send file chunk.") 
    end

    nothing
end

function OnToxFileRecv(tox::Ptr{Tox}, friend_number::Uint32, file_number::Uint32, kind::TOX_FILE_KIND, file_size::Uint64, filename::Ptr{Uint8}, filename_length::Csize_t, user_data::Ptr{Void})
    println("File Recv Callback")

    nothing
end

function OnToxFileRecvChunk(tox::Ptr{Tox}, friend_number::Uint32, file_number::Uint32, position::Uint64, data::Ptr{Uint8}, data_length::Csize_t, user_data::Ptr{Void})
    println("File Recv Chunk Callback")

    nothing
end
println("6")
function OnToxFileRecvControl(tox::Ptr{Tox}, friend_number::Uint32, file_number::Uint32, control::TOX_FILE_CONTROL, user_data::Ptr{Void})
    if control == TOX_FILE_CONTROL_RESUME
        println("Resumming file transfer.")
    elseif control == TOX_FILE_CONTROL_PAUSE 
        println("File transfer paused.")
    else # TOX_FILE_CONTROL_CANCEL
        println("File transfer cancelled.")
    end

    nothing
end
println("7")
function OnToxFriendRequest(tox::Ptr{Tox}, public_key::Ptr{Uint8}, message::Ptr{Uint8}, length::Csize_t, user_data::Ptr{Void})
    tox_friend_add_norequest(tox, ToxPublicKey(public_key))
    println("Accepted a friend request.")
    nothing
end
println("8")
function OnToxFriendMessage(tox::Ptr{Tox}, friend_number::Uint32, typ::TOX_MESSAGE_TYPE, message::Ptr{Uint8}, message_length::Csize_t, user_data::Ptr{Void})
    global MESSAGES
    msg = utf8(message, message_length)
    push!(MESSAGES, msg)
    nothing
end
println("9")
function main()
    global bot

    info("This is the Julia Tox bot")

    # Load the file that the bot always sends
    julia_svg_file = open(Pkg.dir("Toxcore", "test/julia.svg"), "r") 
    bot.svg_file_bytes = readbytes(julia_svg_file)
    close(julia_svg_file)

    # Try to load the tox settings
    my_tox = 0

    try 
        savefile = open(Pkg.dir("Toxcore", "test", "bot_savedata.binary"), "r")
        savedata = readbytes(savefile)
        close(savefile)

        default_options = tox_options_default()

        options = Tox_Options(default_options.ipv6_enabled,
                            default_options.udp_enabled,
                            default_options.proxy_type,
                            default_options.proxy_host,
                            default_options.proxy_port,
                            default_options.start_port,
                            default_options.end_port,
                            default_options.tcp_port,
                            TOX_SAVEDATA_TYPE_TOX_SAVE,
                            pointer(savedata),
                            length(savedata))

        my_tox = tox_new(options)

        info("Previous bot instance found. Reusing it!")
    catch e 
        println(e)
        #Create a default Tox
        my_tox = tox_new()

        info("Created new bot instance")
    end

    # register the callbacks 
    tox_callback_file_chunk_request(my_tox, OnToxFileChunkRequest, C_NULL)
    tox_callback_friend_request(my_tox, OnToxFriendRequest, C_NULL)
    tox_callback_friend_message(my_tox, OnToxFriendMessage, C_NULL)
    tox_callback_file_recv(my_tox, OnToxFileRecv, C_NULL)
    tox_callback_file_recv_chunk(my_tox, OnToxFileRecvChunk, C_NULL)
    tox_callback_file_recv_control(my_tox, OnToxFileRecvControl, C_NULL)

    # print own address
    info("Here is my address")
    println(convert(ASCIIString, tox_self_get_address(my_tox)))

    # define user details
	tox_self_set_name(my_tox, "Julia")
    tox_self_set_status_message(my_tox, "I am Julia, a high-level, high-performance dynamic programming language for technical computing.") 
    Toxcore.CInterface.tox_self_set_status(my_tox, Toxcore.CInterface.TOX_USER_STATUS_NONE) 
    # bootstrap from the node defined above 
    if !tox_bootstrap(my_tox)
        println("Failed to bootstrap.")
        exit()
    end 

    # get the friend list
    friendlist = tox_self_get_friend_list(my_tox)
    info("I have $(length(friendlist)) friend(s)")
    currentfriend = 0
    for friend in friendlist
        fname = tox_friend_get_name(my_tox, friend) 
        println(fname)
        fname == "SimonD" && (currentfriend = friend)
    end
    println(currentfriend)
    println(tox_friend_get_name(my_tox, currentfriend) )
    write_area, main_area = y_partition(RS.area, 20.0)
    write_screen      = Screen(RS, area=write_area)
    main_screen       = Screen(RS, area=main_area)

    text = visualize("write something \n", model=translationmatrix(Vec3(0,write_area.value.h,0)))
    background, cursor_robj, text_sig = vizzedit(text[:glyphs], text, write_screen.inputs)
    buttonspressed = write_screen.inputs[:buttonspressed]
    enter_pressed = lift(==, buttonspressed, IntSet(GLFW.KEY_ENTER))
    message       = sampleon(keepwhen(enter_pressed, true, enter_pressed), text_sig)
    message = lift(message) do msg
        tox_friend_send_message(my_tox, currentfriend, msg)
    end

    view(background,    write_screen)
    view(text,          write_screen)
    view(cursor_robj,   write_screen)

    view(visualize(lift(x->Rectangle(0,0,x.w, x.h), write_screen.area), color=RGBA(0f0,0f0,1f0,1f0)), write_screen, method=:fixed_pixel)

    scroll_window = foldl(+, 0.0, keepwhen(main_screen.inputs[:mouseinside], 0.0, main_screen.inputs[:scroll_y]))


    foldl(handle_message, write_area.value.h, MESSAGES, Input(scroll_window), Input(main_screen))

    push!(MESSAGES, utf8("Willkommen bei Toxcore, digga, lol!!"))
    toxloop(my_tox, RS)

end
function toxloop(my_tox, screen)
    while screen.inputs[:open].value
        renderloop(screen)
        tox_iterate(my_tox)
    end
    GLFW.Terminate()
    GLVisualize.FreeTypeAbstraction.done()
    savedata = tox_get_savedata(my_tox)
    tox_kill(my_tox)

    savefile = open(Pkg.dir("Toxcore", "test", "bot_savedata.binary"), "w")
    write(savefile, savedata)
    close(savefile)

    info("Bot instance saved")
end
println("22")
main()
println("7")
