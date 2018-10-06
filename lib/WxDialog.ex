defmodule WxDialog do
  def messageDialog(parent, message, options \\ []) do
    # Parent = wxWindow:wxWindow()
    # Message = unicode:chardata()
    # Option = {caption, unicode:chardata()} | {style, integer()} | {pos, {X::integer(), Y::integer()}}
    :wxMessageDialog.new(:wx.null(), "hello world")
  end
end
