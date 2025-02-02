
module ConversionModeGroup
  # @param [Gtk::Box] box to add the group to
  def create_conversion_mode_group(box:, parent:)
    group = Adwaita::PreferencesGroup.new
    group.title = _("Conversion")

    @source_entry = Gtk::Entry.new
    @source_entry.text = @source_entry.text = ARGV.join(" ") || ""

    #source_button = Gtk::Button.new(label: _("Select Source File ..."))
    source_button = Gtk::Button.new
    source_button.set_icon_name("document-save-symbolic") # Add icon
    source_button.set_valign(Gtk::Align::CENTER) # Align vertically
    source_button.set_halign(Gtk::Align::CENTER) # Align horizontally

    # Create a box to contain the button
    button_box = Gtk::Box.new(:horizontal)
    button_box.append(source_button)

    @output_entry_row = Adwaita::ActionRow.new
    @output_entry_row.title = _("Select target file")
    @output_entry_row.subtitle = "-"
    @output_entry_row.activatable = true
    @output_entry_row.signal_connect("activated") { on_conversion_row_clicked parent: parent }
    @output_entry_row.add_suffix(button_box)

    source_button.signal_connect("clicked") { on_conversion_row_clicked parent: parent }

    group.add @output_entry_row
    box.append(group)
  end

  def on_conversion_row_clicked(parent:)
    OpenFileDialog.show(parent: parent, title: _("Select target file"), action: Gtk::FileChooserAction::SAVE) do |file|
      if file
        @output_entry_row.subtitle = @output_entry = file
      end
    end
  end

end