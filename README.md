
# ElixirWx
==Note==  I will only be updating this repository occasionally. The current version of ElixirWx can be found in the /lib/ElixirEx directory in the ElixirWxTests repository

An Elixir interface to wxErlang
----

The concept of ElixirWx is to provide a clearer interface to wxWindows than is currently possible. Using wxErlang directly from Elixir tends to produce hard to read code. My first attemptat an improvement was to wrap the various wxErlang functions in Elixir wrappers. This approach works ok, but only improves the syntax (From the Elixir point of view :-) ). The problem is deeper than that. 

Constructing a GUI consists of several steps:

- Creating components
- Setting their attributes
- Linking them together

The structure of a GUI window is hierarchical, making a procedural  approach messy. This is because the structure of the code does not match the structure of the window.

For instance consider the following code:

    create_window() ->
        wxFrame = wxFrame:new(wx:null(), -1, "Sudoku", []),
        wxFrame:createStatusBar(Frame,[]),
        wxFrame:connect(Frame, close_window),
    
        MenuBar = wxMenuBar:new(),
        File    = wxMenu:new([]),
        Opt     = wxMenu:new([]),
        Help    = wxMenu:new([]),
    
        wxMenu:append(File, ?NEW,  "&New Game"),
        wxMenu:append(File, ?OPEN, "&Open Game"),
        wxMenu:append(File, ?SAVE, "&Save Game"),
        wxMenu:appendSeparator(File),
        wxMenu:append(File, ?PRINT, "Print"),
        wxMenu:append(File, ?PRINT_PAGE_SETUP, "Page Setup"),
        wxMenu:append(File, ?PRINT_PRE, "Print Preview"),
        wxMenu:appendSeparator(File),
        wxMenu:append(File, ?QUIT, "&Quit Game"),
    
        wxMenu:append(Help, ?RULES, "Rules"),
        wxMenu:append(Help, ?ABOUT, "About"), 
    
        wxMenu:appendRadioItem(Opt, ?TRIVIAL, "Level: Trivial"),
        wxMenu:appendRadioItem(Opt, ?EASY, "Level: Easy"),
        LItem = wxMenu:appendRadioItem(Opt, ?NORMAL, "Level: Normal"),
        wxMenu:appendRadioItem(Opt, ?HARD, "Level: Hard"),
        wxMenu:appendRadioItem(Opt, ?HARDEST, "Level: Hardest"),
        wxMenu:appendSeparator(Opt),
        EItem = wxMenu:appendCheckItem(Opt, ?SHOW_ERROR, "Show errors"),
    
        wxMenuBar:append(MenuBar, File, "&File"),
        wxMenuBar:append(MenuBar, Opt, "O&ptions"),
        wxMenuBar:append(MenuBar, Help, "&Help"),
    
        wxFrame:setMenuBar(Frame, MenuBar),
        wxFrame:connect(Frame, command_menu_selected),
    
        MainSz = wxBoxSizer:new(?wxVERTICAL),
        Top    = wxBoxSizer:new(?wxHORIZONTAL),
    
        Panel = wxPanel:new(Frame), 
        NewGame = wxButton:new(Panel, ?NEW, [{label,"New Game"}]),
        wxButton:connect(NewGame, command_button_clicked),
        Empty = wxButton:new(Panel, ?EMPTY, [{label,"Empty Board "}]),
        wxButton:connect(Empty, command_button_clicked),
        Clean = wxButton:new(Panel, ?CLEAR, [{label,"Clear"}]),
        wxButton:connect(Clean, command_button_clicked),
        Hint  = wxButton:new(Panel, ?HINT, [{label, "Hint"}]),
        wxButton:connect(Hint, command_button_clicked),
    
        wxSizer:addSpacer(Top,2),
        SF = wxSizerFlags:new(),
        wxSizerFlags:proportion(SF,1),
        wxSizer:add(Top, NewGame, wxSizerFlags:left(SF)), 
        wxSizer:addSpacer(Top,3),
        wxSizer:add(Top, Empty,   wxSizerFlags:center(SF)),
        wxSizer:addSpacer(Top,3),   
        wxSizer:add(Top, Clean,   wxSizerFlags:center(SF)),
        wxSizer:addSpacer(Top,3),   
        wxSizer:add(Top, Hint,    wxSizerFlags:right(SF)),
    
        wxSizer:addSpacer(MainSz,5),
        wxSizer:add(MainSz, Top, wxSizerFlags:center(wxSizerFlags:proportion(SF,0))),
        wxSizer:addSpacer(MainSz,10),
    
        Board = sudoku_board:new(Panel),
    
        wxSizer:add(MainSz, Board, wxSizerFlags:proportion(wxSizerFlags:expand(SF),1)),
        wxWindow:setSizer(Panel,MainSz),
        wxSizer:fit(MainSz, Frame),
        wxSizer:setSizeHints(MainSz,Frame),
        wxWindow:show(Frame),
        %% Check after append so it's initialized on all platforms
        wxMenuItem:check(LItem),
        wxMenuItem:check(EItem),
    	{Frame, Board}.`
	
It's hard to see the structure, although all this code is doing is defining the structure! What if I could structure the above code as follows (Yes I know its totally broken, but I want to show the principle):

```

 wxFrame = wxFrame:new(wx:null(), -1, "Sudoku", []),
    	wxMenuBar:new(),
		 File = wxMenu:new([]),
 			wxMenu:append(File, ?NEW,  "&New Game"),
    			wxMenu:append(File, ?OPEN, "&Open Game"),
    			wxMenu:append(File, ?SAVE, "&Save Game"),
   			wxMenu:appendSeparator(File),
    			wxMenu:append(File, ?PRINT, "Print"),
    			wxMenu:append(File, ?PRINT_PAGE_SETUP, "Page Setup"),
   			wxMenu:append(File, ?PRINT_PRE, "Print Preview"),
    			wxMenu:appendSeparator(File),
    			wxMenu:append(File, ?QUIT, "&Quit Game"),

    		Opt = wxMenu:new([]),
 			wxMenu:appendRadioItem(Opt, ?TRIVIAL, "Level: Trivial"),
    			wxMenu:appendRadioItem(Opt, ?EASY, "Level: Easy"),
    			LItem = wxMenu:appendRadioItem(Opt, ?NORMAL, "Level: Normal"),
    			wxMenu:appendRadioItem(Opt, ?HARD, "Level: Hard"),
    			wxMenu:appendRadioItem(Opt, ?HARDEST, "Level: Hardest"),
    			wxMenu:appendSeparator(Opt),
			EItem = wxMenu:appendCheckItem(Opt, ?SHOW_ERROR, "Show errors"),

   		 Help = wxMenu:new([]),
 			wxMenu:append(Help, ?RULES, "Rules"),
    			wxMenu:append(Help, ?ABOUT, "About"), 
		wxFrame:connect(Frame, command_menu_selected),
	
	Panel = wxPanel:new(Frame), 
		MainSz = wxBoxSizer:new(?wxVERTICAL),
  		  	wxSizer:addSpacer(MainSz,5),
   			wxSizer:add(MainSz, Top, wxSizerFlags:center(wxSizerFlags:proportion(SF,0))),
    			wxSizer:addSpacer(MainSz,10),
			Top = wxBoxSizer:new(?wxHORIZONTAL),
				wxSizer:addSpacer(Top,2),
    				SF = wxSizerFlags:new(),
    				wxSizerFlags:proportion(SF,1),
    				wxSizer:add(Top, NewGame, wxSizerFlags:left(SF)), 
    				wxSizer:addSpacer(Top,3),
   				 wxSizer:add(Top, Empty,   wxSizerFlags:center(SF)),
    					Empty = wxButton:new(Panel, ?EMPTY, [{label,"Empty Board "}]),
   					 wxButton:connect(Empty, command_button_clicked),
    				 wxSizer:addSpacer(Top,3),   
				…

 wxFrame:createStatusBar(Frame,[]),
 wxFrame:connect(Frame, close_window),

```

Note that the various attach statements fall away, as the structure of the window is now implicit...

I have written a DSL that implements this idea, and the Elixir code looks like this (A real working example):

```

def createWindow(show) do
    window show: show do
      # Create a frame with a status bar and a menu.
      frame id: :main_frame,
            title: "Countdown",
            size: {250, 150} do
        # event(:close_window, &AnotherTutorialApp.windowClosed/3)
        panel id: :main_panel do
          boxSizer id: :outer_sizer, orient: @wxHORIZONTAL do
            spacer(space: 20)
            boxSizer id: :main_sizer,
                     orient: @wxVERTICAL do
              spacer(space: 10)
              staticBoxSizer id: :input_sizer,
                             orient: @wxHORIZONTAL,
                             label: "Enter an integer" do
                textControl(id: :time_input, value: "10")
                spacer(space: 5)
                staticText(id: :output, text: "Output Area")
                spacer(space: 10)
              end
              boxSizer id: :button_sizer,
                       orient: @wxHORIZONTAL do
                button(id: :countdown_btn, label: "&Countdown")
                button(id: :exit_btn, label: "&Exit")
              end
            end
          end
        end
      end
      event(:close_window, &CountdownApp.windowClosed/3)
      event(:command_button_clicked)
    end
  end
```

You can see a screenshots of the created window in the img directory....

The code is a long way from finished, but I (at least) am encouraged by the results so far!...
