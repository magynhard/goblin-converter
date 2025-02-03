require 'ostruct'

require_relative 'main/source_file_group'
require_relative 'main/target_file_group'
require_relative 'main/conversion_mode_group'
require_relative 'main/convert_button_group'

class MainWindow

  extend SourceFileGroup, TargetFileGroup, ConversionModeGroup, ConvertButtonGroup

  def self.show(app:)
    @@app = app
    @@argument = ARGV.join(" ")
    @form_data = OpenStruct.new(
      source_path: @@argument || nil,
      target_path: nil,
      options: OpenStruct.new(
        mode: "monochrome",
        resolution: 300,
        threshold: 66,
        quality: 75,
        strip_metadata: true
      )
    )
    window = Gtk::ApplicationWindow.new(app)
    window.set_application(app)
    window.set_title("Goblin Converter")
    window.set_default_size(550, 600)

    vbox = Gtk::Box.new(:vertical, 10)
    vbox.margin_top = 20
    vbox.margin_bottom = 20
    vbox.margin_start = 20
    vbox.margin_end = 20

    create_menu(window)

    create_conversion_mode_group box: vbox, parent: window
    create_source_file_group box: vbox, parent: window
    create_target_file_group box: vbox, parent: window
    create_convert_button_group box: vbox, parent: window, app: app


    window.child = vbox
    window.present

    # show_error_dialog(window, title: "Error", text: "This is an error message")
    # show_custom_dialog(window, title: "Error", text: "This is an error message")
  end

  def self.create_menu(window)
    # Create a box to hold the menu button
    # Create a header bar (top bar)
    header_bar = Gtk::HeaderBar.new

    # Create a box to hold the header and sub-header
    header_box = Gtk::Box.new(:vertical, 0)

    # Create the main header label (big title)
    main_title = Gtk::Label.new
    main_title.set_markup(%Q(<span font_weight="bold" font_size="11000">#{'Goblin Converter'}</span>))
    main_title.halign = :center # Align to the start (left)

    # Create the sub-header label
    sub_title = Gtk::Label.new
    sub_title.set_markup(%Q(<span font_size="8000" foreground="gray">#{_("A simple document converter")}</span>))
    sub_title.halign = :center # Align to the start (left)
    sub_title.set_ellipsize(Pango::EllipsizeMode::MIDDLE) # Truncate with ellipsis at the end
    sub_title.set_max_width_chars(50)

    # Add labels to the header box
    header_box.append(main_title)
    header_box.append(sub_title)

    # Add the header box to the header bar
    header_bar.title_widget = header_box

    # Create a Menu Button styled as a hamburger menu
    burger_menu = Gtk::MenuButton.new
    burger_menu.icon_name = 'open-menu-symbolic' # Standard hamburger icon in GTK

    # Create a PopoverMenu for the hamburger menu
    popover = Gtk::PopoverMenu.new
    burger_menu.popover = popover

    # Create a Gio::Menu for the popover
    menu_model = Gio::Menu.new
    #menu_model.append(_('Settings'), 'app.settings')
    menu_model.append(_('About'), 'app.about')

    # Set the menu model to the popover
    popover.menu_model = menu_model

    # Add actions for the menu items
    @@app.add_action(Gio::SimpleAction.new('settings').tap { |action|
      action.signal_connect('activate') {
        GoblinApp.show_custom_dialog window, title: "", text: "", message_type: :info
        puts 'Settings clicked!'
      }
    })
    @@app.add_action(Gio::SimpleAction.new('about').tap { |action|
      action.signal_connect('activate') { AboutDialog.show(window) }
    })

    # Add the burger menu to the header bar
    header_bar.pack_end(burger_menu)

    # Set the header bar as the title bar of the window
    window.set_titlebar(header_bar)
  end

end