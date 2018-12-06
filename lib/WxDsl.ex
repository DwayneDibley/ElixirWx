defmodule WxDsl do
  @moduledoc """
  An implementation of a DSL for generating GUI's
  """
  defmacro __using__(_opts) do
    quote do
      import WxDsl
      require Logger
      import WxFunctions
      import WxUtilities
      import WinInfo
      use WxDefines
    end
  end

  require Logger

  @doc """
  This is the top level window and should be the outer element of a window specification. This window performs the initialisation.

  | Parameter | Description                                                  | Value     | Default                |
  | --------- | ------------------------------------------------------------ | --------- | ---------------------- |
  | name      | The name by which the window will be referred to.            | atom()    | modulename |
  | show      | If set to true the window will be made visible when the construction is complete. If set to false, the window will be invisible until explicitly shown using :wxFrame.show(frame). | Boolean() | true                   |

  Example:

  ```
  defmodule TestWindow do
    use WxDsl
    import WxDefines

    def createWindow(show) do
      mainWindow show: show do
        # Create a frame with a status bar and a menu.
        frame id: :main_frame,
        ...
        ...
        end
      end
    end

  """
  defmacro mainWindow(attributes, do: block) do
    quote do
      Logger.debug("")

      Logger.debug(
        "mainWindow #{inspect(self())} +++++++++++++++++++++++++++++++++++++++++++++++++++++"
      )

      # Get the function attributes
      defaults = [show: false, icon: nil]
      {id, opts, errs} = getOptions(unquote(attributes), defaults)

      # Create the window storage
      WinInfo.createInfoTable()

      # Create a new wxObject for the window
      wx = :wx.new()
      debug(0, ":window = :wx.new()")

      # put_info( :window, wx)
      WinInfo.insertObject(:window, wx)

      # execute the function body
      stack_push({wx, wx, nil, 2})
      child = unquote(block)
      stack_pop()

      case {opts[:show], child} do
        {_, nil} ->
          error(0, ":wxWindow.show: No __main__frame__")

        {true, {:wx_ref, _, :wxFrame, []}} ->
          debug(0, ":wxWindow.show(#{inspect(getObjectId(child))}")
          :wxFrame.show(child)

        {false, {:wx_ref, _, :wxFrame, []}} ->
          warn(0, ":wxWindow.show: show was false")

        {show, child} ->
          error(
            0,
            ":wxWindow.show: Child must be a frame, was: {#{inspect(show)},#{inspect(child)}"
          )
      end

      Logger.debug("mainWindow -----------------------------------------------------")
      Logger.debug("")
      display_table()

      # case opts[:icon] do
      #   nil -> nil
      #   icon -> WxTopLevelWindow.setIcon(icon)
      # end
    end
  end

  @doc """
  Set the background colour for the enclosing control.

  The colour may be either one of the defined colours in wxDefines.ex or a nummeric
  RGB specification in the form {r, g, b}.

  ```
    bgColour(@wxSILVER)
    bgColour({{192, 192, 192}})
  ```

  """
  defmacro bgColour(colour) do
    quote do
      Logger.debug("bgColour +++++++++++++++++++++++++++++++++++++++++++++++++++++")

      {container, parent, sizer, indent} = stack_tos()
      Logger.debug("  tos = {#{inspect(parent)}, #{inspect(container)}, #{inspect(sizer)}}")

      :wxWindow.setBackgroundColour(parent, unquote(colour))
      Logger.debug("bgColour -----------------------------------------------------")
    end
  end

  defmacro border(attributes) do
    quote do
      Logger.debug("border/1 +++++++++++++++++++++++++++++++++++++++++++++++++++++")

      {container, parent, sizer, indent} = stack_tos()
      Logger.debug("  tos = #{inspect(container)}, #{inspect(parent)}, #{inspect(sizer)}}")

      defaults = [size: 1, flags: @wxALL]
      {id, options, errors} = WxUtilities.getOptions(unquote(attributes), defaults)

      Logger.debug(
        "  :wxSizer.insertSpacer(#{inspect(parent)}, #{inspect(Map.get(opts, :space, 0))})"
      )

      :wxSizer.addSpacer(parent, Map.get(opts, :space, 0))
      :wxSizer.insertSpacer(bs, 9999, 20)
      Logger.debug("border/1 -----------------------------------------------------")
    end
  end

  defmacro spacer(attributes) do
    quote do
      Logger.debug("Spacer/1 +++++++++++++++++++++++++++++++++++++++++++++++++++++")

      {container, parent, sizer, indent} = stack_tos()
      Logger.debug("  tos = {#{inspect(parent)}, #{inspect(container)}, #{inspect(sizer)}}")

      defaults = [space: nil, size: nil, layout: []]
      {id, options, restOpts} = getOptions(unquote(attributes), defaults)

      new_id = :wx_misc.newId()

      space = options[:space]
      size = options[:size]
      layout = options[:layout]

      case space do
        nil ->
          case size do
            nil ->
              Logger.error("spacer: Either space: or size must be supplied!")

            {w, h} ->
              Logger.debug(
                "  :wxSizer.add(#{inspect(sizer)}, #{inspect(w)}, #{inspect(h)},  #{
                  inspect(layout)
                }}}"
              )

              :wxSizer.add(sizer, w, h, layout)

            other ->
              Logger.error(
                "spacer: Expected {w,h} for the :size parameter, got #{inspect(other)}"
              )
          end

        space ->
          Logger.debug("  :wxSizer.add(#{inspect(sizer)}, #{inspect(space)}}}")
          :wxSizer.addSpacer(sizer, space)
      end

      Logger.debug("Spacer/1 -----------------------------------------------------")
    end
  end

  @doc """
  A wxBoxSizer can lay out its children either vertically or horizontally, depending
  on what flag is being used in its constructor.

  When using a vertical sizer, each child can be centered, aligned to the right
  or aligned to the left.

  Correspondingly, when using a horizontal sizer, each child can be centered,
  aligned at the bottom or aligned at the top.

  The stretch factor is used for the main orientation, i.e. when using a
  horizontal box sizer, the stretch factor determines how much the child can be
  stretched horizontally.

  | option      | Description                                             | Value     | Default   |
  | ----------- | ------------------------------------------------------- | --------- | --------- |
  | id          | The name by which the box sizer will be referred to.    | atom()    | none      |
  | :orient     | Orientation: @wxVERTICAL or @wxHORIZONTAL               | integer() |@wxVERTICAL|
  | :proportion | The proportion that the enclosed object will be resized | integer() | 1         |
  |             | (stretched) when the enclosing control is resized.      |           |           |
  |             | 0 - No resizing                                         |           |           |
  |             | 1 - In proportion                                       |           |           |
  |             | n - 1:n                                                 |           |           |
  | :flag       | @wxEXPAND: Make stretchable                             | integer() | @wxEXPAND |
  |             | @wxALL:    Make a border all around                     |           |           |
  | :border     | Width of the border                                     | integer() | 0         |
  Example:

  ```
  wxBoxSizer(
    id: :txt1sizer,
    orient: @wxVERTICAL,
    proportion: 1,
    flag: @wxEXPAND,
    border: 0
  ) do

  ...

  end


  """
  defmacro wxBoxSizer(attributes, do: block) do
    quote do
      # Logger.debug("Box Sizer ++++++++++++++++++++++++++++++++++++++++++++++++++")
      {container, parent, sizer, indent} = stack_tos()

      # Get the function attributes
      defaults = [id: nil, orient: @wxHORIZONTAL, proportion: 1, flag: @wxEXPAND, border: 0]
      {id, opts, errs} = getOptions(unquote(attributes), defaults)

      bs = :wxBoxSizer.new(opts[:orient])
      WinInfo.insertObject(id, bs, parent)

      debug(indent, "#{inspect(getObjectId(bs))} = :wxBoxSizer.new(#{inspect(opts[:orient])})")

      stack_push({container, parent, bs, indent + 2})
      child = unquote(block)
      stack_pop()

      case child do
        nil ->
          warn(indent, "wxBoxSizer has no children!")

        child ->
          :wxBoxSizer.add(bs, child,
            proportion: opts[:proportion],
            flag: opts[:flag],
            border: opts[:border]
          )

          debug(
            indent,
            ":wxBoxSizer.add(#{inspect(id)}, #{inspect(getObjectId(child))}, proportion: #{
              inspect(opts[:proportion])
            }, flag: #{inspect(opts[:flag])}, border: #{inspect(opts[:border])}"
          )
      end

      case parent do
        {:wx_ref, _, :wxFrame, _} ->
          debug(
            indent,
            ":wxBoxSizer.setSizeHints(#{inspect(id)}, #{inspect(getObjectId(parent))})"
          )

          :wxBoxSizer.setSizeHints(bs, parent)

        _ ->
          nil
      end

      # Logger.debug("boxSizer ---------------------------------------------------")
      bs
    end
  end

  defmacro button(attributes, do: block) do
    quote do
      Logger.debug("Button +++++++++++++++++++++++++++++++++++++++++++++++++++++")

      {container, parent, sizer, indent} = stack_tos()
      Logger.debug("  tos = #{inspect(container)}, #{inspect(parent)}, #{inspect(sizer)}}")

      new_id = :wx_misc.newId()

      defaults = [id: :unknown, label: "??", size: nil]
      {id, options, errors} = WxUtilities.getOptions(unquote(attributes), defaults)

      Logger.debug("  :button.new(#{inspect(parent)}, #{inspect(new_id)}, #{inspect(options)})")

      bt = :wxButton.new(parent, new_id, options)

      stack_push({container, bt, sizer})
      ret = unquote(block)
      stack_pop()

      Logger.debug("  button: ret = #{inspect(ret)}")

      case sizer do
        {:wx_ref, _, :wxBoxSizer, _} ->
          Logger.debug("  :wxBoxSizer.add(#{inspect(sizer)}, #{inspect(bt)}), []")
          :wxBoxSizer.add(sizer, bt, [{:flag, @wxALL}, {:proportion, 10}])

        {:wx_ref, _, :wxStaticBoxSizer, _} ->
          Logger.debug("  :wxBoxSizer.add(#{inspect(sizer)}, #{inspect(bt)}), []")
          :wxStaticBoxSizer.add(sizer, bt, [{:flag, @wxALL}, {:proportion, 10}])

          # xSizer:add(Sizer, ListBox, [{flag, ?wxEXPAND}])
      end

      WinInfo.insert({id, new_id, bt})

      Logger.debug("Button -----------------------------------------------------")
    end
  end

  defmacro button(attributes) do
    quote do
      Logger.debug("Button/1 +++++++++++++++++++++++++++++++++++++++++++++++++++++")

      {container, parent, sizer, indent} = stack_tos()
      Logger.debug("  tos = #{inspect(container)}, #{inspect(parent)}, #{inspect(sizer)}}")

      new_id = :wx_misc.newId()

      defaults = [id: :unknown, label: "??", size: nil, layout: []]
      {id, options, errors} = WxUtilities.getOptions(unquote(attributes), defaults)

      defaults = [label: "??", size: nil, layout: []]
      attrs = WxUtilities.getObjOpts(unquote(attributes), defaults)
      Logger.debug("  getObjOpts = #{inspect(attrs)}")

      layout = attrs[:layout]
      options = attrs[:options]

      #      {layout, options} =
      #        case List.keytake(options, :layout, 0) do
      #          {{_, layoutName}, options} -> {WxLayout.getLayout(layoutName), options}
      #          nil -> {[], options}
      #        end

      Logger.debug("  :layout = #{inspect(layout)}")

      Logger.debug(
        "  :button.new(#{inspect(container)}, #{inspect(new_id)}, #{inspect(options)})"
      )

      bt = :wxButton.new(parent, new_id, options)

      case sizer do
        {:wx_ref, _, :wxBoxSizer, _} ->
          Logger.debug("  :wxBoxSizer.add(#{inspect(sizer)}, #{inspect(bt)}, #{inspect(layout)})")

          # :wxBoxSizer.add(parent, bt, [{:flag, @wxALL}, {:proportion, 10}])
          :wxBoxSizer.add(sizer, bt, layout)

        {:wx_ref, _, :wxStaticBoxSizer, _} ->
          Logger.debug("  :wxBoxSizer.add(#{inspect(sizer)}, #{inspect(bt)}, #{inspect(layout)})")

          # :wxStaticBoxSizer.add(parent, bt, [{:flag, @wxALL}, {:proportion, 10}])
          :wxStaticBoxSizer.add(sizer, bt, layout)
      end

      WinInfo.insert({id, new_id, bt})

      Logger.debug("Button/1 -----------------------------------------------------")
    end
  end

  defmacro event(eventType) do
    quote do
      Logger.debug("Event ++++++++++++++++++++++++++++++++++++++++++++++++++")

      {container, parent, sizer, indent} = stack_tos()
      Logger.debug("  tos = #{inspect(container)}, #{inspect(parent)}, #{inspect(sizer)}}")

      # Logger.debug("  :wxEvtHandler.connect(#{inspect(parent)}, #{inspect(unquote(eventType))})")
      new_id = :wx_misc.newId()

      options = [
        # id: new_id,
        userData: __ENV__.module
      ]

      :wxEvtHandler.connect(container, unquote(eventType), options)

      Logger.debug(
        "  :wxEvtHandler.connect(#{inspect(container)}, #{inspect(unquote(eventType))}, #{
          inspect(options)
        }"
      )

      WinInfo.insert({unquote(eventType), new_id, nil})
      Logger.debug("Event  --------------------------------------------------")
    end
  end

  defmacro event(eventType, callBack) do
    quote do
      Logger.debug("Event ++++++++++++++++++++++++++++++++++++++++++++++++++")

      # WinInfo.insert({Map.get(opts, :id, :unknown), new_id, mi})
      put_info(var!(info, Dsl), unquote(eventType), unquote(callBack))

      # WinInfo.get_by_name( name)

      # put_info(eventType, callBack)
      # Agent.update(state, &Map.put(&1, unquote(eventType), unquote(callBack)))
      {container, parent, sizer, indent} = stack_tos()
      Logger.debug("  tos = #{inspect(container)}, #{inspect(parent)}, #{inspect(sizer)}}")
      new_id = :wx_misc.newId()

      options = [
        # id: new_id,
        callback: &WxFunctions.eventCallback/2,
        userData: __ENV__.module
      ]

      :wxEvtHandler.connect(container, unquote(eventType), options)

      WinInfo.insert({unquote(eventType), new_id, unquote(callBack)})
      Logger.debug("Event  --------------------------------------------------")
    end
  end

  @doc """
  Macro to set up the event connections for the window.
  The attributes consist of one of the following:
  {<event>: callback | nil, <option>: value, ...}

  event may be one of:
    :command_button_clicked
    :close_window
    :timeout                  # This is a function to be called repeatedly every
                              # n seconds where n is given by the :delay options
                              # in milliseconds (default 1000 (1 second))

  if a callback is supplied it must have arity 4.
  """
  defmacro events(attributes) do
    quote do
      Logger.debug("Events +++++++++++++++++++++++++++++++++++++++++++++++++++++")
      {container, parent, sizer, indent} = stack_tos()
      Logger.debug("  tos = {#{inspect(container)}, #{inspect(parent)}, #{inspect(sizer)}}")

      Logger.debug("  events: #{inspect(unquote(attributes))}")

      # frame = WinInfo.getWxObject(:__main_frame__)
      frame = parent
      WxEvents.setEvents(__ENV__.module, frame, unquote(attributes))
      Logger.debug("Events -----------------------------------------------------")
    end
  end

  @doc """
  wxFrame(
    id:     Id of frame (Atom)
    title:  Title shown in title bar (String)
    pos:    Initial posititon of window ({x, y})
    size:   Initial size of window ({w, h})
    style:  Window style (?)
    )
  """
  defmacro wxFrame(attributes, do: block) do
    quote do
      # Logger.debug("Frame +++++++++++++++++++++++++++++++++++++++++++++++++++++")

      {container, parent, sizer, indent} = stack_tos()
      args_dict = Enum.into(unquote(attributes), %{})

      opts_list =
        Enum.filter(unquote(attributes), fn attr ->
          case attr do
            {:id, _} -> false
            {:title, _} -> false
            {:pos, {_, _}} -> true
            {:size, {_, _}} -> true
            {:style, _} -> true
            {:name, _} -> false
            {arg, argv} -> error(indent, "Illegal option #{inspect(arg)}: #{inspect(argv)}")
          end
        end)

      frame =
        :wxFrame.new(
          container,
          # window id
          @wxID_ANY,
          # window title
          Map.get(args_dict, :title, "No title"),
          opts_list
          # [{:size, Map.get(opts, :size, {600, 400})}]
        )

      debug(
        indent,
        "#{inspect(Map.get(args_dict, :id, "No Id"))} = :wxFrame.new(#{
          inspect(getObjectId(container))
        }, #{inspect(@wxID_ANY)}, #{inspect(Map.get(args_dict, :title, "No title"))},#{
          inspect(opts_list)
        })"
      )

      WinInfo.insertObject(Map.get(args_dict, :id, :noname), frame, parent)
      stack_push({frame, frame, nil, indent + 2})
      child = unquote(block)
      stack_pop()

      case child do
        {:wx_ref, _, :wxBoxSizer, _} ->
          debug(
            indent,
            ":wxFrame.setSizer(#{inspect(getObjectId(frame))}, #{inspect(getObjectId(child))})"
          )

          :wxFrame.setSizer(frame, child)

        nil ->
          warn(indent, "Frame has no children!")

        _ ->
          debug(indent, "Frame child was not sizer: #{inspect(child)}")
          nil
      end

      # Logger.debug("Frame -----------------------------------------------------")
      frame
    end
  end

  defmacro htmlWindow(attributes) do
    quote do
      Logger.debug("htmlWindow/1 +++++++++++++++++++++++++++++++++++++++++++++++++++++")

      {container, parent, sizer, indent} = stack_tos()
      Logger.debug("  tos = {#{inspect(parent)}, #{inspect(container)}, #{inspect(sizer)}}")

      defaults = [style: nil, size: nil]
      {id, options, restOpts} = getOptions(unquote(attributes), defaults)

      new_id = :wx_misc.newId()

      Logger.debug(
        "  :wxHtmlWindow.new(#{inspect(parent)}, #{inspect(new_id)}, #{inspect(options)}"
      )

      win = :wxHtmlWindow.new(parent, new_id, options)

      WinInfo.insert({id, new_id, win})

      WxSizer.addToSizer(win, sizer, restOpts)
      Logger.debug("htmlWindow/1 -----------------------------------------------------")
      win
    end
  end

  defmacro htmlWindow(attributes, do: block) do
    quote do
      Logger.debug("htmlWindow/2 +++++++++++++++++++++++++++++++++++++++++++++++++++++")

      {container, parent, sizer, indent} = stack_tos()

      {id, new_id, win} = WxHtmlWindow.new(parent, unquote(attributes))

      stack_push({container, win, sizer, indent + 2})
      unquote(block)
      stack_pop()

      WxSizer.add(win, sizer, unquote(attributes))

      Logger.debug("htmlWindow/2 -----------------------------------------------------")
      win
    end
  end

  defmacro layout(attributes) do
    quote do
      Logger.debug("layout ++++++++++++++++++++++++++++++++++++++++++++++++++")
      # Logger.debug("  layout(#{inspect(unquote(attributes))})")

      {id, {width, height}, flags} = WxLayout.getLayoutAttributes(unquote(attributes))

      case id do
        :_no_id_ -> :ok
        _ -> WinInfo.insert({id, {width, height}, flags})
      end

      Logger.debug("Layout ---------------------------------------------------")

      {width, height, flags}
    end
  end

  @doc """
  Create a WxListCtrl.

  | Parameter | Description                                                  | Value     | Default  |
  | --------- | ------------------------------------------------------------ | --------- | -------- |
  | id        | The id of the list control.                                  | atom()    | none     |
  | layout    | The layout to be applied when adding this control to the containing sizer. | list() | []|

  Example:

  ```
  ...
  boxSizer id: :outer_sizer, orient: @wxHORIZONTAL do
    layout1 = [proportion: 1, flag: @wxEXPAND ||| @wxALL, border: 5]

    listCtrl id: :list_ctrl_1, layout: layout1 do
      listCtrlCol(col: 0, heading: "Pid", width: 100)
      listCtrlCol(col: 1, heading: "Message Queue")
      listCtrlCol(col: 2, heading: "Heap")
    end
  end
  ...
  """
  defmacro listCtrl(attributes, do: block) do
    quote do
      Logger.debug("listCtrl/2 +++++++++++++++++++++++++++++++++++++++++++++++++++++")
      # new_id = :wx_misc.newId()
      {container, parent, sizer, indent} = stack_tos()

      defaults = [id: "_no_id_", style: nil, size: nil]
      {id, options, _restOpts} = getOptions(unquote(attributes), defaults)

      # options = [{:winid, new_id} | options]
      lc = WxListCtrl.new(parent, options)
      {:wx_ref, ctrlId, :wxListCtrl, data} = lc

      WinInfo.insert({id, ctrlId, lc})

      stack_push({container, lc, sizer})
      unquote(block)
      stack_pop()

      WxSizer.add(lc, sizer, unquote(attributes))

      Logger.debug("listCtrl/2 -----------------------------------------------------")
      lc
    end
  end

  @doc """
  Create a listCtrl column and add it to the containing list control.

  | Parameter | Description                   | Value     | Default  |
  | --------- | ------------------------------| --------- | -------- |
  | col       | The column to add.            | integer() | none     |
  | heading   | The column heading.           | string()  | ""       |

  Example:

  ```
  ...
  boxSizer id: :outer_sizer, orient: @wxHORIZONTAL do
    layout1 = [proportion: 1, flag: @wxEXPAND ||| @wxALL, border: 5]

    listCtrl id: :list_ctrl_1, layout: layout1 do
      listCtrlCol(col: 0, heading: "Pid", width: 100)
      listCtrlCol(col: 1, heading: "Message Queue")
      listCtrlCol(col: 2, heading: "Heap")
    end
  end
  ...
  """
  defmacro listCtrlCol(attributes) do
    quote do
      Logger.debug("listCtrlCol/2 +++++++++++++++++++++++++++++++++++++++++++++++++++++")

      {container, parent, sizer, indent} = stack_tos()

      defaults = [col: 0, heading: ""]
      {_, options, restOpts} = getOptions(unquote(attributes), defaults)

      col =
        case parent do
          {_, _, :wxListCtrl, _} ->
            col = WxListCtrl.newColumn(parent, options[:col], options[:heading], restOpts)
            # Logger.error("lcc = #{inspect(col)}")
            col

          _ ->
            Logger.error("Error listCtrlCol: Parent must be a list control")
            nil
        end

      parentName = WinInfo.getCtrlName(parent)
      colName = String.to_atom("#{Atom.to_string(parentName)}_col#{inspect(col)}")

      # id = :lcc
      # Logger.error("listCtrlCol = #{inspect(col)}")
      # new_id = 9999
      WinInfo.insertCtrl(
        colName,
        {:wx_ref, :wx_misc.newId(), :wxListCtrlCol, [col: col, listCtrl: parent]}
      )

      Logger.debug("listCtrlCol/2 -----------------------------------------------------")
    end
  end

  defmacro wxMenu(attributes, do: block) do
    quote do
      Logger.debug("  Menu +++++++++++++++++++++++++++++++++++++++++++++++++++++++")
      {container, parent, sizer, indent} = stack_tos()
      Logger.debug("  tos = #{inspect(container)}, #{inspect(parent)}, #{inspect(sizer)}}")

      opts = get_opts_map(unquote(attributes))

      mnu = :wxMenu.new()
      Logger.debug("  :wxMenu.new() => #{inspect(mnu)}")

      t = Map.get(opts, :text, "&????")

      stack_push({container, mnu, sizer})
      unquote(block)
      stack_pop()

      ret = :wxMenuBar.append(parent, mnu, t)

      Logger.debug(
        "  :wxMenuBar.append(#{inspect(parent)}, #{inspect(mnu)}, #{inspect(t)}) => #{
          inspect(ret)
        }"
      )

      Logger.debug("  Menu -------------------------------------------------------")
    end
  end

  defmacro wxMenuBar(do: block) do
    quote do
      Logger.debug("Menu Bar +++++++++++++++++++++++++++++++++++++++++++++++++++")

      {container, parent, sizer, indent} = stack_tos()
      Logger.debug("  tos = #{inspect(container)}, #{inspect(parent)}, #{inspect(sizer)}}")

      mb = :wxMenuBar.new()
      WinInfo.insertCtrl(:menu_bar, mb)
      Logger.debug("  :wxMenuBar.new() => #{inspect(mb)}")

      stack_push({container, mb, sizer})
      unquote(block)
      stack_pop()

      ret = :wxFrame.setMenuBar(parent, mb)
      Logger.debug("  :wxFrame.setMenuBar(#{inspect(parent)}, #{inspect(mb)}) => #{inspect(ret)}")

      Logger.debug("Menu Bar ---------------------------------------------------")
    end
  end

  defmacro wxMenuItem(attributes) do
    quote do
      Logger.debug("    Menu Item ++++++++++++++++++++++++++++++++++++++++++++++++++")
      {container, parent, sizer, indent} = stack_tos()
      Logger.debug("  tos = #{inspect(container)}, #{inspect(parent)}, #{inspect(sizer)}}")

      defaults = [id: :unknown, text: "??"]
      {id, options, errors} = WxUtilities.getOptions(unquote(attributes), defaults)

      new_id = :wx_misc.newId()

      Logger.debug("    New Menu Item: #{inspect(options)}")

      mi =
        :wxMenuItem.new([
          {:id, new_id},
          {:text, options[:text]}
        ])

      Logger.debug(
        "    :wxMenuItem.new([{:id, #{inspect(new_id)}}, {:text, #{inspect(options[:text])}}]) => #{
          inspect(mi)
        }"
      )

      WinInfo.insertCtrl(id, new_id, mi)

      ret = :wxMenu.append(parent, mi)
      Logger.debug("    :wxMenu.append(#{inspect(parent)}, #{inspect(mi)}) => #{inspect(ret)}")

      Logger.debug("    MenuItem  --------------------------------------------------")
    end
  end

  defmacro wxMenuRadioItem(attributes) do
    quote do
      Logger.debug("    Menu Item ++++++++++++++++++++++++++++++++++++++++++++++++++")
      {container, parent, sizer, indent} = stack_tos()
      Logger.debug("  tos = #{inspect(container)}, #{inspect(parent)}, #{inspect(sizer)}}")

      defaults = [id: :unknown, text: "??"]
      {id, options, errors} = WxUtilities.getOptions(unquote(attributes), defaults)

      new_id = :wx_misc.newId()

      Logger.debug("    New Menu Item: #{inspect(options)}")

      mi =
        :wxMenuItem.new([
          {:id, new_id},
          {:text, options[:text]},
          {:kind, @wxITEM_RADIO}
        ])

      Logger.debug(
        "    :wxMenuItem.new([{:id, #{inspect(new_id)}}, {:text, #{inspect(options[:text])}}]) => #{
          inspect(mi)
        }"
      )

      # WinInfo.insertCtrl(id, mi)
      WinInfo.insertCtrl(id, new_id, mi)

      ret = :wxMenu.append(parent, mi)
      Logger.debug("    :wxMenu.append(#{inspect(parent)}, #{inspect(mi)}) => #{inspect(ret)}")

      Logger.debug("    MenuItem  --------------------------------------------------")
    end
  end

  defmacro wxMenuSeparator() do
    quote do
      Logger.debug("    Menu Separator +++++++++++++++++++++++++++++++++++++++++")
      {container, parent, sizer, indent} = stack_tos()
      Logger.debug("  tos = #{inspect(container)}, #{inspect(parent)}, #{inspect(sizer)}}")

      new_id = :wx_misc.newId()

      Logger.debug("    New Menu Separator")

      :wxMenu.appendSeparator(parent)

      # put_info(Map.get(opts, :id, :unknown), mi)
      # put_xref(new_id, Map.get(opts, :id, :unknown))

      Logger.debug("    Menu Separator  ----------------------------------------")
    end
  end

  defmacro wxPanel(attributes, do: block) do
    quote do
      # Logger.debug("Panel +++++++++++++++++++++++++++++++++++++++++++++++++++++")
      {container, parent, sizer, indent} = stack_tos()

      defaults = [id: "_no_id_", pos: nil, size: nil, style: nil]
      {id, options, restOpts} = getOptions(unquote(attributes), defaults)

      new_id = :wx_misc.newId()
      args_dict = Enum.into(unquote(attributes), %{})

      opts_list =
        Enum.filter(unquote(attributes), fn attr ->
          case attr do
            {:id, _} -> false
            {:pos, {_, _}} -> true
            {:size, {_, _}} -> true
            {:style, _} -> true
            {arg, argv} -> Logger.error("    Illegal option #{inspect(arg)}: #{inspect(argv)}")
          end
        end)

      panel = :wxPanel.new(parent, options)

      debug(
        indent,
        "#{inspect(id)} = :wxPanel.new(#{inspect(getObjectId(parent))}, #{inspect(options)})"
      )

      WinInfo.insertObject(id, panel, parent)

      stack_push({container, panel, sizer, indent + 2})
      child = unquote(block)
      # info(indent, "wxPanel child = #{inspect(child)}")
      stack_pop()

      case child do
        {:wx_ref, _, :wxBoxSizer, _} ->
          debug(indent, ":wxPanel.setSizer(#{inspect(id)}, #{inspect(getObjectId(child))}))")
          :wxPanel.setSizer(panel, child)

        {:wx_ref, _, :wxStaticBoxSizer, _} ->
          debug(indent, ":wxPanel.setSizer(#{inspect(id)}, #{inspect(getObjectId(child))}))")
          :wxPanel.setSizer(panel, child)

        _ ->
          warn(indent, "Panel: Child is: #{inspect(child)}")
      end

      # Logger.debug("panel -----------------------------------------------------")
    end
  end

  @doc """
  Create a WxListCtrl.

  | Parameter | Description                                                  | Value     | Default  |
  | --------- | ------------------------------------------------------------ | --------- | -------- |
  | id        | The id of the list control.                                  | atom()    | none     |
  | layout    | The layout to be applied when adding this control to the containing sizer. | list() | []|

  Example:

  ```
  ...
  boxSizer id: :outer_sizer, orient: @wxHORIZONTAL do
    layout1 = [proportion: 1, flag: @wxEXPAND ||| @wxALL, border: 5]

    listCtrl id: :list_ctrl_1, layout: layout1 do
      listCtrlCol(col: 0, heading: "Pid", width: 100)
      listCtrlCol(col: 1, heading: "Message Queue")
      listCtrlCol(col: 2, heading: "Heap")
    end
  end
  ...
  """
  defmacro report(attributes, do: block) do
    quote do
      Logger.debug("listCtrl/2 +++++++++++++++++++++++++++++++++++++++++++++++++++++")
      # new_id = :wx_misc.newId()
      {container, parent, sizer, indent} = stack_tos()
      defaults = [id: "_no_id_", style: nil, size: nil]
      {id, options, _restOpts} = getOptions(unquote(attributes), defaults)

      lc = WxReport.new(parent, options)
      {:wx_ref, ctrlId, :wxListCtrl, data} = lc

      WinInfo.insert({id, ctrlId, lc})

      stack_push({container, lc, sizer})
      unquote(block)
      stack_pop()

      WxSizer.add(lc, sizer, unquote(attributes))

      Logger.debug("listCtrl/2 -----------------------------------------------------")
      lc
    end
  end

  @doc """
  Create a listCtrl column and add it to the containing list control.

  | Parameter | Description                   | Value     | Default  |
  | --------- | ------------------------------| --------- | -------- |
  | col       | The column to add.            | integer() | none     |
  | heading   | The column heading.           | string()  | ""       |

  Example:

  ```
  ...
  boxSizer id: :outer_sizer, orient: @wxHORIZONTAL do
    layout1 = [proportion: 1, flag: @wxEXPAND ||| @wxALL, border: 5]

    listCtrl id: :list_ctrl_1, layout: layout1 do
      listCtrlCol(col: 0, heading: "Pid", width: 100)
      listCtrlCol(col: 1, heading: "Message Queue")
      listCtrlCol(col: 2, heading: "Heap")
    end
  end
  ...
  """
  defmacro reportCol(attributes) do
    quote do
      Logger.debug("listCtrlCol/2 +++++++++++++++++++++++++++++++++++++++++++++++++++++")

      {container, parent, sizer, indent} = stack_tos()
      defaults = [col: 0, heading: ""]
      {_, options, restOpts} = getOptions(unquote(attributes), defaults)

      col =
        case parent do
          {_, _, :wxListCtrl, _} ->
            WxReport.newColumn(parent, options[:col], options[:heading], restOpts)

          _ ->
            Logger.error("Error listCtrlCol: Parent must be a list control")
            nil
        end

      parentName = WinInfo.getCtrlName(parent)
      colName = String.to_atom("#{Atom.to_string(parentName)}_col#{inspect(col)}")

      WinInfo.insertCtrl(
        colName,
        {:wx_ref, :wx_misc.newId(), :wxListCtrlCol, [col: col, listCtrl: parent]}
      )

      Logger.debug("listCtrlCol/2 -----------------------------------------------------")
    end
  end


  @doc """
  wxSplitterWindow(
    id:     Id of frame (Atom)
    title:  Title shown in title bar (String)
    pos:    Initial posititon of window ({x, y})
    size:   Initial size of window ({w, h})
    style:  Window style (?)
    )
  """
  defmacro wxSplitterWindow(attributes, do: block) do
    quote do
      # Logger.debug("wxSplitterWindow +++++++++++++++++++++++++++++++++++++++++++++++++++")

      {container, parent, sizer, indent} = stack_tos()

      defaults = []
      defaults = [style: @wxSP_NOBORDER]
      {id, options, restOpts} = getOptions(unquote(attributes), defaults)

      splitter = :wxSplitterWindow.new(parent, options)

      debug(
        indent,
        "#{inspect(restOpts[:id])} = :wxSplitterWindow.new(#{inspect(getObjectId(parent))}, #{
          inspect(options)
        })"
      )

      case restOpts[:sashGravity] do
        nil ->
          debug(indent, "No sash gravity")

        g ->
          :wxSplitterWindow.setSashGravity(splitter, g)

          debug(
            indent,
            ":wxSplitterWindow.setSashGravity(#{inspect(restOpts[:id])}, #{inspect(g)})"
          )
      end

      case restOpts[:minPanelSize] do
        nil ->
          debug(indent, "No minimum panel size")

        mps ->
          :wxSplitterWindow.setMinimumPaneSize(splitter, mps)

          debug(
            indent,
            ":wxSplitterWindow.setMinimumPaneSize(#{inspect(restOpts[:id])}, #{inspect(mps)})"
          )
      end

      WinInfo.insertObject(restOpts[:id], splitter, parent)

      stack_push({container, splitter, sizer, indent + 2})
      unquote(block)
      stack_pop()

      # info(indent, "wins = #{inspect(getObjectsByParent(splitter))}")
      children = getObjectsByParent(splitter)
      # info(indent, "#{inspect(getObjectsByParent(children))}")

      case length(children) do
        0 ->
          error(indent, "Splitter window has no children!")

        1 ->
          error(indent, "Splitter window needs 2 children, has only one!")

        2 ->
          {child1, rest} = List.pop_at(children, 0)
          {child2, _} = List.pop_at(rest, 0)

          splitOpts =
            case restOpts[:sashPosition] do
              nil -> []
              _ -> [{:sashPosition, restOpts[:sashPosition]}]
            end

          case restOpts[:split] do
            @wxHORIZONTAL ->
              debug(
                indent,
                ":wxSplitterWindow.splitHorizontally(#{inspect(getObjectId(splitter))}, #{
                  inspect(getObjectId(child1))
                }, #{inspect(getObjectId(child2))})"
              )

              :wxSplitterWindow.splitHorizontally(splitter, child1, child2, splitOpts)

            @wxVERTICAL ->
              debug(
                indent,
                ":wxSplitterWindow.splitVertically(#{inspect(getObjectId(splitter))}, #{
                  inspect(getObjectId(child1))
                }, #{inspect(getObjectId(child2))})"
              )

              :wxSplitterWindow.splitVertically(splitter, child1, child2, splitOpts)

            _ ->
              error(
                indent,
                "Splitter window split: Invalid argument: #{inspect(restOpts[:split])}"
              )
          end

          debug(
            indent,
            ":wxSplitterWindow.splitVertically(#{inspect(getObjectId(splitter))}, #{
              inspect(getObjectId(child1))
            }, #{inspect(getObjectId(child2))})"
          )

          :wxSplitterWindow.splitVertically(splitter, child1, child2)

        _ ->
          error(
            indent,
            "Splitter window needs 2 children, #{inspect(length(children))} supplied!"
          )
      end

      # Logger.debug("wxSplitterWindow ---------------------------------------------------")
      splitter
    end
  end

  # defmacro splitVertically(splitter, win1, win2) do
  #   quote do
  #     Logger.debug("splitVertically ++++++++++++++++++++++++++++++++++++++++++++++++++")
  #     splitter = WinInfo.getWxObject(unquote(splitter))
  #     win1 = WinInfo.getWxObject(unquote(win1))
  #     win2 = WinInfo.getWxObject(unquote(win2))
  #
  #     # parent = :wxWindow.getParent(win1)
  #     # Logger.debug("  Parent = #{inspect(parent)}")
  #
  #     Logger.debug(
  #       "  :wxSplitterWindow.splitVertically(#{inspect(splitter)}, #{inspect(win1)}, #{
  #         inspect(win2)
  #       })"
  #     )
  #
  #     :wxSplitterWindow.splitVertically(splitter, win1, win2)
  #     Logger.debug("splitVertically  --------------------------------------------------")
  #   end
  # end

  def setEvents(events) do
    Logger.debug("setEvents ++++++++++++++++++++++++++++++++++++++++++++++++++")
    setEvents(events, WinInfo.getWxObject(:__main_frame__))
    Logger.debug("setEvents  --------------------------------------------------")
  end

  def setEvents([], _) do
    :ok
  end

  def setEvents([event | events], parent) do
    case event do
      {:timeout, _func} ->
        :ok

      {evt, nil} ->
        options = [userData: __ENV__.module]
        :wxEvtHandler.connect(parent, evt, options)

      {evt, _callback} ->
        options = [userData: __ENV__.module]
        :wxEvtHandler.connect(parent, evt, options)
        # {evt, callback, options} -> options = [{userData: window} | options]
        #                        :wxEvtHandler.connect(parent, evt, options)
    end

    setEvents(events, parent)
  end

  @doc """
  A wxBoxSizer can lay out its children either vertically or horizontally, depending
  on what flag is being used in its constructor.

  When using a vertical sizer, each child can be centered, aligned to the right
  or aligned to the left.

  Correspondingly, when using a horizontal sizer, each child can be centered,
  aligned at the bottom or aligned at the top.

  The stretch factor is used for the main orientation, i.e. when using a
  horizontal box sizer, the stretch factor determines how much the child can be
  stretched horizontally.

  | option      | Description                                             | Value     | Default   |
  | ----------- | ------------------------------------------------------- | --------- | --------- |
  | id          | The name by which the box sizer will be referred to.    | atom()    | none      |
  | :orient     | Orientation: @wxVERTICAL or @wxHORIZONTAL               | integer() |@wxVERTICAL|
  | :proportion | The proportion that the enclosed object will be resized | integer() | 1         |
  |             | (stretched) when the enclosing control is resized.      |           |           |
  |             | 0 - No resizing                                         |           |           |
  |             | 1 - In proportion                                       |           |           |
  |             | n - 1:n                                                 |           |           |
  | :flag       | @wxEXPAND: Make stretchable                             | integer() | @wxEXPAND |
  |             | @wxALL:    Make a border all around                     |           |           |
  | :border     | Width of the border                                     | integer() | 0         |
  Example:

  ```
  wxBoxSizer(
    id: :txt1sizer,
    orient: @wxVERTICAL,
    proportion: 1,
    flag: @wxEXPAND,
    border: 0
  ) do

  ...

  end


  """
  defmacro wxStaticBoxSizer(attributes, do: block) do
    quote do
      # Logger.debug("Static Box Sizer ++++++++++++++++++++++++++++++++++++++++++++++++++")
      {container, parent, sizer, indent} = stack_tos()

      # Get the function attributes
      defaults = [
        id: nil,
        label: "",
        orient: @wxHORIZONTAL,
        proportion: 1,
        flag: @wxEXPAND,
        border: 0,
        minSize: nil
      ]

      {id, opts, errs} = getOptions(unquote(attributes), defaults)

      if length(errs) > 0 do
        warn(indent, "Unexpected option(s): #{inspect(errs)}")
      end

      bs = :wxStaticBoxSizer.new(opts[:orient], parent, label: opts[:label])
      WinInfo.insertObject(id, bs, parent)

      debug(
        indent,
        "#{inspect(getObjectId(bs))} = :wxStaticBoxSizer.new(#{inspect(opts[:orient])})"
      )

      stack_push({container, parent, bs, indent + 2})
      child = unquote(block)
      stack_pop()

      case child do
        nil ->
          warn(indent, "wxStaticBoxSizer has no children!")

        child ->
          :wxBoxSizer.add(bs, child,
            proportion: opts[:proportion],
            flag: opts[:flag],
            border: opts[:border]
          )

          debug(
            indent,
            ":wxStaticBoxSizer.add(#{inspect(id)}, #{inspect(getObjectId(child))}, proportion: #{
              inspect(opts[:proportion])
            }, flag: #{inspect(opts[:flag])}, border: #{inspect(opts[:border])}"
          )
      end

      case parent do
        {:wx_ref, _, :wxFrame, _} ->
          debug(
            indent,
            ":wxStaticBoxSizer.setSizeHints(#{inspect(id)}, #{inspect(getObjectId(parent))})"
          )

          :wxStaticBoxSizer.setSizeHints(bs, parent)

        _ ->
          nil
      end

      case opts[:minSize] do
        nil ->
          nil

        _ ->
          debug(
            indent,
            ":wxStaticBoxSizer.setMinSize(#{inspect(id)}, #{inspect(opts[:minSize])}"
          )

          :wxStaticBoxSizer.setMinSize(bs, opts[:minSize])
      end

      # Logger.debug("boxSizer ---------------------------------------------------")
      bs
    end
  end

  @doc """
  Create a new box sizer.

  """
  defmacro wxStaticBoxSizerxxx(attributes, do: block) do
    quote do
      Logger.debug("Static Box Sizer ++++++++++++++++++++++++++++++++++++++++++++++++++")
      {container, parent, sizer, indent} = stack_tos()
      Logger.debug("   tos = #{inspect(container)}, #{inspect(parent)}, #{inspect(sizer)}}")

      opts = get_opts_map(unquote(attributes))

      Logger.debug("  opts = #{inspect(opts)}")

      Logger.debug("  :wxStaticBoxSizer.new(#{inspect(Map.get(opts, :orient, @wxHORIZONTAL))})")

      bs =
        :wxStaticBoxSizer.new(Map.get(opts, :orient, @wxHORIZONTAL), parent,
          label: Map.get(opts, :label, "")
        )

      # :wxSizer.insertSpacer(bs, 9999, 20)

      stack_push({container, parent, bs})
      unquote(block)
      stack_pop()

      case sizer do
        {:wx_ref, _, :wxStaticBoxSizer, _} ->
          Logger.debug("  :wxBoxSizer.add(#{inspect(sizer)}, #{inspect(bs)}), []")
          :wxBoxSizer.add(sizer, bs)

        {:wx_ref, _, :wxBoxSizer, _} ->
          Logger.debug("  :wxBoxSizer.add(#{inspect(sizer)}, #{inspect(bs)}), []")
          :wxBoxSizer.add(sizer, bs)

        nil ->
          case parent do
            {:wx_ref, _, :wxPanel, []} ->
              Logger.debug("  :wxPanel.setSizer(#{inspect(parent)}, #{inspect(bs)})")
              :wxPanel.setSizer(parent, bs)

            {:wx_ref, _, :wxFrame, []} ->
              Logger.debug("  :wxWindow.setSizer(#{inspect(parent)}, #{inspect(bs)})")
              # :wxFrame.setSizerAndFit(parent, bs)
              :wxWindow.setSizer(parent, bs)

            {:wx_ref, _, :wxSplitterWindow, []} ->
              Logger.debug("  :wxWindow.setSizer(#{inspect(parent)}, #{inspect(bs)})")
              # :wxFrame.setSizerAndFit(parent, bs)
              :wxWindow.setSizer(parent, bs)

            other ->
              Logger.error("  BoxSizer: No parent = #{inspect(parent)}")
          end

        other ->
          Logger.error("  BoxSizer: sizer = #{inspect(sizer)}")
      end

      Logger.debug("Static Box Sizer ---------------------------------------------------")
    end
  end

  defmacro staticText(attributes) do
    quote do
      Logger.debug("staticText/1 +++++++++++++++++++++++++++++++++++++++++++++++++++++")
      {container, parent, sizer, indent} = stack_tos()
      Logger.debug("  tos = #{inspect(container)}, #{inspect(parent)}, #{inspect(sizer)}}")

      attributes = unquote(attributes)
      Logger.debug("  attributes=#{inspect(attributes)}")

      new_id = :wx_misc.newId()

      attrs = get_opts_map(attributes)

      options =
        Enum.filter(attributes, fn attr ->
          case attr do
            {:xxx, _} ->
              true

            _ ->
              Logger.debug("  invalid attribute")
              false
          end
        end)

      Logger.debug("  :wxStaticText.new(#{inspect(container)}, 1001, #{inspect(options)})")
      st = :wxStaticText.new(parent, new_id, Map.get(attrs, :text, "no text"), [])

      case sizer do
        {:wx_ref, _, :wxBoxSizer, _} ->
          Logger.debug("  :wxBoxSizer.add(#{inspect(sizer)}, #{inspect(st)}), []")
          :wxBoxSizer.add(sizer, st, [])

        {:wx_ref, _, :wxStaticBoxSizer, _} ->
          Logger.debug("  :wxBoxSizer.add(#{inspect(sizer)}, #{inspect(st)}), []")
          :wxStaticBoxSizer.add(sizer, st, [])
      end

      # WinInfo.insert({Map.get(attrs, :id, nil), new_id, st})
      WinInfo.insertCtrl(Map.get(attrs, :id, :none), st)

      # put_info(Map.get(attrs, :id, :unknown), st)
      # put_xref(new_id, Map.get(attrs, :id, :unknown))

      Logger.debug("staticText/1 -----------------------------------------------------")
    end
  end

  @doc """
  Add a status bar to the enclosing frame.

  | attributes | Description                                                  | Value     | Default                |
  | ---------- | ------------------------------------------------------------ | --------- | ---------------------- |
  | number     | The number of fields to create. Specify a value greater than 1 to create a multi-field status bar.| atom()    | modulename             |
  | style       | The status bar style.                                       | integer() | 1             |
  | text     | The initial status bar text                                    | string()
                                                                                list of strings        | []                     |

  Example:

  ```
  statusBar(title: "ElixirWx Menu Test")
  ```
  """
  defmacro statusBar(attributes) do
    quote do
      Logger.debug("Status Bar +++++++++++++++++++++++++++++++++++++++++++++++++")
      {container, parent, sizer, indent} = stack_tos()
      Logger.debug("  tos = #{inspect(container)}, #{inspect(parent)}, #{inspect(sizer)}}")

      {id, new_id, sb} = WxStatusBar.new(parent, unquote(attributes))

      # WinInfo.insert({id, new_id, sb})
      WinInfo.insertCtrl(id, sb)

      Logger.debug("Status Bar -------------------------------------------------")
    end
  end

  defmacro styledTextControl(attributes, do: block) do
    quote do
      Logger.debug("styledTextWindow/2 +++++++++++++++++++++++++++++++++++++++++++++++++++++")

      {container, parent, sizer, indent} = stack_tos()

      {id, new_id, win} = WxStyledTextCtrl.new(parent, unquote(attributes))

      stack_push({container, win, sizer, indent + 2})
      unquote(block)
      stack_pop()

      WxSizer.add(win, sizer, unquote(attributes))

      Logger.debug("styledTextWindow/2 -----------------------------------------------------")
      win
    end
  end

  defmacro scrolledWindow(attributes, do: block) do
    quote do
      Logger.debug("scrolledWindow/2 +++++++++++++++++++++++++++++++++++++++++++++++++++++")

      {container, parent, sizer, indent} = stack_tos()
      Logger.debug("  tos = {#{inspect(parent)}, #{inspect(container)}, #{inspect(sizer)}}")

      # to be done
      defaults = []
      {id, options, restOpts} = getOptions(unquote(attributes), defaults)

      defaults = [scrollRate: nil]
      {id, options, restOpts} = getOptions(unquote(attributes), defaults)

      new_id = :wx_misc.newId()

      Logger.debug("  :wxWindow.new(#{inspect(parent)}, #{inspect(new_id)}, #{inspect(options)}")

      # win = :wxWindow.new(parent, new_id, options)

      win = :wxScrolledWindow.new(parent, [])
      :wxScrolledWindow.setScrollRate(win, 5, 5)

      WinInfo.insert({id, new_id, win})

      stack_push({container, win, sizer, indent + 2})
      unquote(block)
      stack_pop()

      WxSizer.addToSizer(win, sizer, restOpts)
      Logger.debug("scrolledWindow/2 -----------------------------------------------------")
      win
    end
  end

  defmacro wxTextCtrl(attributes) do
    quote do
      # Logger.debug("textControl/1 +++++++++++++++++++++++++++++++++++++++++++++++++++++")

      {container, parent, sizer, indent} = stack_tos()

      new_id = :wx_misc.newId()
      attributes = unquote(attributes)

      attrs = get_opts_map(attributes)

      options =
        Enum.filter(attributes, fn attr ->
          case attr do
            {:value, _} ->
              true

            {:size, _} ->
              true

            {:pos, _} ->
              true

            {:style, _} ->
              true

            {:id, _} ->
              false

            _ ->
              Logger.debug("  textCtrl: invalid attribute")
              false
          end
        end)

      tc = :wxTextCtrl.new(parent, new_id, options)
      WinInfo.insertObject(Map.get(attrs, :id, nil), tc, parent)

      debug(
        indent,
        "#{inspect(getObjectId(tc))} = :wxTextCtrl.new(#{inspect(getObjectId(parent))}, new_id, #{
          inspect(options)
        })"
      )

      # Logger.debug("textControl/1 -----------------------------------------------------")
      tc
    end
  end

  defmacro wxTextCtrl() do
    quote do
      # Logger.debug("textControl/1 +++++++++++++++++++++++++++++++++++++++++++++++++++++")

      {container, parent, sizer, indent} = stack_tos()

      tc = :wxTextCtrl.new(parent, -1, [])
      WinInfo.insertObject(nil, tc, parent)

      debug(
        indent,
        "wxTextCtrl = :wxTextCtrl.new(#{inspect(getObjectId(parent))}, -1, [])"
      )

      # Logger.debug("textControl/1 -----------------------------------------------------")
      tc
    end
  end

  defmacro tool(attributes) do
    quote do
      Logger.debug("  Tool +++++++++++++++++++++++++++++++++++++++++++++++++++++++")
      {container, parent, sizer, indent} = stack_tos()
      Logger.debug("  tos = #{inspect(container)}, #{inspect(parent)}, #{inspect(sizer)}}")

      defaults = [id: :unknown, bitmap: nil, icon: nil, png: nil]
      {id, options, errors} = WxUtilities.getOptions(unquote(attributes), defaults)

      new_id = :wx_misc.newId()

      path = Path.expand(Path.dirname(__ENV__.file) <> "/../")
      Logger.debug("  path: #{inspect(path)}")

      options =
        Enum.filter(options, fn attr ->
          case attr do
            {:bitmap, fileName} ->
              Logger.debug("  BITMAP")
              fileName = Path.expand(path <> "/" <> fileName)
              bitmap = :wxBitmap.new(fileName)
              t = :wxToolBar.addTool(parent, new_id, bitmap)
              WinInfo.insert({id, new_id, t})
              false

            {:icon, fileName} ->
              fileName = Path.expand(path <> "/" <> fileName)
              Logger.debug("  :wxIcon.new(#{inspect(fileName)}, [{:type, @wxBITMAP_TYPE_ICO}])")
              icon = :wxIcon.new(fileName, [{:type, @wxBITMAP_TYPE_ICO}])
              Logger.debug("  :wxBitmap.new()")
              bitmap = :wxBitmap.new()
              Logger.debug("  :wxBitmap.copyFromIcon(#{inspect(bitmap)}, #{inspect(icon)})")
              :wxBitmap.copyFromIcon(bitmap, icon)

              Logger.debug(
                "  :wxToolBar.addTool(#{inspect(parent)}, #{inspect(new_id)}, #{inspect(bitmap)})"
              )

              t = :wxToolBar.addTool(parent, new_id, bitmap)
              WinInfo.insert({id, new_id, t})
              false

            {:png, fileName} ->
              fileName = Path.expand(path <> "/" <> fileName)
              bitmap = :wxBitmap.new()
              x = :wxBitmap.loadFile(bitmap, fileName, [{:type, @wxBITMAP_TYPE_PNG}])
              t = :wxToolBar.addTool(parent, new_id, bitmap)
              WinInfo.insert({id, new_id, t})
              false

            _ ->
              Logger.debug("  invalid attribute")
              false
          end
        end)

      Logger.debug("  Tool ---------------------------------------------------")
    end
  end

  defmacro toolBar(_attributes, do: block) do
    quote do
      Logger.debug("Tool Bar +++++++++++++++++++++++++++++++++++++++++++++++++++")

      {container, parent, sizer, indent} = stack_tos()
      Logger.debug("  tos = #{inspect(container)}, #{inspect(parent)}, #{inspect(sizer)}}")

      Logger.debug("  :wxFrame.createToolBar(#{inspect(parent)})")
      tb = :wxFrame.createToolBar(parent)

      stack_push({container, tb, sizer})
      unquote(block)
      stack_pop()

      Logger.debug("  :wxFrame.setToolBar(#{inspect(parent)}, #{inspect(tb)})")
      :wxFrame.setToolBar(parent, tb)

      Logger.debug("  :wxToolBar.realize(#{inspect(parent)})")
      :wxToolBar.realize(tb)

      Logger.debug("Tool Bar ---------------------------------------------------")
    end
  end

  @doc """
  Create a new window.

  | attributes | Description                                                  | Value     | Default                |
  | ---------- | ------------------------------------------------------------ | --------- | ---------------------- |
  | style      | The window Style.                                            | atom()    | modulename             |
  | size       | The initial size of the window.                              | atom()    | modulename             |
  | layout     | The window layout.                                           | list      | []                     |

  Example:

  ```
  window(style: @wxBORDER_SIMPLE, size: {50, 25},
        layout: [proportion: 0, flag: @wxEXPAND]) do
    bgColour(@wxBLACK)
  end
  ```
  """
  defmacro window(attributes, do: block) do
    quote do
      Logger.debug("Window/2 +++++++++++++++++++++++++++++++++++++++++++++++++++++")

      {container, parent, sizer, indent} = stack_tos()

      {id, new_id, win} = WxWindow.new(parent, unquote(attributes))

      stack_push({container, win, sizer, indent + 2})
      unquote(block)
      stack_pop()

      WxSizer.add(win, sizer, unquote(attributes))

      Logger.debug("Window/2 -----------------------------------------------------")
      win
    end
  end

  defmacro window(attributes) do
    quote do
      Logger.debug("Window/1 +++++++++++++++++++++++++++++++++++++++++++++++++++++")

      {container, parent, sizer, indent} = stack_tos()
      Logger.debug("  tos = {#{inspect(parent)}, #{inspect(container)}, #{inspect(sizer)}}")

      defaults = [style: nil, size: nil]
      {id, options, restOpts} = getOptions(unquote(attributes), defaults)

      new_id = :wx_misc.newId()

      Logger.debug("  :wxWindow.new(#{inspect(parent)}, #{inspect(new_id)}, #{inspect(options)}")
      win = :wxWindow.new(parent, new_id, options)

      WinInfo.insert({id, new_id, win})

      WxSizer.addToSizer(win, sizer, restOpts)
      Logger.debug("Window/1 -----------------------------------------------------")
      win
    end
  end

  # ==============================================================================
  # if condition is true newValue is returned else originalValue
  def replaceIfTrue(originalValue, condition, newValue) do
    if condition do
      newValue
    else
      originalValue
    end
  end

  def get_opts_map(opts) do
    get_opts_map(opts, [])
  end

  def get_opts_map([], opts) do
    Enum.into(opts, %{})
  end

  def get_opts_map([next | attrs], args) do
    get_opts_map(attrs, [next | args])
  end

  # LOGGING
  def info(pad, str) do
    Logger.info(String.pad_leading(str, String.length(str) + pad))
  end

  def warn(pad, str) do
    Logger.warn(String.pad_leading(str, String.length(str) + pad))
  end

  def error(pad, str) do
    Logger.error(String.pad_leading(str, String.length(str) + pad))
  end

  def debug(pad, str) do
    Logger.debug(String.pad_leading(str, String.length(str) + pad))
  end
end
