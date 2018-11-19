defmodule WxReport do
  require Logger

  # import WxUtilities
  # import WinInfo
  use WxDefines

  @moduledoc """
  The List control is so unintuative (At least to me) so I have created this
  module to interface to it in a sensible way.
  """

  @doc """
  Create a new report using the list control.
  """
  def new(parent, options) do
    Logger.debug("  WxReport.new(#{inspect(parent)}, #{inspect(options)}")
    # ||| @wxLC_SINGLE_SEL)
    :wxListCtrl.new(parent, style: @wxLC_REPORT)
  end

  @doc """
  Get the selected row from the list control. Returns a tuple containing the row
  index and the text in the specified column. If no column is specified, then the
  text in the first column is returned.
  """
  def getSelection(listCtrl, col \\ 0) do
    idx = :wxListCtrl.getNextItem(listCtrl, -1, state: @wxLIST_STATE_SELECTED)

    text =
      if idx >= 0 do
        listItem = :wxListItem.new()
        :wxListItem.setId(listItem, idx)
        :wxListItem.setColumn(listItem, col)
        :wxListItem.setMask(listItem, @wxLIST_MASK_TEXT)
        :wxListCtrl.getItem(listCtrl, listItem)
        :wxListItem.getText(listItem)
      else
        ""
      end

    {idx, text}
  end

  @doc """
  Get the selected row from the list control. Returns a tuple containing the row
  index and the text in the specified column. If no column is specified, then the
  text in the first column is returned.
  """
  def setSelection(listCtrl, row, clearOldSelection \\ true) do
    # Logger.debug("setSelection(listCtrl, #{inspect(row)}, #{inspect(clearOldSelection)})")
    # idx = :wxListCtrl.getNextItem(listCtrl, -1, state: @wxLIST_STATE_SELECTED)

    # if clearOldSelection do
    #  clearSelection(listCtrl)
    # end

    nItems = :wxListCtrl.getItemCount(listCtrl)

    res =
      if row >= 0 and row < nItems do
        listItem = :wxListItem.new()
        :wxListItem.setId(listItem, row)
        :wxListItem.setState(listItem, @wxLIST_STATE_SELECTED)
        :wxListCtrl.setItem(listCtrl, listItem)
      else
        false
      end
  end

  def clearSelection(listCtrl) do
    {row, text} = getSelection(listCtrl)
    # Logger.debug("clearSelection(listCtrl) selection=#{inspect(row)}")

    if row >= 0 do
      Logger.debug("Deselect row #{inspect(row)}")
      # wxListCtrl->SetItemState(item, 0, wxLIST_STATE_SELECTED|wxLIST_STATE_FOCUSED);
      # listItem = :wxListItem.new()
      # :wxListItem.setId(listItem, row)
      # :wxListItem.setStateMask(listItem, @wxLIST_STATE_SELECTED)
      # :wxListCtrl.setItem(listCtrl, listItem)
      :wxListCtrl.setItemState(listCtrl, row, 0, @wxLIST_STATE_SELECTED ||| @wxLIST_STATE_FOCUSED)
    else
      false
    end
  end

  @doc """
  Set the data in a report, where the data contains a list lists
  containing rows of data.
  """
  def setReportData(listCtrl, data, font) do
    nRows = :wxListCtrl.getItemCount(listCtrl)
    setData(listCtrl, nRows, 0, data, font)
  end

  def setData(_, _, _, [], _) do
  end

  def setData(listCtrl, nRows, row, [rowData | rest], font) do
    setRowData(listCtrl, nRows, row, 0, rowData, font)
    setData(listCtrl, nRows, row + 1, rest, font)
  end

  def setRowData(_, _, _, _, [], _) do
  end

  def setRowData(listCtrl, nRows, row, 0, [colData | rest], font) do
    cond do
      row >= nRows ->
        :wxListCtrl.insertItem(listCtrl, row, colData)
        :wxListCtrl.setItemFont(listCtrl, row, font)

        case rem(row, 2) do
          0 -> :wxListCtrl.setItemBackgroundColour(listCtrl, row, {230, 247, 255})
          1 -> :wxListCtrl.setItemBackgroundColour(listCtrl, row, @wxWHITE)
        end

      true ->
        :wxListCtrl.setItem(listCtrl, row, 0, colData)
    end

    setColWidth(listCtrl, 0, colData, font)
    setRowData(listCtrl, nRows, row, 1, rest, font)
  end

  def setRowData(listCtrl, nRows, row, col, [colData | rest], font) do
    :wxListCtrl.setItem(listCtrl, row, col, colData)
    setColWidth(listCtrl, col, colData, font)
    setRowData(listCtrl, nRows, row, col + 1, rest, font)
  end

  def setColWidth(listCtrl, col, data, font) do
    {width, _y, _decent, _extLeading} =
      :wxListCtrl.getTextExtent(listCtrl, data, [{:theFont, font}])

    width = width + 10
    cwidth = :wxListCtrl.getColumnWidth(listCtrl, col)

    cond do
      width > cwidth -> :wxListCtrl.setColumnWidth(listCtrl, col, width)
      true -> :ok
    end
  end

  @doc """
  Find the row which has the given text in its first column.
  Id partial is true, then find the row where the text starts with firstColtext.
  startRow is the row to start on whilst searching.
  Returns the column index, or -1 if the text is not found.
  """
  def findRowIndex(listCtrl, firstColText) do
    :wxListCtrl.findItem(listCtrl, -1, firstColText)
  end

  def findRowIndex(listCtrl, firstColText, startRow, partial \\ false) do
    :wxListCtrl.findItem(listCtrl, startRow, firstColText, partial: partial)
  end

  @doc """
  Add a new column to the list control
  """
  def newColumn(parent, colNo, heading, options \\ []) do
    :wxListCtrl.insertColumn(parent, colNo, heading, options)
  end
end
