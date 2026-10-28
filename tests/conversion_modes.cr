require "libadwaita"
require "../src/modules/functions/file_launcher_patch"
require "../src/modules/functions/subprocess_patch"
require "../src/modules/views/main_window"
require "../src/modules/functions/conversion_logic"

# Test-only access to compare the form state with the visible controls.
class GoblinApp::MainWindow
  def test_options : GoblinApp::ConversionOptions
    @form_data.options
  end
end

def descendants(widget : Gtk::Widget) : Array(Gtk::Widget)
  result = [widget] of Gtk::Widget
  child = widget.first_child
  while child
    result.concat(descendants(child))
    child = child.next_sibling
  end
  result
end

def check_mode(window, scales, mode, resolution, quality)
  expected = [66.0, resolution.to_f, quality.to_f]
  raise "Unexpected slider values for #{mode}: #{scales.map(&.value)}" unless scales.map(&.value) == expected
  options = window.test_options
  unless {options.mode, options.threshold, options.resolution, options.quality} == {mode, 66, resolution, quality}
    raise "Form state and controls disagree for #{mode}"
  end
end

app = Adw::Application.new(application_id: "de.magynhard.GoblinConverter.ModeTest", flags: Gio::ApplicationFlags::NonUnique)
status = 0
app.activate_signal.connect do
  begin
    window = GoblinApp::MainWindow.new(app)
    widgets = descendants(app.active_window.not_nil!)
    selector = widgets.compact_map(&.as?(Adw::ComboRow)).first
    scales = widgets.compact_map(&.as?(Gtk::Scale))
    raise "Expected exactly three sliders" unless scales.size == 3
    raise "Expected exactly three modes" unless selector.model.not_nil!.n_items == 3

    check_mode(window, scales, "monochrome", 300, 75)
    widgets.compact_map(&.as?(Gtk::Switch)).first.active = false
    selector.selected = 2
    check_mode(window, scales, "color", 140, 50)
    raise "Mode switching reset the strip-metadata setting" if window.test_options.strip_metadata
    scales[0].value = 42.0
    scales[1].value = 220.0
    scales[2].value = 83.0
    selector.title = "Updated mode title"
    raise "Unrelated notifications reset customized sliders" unless scales.map(&.value) == [42.0, 220.0, 83.0]
    raise "Manual quality changes were not applied" unless window.test_options.quality == 83

    selector.selected = 1
    check_mode(window, scales, "grayscale", 170, 40)
    selector.selected = 0
    check_mode(window, scales, "monochrome", 300, 75)
    raise "Mode switching reset the strip-metadata setting" if window.test_options.strip_metadata
    puts "Mode switching passed: presets, slider synchronization, manual edits and monochrome restoration."
  rescue ex
    STDERR.puts ex.message
    status = 1
  ensure
    app.quit
  end
end
app.run
exit status
