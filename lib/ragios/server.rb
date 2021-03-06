class Hash
  #take keys of hash and transform those to a symbols
  def self.transform_keys_to_symbols(value)
    return value if not value.is_a?(Hash)
    hash = value.inject({}){|memo,(k,v)| memo[k.to_sym] = Hash.transform_keys_to_symbols(v); memo}
    return hash
  end
end

#TODO: Ragios::Server may need to should have an exception class 
#to allow clients like the RESTserver know exactly what a problem is with specific details.

module Ragios 

#hides the messy details of the scheduler from users 
#provides an easy interface to start monitoring the system by calling Ragios::Server start monitors 
 class Server
   
    attr_accessor :ragios
    attr :status_update_scheduler
    
    def self.init
       @ragios = Ragios::Schedulers::Server.new 
       @status_update_scheduler = Rufus::Scheduler.start_new
    end

    def self.find_monitors(options) 
      Couchdb.find_by({:database => 'monitors', options.keys[0] => options.values[0]},Ragios::DatabaseAdmin.session)  
    end


    def self.find_status_update(options)
      Couchdb.find_by({:database => 'status_update_settings', options.keys[0] => options.values[0]},Ragios::DatabaseAdmin.session)  
    end

    def self.status_report(tag = nil)
  
      if(tag == nil)
          @monitors = get_stats
      else
          @monitors = get_stats(tag)
      end 
       
       message_template = ERB.new File.new($path_to_messages + "/server_status_report.erb" ).read
       message_template.result(binding)
    end

   def self.stop_monitor(id)
       @ragios.stop_monitor(id)
   end

   def self.restart_monitor(id)
      Ragios::Monitor.restart(id)
   end


   def self.delete_monitor(id)
    begin 
      auth_session = Ragios::DatabaseAdmin.session
     monitor = Couchdb.view({:database => 'monitors', :doc_id => id},auth_session)    
 
     if(monitor["state"] == "active")
      stop_monitor(id)
     end
     Couchdb.delete_doc({:database => 'monitors', :doc_id => id},auth_session)
    rescue CouchdbException => e
       e.error
    end
   end

   def self.update_monitor(id, options)
      auth_session = Ragios::DatabaseAdmin.session
      doc = { :database => 'monitors', :doc_id => id, :data => options}   
      Couchdb.update_doc doc,auth_session

     monitor = Couchdb.view( {:database => 'monitors', :doc_id => id},auth_session)
     
    if(monitor["state"] == "active")
      stop_monitor(id)
      restart_monitor(id)
    end
   end

  #restart all active status updates - used when server is restarting
  #or restart all stopped status updates by tag - used when restarting a stopped status update 
   def self.restart_status_updates(tag = nil)
       
      if(tag == nil)

        config_settings = get_active_status_updates
      else
        config_settings = get_stopped_status_updates(tag)
      end
         
        if config_settings.empty?
         return 
        end

        config_settings.each do |config| 
         doc = {:database => 'status_update_settings', :doc_id => config["_id"], :data => {:state => "active"}}
         config = Hash.transform_keys_to_symbols(config)
         schedule_status_updates(config, tag = config[:tag])
         Couchdb.update_doc doc,Ragios::DatabaseAdmin.session           
        end
   end

   def self.start_status_update (config)
       save_status_updates(config)
       schedule_status_updates(config,tag = config[:tag])
   end

  #create and save status update settings for different users to database
  def self.save_status_updates config
      auth_session = Ragios::DatabaseAdmin.session
      begin
       Couchdb.create 'status_update_settings',auth_session
      rescue CouchdbException => e
      end 
      id =  UUIDTools::UUID.random_create.to_s
      config = config.merge({:state => "active"})
      doc = {:database => 'status_update_settings', :doc_id => id, :data => config}
      Couchdb.create_doc doc,auth_session
  end

   def self.schedule_status_updates(config, tag = nil)
        #format of config {}
      #config  = {   :every => '1d',
         #          :contact => 'admin@mail.com',
          #         :via => 'gmail'
           #        :tag => 'admin'
           #       }
     
    @status_update_scheduler.every config[:every], :tags => tag do 
             
        @body = status_report(tag) 
        message = {:to => config[:contact],
                  :subject => @subject, 
                  :body => @body}
          
      if config[:via] == 'gmail'
          Ragios::GmailNotifier.new.send message   
        elsif config[:via] == 'email'
          Ragios::Notifiers::EmailNotifier.new.send message
        else
           raise 'Wrong hash parameter for update_status()'
     end
    end
   end

  def self.stop_status_update(tag)
      jobs = @status_update_scheduler.find_by_tag(tag)
      jobs.each do |job| 
         job.unschedule
      end

      updates = find_status_update(:tag => tag)
      updates.each do |update|
       doc = { :database => 'status_update_settings', :doc_id => update["_id"], :data => {:state => "stopped"}}   
       Couchdb.update_doc doc,Ragios::DatabaseAdmin.session
      end
  end
 
  def self.edit_status_update(id, options)
      auth_session = Ragios::DatabaseAdmin.session
      doc = { :database => 'status_update_settings', :doc_id => id, :data => options}   
      Couchdb.update_doc doc,auth_session
     updates = Couchdb.view( {:database => 'status_update_settings', :doc_id => id},auth_session)
      if(updates["tag"] != nil) && (updates["state"] == "active")
        stop_status_update(updates["tag"])
        restart_status_updates(updates["tag"])
      end
      return updates
  end

  def self.delete_status_update(tag)
     #only one status update is expected per tag
     stop_status_update(tag)
     updates = find_status_update(:tag => tag)
     updates.each do |update|
         doc = {:database => 'status_update_settings', :doc_id => update["_id"]}
         Couchdb.delete_doc doc, Ragios::DatabaseAdmin.session
     end
  end
    
    #returns a list of all active monitors in the database
    def self.get_active_monitors
       view = {:database => 'monitors',
        :design_doc => 'monitors',
         :view => 'get_active_monitors',
          :json_doc => $path_to_json + '/get_monitors.json'}

         Couchdb.find_on_fly(view,Ragios::DatabaseAdmin.session)
    end

  #get all stopped status updates
  def self.get_stopped_status_updates(tag)
    view = {:database => 'status_update_settings',
        :design_doc => 'status_updates',
         :view => 'get_stopped_updates_by_tag',
          :json_doc => $path_to_json + '/get_status_updates.json'}
    
    Couchdb.find_on_fly(view,Ragios::DatabaseAdmin.session, key = tag)
  end

 #get all status updates in the system
 def self.get_all_status_updates
   view = {:database => 'status_update_settings',
        :design_doc => 'status_updates',
         :view => 'get_all_status_updates',
          :json_doc => $path_to_json + '/get_status_updates.json'}
    
  Couchdb.find_on_fly(view,Ragios::DatabaseAdmin.session)
 end
  
   #get all active status updates 
  def self.get_active_status_updates
   view = {:database => 'status_update_settings',
        :design_doc => 'status_updates',
         :view => 'get_active_status_updates',
          :json_doc => $path_to_json + '/get_status_updates.json'}
    
    Couchdb.find_on_fly(view,Ragios::DatabaseAdmin.session)
   end
  
   def self.get_monitor(id)
       doc = {:database => 'monitors', :doc_id => id}
       Couchdb.view doc, Ragios::DatabaseAdmin.session
   end

   def self.get_status_update(id)
      doc = {:database => 'status_update_settings', :doc_id => id}
      Couchdb.view doc, Ragios::DatabaseAdmin.session
   end

   def self.get_all_monitors
      view = {:database => 'monitors',
        :design_doc => 'monitors',
         :view => 'get_monitors',
          :json_doc => $path_to_json + '/get_monitors.json'}

         Couchdb.find_on_fly(view,Ragios::DatabaseAdmin.session)
   end

 

   def self.get_stats(tag = nil)

       auth_session = Ragios::DatabaseAdmin.session

       if(tag == nil)
           view = {:database => 'monitors',
        		:design_doc => 'get_stats',
         		:view => 'get_stats',
          		:json_doc => $path_to_json + '/get_stats.json'}
               Couchdb.find_on_fly(view,auth_session)  
       else
         view = {:database => 'monitors',
        		:design_doc => 'get_stats',
         		:view => 'get_tag_and_mature_stats',
          		:json_doc => $path_to_json + '/get_stats.json'}
               Couchdb.find_on_fly(view, auth_session, key = tag)
      end
   end
    
   def self.get_status_update_frm_scheduler(tag = nil)     
      if (tag == nil)
        @status_update_scheduler.jobs
      else
        @status_update_scheduler.find_by_tag(tag)
      end
   end

  def self.get_monitors(tag = nil)
      @ragios.get_monitors(tag)
  end

   def self.get_monitors_frm_scheduler(tag = nil)
     if (tag == nil)
        @ragios.get_monitors
      else
        @ragios.get_monitors(tag)
      end
   end
 
    def self.restart monitors
       @ragios.restart monitors 
    end

    def self.start monitors 
     @ragios.create monitors
     @ragios.start 
    end
 end

end
