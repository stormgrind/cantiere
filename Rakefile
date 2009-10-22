$: << 'lib'

additional_libs = [ "net-ssh", "net-sftp" ]

additional_libs.each do |lib|
  $LOAD_PATH.unshift( "#{File.dirname( __FILE__ )}/lib/#{lib}/lib" )
end

require 'cantiere/helpers/rake-helper'

Cantiere::RakeHelper.new
