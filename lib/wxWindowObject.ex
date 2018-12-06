defmodule WxWinObj do
  use GenServer
  require Logger

  @moduledoc """
  This object creates, encapsulates and provides an interface to a window.
  """

  ## Client API ----------------------------------------------------------------
  @doc """
  Create and optionally show a window.

  - **windowSpec**: The name of the module containing the window specification (see WxDsl).
  - **evtHandler**: The name of th emodule containing the event handling code.
  - **options**: Options when creating a window.They can be:
    * _show:_ Bool, Show the window when created(default)
    * _name:_ The name that the window will be registered with. if a name is not supplied
    or is nil, then the name of the module containing the winowSpec will be used to register the window.

    ```
    start_link(MyWindow, MyWindowEvents, show: true, name: MyWindow)
    ```
  """
  def start_link(windowSpec, windowLogic, options \\ []) when is_atom(windowSpec) do
    GenServer.start_link(__MODULE__, {self(), windowSpec, windowLogic, options})
  end

  @doc """
  See start_link()
  """
  def start(windowSpec, windowLogic, options \\ []) when is_atom(windowSpec) do
    GenServer.start_link(__MODULE__, {self(), windowSpec, windowLogic, options})
  end

  @doc """
  Show the specified window.
  ```
  show(pid)
  ```
  """
  def show(window) do
    GenServer.cast(window, {:show, true})
  end

  @doc """
  Hide the specified window.
  ```
  hide(window)
  ```
  """
  def hide(window) do
    GenServer.cast(window, {:show, false})
  end

  @doc """
  Set the given attribute value.

  window: Atom; The name of the window (see start_link())
  obj: Atom; The name of the window element.
  attr: Atom; The name of the attribute to be retrieved
  value: Term; The value to set the attribute to.
  ```
  setAttr(:my_window, :ok_button, :size, {100, 200})
  ```
  """
  def setAttr(window, obj, attr, value) do
    GenServer.cast(window, {:set, {obj, attr, value}})
  end

  @doc """
  Get the given attribute value.

  window: Atom; The name of the window (see start_link())
  obj: Atom; The name of the window element.
  attr: Atom; The name of the attribute to be retrieved

  returns the value of the attribute.

  ```
  getAttr(:my_window, :ok_button, :text)
  ```
  """
  def getAttr(window, obj, attr) do
    GenServer.call(window, {:get, {obj, attr}})
  end

  @doc """
  Set the status bar text.
  """
  def statusBarText(pid, text, index \\ 0) when is_binary(text) or is_list(text) do
    GenServer.cast(pid, {:statusBarText, text, index})
  end

  ## Server Callbacks ----------------------------------------------------------
  @impl true
  def init({parent, windowSpec, windowLogic, options}) do
    Process.monitor(parent)

    Logger.debug("Window Logic = #{inspect(windowLogic)}")

    name =
      case options[:name] do
        nil ->
          windowSpec

        name ->
          Process.register(self(), name)
          name
      end

    # Check that the window definition file exists
    windowSpec =
      case Code.ensure_loaded(windowSpec) do
        {:error, :nofile} ->
          Logger.error("No such window specification: #{inspect(windowSpec)}")
          nil

        # {:stop, "No such module: #{inspect(window)}"}
        {:module, _} ->
          windowSpec
      end

    # Check that the windowLogic definition file exists. It may be null
    # if we dont want to handle any events.
    {windowLogic, logic_fns} =
      case windowLogic do
        nil ->
          {nil, []}

        _ ->
          case Code.ensure_loaded(windowLogic) do
            {:error, :nofile} ->
              Logger.error("Window Logic: No such module: #{inspect(windowLogic)}")
              {nil, []}

            {:module, _} ->
              {windowLogic, windowLogic.module_info(:exports)}
          end
      end

    {action, state} =
      case {windowSpec, windowLogic, logic_fns} do
        {nil, _, _} ->
          {:stop, "No such module: #{inspect(windowSpec)}"}

        {windowSpec, nil, _} ->
          win = windowSpec.createWindow(show: options[:show])

          {:ok,
           [
             parent: parent,
             winName: name,
             winInfo: win,
             window: windowSpec,
             logic: nil,
             logic_fns: []
           ]}

        {windowSpec, windowLogic, logic_fns} ->
          win = windowSpec.createWindow(show: options[:show])

          {:ok,
           [
             parent: parent,
             winName: name,
             winInfo: win,
             window: windowSpec,
             logic: windowLogic,
             logic_fns: logic_fns
           ]}
      end

    # Logger.debug("State = #{inspect(state)}")

    # If there is an init() function in the logic module, call it. The init function
    # may change the action or state.
    {action, state, timeout} =
      case state[:logic_fns][:init] do
        nil ->
          Logger.info("#{inspect(state[:winName])} - no initialisation in logic}")
          {action, state, nil}

        0 ->
          # Code.eval_string("#{state[:logic]}.#{:init}()")
          case apply(state[:logic], :init, []) do
            {action, state, timeout} -> {action, state, timeout}
            {action, state} -> {action, state, nil}
            _ -> {action, state, nil}
          end

        1 ->
          # Code.eval_string("#{state[:logic]}.#{:init}()")
          case apply(state[:logic], :init, [{action, state}]) do
            {action, state, timeout} -> {action, state, timeout}
            {action, state} -> {action, state, nil}
            _ -> {action, state, nil}
          end

        # {action, state, timeout} = apply(state[:logic], init, [{action, state}])

        _ ->
          Logger.error("#{inspect(state[:winName])} - Window logic init takes no arguments")
      end

    case timeout do
      nil -> {action, state}
      _ -> {action, state, timeout}
    end

    # {action, state}
  end

  # Call interface ----
  @impl true
  def handle_call({:get, {_obj, attr}}, _from, state) do
    # attr = WxAttributes.getAttr(obj, attr)
    {:reply, attr, state}
  end

  # Cast interface ----
  @impl true
  def handle_cast({:push, item}, state) do
    {:noreply, [item | state]}
  end

  @impl true
  def handle_cast({:show, _how}, state) do
    Logger.info("Show!!")
    frame = WinInfo.getWxObject(:__main_frame__)
    :wxFrame.show(frame)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:set, {_obj, _attr, _val}}, state) do
    # WxAttributes.setAttr(obj, attr, val)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:statusBarText, text, index}, state) do
    Logger.info("Show!!: #{inspect(text)}, #{inspect(index)}")

    # WxWindow.show(how)
    {:noreply, state}
  end

  # Gen_server callbacks ---------------------------------------------------------
  @impl true
  def terminate(reason, msg) do
    Logger.debug("terminate: #{inspect(reason)}, #{inspect(msg)}")
  end

  @impl true
  def handle_info(:timeout, state) do
    case handlerExists(state, :do_timeout, 1) do
      true ->
        apply(state[:logic], :do_timeout, [state])

      false ->
        Logger.warn("No handler for handle_info(:timeout)")
        {:noreply, state}
    end
  end

  def handle_info({:wx, _, _, _, _} = evt, state) do
    WxWinObjEvt.handleWxEvent(evt, state)
  end

  # Handle Info
  def handle_info({_, _, _sender, _, {:wxClose, :close_window}}, state) do
    send(state[:parent], {state[:winName], :child_window_closed, "Close window event"})

    # WxFunctions.closeWindow(state[:window])
    frame = WinInfo.getWxObject(:__main_frame__)
    :wxEvtHandler.disconnect(frame)
    :wxWindow.destroy(frame)
    {:stop, :normal, "#{inspect(state[:winName])} - Close window event"}
  end

  # Menu event
  def handle_info(
        {_a, sender, _b, _c, {:wxCommand, :command_menu_selected, _d, _e, _f}},
        state
      ) do
    # Logger.debug(
    #   "Handle info: #{
    #     inspect({_a, sender, _b, _c, {:wxCommand, :command_menu_selected, _d, _e, _f}})
    #   }"
    # )

    ret =
      case handlerExists(state, :do_menu_click, 2) do
        true ->
          Logger.debug("handle_info command_menu_selected - get_by_id()")

          {name, _id, _obj} = WinInfo.get_by_id(sender)
          apply(state[:logic], :do_menu_click, [name, state])

        false ->
          Logger.warn("No handler for handle_info(:do_menu_click)")
          {:noreply, state}
      end

    ret
  end

  # Menu event
  def handle_info(
        {_, sender, _, _, {:wxCommand, :command_button_clicked, _, _, _}},
        state
      ) do
    case handlerExists(state, :do_button_click, 2) do
      true ->
        apply(state[:logic], :do_button_click, [sender, state])

      false ->
        Logger.warn("No handler for handle_info(:do_button_click)")
        {:noreply, state}
    end
  end

  # List Ctrl Click
  # {:wxList, :command_list_col_click, -1, -1, -1, 0, {51, -9}}}
  def handle_info(
        {_, sender, _, _, {:wxListx, :command_list_col_click, _, _, _, col, _}},
        state
      ) do
    case handlerExists(state, :do_command_list_col_click, 3) do
      true ->
        apply(state[:logic], :do_command_list_col_click, [sender, col, state])

      false ->
        Logger.warn("No handler for handle_info(:do_command_list_col_click)")
        {:noreply, state}
    end
  end

  # Child window closed event received
  def handle_info(
        {window, :child_window_closed, _reason},
        state
      ) do
    case handlerExists(state, :do_child_window_closed, 2) do
      true ->
        apply(state[:logic], :do_child_window_closed, [window, state])

      false ->
        Logger.warn("No handler for handle_info(:do_child_window_closed)")
        {:noreply, state}
    end
  end

  # Child window closed event received
  def handle_info(
        {:DOWN, _, :process, pid, how},
        state
      ) do
    parent = state[:parent]

    case pid == parent do
      true -> Logger.info("Parent window exited: #{inspect(how)}")
      false -> Logger.info("Window exit event caught: #{inspect(pid)}")
    end

    case handlerExists(state, :do_parent_window_closed, 2) do
      true ->
        apply(state[:logic], :do_parent_window_closed, [pid, state])

      false ->
        Logger.warn("No handler for handle_info(:do_parent_window_closed)")
        {:noreply, state}
    end

    invokeEventHandler(:do_parent_window_closed, pid, state)
    {:stop, :normal, "Parent died"}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.info("#{inspect(state[:winName])} - handle Info: #{inspect(msg)}, #{inspect(state)}")
    {:noreply, state}
  end

  # Helper functions ===========================================================
  defp invokeEventHandler(:child_window_closed, sender, state) do
    event = :child_window_closed

    case state[:logic_fns][event] do
      nil ->
        Logger.info(
          "#{inspect(state[:winName])} - unhandled #{inspect(event)} event from #{
            inspect(inspect(sender))
          }"
        )

      1 ->
        Code.eval_string("#{state[:logic]}.#{event}(#{inspect(sender)})")

      2 ->
        Logger.info("Eval: \"#{state[:logic]}.#{event}(#{inspect(sender)}, #{inspect(state)})\"")
        Code.eval_string("#{state[:logic]}.#{event}(#{inspect(sender)}, #{inspect(state)})")
    end
  end

  defp invokeEventHandler(event, sender, state) do
    {name, _id, _obj} = WinInfo.get_by_id(sender)
    Logger.error("invokeEventHandler - get_by_id()")

    case state[:logic_fns][event] do
      nil ->
        Logger.info(
          "#{inspect(state[:winName])} - unhandled #{event} event: #{inspect(inspect(name))}"
        )

      #      1 -> state[:handler].event.(sender)
      1 ->
        # Code.eval_string("#{state[:logic]}.#{event}(#{inspect(name)})")
        apply(state[:logic], event, [name])

      2 ->
        Logger.info("Eval2: \"#{state[:logic]}.#{event}(#{inspect(sender)}, #{inspect(state)})\"")
        Logger.info("State = #{inspect(state)}")
        apply(state[:logic], event, [name, state])
    end
  end

  # Check to see if a function of the correct arity exists in the logic module
  defp handlerExists(state, handler, arity) do
    case state[:logic_fns][handler] do
      nil ->
        false

      handlerArity ->
        cond do
          handlerArity != arity -> false
          true -> true
        end
    end
  end
end
