require 'gtk4'
require 'shellwords'

class GoblinApp
  def initialize
    @app = Gtk::Application.new("com.example.Goblin", :flags_none)

    @app.signal_connect("activate") do |application|
      create_window(application)
    end
  end

  def create_window(application)
    window = Gtk::ApplicationWindow.new(application)
    window.set_title("Goblin")
    window.set_default_size(400, 300)

    vbox = Gtk::Box.new(:vertical, 10)
    vbox.margin_top = 20
    vbox.margin_bottom = 20
    vbox.margin_start = 20
    vbox.margin_end = 20

    source_button = Gtk::Button.new(label: "Select Source File (PDF)")
    output_button = Gtk::Button.new(label: "Select Output File (ODF)")

    @source_label = Gtk::Label.new("No file selected")
    @output_label = Gtk::Label.new("No file selected")

    source_button.signal_connect("clicked") do
      open_file_dialog(window, "Select PDF Source File", Gtk::FileChooserAction::OPEN) do |file|
        @source_label.text = file if file
      end
    end

    output_button.signal_connect("clicked") do
      open_file_dialog(window, "Select Output ODF File", Gtk::FileChooserAction::SAVE) do |file|
        @output_label.text = file if file
      end
    end

    dropdown = Gtk::ComboBoxText.new
    dropdown.append_text("Monochrome")
    dropdown.active = 0
    vbox.append(Gtk::Label.new("Conversion Mode:"))
    vbox.append(dropdown)

    density_scale = Gtk::Scale.new(:horizontal, 50, 500, 25)
    density_scale.value = 300
    density_scale.draw_value = true
    density_scale.value_pos = :top
    vbox.append(Gtk::Label.new("Density (default 300):"))
    vbox.append(density_scale)

    vbox.append(Gtk::Label.new("Source File:"))
    vbox.append(@source_label)
    vbox.append(source_button)

    vbox.append(Gtk::Label.new("Output File:"))
    vbox.append(@output_label)
    vbox.append(output_button)

    convert_button = Gtk::Button.new(label: "Convert")
    vbox.append(convert_button)

    convert_button.signal_connect("clicked") do
      source_file = @source_label.text
      output_file = @output_label.text
      mode = dropdown.active_text.downcase
      density = density_scale.value.to_i

      if source_file != "No file selected" && output_file != "No file selected"
        mode = if mode == "monochrome"
                 "monochrome"
               else
                 "monochrome"
               end
        command = "magick -density #{density} #{Shellwords.escape(source_file)} -threshold 66% -#{mode} -strip -compress Fax #{Shellwords.escape(output_file)}"
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