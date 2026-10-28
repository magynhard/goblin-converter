module GoblinApp
  class MainWindow
    CONVERSION_MODES = {
      "Monochrome" => "monochrome",
      "Grayscale"  => "grayscale",
      "Color"      => "color",
    }

    private def create_conversion_mode_group(box)
      group = Adw::PreferencesGroup.new
      group.title = GoblinApp.translate("Conversion")

      # Mode selector
      mode_row = Adw::ComboRow.new
      mode_row.title = GoblinApp.translate("Mode")
      # Display names as literals so xgettext can extract them.
      # Order must match CONVERSION_MODES (lookup by selected index).
      mode_names = [
        GoblinApp.translate("Monochrome"),
        GoblinApp.translate("Grayscale"),
        GoblinApp.translate("Color"),
      ]
      mode_row.model = Gtk::StringList.new(mode_names)
      mode_row.selected = 0
      group.add(mode_row)

      # Threshold
      threshold_row, threshold_scale = create_scale_row(
        title: GoblinApp.translate("Threshold"),
        subtitle: GoblinApp.translate("Decrease for more black.\n66 is a good fit for colored docs.\nFor grayscaled documents 50-60 is\noften a good choice."),
        min: 1.0, max: 100.0, step: 1.0, default: @form_data.options.threshold.to_f
      ) do |value|
        @form_data = @form_data.copy_with(options: @form_data.options.copy_with(threshold: value.to_i))
      end
      group.add(threshold_row)

      # Resolution
      resolution_row, resolution_scale = create_scale_row(
        title: GoblinApp.translate("Resolution"),
        subtitle: GoblinApp.translate("Density of the resolution in dpi for your output"),
        min: 50.0, max: 500.0, step: 10.0, default: @form_data.options.resolution.to_f
      ) do |value|
        @form_data = @form_data.copy_with(options: @form_data.options.copy_with(resolution: value.to_i))
      end
      group.add(resolution_row)

      # Quality
      quality_row, quality_scale = create_scale_row(
        title: GoblinApp.translate("Quality"),
        subtitle: GoblinApp.translate("Lossy compression quality"),
        min: 1.0, max: 100.0, step: 1.0, default: @form_data.options.quality.to_f
      ) do |value|
        @form_data = @form_data.copy_with(options: @form_data.options.copy_with(quality: value.to_i))
      end
      group.add(quality_row)

      mode_row.notify_signal.connect do |property|
        if property.name == "selected"
          mode = CONVERSION_MODES.values[mode_row.selected]
          options = GoblinApp.mode_defaults(mode).copy_with(strip_metadata: @form_data.options.strip_metadata)
          @form_data = @form_data.copy_with(options: options)
          threshold_scale.value = options.threshold.to_f
          resolution_scale.value = options.resolution.to_f
          quality_scale.value = options.quality.to_f
        end
      end

      # Strip metadata
      strip_row = Adw::ActionRow.new
      strip_row.title = GoblinApp.translate("Strip metadata")
      strip_row.subtitle = GoblinApp.translate("Remove metadata like EXIF, IPTC, XMP, and ICC profiles from output file")

      switch = Gtk::Switch.new
      switch.valign = :center
      switch.halign = :center
      switch.active = true
      switch.state_set_signal.connect do |state|
        @form_data = @form_data.copy_with(options: @form_data.options.copy_with(strip_metadata: state))
        false
      end

      switch_box = Gtk::Box.new(:horizontal, 0)
      switch_box.append(switch)
      strip_row.add_suffix(switch_box)

      group.add(strip_row)
      box.append(group)
    end

    private def create_scale_row(title, subtitle, min, max, step, default, &block : Float64 ->) : Tuple(Adw::ActionRow, Gtk::Scale)
      row = Adw::ActionRow.new

      label_box = Gtk::Box.new(:vertical, 5)
      label_box.margin_top = 6
      label_box.margin_bottom = 6

      label = Gtk::Label.new(title)
      label.hexpand = false
      label.set_size_request(250, -1)
      label.xalign = 0

      subtitle_label = Gtk::Label.new
      subtitle_label.hexpand = false
      subtitle_label.set_size_request(250, -1)
      subtitle_label.xalign = 0
      subtitle_label.add_css_class("dim-label")
      subtitle_label.markup = "<small>#{subtitle}</small>"

      label_box.append(label)
      label_box.append(subtitle_label)
      row.add_prefix(label_box)

      adjustment = Gtk::Adjustment.new(default, min, max, step, step, 0)
      scale = Gtk::Scale.new(:horizontal, adjustment)
      scale.hexpand = true
      scale.draw_value = true
      scale.value = default
      scale.set_size_request(300, -1)
      scale.value_pos = :right

      callback = block
      scale.value_changed_signal.connect do
        value = scale.value
        snapped = ((value / step).round * step)
        adjustment.value = snapped unless value == snapped
        callback.call(adjustment.value)
      end

      row.add_suffix(scale)
      {row, scale}
    end
  end
end
