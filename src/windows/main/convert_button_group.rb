
module ConvertButtonGroup
  # @param [Gtk::Box] box to add the group to
  def create_convert_button_group(box:, parent:, app:)

    # Create a ListBox
    list_box = Gtk::ListBox.new
    list_box.selection_mode = :none
    list_box.add_css_class("boxed-list-separate")

    # Create a Suggested Button (Primary Action)
    suggested_button = Adwaita::ButtonRow.new
    suggested_button.title = _("Convert")
    suggested_button.activatable = true
    suggested_button.add_css_class "suggested-action" # Makes it a primary action
    suggested_button.add_css_class "boxed-list-separate" # Makes it a primary action
    suggested_button.set_end_icon_name "document-revert-rtl-symbolic"
    suggested_button.signal_connect("activated") { puts "Continue button clicked!" }
    list_box.append suggested_button

    suggested_button.signal_connect("activated") do
      source_file = @form_data.source_path.to_s
      output_file = @form_data.target_path.to_s
      if File.exist?(output_file)
        GoblinApp.show_overwrite_dialog(parent) do |response|
          if response == "overwrite"
            puts "User chose to overwrite the file."
            # Overwrite file logic here
          else
            puts "User canceled the operation."
            # Cancel logic here
          end
        end
      end
      mode = @form_data.options.mode
      density = @form_data.options.resolution.to_i
      threshold = @form_data.options.threshold.to_i
      quality = @form_data.options.quality.to_i

      if !["", nil].include?(source_file) && !["", nil].include?(output_file)
        info = GoblinApp.show_custom_dialog(parent, text: _("Converting..."), message_type: :info)
        sleep 0.25
        mode_parameter = if mode == "monochrome"
                           "-threshold #{threshold}% -monochrome -compress Fax"
                         elsif mode == "grayscale"
                           "-colorspace Gray -compress Zip"
                         elsif mode == "grayscale_quality"
                           "-colorspace Gray -compress JPEG -quality #{quality}"
                         elsif mode == "color"
                           "-compress JPEG -quality #{quality}"
                         else
                           "monochrome"
                         end
        command = "magick -density #{density} #{Shellwords.escape(source_file)} #{mode_parameter} -strip #{Shellwords.escape(output_file)}"
        puts "Executing command: #{command}"
        ret = system(command)
        info.destroy
        if ret
          GoblinApp.show_custom_dialog(parent, text: _("Conversion Complete!"), message_type: :info)
        else
          GoblinApp.show_custom_dialog(parent, text: _("An error occurred while conversion!"), message_type: :error)
        end
      else
        GoblinApp.show_custom_dialog(parent, text: _("Please select both source and output files."), message_type: :error)
      end
    end

    box.append(list_box)
  end

  def validate_form_data

  end

end