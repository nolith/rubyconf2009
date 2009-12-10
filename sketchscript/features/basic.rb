#
# wpf.rb gives nice helpers for gui apps
#
require 'wpf'

#
# SketchScript is the .NET namespace of the host app
#
include SketchScript 

$window = @window = window
@canvas = canvas
@offset = 20
@rect_size = 20

#
# Pick a random color from the pallete
#
def random_pretty_color
  @pretty_colors ||= [
    [0, 113, 118],
    [0,173,239],
    [68,199,244],
    [157,220,249],
    [255,235,149]
  ].map {|c| SolidColorBrush.new Color.from_rgb(*c) }
  @pretty_colors[rand(@pretty_colors.size)]
end

#
# clear all objects from the canvas
#
def cls
  canvas.children.clear
end

#
# render a random colored square on the canvas in a random position
#
def random_square
  rect = Rectangle.new
  rect.width, rect.height, rect.fill = @rect_size, @rect_size, random_pretty_color 
  canvas.children.add rect
  Canvas.set_left rect, rand(canvas.actual_width - @offset)
  Canvas.set_top  rect, rand(canvas.actual_height - @offset)
  rect
end

#
# Add a button with "name" to a "container".
# OnClick, run the block
#
def as_button name, container, &block
  b = Button.new
  b.content = name
  b.click &block
  container.children.add b
  container.show
  b
end

#
# add a "show" and "hide" method to the "type", which hides/shows row "i"
#
def __generate_show_and_hide_methods(type, i)
  self.instance_eval %{
    class << window.#{type}_controls
      def show
        $window.content.row_definitions[#{i}].height = GridLength.new(23)
      end
      def hide
        $window.content.row_definitions[#{i}].height = GridLength.new(0)
      end
    end
  }
end

def reset_host_state
  window.canvas_controls.children.clear
  window.output_controls.children.clear
  canvas.children.clear
  window.editor_toggle.mouse_enter.remove @_mouse_enter if @_mouse_enter
  window.editor_toggle.mouse_leave.remove @_mouse_leave if @_mouse_leave
end

# "light up" the grid splitters -- so people know that
# they actually do something
def hover_for_splitters
  @_mouse_enter = lambda do |s, e|
    @__tempbrush = s.background
    s.background = SolidColorBrush.new Color.from_argb(0x55, 0xcc, 0xcc, 0xcc)
  end
  window.editor_toggle.mouse_enter &@_mouse_enter
  window.console_splitter.mouse_enter &@_mouse_enter
  @_mouse_leave = lambda do |s, e|
    s.background = @__tempbrush
  end
  window.editor_toggle.mouse_leave &@_mouse_leave
  window.console_splitter.mouse_leave &@_mouse_leave
end

def add_default_buttons
  @default_canvas_buttons.each do |b|
    window.canvas_controls.children.remove b
  end if @default_canvas_controls
  
  @default_output_buttons.each do |b|
    window.output_controls.children.remove b
  end if @default_output_controls
  
  @default_canvas_buttons = []
  @default_output_buttons = []

  @default_canvas_buttons << (as_button("Random Square", window.canvas_controls) { |s,e|
    random_square
  })
  @default_canvas_buttons << (as_button("Clear", window.canvas_controls) { |s,e|
    canvas.children.clear
  })
  
  @default_output_buttons << (as_button("Reload", window.output_controls) { |s,e|
    reload
  })
  @default_output_buttons << (as_button("Run next", window.output_controls) { |s,e|
    select_upto_next_pause
    window.run_code window.code
  })
end

#
# called by host automatically
#
def setup
  __generate_show_and_hide_methods :canvas, 0
  __generate_show_and_hide_methods :output, 4

  reset_host_state

  hover_for_splitters

  add_default_buttons

  # load the "interactive" file into the interactive textbox
  window.code.text = File.read("../../../features/interactive.rb")
end

def reload
  load 'basic.rb'
end

def scroll_to_first_selected_line
  lines = window.code.text.split(/\n/)
  char_index = window.code.selection_start
  lines.each_with_index do |line, index|
    if char_index <= line.size
      window.code.scroll_to_line index
      break
    end
    char_index -= line.size
  end
end

#
# selects code up to the next %pause comment
#
def select_upto_next_pause(indicatortxt = '#%pause')
  offset = window.code.selection_length == 0 ?
    0 : 
    window.code.selection_start + window.code.selection_length
  sections = window.code.text[offset..-1].split(/^#{indicatortxt}/)
  length = sections.first.length + indicatortxt.length
  window.code.select offset, length
  window.code.focus
  scroll_to_first_selected_line
end

# kick off everything

setup
