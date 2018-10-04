defmodule Defines do
  defmacro __using__(_opts) do
    quote do
      import Defines
      import Bitwise

      @wxBITMAP_TYPE_XPM 9
      @wxBITMAP_TYPE_INVALID 0
      @wxBITMAP_TYPE_BMP 1
      @wxBITMAP_TYPE_BMP_RESOURCE 2
      @wxBITMAP_TYPE_RESOURCE @wxBITMAP_TYPE_BMP_RESOURCE
      @wxBITMAP_TYPE_ICO 2 + 1
      @wxBITMAP_TYPE_ICO_RESOURCE 2 + 2
      @wxBITMAP_TYPE_CUR 2 + 3
      @wxBITMAP_TYPE_CUR_RESOURCE 2 + 4
      @wxBITMAP_TYPE_XBM 2 + 5
      @wxBITMAP_TYPE_XBM_DATA 2 + 6
      @wxBITMAP_TYPE_XPM 2 + 7
      @wxBITMAP_TYPE_XPM_DATA 2 + 8
      @wxBITMAP_TYPE_TIF 2 + 9
      @wxBITMAP_TYPE_TIF_RESOURCE 2 + 10
      @wxBITMAP_TYPE_GIF 2 + 11
      @wxBITMAP_TYPE_GIF_RESOURCE 2 + 12
      @wxBITMAP_TYPE_PNG 2 + 13
      @wxBITMAP_TYPE_PNG_RESOURCE 2 + 14
      @wxBITMAP_TYPE_JPEG 2 + 15
      @wxBITMAP_TYPE_JPEG_RESOURCE 2 + 16
      @wxBITMAP_TYPE_PNM 2 + 17
      @wxBITMAP_TYPE_PNM_RESOURCE 2 + 18
      @wxBITMAP_TYPE_PCX 2 + 19
      @wxBITMAP_TYPE_PCX_RESOURCE 2 + 20
      @wxBITMAP_TYPE_PICT 2 + 21
      @wxBITMAP_TYPE_PICT_RESOURCE 2 + 22
      @wxBITMAP_TYPE_ICON 2 + 23
      @wxBITMAP_TYPE_ICON_RESOURCE 2 + 24
      @wxBITMAP_TYPE_ANI 2 + 25
      @wxBITMAP_TYPE_IFF 2 + 26
      @wxBITMAP_TYPE_TGA 2 + 27
      @wxBITMAP_TYPE_MACCURSOR 2 + 28
      @wxBITMAP_TYPE_MACCURSOR_RESOURCE 2 + 29
      @wxBITMAP_TYPE_ANY 50

      # From "defs.h": wxOrientation
      @wxHORIZONTAL 4
      @wxVERTICAL 8
      # @wxBOTH @wxVERTICAL ||| @wxHORIZONTAL

      # From "toolbar.h"
      @wxTB_HORIZONTAL 115
      @wxTB_TOP @wxTB_HORIZONTAL
      @wxTB_VERTICAL @wxVERTICAL
      @wxTB_LEFT @wxTB_VERTICAL
      @wxTB_3DBUTTONS 16
      @wxTB_FLAT 32
      @wxTB_DOCKABLE 64
      @wxTB_NOICONS 128
      @wxTB_TEXT 256
      @wxTB_NODIVIDER 512
      @wxTB_NOALIGN 1024
      @wxTB_HORZ_LAYOUT 2048
      # @wxTB_HORZ_TEXT @TB_HORZ_LAYOUT ||| @TB_TEXT
      @wxTB_NO_TOOLTIPS 4096
      @wxTB_BOTTOM 8192
      @wxTB_RIGHT 16384
      # From "toolbook.h"
      @wxBK_BUTTONBAR 256
    end
  end
end
