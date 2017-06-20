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
          unless target.is_a?(Class) || target.name =~ /Helper\Z/
            raise(
              InvalidDecorator,
              <<-eos.strip_heredoc

                Problem:
                  You cannot decorate a Module
                Summary:
                  Decoration only works with classes. Decorating modules requires
                  managing load order, a problem that is very complicated and
                  beyond the scope of this system.
                Resolution:
                  Decorate multiple classes that include the module like so:
                  `decorate Catalog::Product, Content::Page do`
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

          target.const_set(decorator_name, mod)

          if target.name.to_s.end_with?('Helper')
            engine = target.name =~ /::/ ? target.name.to_s.split('::')[0..-1].join('::') : nil
            controller = [engine, 'ApplicationController'].join('::').constantize

            controller.helper(mod)
          else
            mod.decorates(target)
          end
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
