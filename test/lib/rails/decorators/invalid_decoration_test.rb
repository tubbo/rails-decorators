require 'test_helper'

module Rails
  class InvalidDecorationTest < Minitest::Test
    class TestClass
    end

    module TestModule
    end

    def test_duplicate_decorating
      decorate(TestClass, with: 'testing') {}

      assert_raises(Rails::Decorators::InvalidDecorator) do
        decorate(TestClass, with: 'testing') {}
      end
    end

    def test_module_decorating_with_instance_methods
      assert_raises(Rails::Decorators::InvalidDecorator) do
        decorate(TestModule) do
          # class_methods do
          #   def foo
          #     'bar'
          #   end
          # end

          def foo
            'bar'
          end
        end
      end
    end
  end
end
