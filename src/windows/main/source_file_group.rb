
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

    # Set up Drag & Drop target for files
    drop_target = Gtk::DropTarget.new(Gdk::FileList, Gdk::DragAction::COPY)

    drop_target.signal_connect "drop" do |_, value|
      file_list = value.value # Extracts the Gdk::FileList object from GLib::Value

      if file_list.is_a?(Gdk::FileList)
        files = file_list.files.map { |file| file.path } # Get file paths
        @source_file_row.subtitle = @form_data.source_path = files.first
        @output_entry_row.subtitle = @form_data.target_path = files.first.gsub(/\.([a-zA-Z]{3,4})$/, "_converted.\\1")
      else
        puts "Invalid drop format"
      end
      true
    end

    # Attach drop target to the row
    @source_file_row.add_controller(drop_target)

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