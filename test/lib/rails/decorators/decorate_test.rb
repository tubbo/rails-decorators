require 'test_helper'

class DecorateTest < Minitest::Test
  module TestModule
    def self.foo
      'bar'
    end

    def bar
      'wonder'
    end
  end

  class TestClass
    include TestModule

    def self.foo
      'bar'
    end

    def foo
      'bar'
    end
  end

  class ChildClass < TestClass
  end

  class DifferentTestClass
    def bar
      'hershey'
    end
  end

  def test_decorate
    decorate(TestClass, with: 'testing') do
      class_methods do
        def foo
          "#{super}|baz"
        end
      end

      decorated { attr_reader :test }

      def foo
        "#{super}|baz"
      end
    end

    assert(TestClass.new.respond_to?(:test))
    assert_equal('bar|baz', TestClass.new.foo)
    assert_equal('bar|baz', TestClass.foo)
  end

  def test_subclass_decoration
    decorate(ChildClass, with: 'testing') do
      def baz
        'decorated'
      end
    end

    assert_equal('decorated', ChildClass.new.baz)
  end

  def test_module_definition
    decorate(TestClass, with: 'tests') {}
    assert(TestClass.const_defined?(:TestsTestClassDecorator))
  end

  def test_module_class_methods_decoration
    decorate(TestModule, with: 'tests') do
      class_methods do
        def foo
          "#{super}-baz"
        end
      end
    end

    assert_equal("bar-baz", TestModule.foo)
  end

  def test_decorators_array
    decorate(TestClass, with: 'collection') {}
    decorators = TestClass.decorators.map(&:to_s)

    refute_includes(decorators, 'BasicObject')
    assert_includes(decorators, 'DecorateTest::TestClass::CollectionTestClassDecorator')
  end

  class SomeOtherClass
    def bar
      'hello'
    end
  end

  def test_mixin_module_decoration
    SomeOtherClass.include(TestModule)

    decorate(TestModule, with: 'mixin') do
      def bar
        "#{super} bar"
      end
    end

    DifferentTestClass.include(TestModule)

    assert_includes(TestModule.mixed_into, TestClass)
    assert_includes(TestModule.mixed_into, DifferentTestClass)

    assert_equal('hershey bar', DifferentTestClass.new.bar)
    assert_equal('wonder bar', TestClass.new.bar)
    assert_equal('hello bar', SomeOtherClass.new.bar)
  end
end
