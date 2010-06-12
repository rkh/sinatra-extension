require File.expand_path("../../spec_helper", __FILE__)

module Sinatra
  module OtherExtension
  end

  module ExampleExtension
    extend Sinatra::Extension
    register OtherExtension

    %w[get put post delete].each { |verb| __send__(verb, '/foo') { 'bar' } }

    configure(:test) { set :foo, 42 }
    configure(:development) { set :foo, 'oh no' }

    on_register do
      set :bar,:blah
    end

    helpers do
      def foo(value) value end
    end

    set :counter, 0
    on_set(:trigger) { set :counter, counter + 1 }

    on_enable :special_foo do
      helpers do
        def foo(value) 42 end
      end
    end
  end
end

describe Sinatra::Extension do
  before { app :ExampleExtension }
  it_should_behave_like 'sinatra'

  it 'should forward register correctly' do
    app.should be_a(Sinatra::OtherExtension)
  end

  %w[head get put post delete].each do |verb|
    it "should forward #{verb} correctly" do
      browse_route(verb, '/foo').should be_ok
      last_response.body.should == 'bar' unless verb == 'head'
    end
  end

  it "should forward configure correctly" do
    app.should be_test # just to be sure
    app.foo.should == 42
  end

  it "should trigger on_register" do
    app.bar.should == :blah
  end

  it "should forward helpers correctly" do
    app.new.foo(10).should == 10
  end

  it "should trigger on_set block" do
    app.set :counter, 0
    app.counter.should == 0
    app.enable :trigger
    app.counter.should == 1
    app.disable :trigger
    app.counter.should == 2
    app.set :trigger, :foo
    app.counter.should == 3
    app.trigger = 42
    app.counter.should == 4
  end

  it "should apply on_enable blocks only if given option has been enabled" do
    app.should_not be_special_foo
    app.special_foo.should be_false
    app.new.foo(10).should == 10
    app.disable :special_foo
    app.should_not be_special_foo
    app.special_foo.should be_false
    app.new.foo(10).should == 10
    app.enable :special_foo
    app.should be_special_foo
    app.new.foo(10).should == 42
  end
end