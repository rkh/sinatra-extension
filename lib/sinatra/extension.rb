require 'sinatra/base'
require 'sinatra/sugar'
require 'monkey-lib'

module Sinatra
  module Delegator
    def self.delegate(*methods)
      methods.each do |method_name|
        eval <<-RUBY, binding, '(__DELEGATE__)', 1
          def #{method_name}(*args, &b) sinatra_application.send(#{method_name.inspect}, *args, &b) end
          private #{method_name.inspect}
        RUBY
      end
    end

    delegate(*private_instance_methods(false))

    def sinatra_application
      ::Sinatra::Application
    end
  end

  module Extension
    BasicObject = Object unless defined? BasicObject
    class MethodRecorder < BasicObject
      def initialize(list) @calls = list end
      def method_missing(*a, &b) @calls << [a, b] end
    end

    include Delegator

    def method_calls
      @method_calls ||= []
    end

    def register_hooks
      @register_hooks ||= []
    end

    def on_register(&block)
      register_hooks << block
    end

    def enabled(option, &block)
      mod = Module.new
      mod.extend Sinatra::Extension
      define_method(option) { nil }
      define_method("#{option}?") { false }
      define_method("#{option}=") do |value|
        metadef(option) { value }
        return value unless value
        metadef("#{option}?") { true }
        instance_yield block
      end
    end

    def register(*extensions)
      on_register { register(*extensions) }
    end

    def configure(*args, &block)
      on_register do
        configure(*args) { |klass| klass.instance_yield block }
      end
    end

    def registered(klass)
      register Sinatra::Sugar
      method_calls.each { |a,b| klass.__send__(*a, &b) }
      register_hooks.each { |hook| klass.instance_yield hook }
    end

    def sinatra_application
      @sinatra_application ||= MethodRecorder.new method_calls
    end
  end
end
