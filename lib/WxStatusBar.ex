defmodule WxStatusBar do
  import WxUtilities
  import WinInfo
  require Logger

  @doc """
  Create a new status bar and attach it to the main frame.
  If a :text option is supplied, set the text.
  """
  def new(parent, attributes) do
    new_id = :wx_misc.newId()

    defaults = [id: :status_bar, number: nil, style: nil]
    {id, options, restOpts} = getOptions(attributes, defaults)

    Logger.debug("  :wxFrame.createStatusBar(#{inspect(parent)}, #{inspect(options)}")
    sb = :wxFrame.createStatusBar(parent, options)

    put_table({id, new_id, sb})

    defaults = [text: nil]
    {_, options, _restOpts} = getOptions(restOpts, defaults)

    case options[:text] do
      nil -> :ok
      "" -> :ok
      other -> setText(other)
    end

    {id, new_id, sb}
  end

  @doc """
  Set the status bar text.
  If the suppied test is a string, then set it in the first field.
  If it is a list of strings, then set all fields, setting the number of fields
  to the length of the supplied list
  """
  # def setText(text) when is_binary(text) do
  #  {_, _, sb} = WinInfo.get_by_name(:status_bar)
  #  :wxStatusBar.setStatusText(sb, text)
  # end

  # Set the text of the status bar field. THe number of fields is extended if necessary.
  def setText(text, index \\ 1) when is_binary(text) do
    {_, _, sb} = WinInfo.get_by_name(:status_bar)

    case index do
      1 ->
        :wxStatusBar.setStatusText(sb, text)

      _ ->
        n = :wxStatusBar.getFieldsCount(sb)

        cond do
          n < index ->
            :wxStatusBar.setFieldsCount(sb, length(index))
            :wxStatusBar.setStatusText(sb, text, [{:number, index}])

          n >= index ->
            :wxStatusBar.setStatusText(sb, text, [{:number, index}])
        end
    end
  end

  def setText(text) when is_list(text) do
    {_, _, sb} = WinInfo.get_by_name(:status_bar)
    :wxStatusBar.setFieldsCount(sb, length(text))
    setTextList(sb, text, 0)
  end

  def setTextList(_, [], _), do: :ok

  def setTextList(sb, [h | t], n) do
    :wxStatusBar.setStatusText(sb, h, [{:number, n}])
    setTextList(sb, t, n + 1)
  end
end
