require "libadwaita"
require "gettext"

require "./modules/prerequisites"
require "./modules/functions/dialogs"
require "./modules/functions/open_file_dialog"
require "./modules/functions/file_launcher_patch"
require "./modules/functions/subprocess_patch"
require "./modules/functions/conversion_logic"
require "./modules/views/main_window"

module GoblinApp
  class App < Adw::Application
    def initialize
      super(application_id: "de.magynhard.GoblinConverter", flags: Gio::ApplicationFlags::HandlesOpen)
      open_signal.connect do |files, _hint|
        files.each do |file|
          if path = file.path
            MainWindow.new(self, source_path: path.to_s)
          else
            GoblinApp.log("File ignored: only local files are supported: #{file.uri}")
          end
        end
      end
    end

    @[GObject::Virtual]
    def activate
      MainWindow.new(self)
    end
  end
end

exit(GoblinApp::App.new.run)
