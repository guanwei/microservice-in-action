project_root = File.dirname(__FILE__) + '/..'
$LOAD_PATH << "#{project_root}/api"
require 'grape'
require 'api'