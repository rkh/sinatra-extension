Sinatra::Extension
==================

Mixin to ease [Sinatra](http://sinatrarb.com) extension development.

BigBand
-------

Sinatra::Extension is part of the [BigBand](http://github.com/rkh/big_band) stack.
Check it out if you are looking for other fancy Sinatra extensions.

Installation
------------

    gem install sinatra-extension

Example
-------

    module MyFancyExtension
      extend Sinatra::Extension
      
      enable :session
      
      get '/foo' do
        "bar"
      end
      
      enabled :fancy_mode do
        use VeryFancyMiddleware
        get '/fancy' do
          "fancy!"
        end
      end
    end
    
    class MyApp < Sinatra::Base
      register MyFancyExtension
      enable :fancy_mode
    end
