#!/usr/bin/env ruby

require 'gtk4'
require 'adwaita'
require 'shellwords'

class GoblinApp
  def initialize
    Adwaita.init
    @app = Adwaita::Application.new("de.magynhard.goblin", :flags_none)

    @app.signal_connect("activate") do |application|
      create_window(application)
    end

    add_actions
  end

  def create_window(application)
    # window = Gtk::Window.new()
    window = Gtk::ApplicationWindow.new(application)
    window.set_application(application)
    window.set_title("Goblin")
    window.set_default_size(400, 300)

    vbox = Gtk::Box.new(:vertical, 10)
    vbox.margin_top = 20
    vbox.margin_bottom = 20
    vbox.margin_start = 20
    vbox.margin_end = 20

    create_menu(window)

    source_button = Gtk::Button.new(label: "Select Source File (PDF, PNG, JPG, ...)")
    output_button = Gtk::Button.new(label: "Select Output File (PDF)")

    @source_entry = Gtk::Entry.new
    @source_entry.text = ""

    @output_entry = Gtk::Entry.new
    @output_entry.text = ""

    source_button.signal_connect("clicked") do
      open_file_dialog(window, "Select Source File", Gtk::FileChooserAction::OPEN) do |file|
        if file
          @source_entry.text = file
          @output_entry.text = file.gsub(/\.pdf$/, "_sw.pdf")
        end
      end
    end

    output_button.signal_connect("clicked") do
      open_file_dialog(window, "Select Output File", Gtk::FileChooserAction::SAVE) do |file|
        @output_entry.text = file if file
      end
    end

    dropdown = Gtk::ComboBoxText.new
    dropdown.append_text("Monochrome")
    dropdown.active = 0
    vbox.append(Gtk::Label.new("Conversion Mode:"))
    vbox.append(dropdown)

    adjustment = Gtk::Adjustment.new(300, 50, 500, 25, 25, 0)
    density_scale = Gtk::Scale.new(:horizontal, adjustment)
    density_scale.value = 300
    density_scale.draw_value = true
    density_scale.value_pos = :top

    density_scale.signal_connect("value-changed") do
      value = density_scale.value
      step = adjustment.step_increment
      snapped_value = ((value / step).round) * step
      adjustment.value = snapped_value unless value == snapped_value
    end

    adjustment2 = Gtk::Adjustment.new(66, 0, 100, 1, 1, 0)
    threshold_scale = Gtk::Scale.new(:horizontal, adjustment2)
    threshold_scale.value = 66
    threshold_scale.draw_value = true
    threshold_scale.value_pos = :top

    threshold_scale.signal_connect("value-changed") do
      value = threshold_scale.value
      step = adjustment2.step_increment
      snapped_value = ((value / step).round) * step
      adjustment2.value = snapped_value unless value == snapped_value
    end

    vbox.append(Gtk::Label.new("Density (default 300):"))
    vbox.append(density_scale)

    vbox.append(Gtk::Label.new("Threshold (default 66%):"))
    vbox.append(threshold_scale)

    vbox.append(Gtk::Label.new("Source File:"))
    vbox.append(@source_entry)
    vbox.append(source_button)

    vbox.append(Gtk::Label.new("Output File:"))
    vbox.append(@output_entry)
    vbox.append(output_button)

    convert_button = Gtk::Button.new(label: "Convert")
    vbox.append(convert_button)

    convert_button.signal_connect("clicked") do
      source_file = @source_entry.text
      output_file = @output_entry.text
      mode = dropdown.active_text.downcase
      density = density_scale.value.to_i
      threshold = threshold_scale.value.to_i

      if !["", nil].include?(source_file)  && !["", nil].include?(output_file)
        mode = if mode == "monochrome"
                 "monochrome"
               else
                 "monochrome"
               end
        command = "magick -density #{density} #{Shellwords.escape(source_file)} -threshold #{threshold}% -#{mode} -strip -compress Fax #{Shellwords.escape(output_file)}"
        system(command)
        show_custom_dialog(window, "Conversion Complete!", :info)
      else
        show_custom_dialog(window, "Please select both source and output files.", :error)
      end
    end

    window.child = vbox
    window.present
  end

  def create_menu(window)# Create a box to hold the menu button
    # Create a header bar (top bar)
    header_bar = Gtk::HeaderBar.new

    # Create a box to hold the header and sub-header
    header_box = Gtk::Box.new(:vertical, 0)

    # Create the main header label (big title)
    main_title = Gtk::Label.new
    main_title.set_markup('<span font_weight="bold" font_size="11000" foreground="white">Goblin</span>')
    main_title.halign = :center # Align to the start (left)

    # Create the sub-header label
    sub_title = Gtk::Label.new
    sub_title.set_markup('<span font_size="8000" foreground="gray">~Path or other info</span>')
    sub_title.halign = :center # Align to the start (left)

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
    menu_model.append('Settings', 'app.settings')
    menu_model.append('Help', 'app.help')
    menu_model.append('Exit', 'app.quit')

    # Set the menu model to the popover
    popover.menu_model = menu_model

    # Add actions for the menu items
    @app.add_action(Gio::SimpleAction.new('settings').tap { |action|
      action.signal_connect('activate') { puts 'Settings clicked!' }
    })
    @app.add_action(Gio::SimpleAction.new('help').tap { |action|
      action.signal_connect('activate') { puts 'Help clicked!' }
    })
    @app.add_action(Gio::SimpleAction.new('quit').tap { |action|
      action.signal_connect('activate') { window.close }
    })

    # Add the burger menu to the header bar
    header_bar.pack_end(burger_menu)

    # Set the header bar as the title bar of the window
    window.set_titlebar(header_bar)
  end

  def add_actions
    about_action = Gio::SimpleAction.new("about")
    about_action.signal_connect("activate") do
      show_about_dialog
    end
    @app.add_action(about_action)
  end

  def show_about_dialog
    dialog = Gtk::AboutDialog.new
    dialog.program_name = "Goblin"
    dialog.version = "1.0"
    dialog.comments = "This is a sample application."
    dialog.present
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
    dialog.set_default_size(300, 100)

    content_area = dialog.content_area
    label = Gtk::Label.new(text)
    content_area.append(label)

    ok_button = Gtk::Button.new(label: "OK")
    ok_button.signal_connect("clicked") do
      dialog.destroy
    end
    content_area.append(ok_button)

    dialog.show
  end

  def run
    @app.run
  end
end

GoblinApp.new.run