
class MainWindow

  def self.show(application)
    @@app = application
    @@argument = ARGV.join(" ")
    window = Gtk::ApplicationWindow.new(application)
    window.set_application(application)
    window.set_title("Goblin Converter")
    window.set_default_size(800, 600)

    vbox = Gtk::Box.new(:vertical, 10)
    vbox.margin_top = 20
    vbox.margin_bottom = 20
    vbox.margin_start = 20
    vbox.margin_end = 20

    create_menu(window)

    source_button = Gtk::Button.new(label: _("Select Source File ..."))
    output_button = Gtk::Button.new(label: _("Select Output File ..."))

    @source_entry = Gtk::Entry.new
    @source_entry.text = @source_entry.text = @@argument || ""

    @output_entry = Gtk::Entry.new
    @output_entry.text = @@argument.gsub(/\.([a-zA-Z]{3,4})$/, "_sw.\\1") || ""

    source_button.signal_connect("clicked") do
      OpenFileDialog.show(parent: window, title: _("Select Source File"), action: Gtk::FileChooserAction::OPEN) do |file|
        if file
          @source_entry.text = file
          @output_entry.text = file.gsub(/\.([a-zA-Z]{3,4})$/, "_sw.\\1")
        end
      end
    end

    output_button.signal_connect("clicked") do
      OpenFileDialog.show(parent: window, title: _("Select Output File"), action: Gtk::FileChooserAction::SAVE) do |file|
        @output_entry.text = file if file
      end
    end

    dropdown = Gtk::ComboBoxText.new
    conversion_modes = {
      _("Monochrome") => "monochrome",
      _("Grayscale") => "grayscale",
      _("Grayscale quality") => "grayscale_quality",
      _("Color") => "color",
    }
    conversion_modes.each_key do |label|
      dropdown.append_text(label)
    end
    dropdown.active = 0
    vbox.append(Gtk::Label.new(_("Conversion Mode:")))
    vbox.append(dropdown)

    density_adjustment = Gtk::Adjustment.new(300, 50, 500, 25, 25, 0)
    density_scale = Gtk::Scale.new(:horizontal, density_adjustment)
    density_scale.value = 300
    density_scale.draw_value = true
    density_scale.value_pos = :top

    density_scale.signal_connect("value-changed") do
      value = density_scale.value
      step = density_adjustment.step_increment
      snapped_value = ((value / step).round) * step
      density_adjustment.value = snapped_value unless value == snapped_value
    end

    # put the adjustment in a row

    threshold_adjustment = Gtk::Adjustment.new(66, 0, 100, 1, 1, 0)
    threshold_scale = Gtk::Scale.new(:horizontal, threshold_adjustment)
    threshold_scale.value = 66
    threshold_scale.draw_value = true
    threshold_scale.value_pos = :top
    threshold_scale.set_hexpand(true)

    threshold_scale.signal_connect("value-changed") do
      value = threshold_scale.value
      step = threshold_adjustment.step_increment
      snapped_value = ((value / step).round) * step
      threshold_adjustment.value = snapped_value unless value == snapped_value
    end

    threshold_box = Gtk::Box.new(:horizontal, 10)
    threshold_label = Gtk::Label.new(_("Threshold:"))
    threshold_label.set_xalign(0) # Align to the left
    threshold_box.append(threshold_label)
    threshold_box.append(threshold_scale)
    vbox.append(threshold_box)

    # Preferences Group
    preferences_group = Adwaita::PreferencesGroup.new
    preferences_group.title = "Preferences"
    vbox.append(preferences_group)

    # Action Row: Mouse Speed
    mouse_speed_row = Adwaita::ActionRow.new
    mouse_speed_row.title = "Mouse Speed"
    mouse_speed_row.subtitle = "Perfecto"

    # Slider for Mouse Speed
    adjustment = Gtk::Adjustment.new(5, 0, 10, 1, 0, 0)
    speed_slider = Gtk::Scale.new(:horizontal, adjustment)
    speed_slider.set_hexpand(true)

    # Add slider to the action row
    mouse_speed_row.add_suffix(speed_slider)
    preferences_group.add(mouse_speed_row)

    # Action Row: Natural Scrolling
    natural_scroll_row = Adwaita::ActionRow.new
    natural_scroll_row.title = "Natural Scrolling"

    # Switch for Natural Scrolling
    scroll_switch = Gtk::Switch.new
    natural_scroll_row.add_suffix(scroll_switch)
    preferences_group.add natural_scroll_row
    vbox.append preferences_group

    quality_adjustment = Gtk::Adjustment.new(75, 0, 100, 1, 1, 0)
    quality_scale = Gtk::Scale.new(:horizontal, quality_adjustment)
    quality_scale.value = 75
    quality_scale.draw_value = true
    quality_scale.value_pos = :top

    quality_scale.signal_connect("value-changed") do
      value = quality_scale.value
      step = quality_adjustment.step_increment
      snapped_value = ((value / step).round) * step
      quality_adjustment.value = snapped_value unless value == snapped_value
    end

    vbox.append(Gtk::Label.new(_("Density:")))
    vbox.append(density_scale)

    vbox.append(Gtk::Label.new(_("Threshold:")))
    vbox.append(threshold_scale)

    vbox.append(Gtk::Label.new(_("Quality:")))
    vbox.append(quality_scale)

    # Add option to strip metadata
    strip_metadata = Gtk::CheckButton.new(_("Strip Metadata"))
    strip_metadata.active = true
    vbox.append(strip_metadata)

    vbox.append(Gtk::Label.new(_("Source File:")))
    vbox.append(@source_entry)
    vbox.append(source_button)

    vbox.append(Gtk::Label.new(_("Output File:")))
    vbox.append(@output_entry)
    vbox.append(output_button)

    convert_button = Gtk::Button.new(label: _("Convert"))
    vbox.append(convert_button)

    convert_button.signal_connect("clicked") do
      source_file = @source_entry.text
      output_file = @output_entry.text
      if File.exist?(output_file)
        show_overwrite_dialog(window) do |response|
          if response == "overwrite"
            puts "User chose to overwrite the file."
            # Overwrite file logic here
          else
            puts "User canceled the operation."
            # Cancel logic here
          end
        end
      end
      mode = conversion_modes[dropdown.active_text]
      density = density_scale.value.to_i
      threshold = threshold_scale.value.to_i
      quality = quality_scale.value.to_i

      if !["", nil].include?(source_file) && !["", nil].include?(output_file)
        info = show_custom_dialog(window, text: _("Converting..."), message_type: :info)
        sleep 0.25
        mode_parameter = if mode == "monochrome"
                           "-threshold #{threshold}% -monochrome -compress Fax"
                         elsif mode == "grayscale"
                           "-colorspace Gray -compress Zip"
                         elsif mode == "grayscale_quality"
                           "-colorspace Gray -compress JPEG -quality #{quality}"
                         elsif mode == "color"
                           "-compress JPEG -quality #{quality}"
                         else
                           "monochrome"
                         end
        command = "magick -density #{density} #{Shellwords.escape(source_file)} #{mode_parameter} -strip #{Shellwords.escape(output_file)}"
        ret = system(command)
        info.destroy
        if ret
          show_custom_dialog(window, text: _("Conversion Complete!"), message_type: :info)
        else
          show_custom_dialog(window, text: _("An error occurred while conversion!"), message_type: :error)
        end
      else
        show_custom_dialog(window, text: _("Please select both source and output files."), message_type: :error)
      end
    end

    window.child = vbox
    window.present

    # show_error_dialog(window, title: "Error", text: "This is an error message")
    # show_custom_dialog(window, title: "Error", text: "This is an error message")
  end


  def self.create_menu(window)
    # Create a box to hold the menu button
    # Create a header bar (top bar)
    header_bar = Gtk::HeaderBar.new

    # Create a box to hold the header and sub-header
    header_box = Gtk::Box.new(:vertical, 0)

    # Create the main header label (big title)
    main_title = Gtk::Label.new
    main_title.set_markup(%Q(<span font_weight="bold" font_size="11000">#{'Goblin Converter'}</span>))
    main_title.halign = :center # Align to the start (left)

    # Create the sub-header label
    sub_title = Gtk::Label.new
    sub_title.set_markup(%Q(<span font_size="8000" foreground="gray">#{_("A simple document converter")}</span>))
    sub_title.halign = :center # Align to the start (left)
    sub_title.set_ellipsize(Pango::EllipsizeMode::MIDDLE) # Truncate with ellipsis at the end
    sub_title.set_max_width_chars(50)

    # Add labels to the header box
    header_box.append(main_title)
    header_box.append(sub_title)

    # Add the header box to the header bar
    header_bar.title_widget = header_box

    # Create a Menu Button styled as a hamburger menu
    burger_menu = Gtk::MenuButton.new
    burger_menu.icon_name = 'open-menu-symbolic' # Standard hamburger icon in GTK

    # Create a PopoverMenu for the hamburger menu
    popover = Gtk::PopoverMenu.new
    burger_menu.popover = popover

    # Create a Gio::Menu for the popover
    menu_model = Gio::Menu.new
    menu_model.append(_('Settings'), 'app.settings')
    menu_model.append(_('About'), 'app.about')

    # Set the menu model to the popover
    popover.menu_model = menu_model

    # Add actions for the menu items
    @@app.add_action(Gio::SimpleAction.new('settings').tap { |action|
      action.signal_connect('activate') { puts 'Settings clicked!' }
    })
    @@app.add_action(Gio::SimpleAction.new('about').tap { |action|
      action.signal_connect('activate') { AboutDialog.show(window) }
    })

    # Add the burger menu to the header bar
    header_bar.pack_end(burger_menu)

    # Set the header bar as the title bar of the window
    window.set_titlebar(header_bar)
  end

end