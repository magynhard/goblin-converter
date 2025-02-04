
module SourceFileGroup
  # @param [Gtk::Box] box to add the group to
  def create_source_file_group(box:, parent:)
    group = Adwaita::PreferencesGroup.new
    group.title = _("Source")

    @source_entry = Gtk::Entry.new
    @source_entry.text = @source_entry.text = ARGV.join(" ") || ""

    #source_button = Gtk::Button.new(label: _("Select Source File ..."))
    source_button = Gtk::Button.new
    source_button.set_icon_name("document-open-symbolic") # Add icon
    source_button.set_valign(Gtk::Align::CENTER) # Align vertically
    source_button.set_halign(Gtk::Align::CENTER) # Align horizontally

    # Create a box to contain the button
    button_box = Gtk::Box.new(:horizontal)
    button_box.append(source_button)

    @source_file_row = Adwaita::ActionRow.new
    @source_file_row.title = _("Select Source File")
    @source_file_row.subtitle = "-"
    @source_file_row.activatable = true
    @source_file_row.signal_connect("activated") { on_source_row_clicked parent: parent }
    @source_file_row.add_suffix(button_box)

    source_button.signal_connect("clicked") { on_source_row_clicked parent: parent }

    group.add @source_file_row
    box.append(group)
  end

  def on_source_row_clicked(parent:)
    OpenFileDialog.show(parent: parent, title: _("Select Source File"), action: Gtk::FileChooserAction::OPEN, file: @form_data.source_path) do |file|
      if file
        @source_file_row.subtitle = @form_data.source_path = file
        @output_entry_row.subtitle = @form_data.target_path = file.gsub(/\.([a-zA-Z]{3,4})$/, "_converted.\\1")
      end
    end
  end

end