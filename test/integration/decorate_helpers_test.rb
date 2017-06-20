require 'test_helper'

class DecorateHelpersTest < ActionDispatch::IntegrationTest
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  def test_foo
    visit root_path
    assert_text 'foo: bar baz'
  end

  def teardown
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end
