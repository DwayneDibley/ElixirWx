defmodule WinInfo do
  require Logger

  @moduledoc """
  When a window is created, an ets table is created which contains information
  about the various window components. The information consists of the tuple
  {name, id, obj} where:

    | item | Description                                                      | Value     |
    | --------- | --------------------------------------------------------    | --------- |
    | name      | The id supplied when the component is created               | atom()    |
    | object    | The WxWindows object reference.                             |           |
    | parent    | The id of the parent of this object.                        | atom      |

  This module provides an interface to the information.
  """
  def createInfoTable() do
    try do
      :ets.new(table_name(), [:ordered_set, :protected, :named_table])
      :ok
    rescue
      _ ->
        Logger.warn("Attempt to create #{inspect(table_name())} failed: Table exists. ")
        :error
    end
  end

  @doc """
  Insert an object into the table.
  """
  def insertObject(id, obj) do
    :ets.insert_new(table_name(), {id, obj, nil})
  end

  @doc """
  Add a new object to the object table
  """
  def insertObject(id, obj, parent) do
    id =
      case id do
        nil ->
          {_, id, name, _} = obj
          String.to_atom("#{to_string(name)}_#{inspect(id)}")

        _ ->
          id
      end

    case getObject(id) do
      nil -> :ets.insert_new(table_name(), {id, obj, parent})
      _ -> Logger.error("insertObject: Object already exists: #{inspect(id)}")
    end
  end

  @doc """
  Given the atom id of an object, return the object
  """
  def getObject(id) do
    case :ets.lookup(table_name(), id) do
      {_id, obj, _parent} -> obj
      [{_id, obj, _parent}] -> obj
      [] -> nil
    end
  end

  def getObjectId(object) do
    matches = :ets.match(table_name(), {:"$1", object, :_})
    List.first(List.flatten(matches))
  end

  @doc """
  return a list of all objects having the given parent.
  """
  def getObjectsByParent(parent) do
    matches = :ets.match(table_name(), {:_, :"$1", parent})
    List.flatten(matches)
  end

  @doc """
  Insert window information into the winInfo table.
  """
  def insert(value) do
    Logger.warn("WinInfo.insert(value) is Deprecated.")
    :ets.insert_new(table_name(), value)
  end

  @doc """
  Insert window information into the winInfo table.
  """
  def insertCtrl(name, control) do
    Logger.warn("WinInfo.insertCtrl(name, control) is Deprecated.")
    {_, id, _, _} = control
    :ets.insert_new(table_name(), {name, id, control})
  end

  def insertCtrl(name, id, control) do
    Logger.warn("WinInfo.insertCtrl(name, id, control) is Deprecated.")
    :ets.insert_new(table_name(), {name, id, control})
  end

  def getCtrlName({_, id, _, _}) do
    Logger.warn("WinInfo.getCtrlName({_, id, _, _}) is Deprecated.")

    # {_, id, _, _} = ctrl
    res = :ets.match_object(table_name(), {:_, id, :_})
    {name, _id, _obj} = List.first(res)
    name
  end

  def getCtrlName(id) when is_integer(id) do
    Logger.warn("WinInfo.getCtrlName(id) is Deprecated.")
    # {_, id, _, _} = ctrl
    res = :ets.match_object(table_name(), {:_, id, :_})
    {name, _id, _obj} = List.first(res)
    name
  end

  @doc """
  Given the name or id of a the window object, return it.
  """
  def getWxObject(key) do
    Logger.warn("WinInfo.getWxObject(key) is Deprecated.")

    res =
      cond do
        is_atom(key) -> :ets.lookup(table_name(), key)
        is_integer(key) -> :ets.match_object(table_name(), {:_, key, :_})
      end

    obj =
      case length(res) do
        0 ->
          nil

        _ ->
          {_name, _id, obj} = List.first(res)
          obj
      end

    obj
  end

  # ------------------
  # Helper Functions
  # ------------------
  # Create the table name
  defp table_name() do
    String.to_atom("#{inspect(self())}")
  end

  # ---------
  @doc """
  Retrieve data from the ets table
  """
  def getWindowId(id) when is_atom(id) do
    Logger.warn("WinInfo.getWindowId(id) is Deprecated.")
    res = :ets.match_object(table_name(), {:_, id, :_})

    {name, id, obj} =
      case length(res) do
        0 -> {nil, nil, nil}
        _ -> List.first(res)
      end

    {name, id, obj}
  end

  @doc """
  Given a numeric ID, get the info for the object.
  returns {name, id, obj}
  """
  def get_by_id(id) do
    Logger.warn("WinInfo.get_by_id(id) is Deprecated.")

    res = :ets.match_object(table_name(), {:_, id, :_})

    {name, id, obj} =
      case length(res) do
        0 -> {nil, nil, nil}
        _ -> List.first(res)
      end

    {name, id, obj}
  end

  @doc """

  """
  def get_object_name(id) do
    Logger.warn("WinInfo.get_object_name(id) is Deprecated.")
    {name, _id, _obj} = get_by_id(id)
    name
  end

  def get_events() do
    res = :ets.lookup(table_name(), :__events__)

    events =
      case length(res) do
        0 ->
          %{}

        _ ->
          {_, events} = List.first(res)
          events
      end

    events
  end

  def put_event(event_type, info) do
    res = :ets.lookup(table_name(), :__events__)

    events =
      case length(res) do
        0 ->
          %{}

        _ ->
          {_, events} = List.first(res)
          events
      end

    events = Map.put(events, event_type, info)
    :ets.insert(table_name(), {:__events__, events})
  end

  def display_table() do
    table = String.to_atom("#{inspect(self())}")
    all = :ets.match(table_name(), :"$1")
    Logger.debug("Table: #{inspect(table)}")
    display_rows(all)
  end

  def display_rows([]) do
    :ok
  end

  def display_rows([[h] | t]) do
    Logger.debug("  #{inspect(h)}")
    display_rows(t)
  end

  # def table_name() do
  #   String.to_atom("#{inspect(self())}")
  # end

  @doc """
    FIFO implemented using ETS storage. This is used during window creation
  """
  def stack_push(value) do
    stack = get_stack()

    new_stack =
      case stack do
        [] ->
          [value]

        _ ->
          [value | stack]
      end

    # Logger.debug("insert = #{inspect(new_stack)}")
    :ets.insert(table_name(), {:__stack__, new_stack})
  end

  def stack_tos() do
    stack = get_stack()
    # Logger.debug("get tos = #{inspect(stack)}")

    tos =
      case stack do
        nil ->
          nil

        [tos | _rest] ->
          tos

        [] ->
          # Logger.debug("get tos []")
          nil
      end

    tos
  end

  def stack_pop() do
    stack = get_stack()

    {tos, rest} =
      case stack do
        nil -> {nil, []}
        [] -> {nil, []}
        [tos | rest] -> {tos, rest}
      end

    :ets.insert(table_name(), {:__stack__, rest})
    tos
  end

  defp get_stack() do
    res = :ets.lookup(table_name(), :__stack__)

    # res =
    case res do
      [] -> []
      _ -> res[:__stack__]
    end
  end
end
