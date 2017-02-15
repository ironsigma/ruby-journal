require 'test_helper'

# Tests
class JournalTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Journal::VERSION
  end
end
