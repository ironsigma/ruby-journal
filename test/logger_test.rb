require 'test_helper'

# Tests
class LoggerTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Logger::VERSION
  end
end
