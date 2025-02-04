class OpenFileDialog
  def self.show(parent:, title:, action:, file: nil)
    dialog = Gtk::FileChooserDialog.new(title: title, parent: parent, action: action)
    dialog.add_button("_Cancel", Gtk::ResponseType::CANCEL)
    dialog.add_button("_Open", Gtk::ResponseType::ACCEPT) if action == Gtk::FileChooserAction::OPEN
    dialog.add_button("_Apply", Gtk::ResponseType::ACCEPT) if action == Gtk::FileChooserAction::SAVE
    dialog.set_modal(true)
    puts "FILE: #{file}"
    if file && !file.empty?
      dir = if File.directory? file
              file
            elsif File.file? file
              File.dirname file
            else
              file
            end
      dialog.set_current_folder(Gio::File.new_for_path(dir))
      dialog.set_current_name File.basename(file)
    end
    dialog.signal_connect("response") do |d, response|
      if response == Gtk::ResponseType::ACCEPT
        yield d.file.path
      end
      d.destroy
    end
    dialog.show
  end
end