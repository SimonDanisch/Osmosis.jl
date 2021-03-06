using Toxcore
using GLVisualize
using GLWindow
using Reactive
using GeometryTypes
using GLAbstraction
using ColorTypes
using FileIO
using ImageIO
using MeshIO
using WavefrontObj
using Meshes
using NPZ
using GLFW
using ModernGL

include("helper.jl")
function xy_data(x,y,i, N)
    x = ((x/N)-0.5f0)*i
    y = ((y/N)-0.5f0)*i
    r = sqrt(x*x + y*y)
    Float32(sin(r)/r)
end
generate(i, N) = Float32[xy_data(Float32(x),Float32(y),Float32(i), N) for x=1:N, y=1:N]



immutable Message
    leftaligned::Bool # kinda silly place, but it works for now
    color::RGBA{Float32}
    text::UTF8String
end
global const MESSAGES = Input(Message(false, RGBA(1f0,0.2f0,0.5f0,0.7f0), "msg"))


function message_area(yoffset, y_scroll, m_area, screen_width, screen_height, left_aligned)
    yposition    = yoffset+(round(Int, y_scroll)*50) # for scrolling and positioning
    xposition    = left_aligned ? 50 : (m_area.w - 50 - screen_width)
    Rectangle(xposition, yposition, screen_width, screen_height)
end
const edit_value_names = (
    :color,
    :grid_min,
    :grid_max,
    :algorithm,
    :style,
    :technique,
    :scale,
    :norm,
    :absorption,
    :light_position,
    :isovalue
)

is_screen_active(v0, ek, esc) = (esc && return false; ek && return true; v0)

function create_edit_screen(parent, robj, namefilter=edit_value_names)
    frame       = 20
    key_string  = ""
    yoffset     = 10
    vizzes      = RenderObject[]
    max_screenwidth = 0
    screenheigth    = 0
    for (key, value) in filter((k,v)->in(k, namefilter), robj.uniforms)
        if applicable(vizzedit, value, parent.inputs)

            signal, editvizz = vizzedit(value, parent.inputs)
            robj[key]        = signal
            keylabel         = visualize(string(key)*": ")


            boundingbox      = keylabel.boundingbox.value
            bbsize           = boundingbox.maximum - boundingbox.minimum
            key_width        = round(Int, bbsize[1])
            key_height       = round(Int, bbsize[2])
            move             = -boundingbox.minimum+Float32(frame/2f0)+Vec3f0(0, yoffset, 0)
            keylabel[:model] = translationmatrix(Vec3f0(move[1], move[2], 0f0))
            keylabel[:preferred_camera] = :fixed_pixel

            boundingbox      = editvizz.boundingbox.value
            bbsize           = boundingbox.maximum - boundingbox.minimum
            edit_width       = round(Int, bbsize[1])
            edit_height      = round(Int, bbsize[2])
            move             = -boundingbox.minimum+Float32(frame/2f0)+Vec3f0(key_width, yoffset, 0)
            editvizz[:model] = translationmatrix(Vec3f0(move[1], move[2], 0f0))
            editvizz[:preferred_camera] = :fixed_pixel
            push!(vizzes, editvizz, keylabel)

            yoffset         += max(edit_height, key_height)+50
            max_screenwidth = max(max_screenwidth, key_width+edit_width)
        end
    end

    buttonspressed  = parent.inputs[:buttonspressed]

    edit_key            = lift(==, buttonspressed, [GLFW.KEY_LEFT_CONTROL, GLFW.KEY_E])
    escape_key          = lift(==, buttonspressed, [GLFW.KEY_ESCAPE])
    edit_key_active     = keepwhen(edit_key, false, edit_key)

    mouse_at_edit_time  = sampleon(edit_key_active, parent.inputs[:mouseposition])
    is_active           = foldl(is_screen_active, false, edit_key, escape_key)
    area                = lift(mouse_at_edit_time, is_active) do mousepos, active
        !active && return Rectangle(0,0,0,0)
        Rectangle(round(Int, mousepos[1]), round(Int, mousepos[2]), max_screenwidth+frame, yoffset)
    end
    edit_screen         = Screen(parent, area=area)
    view(
        visualize(lift(zeroposition, area), color=RGBA(0f0,0f0,0f0,1f0)),
        edit_screen, method=:fixed_pixel
    )
    view(vizzes, edit_screen)
end

function create_screens(yoffset, robjs_alignment, scroll_window, main_screen)
    frame = 40
    robjs, alignement, color = robjs_alignment
    for robj in robjs
        yoffset -= 30
        camera_position = Vec3f0(2)
        camera_lookat   = Vec3f0(0)
        boundingbox     = robj.boundingbox.value
        bbsize          = boundingbox.maximum - boundingbox.minimum
        if endswith(string(robj[:preferred_camera]), "_pixel") # terrible way of working around the lack of a unit system
            screen_height           = round(Int, bbsize[2])+frame
            screen_width            = round(Int, bbsize[1])+frame
            move                    = -boundingbox.minimum+Float32(frame/2f0)
            robj[:model]            = translationmatrix(Vec3f0(move[1], move[2], 0f0))
            robj[:preferred_camera] = :fixed_pixel #better fixate this
        else
            screen_height     = 700 # for now, all 3D windows will have a fixed size
            screen_width      = lift(x->round(Int, x.w*0.9), main_screen.area)
            camera_position   = boundingbox.minimum+(bbsize*1.5f0)
            camera_lookat     = boundingbox.minimum+(bbsize*0.5f0)
        end
        yoffset     -= screen_height
        area        = lift(message_area, yoffset, scroll_window, main_screen.area, screen_width, screen_height, alignement)
        new_screen  = Screen(main_screen, area=area, position=camera_position, lookat=camera_lookat)
        #view(
        #    visualize(lift(zeroposition, area), color=color),
        #    new_screen, method=:fixed_pixel
        #)
        view(robj, new_screen)
        #create_edit_screen(new_screen, robj)
    end
    yoffset
end



function handle_drop(files::Vector{UTF8String})
    files = map(File, files)
    (RenderObject[visualize(f) for f in files], false, RGBA(1f0,1f0,1f0,0.7f0))
end

function visualize_source(source)
    value = save_eval(source)
    if isa(value, RenderObject)
        return value
    else
        try
            return visualize(value)
        catch e # ultra terrible way of trying to find out if there is a default visulization
            return visualize("error: $e", preferred_camera=:fixed_pixel)
        end
    end
end

function GLVisualize.visualize(julia_source::File{:jl})
    source = readall(abspath(julia_source))
    visualize_source(source)
end
function GLVisualize.visualize(npzfile::File{:npz}, style::Symbol=:default; kw_args...)
    volume = npzread(abspath(npzfile))["data"]
    volume = volume./256f0
    visualize(volume, Style{style}(), visualize_default(volume, style, kw_args))
end


function visualize_message(msg::Message)
    text = msg.text
    vizz = "error"
    if startswith(text, "jl\"") && endswith(text, "\"") # its julia code
        vizz = visualize_source(text[4:end-1])
    else # its just text
        vizz = visualize(text, preferred_camera=:fixed_pixel)
    end
    return ([vizz], msg.leftaligned, msg.color) # this is what the insertinto screen function wants!
end


function main()
    RS, renderloop = Screen()
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
	tox_self_set_name(my_tox, "SamD")
    tox_self_set_status_message(my_tox, "Whatup yo!")
    Toxcore.CInterface.tox_self_set_status(my_tox, Toxcore.CInterface.TOX_USER_STATUS_NONE)
    # bootstrap from the node defined above
    if !tox_bootstrap(my_tox)
        println("Failed to bootstrap.")
        exit()
    end

    # get the friend list
    friendlist = tox_self_get_friend_list(my_tox)
    info("I have $(length(friendlist)) friend(s)")
    currentfriend = Cuint(0)
    for friend in friendlist
        fname = tox_friend_get_name(my_tox, friend)
        println(fname)
        fname == "SimonD" && (currentfriend = Cuint(friend))
    end
    println(currentfriend)
    println(tox_friend_get_name(my_tox, currentfriend))

    write_area, main_area   = y_partition(RS.area, 20.0)
    write_screen            = Screen(RS, area=write_area)
    main_screen             = Screen(RS, area=main_area)

    text = visualize("write something \n", model=translationmatrix(Vec3f0(0, write_area.value.h-40,0)))
    background, cursor_robj, text_sig = vizzedit(text[:glyphs], text, write_screen.inputs)
    buttonspressed  = write_screen.inputs[:buttonspressed]
    enter_pressed   = lift(==, buttonspressed, [GLFW.KEY_ENTER])
    system_message  = Input(utf8("jl\"file\"osmosisheader.png\"\""))
    message         = sampleon(keepwhen(enter_pressed, true, enter_pressed), text_sig)
    message         = merge(system_message, message)

    mymessages      = lift(message) do msg
        tox_friend_send_message(my_tox, currentfriend, msg)
        Message(false, RGBA(1f0,1f0,1f0,0.7f0), msg)
    end

    view(visualize(lift(x->Rectangle(0,0,x.w, x.h), write_screen.area), color=RGBA(0f0,0f0,0f0,0.7f0)), write_screen, method=:fixed_pixel)

    view(background,    write_screen)
    view(text,          write_screen)
    view(cursor_robj,   write_screen)


    scroll_window   = foldl(+, 0.0, keepwhen(main_screen.inputs[:mouseinside], 0.0, main_screen.inputs[:scroll_y]))

    drop_robjs      = lift(handle_drop, RS.inputs[:droppedfiles])

    all_msgs        = merge(mymessages, MESSAGES)

    msg_robj        = lift(visualize_message, all_msgs)
    all_robjs       = merge(msg_robj, drop_robjs)

    foldl(
        create_screens,
        main_area.value.h,
        all_robjs,
        Input(scroll_window), Input(main_screen)
    )
    push!(system_message, utf8("jl\"file\"osmosisheader.png\"\""))

    glClearColor(1,1,1,1)
    renderloop(()-> tox_iterate(my_tox))

    savedata = tox_get_savedata(my_tox)
    tox_kill(my_tox)

    savefile = open(Pkg.dir("Toxcore", "test", "bot_savedata.binary"), "w")
    write(savefile, savedata)
    close(savefile)

    info("Bot instance saved")

end

main()
