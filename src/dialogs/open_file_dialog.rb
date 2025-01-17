class OpenFileDialog
  def self.show(parent:, title:, action:)
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
end