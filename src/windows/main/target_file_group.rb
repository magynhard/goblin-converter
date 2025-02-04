
module TargetFileGroup
  # @param [Gtk::Box] box to add the group to
  def create_target_file_group(box:, parent:)
    group = Adwaita::PreferencesGroup.new
    group.title = _("Target")

    @source_entry = Gtk::Entry.new
    @source_entry.text = @source_entry.text = ARGV.join(" ") || ""

    source_button = Gtk::Button.new
    source_button.set_icon_name("document-save-symbolic") # Add icon
    source_button.set_valign(Gtk::Align::CENTER) # Align vertically
    source_button.set_halign(Gtk::Align::CENTER) # Align horizontally

    edit_button = Gtk::Button.new
    edit_button.set_icon_name("document-edit-symbolic") # Add icon
    edit_button.set_valign(Gtk::Align::CENTER) # Align vertically
    edit_button.set_halign(Gtk::Align::CENTER) # Align horizontally
    edit_button.margin_end = 10

    # Create a box to contain the button
    button_box = Gtk::Box.new(:horizontal)
    button_box.append(edit_button)
    button_box.append(source_button)

    @output_entry_row = Adwaita::ActionRow.new
    @output_entry_row.title = _("Select target file")
    @output_entry_row.subtitle = "-"
    @output_entry_row.activatable = true
    @output_entry_row.signal_connect("activated") { on_target_row_clicked parent: parent }
    @output_entry_row.add_suffix(button_box)

    source_button.signal_connect("clicked") { on_target_row_clicked parent: parent }
    edit_button.signal_connect("clicked") do
      on_target_row_edit_clicked(parent: parent, text: @form_data.target_path) do |edited_text|
        @form_data.target_path = edited_text
        @output_entry_row.subtitle = edited_text
      end
    end

    # Set up Drag & Drop target for files
    drop_target = Gtk::DropTarget.new(Gdk::FileList, Gdk::DragAction::COPY)

    drop_target.signal_connect "drop" do |_, value|
      file_list = value.value # Extracts the Gdk::FileList object from GLib::Value
      if file_list.is_a?(Gdk::FileList)
        files = file_list.files.map { |file| file.path } # Get file paths
        @output_entry_row.subtitle = @form_data.target_path = files.first
      else
        puts "Invalid drop format"
      end
      true
    end

    # Attach drop target to the row
    @output_entry_row.add_controller(drop_target)

    group.add @output_entry_row
    box.append(group)
  end

  def on_target_row_clicked(parent:)
    OpenFileDialog.show(parent: parent, title: _("Select target file"), action: Gtk::FileChooserAction::SAVE, file: @form_data.target_path) do |file|
      if file
        @output_entry_row.subtitle = @form_data.target_path = file
      end
    end
  end
  def on_target_row_edit_clicked(parent:, text: "")
    dialog = Adwaita::MessageDialog.new(parent, _("Edit path"), "")
    dialog.set_default_size(800, 150)

    # Fügen Sie ein Eingabefeld hinzu
    entry = Gtk::Entry.new
    entry.text = text || ""
    dialog.set_extra_child(entry)

    # Fügen Sie die Schaltflächen hinzu
    dialog.add_response("cancel", "_Cancel")
    dialog.add_response("apply", "_Apply")
    dialog.set_response_appearance("apply", :suggested)

    dialog.set_default_response("apply")
    dialog.set_close_response("cancel")

    dialog.signal_connect("response") do |_, response|
      if response == "apply"
        @output_entry_row.subtitle = @form_data.target_path = entry.text
      end
      dialog.destroy
    end

    dialog.present
  end

end