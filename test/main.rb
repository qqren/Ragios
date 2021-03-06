  #ragios/main.rb
  require 'rubygems'
  require "bundler/setup"
  require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/ragios'))
  require  Pathname(__FILE__).dirname.expand_path + 'config' 

  require 'yajl'

 #Add your code here

  monitoring = { tag: 'admin',
                 monitor: 'url',
                   every: '1m',
                   test: '1 test feed',
                   url: 'http://www.website.com/89843/videos.xml',
                   contact: 'obi.akubue@mail.com',
                   via: 'gmail',  
                   notify_interval: '6h'
                    },
                  { tag: 'obi', 
                   monitor: 'url',
                   every: '1m',
                   test: '2 test',
                   url: 'https://github.com/obi-a/Ragios',
                   contact: 'obi.akubue@mail.com',
                   via: 'gmail',  
                   notify_interval:'3h'
                  }
  #Ragios::Monitor.start monitoring
  
  #Ragios::Server.init
  #Ragios::Monitor.start monitoring,server=TRUE
  #Ragios::Monitor.restart
  #sch = Ragios::Server.get_monitors_frm_scheduler
  #puts sch.inspect

  #TODO write tests with these
  #hash  = Ragios::Server.get_all_status_updates
  #puts hash.inspect
   
   
  # hash  = Ragios::Server.get_status_update("ce1aaf2b-6d7d-413e-907e-3425a55953ab")
 #   puts hash.inspect

 # Ragios::Monitor.restart
 
 #auth_session = Ragios::DatabaseAdmin.session
 #puts auth_session


  data = { tag: 'test', 
                   monitor: 'url',
                   every: '1m',
                   test: '2 test',
                   url: 'https://github.com/obi-a/Ragios',
                   contact: 'obi.akubue@mail.com',
                   via: 'gmail',  
                   notify_interval:'3h',
                   describe_test_result:  "sample monitor for specs",
        	   time_of_last_test: "2:30pm",
         	   num_tests_passed: "10",
         	   num_tests_failed: "20",
                   total_num_tests: "30",
                   last_test_result: "PASSED", 
                   status: "UP",
                   state: "stopped"
                  }

      doc = {:database => 'monitors', :doc_id => 'rest_monitor', :data => data}
     begin
     # Couchdb.create_doc doc
     rescue CouchdbException => e
       #puts "Error message: " + e.to_s
     end 

#restart a stopped monitor while server is still running
#Ragios::Monitor.restart(id = 'rest_monitor')
   
# RestClient.put 'http://127.0.0.1:5041/monitors/rest_monitor/state/active',{:content_type => :json}
 #sch = Ragios::Server.get_monitors_frm_scheduler('rest_monitor')
 #puts sch.inspect
#response = RestClient.delete 'http://127.0.0.1:5041/monitors/rest_monitor'


#response = RestClient.put 'http://127.0.0.1:5041/status_updates/this_status_update/state/stopped',{:content_type => :json}

   data  = { every: '18m',
                   contact: 'skyla@ateam.com',
                   via: 'twitter'
                  }
  
  #str = Yajl::Encoder.encode(data)
  #response = RestClient.put 'http://127.0.0.1:5041/status_updates/just_nother_status_update',str, {:content_type => :json, :accept => :json}
 

  
  #hash = Ragios::Server.get_active_monitors
  #hash = Ragios::Server.get_stopped_status_updates('admin')
  #hash = Ragios::Server.get_active_status_updates

  #TODO
  #hash = Ragios::Server.stop_monitor(id ='a62e051e-46dc-437a-90af-965577444884')
  #Ragios::Server.restart_monitor(id ='a62e051e-46dc-437a-90af-965577444884')
  #hash = Ragios::Server.delete_monitor(id ='f9663c34-533f-4a27-b04e-b6d54cd7a870')
  #hash = Ragios::Server.delete_monitor(id ='a62e051e-46dc-437a-90af-965577444884')
  

  #hash = Ragios::Server.find_monitors(:contact => 'obi.akubue@mail.com')
  #hash = Ragios::Server.find_monitors(:monitor => 'url')
  #hash = Ragios::Server.find_monitors(:every => '1m')
  #hash = Ragios::Server.find_monitors(:tag => 'admin')
  
  

  #puts Ragios::Server.status_report(tag = "admin")
  #puts Ragios::Server.status_report


  config = {   :every => '1m',
                   :contact => 'admin@mail.com',
                   :via => 'gmail',
                  :tag => 'obi' 
                  }
    

  #Ragios::Server.start_status_update(config)
  #Ragios::Server.restart_status_updates('admin')

   #this should be run with a server restart
   #Ragios::Server.init
   #Ragios::Server.restart_status_updates
    #sch = Ragios::Server.get_status_update_frm_scheduler
    #puts sch.inspect
   #hash = Ragios::Server.stop_status_update('admin')
  #Ragios::Server.delete_status_update('admin')
   #  
   data = {   :every => '8m',
                   :contact => 'obi@gmail.com',
                   :via => 'email'
                  }
    id = "sample_status_update"
 # hash =  Ragios::Server.edit_status_update(id,data)

   data  = {    monitor: 'url',
                   every: '5m',
                   contact: 'obi.akubue@mail.com',
                   via: 'gmail'
                  }
  # id = "16b2ae38-9116-438c-9c5e-ab743e4edc79"
 # Ragios::Server.update_monitor(id,data)


#sch = Ragios::Server.get_monitors_frm_scheduler
#puts sch.inspect

#puts hash.inspect

 monitoring =  [{ monitor:'url',
                every:'1m',
                test:'video datafeed test',
                url:'http://pennywizard.com/central/wizzer.html',
                contact:'obi.akubue@gmail.com',
                via:'ses',  
                notify_interval:'6m'
                }]
 
Ragios::Monitor.start monitoring

 #trap Ctrl-C to exit gracefully
   puts "PRESS CTRL-C to QUIT"
     loop do
       trap("INT") { puts "\nExiting"; exit; }
     sleep(3)
    end
