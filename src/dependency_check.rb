#
# Dependency check script
#
# When several ruby versions are installed on the system and the default version changes,
# we want to ensure that the gems are installed for the new default version automatically.
#


# Check if bundle command is available
unless system("bash -lc 'command -v bundle > /dev/null'")
  puts "Error: Bundler is not installed. Running 'gem install bundler' to install it ..."
  system "bash -lc 'gem install bundler'"
end

# Run bundle install to install dependencies
system "bash -lc 'bundle install'"