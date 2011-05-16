  #ragios/main.rb
  require 'rubygems'
  require "bundler/setup"
  require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/ragios'))
  require  Pathname(__FILE__).dirname.expand_path + 'config' 

 #Add your code here
 monitoring   = { monitor: 'http',
                  every: '3m',
                  test: 'Http connection to my site',
                  domain: 'www.google.com/fail',
                  contact: 'admin@mysite.com',
                   via: 'twitter',
                   notify_interval: '6h'
                  },
                  { monitor: 'http',
              every: '2m',
              test: 'domain doesnt exist',
              domain: 'www.obiora-akubue.com',
              contact: 'admin@mail.com',
              via: 'gmail',  
              notify_interval: '6h'
             },
                 { monitor: 'url',
                   every: '1m',
                   test: 'another datafeed test',
                   url: 'http://www.google.com/fail',
                   contact: 'obi.akubue@gmail.com',
                   via: 'gmail',
                   notify_interval: '6h'
                  }

  Ragios::Monitor.start monitoring


 #trap Ctrl-C to exit gracefully
    puts "PRESS CTRL-C to QUIT"
     loop do
       trap("INT") { puts "\nExiting"; exit; }
     sleep(3)
    end
