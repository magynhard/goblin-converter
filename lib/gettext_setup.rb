require 'gettext'
require 'gettext-setup'

module GetTextSetup
  def self.initialize
    GetText.bindtextdomain('goblin-doc', path: File.expand_path('../../po', __FILE__), output_charset: 'UTF-8')
  end
end