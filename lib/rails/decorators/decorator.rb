module Rails
  module Decorators
    module Decorator
      def self.loader(roots)
        Proc.new do
          roots.each do |root|
            decorators = Dir.glob("#{root}/app/**/*.#{Rails::Decorators.extension}")
            decorators.sort!
            decorators.each { |d| require_dependency(d) }
          end
        end
      end

      def self.decorate(*targets, &module_definition)
        options = targets.extract_options!

        targets.each do |target|
          if target.name.to_s.end_with?('Helper')
            raise(
              InvalidDecorator,
              <<-eos.strip_heredoc

                Problem:
                  Rails::Decorators doesn't work with helpers.
                Summary:
                  Rails does some magic with helpers which in certain cases
                  causes decoration to not work.
                Resolution:
                  Create a new helper and in a `to_prepare` block, use
                  ActionPack's `helper` method to include the helper, e.g.
                  `MyEngine::ApplicationController.helper(MyEngine::BlogsHelper)`
              eos
            )
          end

          decorator_name = "#{options[:with].to_s.camelize}#{target.to_s.demodulize}Decorator"

          if target.const_defined?(decorator_name)
            # We are probably reloading in Rails development env if this happens
            next if !Rails.application.config.cache_classes

            raise(
              InvalidDecorator,
              <<-eos.strip_heredoc

                Problem:
                  #{decorator_name} is already defined in #{target.name}.
                Summary:
                  When decorating a class, Rails::Decorators dynamically defines
                  a module for prepending the decorations passed in the block. In
                  this case, the name for the decoration module is already defined
                  in the namespace, so decorating would redefine the constant.
                Resolution:
                  Please specify a unique `with` option when decorating #{target.name}.
              eos
            )
          end

          mod = Module.new do
            extend Rails::Decorators::Decorator
            module_eval(&module_definition)
          end
          instance_methods = mod.instance_methods - Object.public_instance_methods
          mixin = instance_methods.any? && !target.is_a?(Class)

          if mixin
            raise(
              InvalidDecorator,
              <<-eos.strip_heredoc

                Problem:
                  You cannot decorate a mixin module
                Summary:
                  Decoration only works with classes and static module methods.
                  Decorating mixin modules requires managing load order, a problem
                  that is very complicated and beyond the scope of this system.
                Resolution:
                  Decorate multiple classes that include the module like so:
                  `decorate Catalog::Product, Content::Page do`
              eos
            )
          end

          target.const_set(decorator_name, mod)
          mod.decorates(target)
        end
      end

      def prepend_features(base)
        super

        if const_defined?(:ClassMethodsDecorator)
          base
            .singleton_class
            .send(:prepend, const_get(:ClassMethodsDecorator))
        end

        if instance_variable_defined?(:@_decorated_block)
          base.class_eval(&@_decorated_block)
        end
      end

      def decorated(&block)
        instance_variable_set(:@_decorated_block, block)
      end

      def class_methods(&class_methods_module_definition)
        mod = const_set(:ClassMethodsDecorator, Module.new)
        mod.module_eval(&class_methods_module_definition)
      end
      alias_method :module_methods, :class_methods

      def decorates(klass)
        klass.send(:prepend, self)
      end
    end
  end
end
