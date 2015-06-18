using Toxcore
using GLVisualize
using GLWindow
using Reactive
using GeometryTypes
using GLAbstraction
using ColorTypes
using FileIO
using ImageIO

include("helper.jl")

type JuliaBot
    quit::Bool
    svg_file_bytes::Vector{Uint8}
end

function JuliaBot()
    JuliaBot(false, [])
end

bot = JuliaBot()


const RS    = GLVisualize.ROOT_SCREEN

function message_area(yoffset, y, m_area, screen_height, offset)
    Rectangle(offset[1], yoffset+(round(Int, y)*50), m_area.w-offset[2], screen_height)
end

immutable Message
    offset::NTuple{2, Int}
    color::RGBA{Float32}
    text::UTF8String
end
global const MESSAGES = Input(Message((50, 200), RGBA(1f0,0.2f0,0.5f0,0.7f0), "msg"))

function handle_message(yoffset, message, scroll_window, main_screen)
    text = message.text
    yoffset -= 30
    if startswith(text, "jl\"") && endswith(text, "\"")
        value           = save_eval(text[4:end-1])
        try 
            robj = visualize(value)
        catch e # ultra terrible way of trying to find out if there is a default visulization
            robj = visualize(string(value))
        end
        screen_height   = 600
    else
        robj            = visualize(text, preferred_camera=:fixed_pixel)
        bb              = robj.boundingbox.value
        width           = bb.max - bb.min
        text_height     = round(Int, width.y)
        robj[:model]    = translationmatrix(Vec3(20, text_height+40, 0))
        screen_height   = text_height+100
    end
    yoffset     -= screen_height
    area        = lift(message_area, yoffset, scroll_window, main_screen.area, screen_height, message.offset)
    new_screen  = Screen(main_screen, area=area)
    view(visualize(lift(zeroposition, area), color=message.color), new_screen, method=:fixed_pixel)
    view(robj, new_screen)
    yoffset
end


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
    tox_callback_friend_request(my_tox, OnToxFriendRequest, C_NULL)
    tox_callback_friend_message(my_tox, OnToxFriendMessage, C_NULL)

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
    println(tox_friend_get_name(my_tox, currentfriend))
    write_area, main_area   = y_partition(RS.area, 20.0)
    write_screen            = Screen(RS, area=write_area)
    main_screen             = Screen(RS, area=main_area)

    text = visualize("write something \n", model=translationmatrix(Vec3(0,write_area.value.h-40,0)))
    background, cursor_robj, text_sig = vizzedit(text[:glyphs], text, write_screen.inputs)
    buttonspressed  = write_screen.inputs[:buttonspressed]
    enter_pressed   = lift(==, buttonspressed, IntSet(GLFW.KEY_ENTER))
    message         = sampleon(keepwhen(enter_pressed, true, enter_pressed), text_sig)
    mymessages      = lift(message) do msg
        tox_friend_send_message(my_tox, currentfriend, msg)
        Message((150, 200), RGBA(1f0,1f0,1f0,0.7f0), msg)
    end

    view(background,    write_screen)
    view(text,          write_screen)
    view(cursor_robj,   write_screen)

    view(visualize(lift(x->Rectangle(0,0,x.w, x.h), write_screen.area), color=RGBA(0f0,0f0,0f0,0.7f0)), write_screen, method=:fixed_pixel)

    scroll_window = foldl(+, 0.0, keepwhen(main_screen.inputs[:mouseinside], 0.0, main_screen.inputs[:scroll_y]))
    ALLMESS = merge(mymessages, MESSAGES)
    foldl(handle_message, write_area.value.h, 
        ALLMESS, Input(scroll_window), 
        Input(main_screen)
    )

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
