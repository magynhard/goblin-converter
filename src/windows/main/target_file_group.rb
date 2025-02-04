
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
    dialog = Gtk::Dialog.new(title: _("Edit path"), parent: parent, flags: :modal)
    dialog.set_default_size(640, 64)
    cancel_button = dialog.add_button("_Cancel", Gtk::ResponseType::CANCEL)
    apply_button = dialog.add_button("_Apply", Gtk::ResponseType::APPLY)
    apply_button.set_css_classes(["suggested-action"])
    apply_button.margin_end = 15
    apply_button.margin_bottom = 15
    cancel_button.margin_bottom = 15

    content_area = dialog.content_area
    content_area.margin_top = 20
    content_area.margin_bottom = 20
    content_area.margin_start = 20
    content_area.margin_end = 20

    entry = Gtk::Entry.new
    entry.text = text || ""
    content_area.append(entry)

    dialog.set_default_response(Gtk::ResponseType::APPLY)

    dialog.signal_connect("response") do |dia, response|
      if response == Gtk::ResponseType::APPLY
        @output_entry_row.subtitle = @form_data.target_path = entry.text
      end
      dia.destroy
    end
    dialog.show
  end

end