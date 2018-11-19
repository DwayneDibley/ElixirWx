defmodule WxWinObjEvt do
  require Logger

  @moduledoc """
  Events.
  """

  @doc """
  Menu event
  """
  def handleWxEvent({_, senderId, senderObj, [], event}, state) do
    # {:wx, 103, {:wx_ref, 36, :wxMenuBar, []}, [], {:wxCommand, :command_menu_selected, [], 1, 0}}
    case senderObj do
      {:wx_ref, _, :wxMenuBar, _} -> menuEvent(senderId, senderObj, event, state)
      {:wx_ref, _, :wxListCtrl, _} -> listCtrlEvent(senderId, senderObj, event, state)
      {:wx_ref, 35, :wxFrame, []} -> frameEvent(senderId, senderObj, event, state)
    end
  end

  @doc """
  Handle a menu event, sent by the menu bar.
  """
  def frameEvent(senderId, senderObj, event, state) do
    sender = WinInfo.getCtrlName(senderId)
    Logger.debug("Event from #{inspect(sender)}: #{inspect(event)}")

    case event do
      {:wxClose, :close_window} ->
        callHandler(state, :do_window_close, [senderId, state])
        {:stop, :normal, "#{inspect(state[:winName])}"}
    end
  end

  @doc """
  Handle a menu event, sent by the menu bar.
  """
  def menuEvent(senderId, senderObj, event, state) do
    sender = WinInfo.getCtrlName(senderId)
    Logger.debug("Menu event from: #{inspect(sender)}")
    callHandler(state, :do_menu_click, [sender, state])
    # {:noreply, state}
  end

  @doc """
  ListCtrl event.
  """
  def listCtrlEvent(senderId, senderObj, event, state) do
    {:wx_ref, id, _, _} = senderObj
    sender = WinInfo.getCtrlName(id)

    case event do
      {:wxList, :command_list_col_click, _, _, _, col, _} -> listCtrlColClick(sender, col, state)
    end
  end

  def listCtrlColClick(sender, col, state) do
    # Logger.info("listCtrl click event: sender=#{inspect(sender)} col=#{inspect(col)}")

    callHandler(state, :do_list_ctrl_col_click, [sender, col, state])
    # {:noreply, state}
  end

  def handle(evt, state) do
    Logger.info("handle unexpected event: #{inspect(evt)}")
    {:noreply, state}
  end

  defp callHandler(state, handler, args) do
    case handlerExists(state, handler, length(args)) do
      true ->
        apply(state[:logic], handler, args)

      false ->
        Logger.debug("No event handler: #{inspect(handler)}()")

        {:noreply, state}
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
