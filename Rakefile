require 'rake'
require 'fileutils'



desc "Install the application"
task :install do
  # Check if bundle command is available
  unless system("bash -lc 'command -v bundle > /dev/null'")
    puts "Error: Bundler is not installed. Running 'gem install bundler' to install it ..."
    sh "bash -lc 'gem install bundler'"
  end

  # Check current Ruby version
  ruby_version = `bash -lc "ruby -v"`.split[1]
  match = ruby_version.match(/([0-9]+.[0-9]+.[0-9]+)/)
  ruby_version = match[1] if match

  # Create .ruby-version file with current Ruby version
  File.write('.ruby-version', ruby_version)

  # Get current path
  current_path = Dir.pwd

  # Run bundle install to install dependencies
  sh "bash -lc 'bundle install'"

  sh "sudo cp '#{File.dirname(__FILE__)}/data/icons/app-icon.svg' '/usr/share/icons/de.magynhard.GoblinDoc.svg'"

  # Target for .desktop file
  desktop_file = File.join('/usr/share/applications/de.magynhard.GoblinDoc.desktop')
  # Copy .desktop file and replace placeholder with actual path
  sh "sudo cp '#{File.dirname(__FILE__)}/data/de.magynhard.GoblinDoc.desktop' #{desktop_file}"
  sh "sudo cp '#{File.dirname(__FILE__)}/goblin-doc' /usr/bin/goblin-doc"

  sh "sudo mkdir -p /usr/share/goblin-doc"

  Dir["#{File.dirname(__FILE__)}/*"].each do |file|
    unless File.directory?(file)
      sh "sudo cp '#{file}' /usr/share/goblin-doc/"
    end
  end
  sh "sudo cp '#{File.dirname(__FILE__)}/.ruby-version' /usr/share/goblin-doc/.ruby-version"
  sh "sudo cp -r '#{File.dirname(__FILE__)}/data' /usr/share/goblin-doc"
  sh "sudo cp -r '#{File.dirname(__FILE__)}/src' /usr/share/goblin-doc"

  puts "Installation complete. You can now run Goblin Document Converter from the applications menu."
end



desc "Uninstall the application"
task :uninstall do
  desktop_file = File.join('/usr/share/applications/goblin-doc.desktop')
  icon_file = File.join('/usr/share/icons/de.magynhard.GoblinDoc.svg')
  binary_file = File.join('/usr/bin/goblin-doc')
  binary_assets = File.join('/usr/share/goblin-doc')

  if File.exist?(desktop_file)
    sh "sudo rm #{desktop_file}"
    puts "The .desktop file has been successfully removed from #{desktop_file}."
  else
    puts "The .desktop file does not exist at #{desktop_file}."
  end

  if File.exist?(icon_file)
    sh "sudo rm #{icon_file}"
    puts "The icon file has been successfully removed from #{icon_file}."
  else
    puts "The icon file does not exist at #{icon_file}."
  end

  if File.exist?(binary_file)
    sh "sudo rm #{binary_file}"
    puts "The binary file has been successfully removed from #{binary_file}."
  else
    puts "The binary file does not exist at #{binary_file}."
  end

  if Dir.exist?(binary_assets)
    sh "sudo rm -rf #{binary_assets}"
    puts "The binary assets have been successfully removed from #{binary_assets}."
  else
    puts "The binary assets do not exist at #{binary_assets}."
  end
end



desc "Generate locale files"
task :generate_locales do
  pot_files = File.read("#{File.dirname(__FILE__)}/po/POTFILES").split("\n")
  Dir.mkdir("po") unless Dir.exist?("po")
  sh "bash -lc 'xgettext -o po/goblin-doc.pot --from-code=UTF-8 --keyword=_ #{pot_files.join(' ')}'"
  locales = File.read("#{File.dirname(__FILE__)}/po/LINGUAS").split("\n")
  locales.each do |locale|
    locale_dir = "po/#{locale}/LC_MESSAGES"
    FileUtils.mkdir_p(locale_dir)
    po_file = "#{locale_dir}/goblin-doc.po"
    if File.exist?(po_file)
      sh "bash -lc 'msgmerge --update --backup=none #{po_file} po/goblin-doc.pot'"
    else
      sh "bash -lc 'msginit --input=po/goblin-doc.pot --locale=#{locale} --output=#{po_file} --no-translator'"
    end
  end
end



desc "Compile locale files"
task :compile_locales do
  locales = File.read("#{File.dirname(__FILE__)}/po/LINGUAS").split("\n")
  locales.each do |locale|
    out_dir = "po/#{locale}/LC_MESSAGES"
    FileUtils.mkdir_p(out_dir)
    sh "msgfmt po/#{locale}/LC_MESSAGES/goblin-doc.po -o po/#{locale}/LC_MESSAGES/goblin-doc.mo"
  end
end



desc "Run some basic tests"
task :test do
  puts "Validate desktop file ... "
  system "desktop-file-validate data/de.magynhard.GoblinDoc.desktop"
end