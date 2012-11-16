# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require 'test/unit'
require 'strong_parameters'
require 'mocha'
require 'active_support/test_case'
require 'action_controller/test_process'

ActionController::Routing::Routes.reload rescue nil

MissingSourceFile::REGEXPS << [/^cannot load such file -- (.+)$/i, 1]

ActionController::TestCase.class_eval do
  def response
    @response
  end
end
