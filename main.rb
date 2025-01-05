#!/usr/bin/env ruby

require 'gtk4'
require 'adwaita'

class GoblinApp
  def initialize
    Adwaita.init
    @app = Adwaita::Application.new("de.magynhard.goblin", :flags_none)

    @app.signal_connect("activate") do |application|
      create_window(application)
    end
  end

  def create_window(application)
    window = Gtk::Window.new()
    window.set_application(application)
    window.set_title("Goblin Document Converter")
    window.set_default_size(400, 300)

    vbox = Gtk::Box.new(:vertical, 10)
    vbox.margin_top = 20
    vbox.margin_bottom = 20
    vbox.margin_start = 20
    vbox.margin_end = 20

    source_button = Gtk::Button.new(label: "Select Source File (PDF, PNG, JPG, ...)")
    output_button = Gtk::Button.new(label: "Select Output File (PDF)")

    @source_entry = Gtk::Entry.new
    @source_entry.text = "No file selected"

    @output_entry = Gtk::Entry.new
    @output_entry.text = "No file selected"

    source_button.signal_connect("clicked") do
      open_file_dialog(window, "Select Source File", Gtk::FileChooserAction::OPEN) do |file|
        if file
          @source_entry.text = file
          @output_entry.text = file.gsub(/\.pdf$/, "_sw.pdf") if @output_entry.text == "No file selected"
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

      if !["No file selected", ""].include?(source_file)  && !["No file selected", "", nil].include?(output_file)
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