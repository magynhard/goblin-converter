#!/usr/bin/env ruby

require_relative "dependency_check"

require_relative '../lib/gettext_setup'
GetTextSetup.initialize
include GetText

require 'gtk4'
require 'adwaita'
require 'shellwords'

class GoblinApp
  def initialize
    Adwaita.init
    @app = Adwaita::Application.new("de.magynhard.GoblinDoc", :flags_none)

    resource_data = Gio::Resource.load(File.expand_path(File.dirname(__FILE__) + '/../data/goblin-doc.gresource'))
    Gio::Resources.register(resource_data)

    # Setzen des Standard-App-Icons
    Gtk::Window.set_default_icon_name('de.magynhard.GoblinDoc')

    @app.signal_connect("activate") do |application|
      create_window(application)
    end

  end

  def create_window(application)
    # window = Gtk::Window.new()
    window = Gtk::ApplicationWindow.new(application)
    window.set_application(application)
    window.set_title("Goblin Doc")
    window.set_default_size(400, 300)

    vbox = Gtk::Box.new(:vertical, 10)
    vbox.margin_top = 20
    vbox.margin_bottom = 20
    vbox.margin_start = 20
    vbox.margin_end = 20

    create_menu(window)

    source_button = Gtk::Button.new(label: _("Select Source File ..."))
    output_button = Gtk::Button.new(label: _("Select Output File ..."))

    @source_entry = Gtk::Entry.new
    @source_entry.text = ""

    @output_entry = Gtk::Entry.new
    @output_entry.text = ""

    source_button.signal_connect("clicked") do
      open_file_dialog(window, _("Select Source File"), Gtk::FileChooserAction::OPEN) do |file|
        if file
          @source_entry.text = file
          @output_entry.text = file.gsub(/\.pdf$/, "_sw.pdf")
        end
      end
    end

    output_button.signal_connect("clicked") do
      open_file_dialog(window, _("Select Output File"), Gtk::FileChooserAction::SAVE) do |file|
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

    threshold_adjustment = Gtk::Adjustment.new(66, 0, 100, 1, 1, 0)
    threshold_scale = Gtk::Scale.new(:horizontal, threshold_adjustment)
    threshold_scale.value = 66
    threshold_scale.draw_value = true
    threshold_scale.value_pos = :top

    threshold_scale.signal_connect("value-changed") do
      value = threshold_scale.value
      step = threshold_adjustment.step_increment
      snapped_value = ((value / step).round) * step
      threshold_adjustment.value = snapped_value unless value == snapped_value
    end

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
      mode = conversion_modes[dropdown.active_text]
      density = density_scale.value.to_i
      threshold = threshold_scale.value.to_i
      quality = quality_scale.value.to_i

      if !["", nil].include?(source_file) && !["", nil].include?(output_file)
        info = show_custom_dialog(window, _("Converting..."), :info)
        sleep 0.5
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
        system(command)
        info.destroy
        show_custom_dialog(window, _("Conversion Complete!"), :info)
      else
        show_custom_dialog(window, _("Please select both source and output files."), :error)
      end
    end

    window.child = vbox
    window.present
  end

  def create_menu(window)
    # Create a box to hold the menu button
    # Create a header bar (top bar)
    header_bar = Gtk::HeaderBar.new

    # Create a box to hold the header and sub-header
    header_box = Gtk::Box.new(:vertical, 0)

    # Create the main header label (big title)
    main_title = Gtk::Label.new
    main_title.set_markup(%Q(<span font_weight="bold" font_size="11000" foreground="white">#{'Goblin Doc'}</span>))
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
    @app.add_action(Gio::SimpleAction.new('settings').tap { |action|
      action.signal_connect('activate') { puts 'Settings clicked!' }
    })
    @app.add_action(Gio::SimpleAction.new('about').tap { |action|
      action.signal_connect('activate') { show_about_dialog(window) }
    })

    # Add the burger menu to the header bar
    header_bar.pack_end(burger_menu)

    # Set the header bar as the title bar of the window
    window.set_titlebar(header_bar)
  end

  def show_about_dialog(parent)
    # dialog = Adwaita::AboutDialog.new('/de/magynhard/GoblinDoc/metainfo.xml')
    dialog = Adwaita::AboutDialog.new #('resource:///de/magynhard/GoblinDoc/de.magynhard.GoblinDoc.metainfo.xml.in')
    dialog.application_name = "Goblin Doc"
    dialog.developer_name = %Q(#{_("A simple document converter")}\n\n#{RUBY_ENGINE} #{RUBY_VERSION}@#{RUBY_PLATFORM}])
    dialog.application_icon = "de.magynhard.GoblinDoc"
    dialog.website = "https://github.com/magynhard/goblin-doc?tab=readme-ov-file#readme"
    dialog.issue_url = "https://github.com/magynhard/goblin-doc/issues"
    dialog.version = "0.2.1"
    dialog.developers = ["Matthäus J. N. Beyrle <goblin-doc.github.com@mail.magynhard.de>"]
    dialog.license_type = Gtk::License::MIT_X11

    dialog.show
    dialog.present(parent)
  end

  def open_file_dialog(parent, title, action)
    dialog = Gtk::FileChooserDialog.new(title: title, parent: parent, action: action)
    dialog.add_button("_Cancel", Gtk::ResponseType::CANCEL)
    dialog.add_button("_Open", Gtk::ResponseType::ACCEPT) if action == Gtk::FileChooserAction::OPEN
    dialog.add_button("_Save", Gtk::ResponseType::ACCEPT) if action == Gtk::FileChooserAction::SAVE

    dialog.set_modal(true)
    dialog.signal_connect("response") do |d, response|
      if response == Gtk::ResponseType::ACCEPT
        yield d.file.path
      end
      d.destroy
    end

    dialog.show
  end

  def show_custom_dialog(parent, text, message_type)
    dialog = Gtk::Dialog.new(parent: parent, title: message_type == :info ? "Information" : "Error", flags: :modal)
    dialog.set_default_size(300, 150)

    content_area = dialog.content_area
    content_area.margin_top = 20
    content_area.margin_bottom = 20
    content_area.margin_start = 20
    content_area.margin_end = 20

    # Icon hinzufügen
    icon = Gtk::Image.new(resource: '/de/magynhard/GoblinDoc/app-icon.svg')
    icon.set_pixel_size(128)
    content_area.append(icon)

    # Text hinzufügen
    label = Gtk::Label.new(text)
    label.margin_top = 10
    label.margin_bottom = 10
    content_area.append(label)

    # OK-Button hinzufügen
    ok_button = Gtk::Button.new(label: "OK")
    ok_button.signal_connect("clicked") do
      dialog.destroy
    end
    content_area.append(ok_button)

    dialog.show
    dialog
  end

  def run
    @app.run
  end
end

GoblinApp.new.run