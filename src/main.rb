#!/usr/bin/env ruby

require_relative "dependency_check"

require_relative '../lib/gettext_setup'
GetTextSetup.initialize
include GetText

require 'gtk4'
require 'adwaita'
require 'shellwords'

require_relative 'dialogs/about_dialog'
require_relative 'dialogs/open_file_dialog'

require_relative 'windows/main_window'

class GoblinApp

  def initialize
    Adwaita.init
    @argument = ARGV.join(" ")
    @app = Adwaita::Application.new("de.magynhard.GoblinConverter", :flags_none)

    resource_data = Gio::Resource.load(File.expand_path(File.dirname(__FILE__) + '/../data/goblin-converter.gresource'))
    Gio::Resources.register(resource_data)

    Gtk::Window.set_default_icon_name('de.magynhard.GoblinConverter')

    @app.signal_connect("activate") do |application|
      MainWindow.show(app: application)
    end
  end


  def self.show_custom_dialog(parent, title: "Info", text:, message_type: :default)
    dialog = Gtk::Dialog.new(parent: parent, title: message_type == :info ? "Information" : "Error", flags: :modal)
    dialog.set_default_size(300, 150)

    content_area = dialog.content_area
    content_area.margin_top = 20
    content_area.margin_bottom = 20
    content_area.margin_start = 20
    content_area.margin_end = 20

    # Icon hinzufügen
    icon = Gtk::Image.new(resource: '/de/magynhard/GoblinConverter/app-icon.svg')
    icon.set_pixel_size(128)
    content_area.append(icon)

    # Text hinzufügen
    label = Gtk::Label.new(text)
    label.margin_top = 10
    label.margin_bottom = 10
    content_area.append(label)

    # OK-Button hinzufügen
    ok_button = Gtk::Button.new(label: "OK")
    ok_button.signal_connect("clicked") do
      dialog.destroy
    end
    content_area.append(ok_button)

    dialog.show
    dialog
  end

  # @param [:destructive|:default|:suggested] message_type
  def self.show_error_dialog(parent, title:, text:, message_type: :default)
    # Create the Adw.MessageDialog
    dialog = Adwaita::MessageDialog.new parent, title, text

    # dialog.heading = title
    # dialog.body = text

    # Add a close button to dismiss the dialog
    dialog.add_response("close", "OK")
    dialog.set_default_response("close")
    dialog.set_response_appearance("close", message_type) # Red button for errors

    # Connect the response signal to handle user actions
    dialog.signal_connect("response") do |_dialog, response|
      puts "Dialog closed with response: #{response}"
      dialog.destroy # Close the dialog after response
    end

    # Show the dialog
    dialog.present
    dialog
  end

  def self.show_overwrite_dialog(parent_window)
    response = nil

    dialog = Adwaita::MessageDialog.new(
      parent_window,
      "File Already Exists",
      "The file already exists. Do you want to overwrite it?"
    )

    dialog.add_response("cancel", "_Cancel")
    dialog.add_response("overwrite", "_Overwrite")

    dialog.set_default_response("overwrite")
    dialog.set_close_response("cancel")

    dialog.signal_connect("response") do |_, res|
      response = res
      dialog.destroy
    end

    dialog.present

    while response.nil?
      Gtk.main_iteration
    end

    response
  end

  def run
    @app.run
  end
end

GoblinApp.new.run