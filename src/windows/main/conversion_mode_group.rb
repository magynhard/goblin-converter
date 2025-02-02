
module ConversionModeGroup

  CONVERSION_MODES = {
    _("Monochrome") => "monochrome",
    _("Grayscale") => "grayscale",
    _("Grayscale quality") => "grayscale_quality",
    _("Color") => "color",
  }

  # @param [Gtk::Box] box to add the group to
  def create_conversion_mode_group(box:, parent:)
    group = Adwaita::PreferencesGroup.new
    group.title = _("Conversion")

    group.add conversion_create_mode box: box, parent: parent
    group.add conversion_create_threshold box: box, parent: parent
    group.add conversion_create_resolution box: box, parent: parent
    group.add conversion_create_quality box: box, parent: parent
    group.add conversion_create_strip_metadata box: box, parent: parent
    box.append(group)
  end

  def conversion_create_mode(box:, parent:)
    @conversion_mode_row = Adwaita::ComboRow.new
    @conversion_mode_row.title = _("Mode")
    @conversion_mode_row.model = Gtk::StringList.new(CONVERSION_MODES.keys)
    @conversion_mode_row.selected = 0  # Default selection (Up)
    @conversion_mode_row.signal_connect("notify::selected") do |row|
      @form_data.options.mode = CONVERSION_MODES.values[row.selected]
      p @form_data
    end
    @conversion_mode_row
  end

  def conversion_create_resolution(box:, parent:)
    @conversion_resolution_row = Adwaita::ActionRow.new

    # Create a Box to hold both Title and Subtitle
    label_box = Gtk::Box.new(:vertical, 5)
    #label_box.set_margin_start(12)  # Match Adwaita's padding
    label_box.set_margin_top(6)     # Match Adwaita's padding
    label_box.set_margin_bottom(6)  # Match Adwaita's padding

    # Main label with fixed width
    label = Gtk::Label.new(_("Resolution"))
    label.hexpand = false
    label.set_size_request(250, -1)  # Set minimum width for the title
    label.xalign = 0  # Left-align the text

    # Subtitle label (smaller text)
    subtitle_label = Gtk::Label.new
    subtitle_label.hexpand = false
    subtitle_label.set_size_request(250, -1)  # Ensure subtitle aligns with title
    subtitle_label.xalign = 0
    subtitle_label.add_css_class("dim-label")  # Apply Adwaita styling for smaller text
    subtitle_label.set_markup("<small>" + _("Density of the resolution in dpi for your output") + "</small>")

    # Pack labels inside the box
    label_box.append(label)
    label_box.append(subtitle_label)
    @conversion_resolution_row.add_prefix(label_box)

    # create range for resolution suffix
    adjustment = Gtk::Adjustment.new(300, 50, 500, 10, 10, 0)
    scale = Gtk::Scale.new(:horizontal, adjustment)
    scale.set_hexpand(true)
    scale.draw_value = true
    scale.value = 300
    scale.draw_value = true
    scale.set_size_request(300, -1)
    scale.value_pos = :right

    scale.signal_connect("value-changed") do
      value = scale.value
      step = adjustment.step_increment
      snapped_value = ((value / step).round) * step
      adjustment.value = snapped_value unless value == snapped_value
      @form_data.options.resolution = adjustment.value
      p @form_data
    end
    @conversion_resolution_row.add_suffix(scale)
    @conversion_resolution_row
  end

  def conversion_create_quality(box:, parent:)
    @conversion_quality_row = Adwaita::ActionRow.new

    # Create a Box to hold both Title and Subtitle
    label_box = Gtk::Box.new(:vertical, 5)
    #label_box.set_margin_start(12)  # Match Adwaita's padding
    label_box.set_margin_top(6)     # Match Adwaita's padding
    label_box.set_margin_bottom(6)  # Match Adwaita's padding

    # Main label with fixed width
    label = Gtk::Label.new(_("Quality"))
    label.hexpand = false
    label.set_size_request(250, -1)  # Set minimum width for the title
    label.xalign = 0  # Left-align the text

    # Subtitle label (smaller text)
    subtitle_label = Gtk::Label.new
    subtitle_label.hexpand = false
    subtitle_label.set_size_request(250, -1)  # Ensure subtitle aligns with title
    subtitle_label.xalign = 0
    subtitle_label.add_css_class("dim-label")  # Apply Adwaita styling for smaller text
    subtitle_label.set_markup("<small>" + _("Lossy compression quality") + "</small>")

    # Pack labels inside the box
    label_box.append(label)
    label_box.append(subtitle_label)
    @conversion_quality_row.add_prefix(label_box)


    # create range for resolution suffix
    adjustment = Gtk::Adjustment.new(75, 1, 100, 1, 1, 0)
    scale = Gtk::Scale.new(:horizontal, adjustment)
    scale.set_hexpand(true)
    scale.draw_value = true
    scale.value = 75
    scale.draw_value = true
    scale.set_size_request(300, -1)
    scale.value_pos = :right

    scale.signal_connect("value-changed") do
      value = scale.value
      step = adjustment.step_increment
      snapped_value = ((value / step).round) * step
      adjustment.value = snapped_value unless value == snapped_value
      @form_data.options.quality = adjustment.value
      p @form_data
    end
    @conversion_quality_row.add_suffix(scale)
    @conversion_quality_row
  end

  def conversion_create_threshold(box:, parent:)
    @conversion_threshold_row = Adwaita::ActionRow.new
    #@conversion_threshold_row.title = _("Threshold")
    #@conversion_threshold_row.subtitle = "Decrease for more black. 66 is a good value for coloured documents.\nFor grayscaled documents 50-60 is often a good choice."


    # Create a Box to hold both Title and Subtitle
    label_box = Gtk::Box.new(:vertical, 5)
    #label_box.set_margin_start(12)  # Match Adwaita's padding
    label_box.set_margin_top(6)     # Match Adwaita's padding
    label_box.set_margin_bottom(6)  # Match Adwaita's padding

    # Main label with fixed width
    label = Gtk::Label.new(_("Threshold"))
    label.hexpand = false
    label.set_size_request(250, -1)  # Set minimum width for the title
    label.xalign = 0  # Left-align the text

    # Subtitle label (smaller text)
    subtitle_label = Gtk::Label.new
    subtitle_label.hexpand = false
    subtitle_label.set_size_request(250, -1)  # Ensure subtitle aligns with title
    subtitle_label.xalign = 0
    subtitle_label.add_css_class("dim-label")  # Apply Adwaita styling for smaller text
    subtitle_label.set_markup("<small>" + _("Decrease for more black.\n66 is a good fit for colored docs.\nFor grayscaled documents 50-60 is\noften a good choice.") + "</small>")

    # Pack labels inside the box
    label_box.append(label)
    label_box.append(subtitle_label)
    @conversion_threshold_row.add_prefix(label_box)

    # create range for resolution suffix
    adjustment = Gtk::Adjustment.new(66, 1, 100, 1, 1, 0)
    scale = Gtk::Scale.new(:horizontal, adjustment)
    scale.set_hexpand(true)
    scale.draw_value = true
    scale.set_size_request(300, -1)
    scale.value = 66
    scale.draw_value = true
    scale.value_pos = :right

    scale.signal_connect("value-changed") do
      value = scale.value
      step = adjustment.step_increment
      snapped_value = ((value / step).round) * step
      adjustment.value = snapped_value unless value == snapped_value
      @form_data.options.threshold = adjustment.value
      p @form_data
    end
    @conversion_threshold_row.add_suffix(scale)
    @conversion_threshold_row
  end

  def conversion_create_strip_metadata(box:, parent:)
    # Action Row: Natural Scrolling
    @conversion_strip_metadata_row = Adwaita::ActionRow.new
    @conversion_strip_metadata_row.title = "Strip metadata"
    @conversion_strip_metadata_row.subtitle = "Remove metadata like EXIF, IPTC, XMP, and ICC profiles from output file"

    # Switch for Natural Scrolling
    switch = Gtk::Switch.new
    switch.set_valign(Gtk::Align::CENTER) # Align vertically
    switch.set_halign(Gtk::Align::CENTER) # Align horizontally
    #switch.set_state(true) # Default state
    switch.active = true
    switch.signal_connect("state-set") do |switch, state|
      @form_data.options.strip_metadata = state
      p @form_data
      nil
    end

    # Create a box to contain the button
    switch_box = Gtk::Box.new(:horizontal)
    switch_box.append(switch)

    @conversion_strip_metadata_row.add_suffix(switch_box)
    @conversion_strip_metadata_row
  end

end