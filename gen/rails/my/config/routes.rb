ActionController::Routing::Routes.draw do |map|

  # routes in all applications, not used by plugins
  def add_common_routes(map)
    map.aq '/aq.:format', :controller => 'front', :action => 'aq'
    # special link for email activation
    #map.users_self_register '/users/self_register.:format', :controller => 'users', :action => 'self_register', :conditions => { :method => :post }
    map.users_self_register '/users/self_register.:format', :controller => 'users', :action => 'self_register'
    map.go '/users/:id/go/:key', :controller => 'users', :action => 'go'
#    map.admin '/admin2548', :controller => 'users', :action => 'admin'
#    map.admin_set_current_user '/admin_set_current_user2548', :controller => 'users', :action => 'admin_set_current_user'
    map.invitation_add_guest '/invitations/add_guest.:format', :controller => 'invitations', :action => 'add_guest', :conditions => { :method => :post }
  end

  # routes used by primary pages in go and by plugin windows in all
  def add_plugin_routes(map)
    # these are in use
    map.connect 'users/:id/password', :controller => 'users', :action => 'password'
    map.connect 'users/:id/social', :controller => 'users', :action => 'social'
    map.user_contact '/contact', :controller => 'users', :action => 'contact', :conditions => { :method => :get }
    map.conference_account '/conferences/:id/account', :controller => 'conferences', :action => 'account', :conditions => { :method => :get }
    map.conference_dashboard '/conferences/:id/dashboard', :controller => 'conferences', :action => 'dashboard', :conditions => { :method => :get }
    map.conference_workspace '/conferences/:id/workspace', :controller => 'conferences', :action => 'workspace', :conditions => { :method => :get }
    map.conference_invitation '/invitation/:id', :controller => 'conferences', :action => 'invitation', :conditions => { :method => :get }

    # pretty sure these are depreciated
    map.numbers '/numbers', :controller => 'conferences', :action => 'numbers', :conditions => { :method => :get }
    map.reference '/reference', :controller => 'conferences', :action => 'reference', :conditions => { :method => :get }
    map.resources :conferences, :has_many => :callees
    map.account_rates '/rates', :controller => 'accounts', :action => 'rates', :conditions => { :method => :get }
    map.email_remove '/emails/:id/remove', :controller => 'emails', :action => 'remove'

    # no idea about these ...
    map.modify_conference '/conferences/:id/modify', :controller => 'conferences', :action => 'modify', :conditions => { :method => :get }
    map.user_search '/users_search', :controller => 'users', :action => 'search', :conditions => { :method => :get }
    map.start '/start', :controller => 'conferences', :action => 'start', :conditions => { :method => :get }
    map.guest '/guest', :controller => 'conferences', :action => 'guest', :conditions => { :method => :get }

    map.upload '/upload.:format', :controller => 'media_files', :action => 'upload', :conditions => { :method => :post }
    map.upload '/upload.:format', :controller => 'media_files', :action => 'options', :conditions => { :method => :options }

    Hobo.add_routes(map)
  end

  def add_go_routes(map)

#  map.site_search  'search', :controller => 'front', :action => 'search'
    map.root :controller => 'front', :action => 'go_landing'

    add_common_routes(map)
    add_plugin_routes(map)

    map.home '/home', :controller => 'conferences', :action => 'home', :conditions => { :method => :get }

    # Install the default routes as the lowest priority.
    # Note: These default routes make all actions in every controller accessible via GET requests. You should
    # consider removing or commenting them out if you're using named routes and resources.
    map.connect ':controller/:action/:id'
    map.connect ':controller/:action/:id.:format'

    # the rest is largely just old boilerplate comments
    
    # The priority is based upon order of creation: first created -> highest priority.

    # Sample of regular route:
    #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
    # Keep in mind you can assign values other than :controller and :action

    # Sample of named route:
    #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
    # This route can be invoked with purchase_url(:id => product.id)

    # Sample resource route (maps HTTP verbs to controller actions automatically):
    #   map.resources :products

    # Sample resource route with options:
    #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

    # Sample resource route with sub-resources:
    #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
    
    # Sample resource route with more complex sub-resources
    #   map.resources :products do |products|
    #     products.resources :comments
    #     products.resources :sales, :collection => { :recent => :get }
    #   end
    # Sample resource route within a namespace:
    #   map.namespace :admin do |admin|
    #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
    #     admin.resources :products
    #   end

    # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
    # map.root :controller => "welcome"

    # See how all your routes lay out with "rake routes"

  end

  def add_rooms_routes(map)
    map.root :controller => 'front', :action => 'tm_landing'

#    map.user_login '/login.:format', :controller => 'users', :action => 'tm_login'
    map.user_login '/login.:format', :controller => 'users', :action => 'login', :layout => 'rooms_lobby_login'

    map.user_logout '/logout.:format', :controller => 'users', :action => 'logout', :conditions => { :method => :get }
#    map.root :controller => 'front', :action => 'index'
#    map.root :controller => 'conferences', :action => 'home', :conditions => { :method => :get }
    map.home '/home', :controller => 'conferences', :action => 'lobby'

#    map.aq '/aq.:format', :controller => 'front', :action => 'aq'
#    map.admin '/admin2548', :controller => 'users', :action => 'admin'
#    map.users '/users/jqgrid_json/:id.:format', :controller=>"users", :action => 'jqgrid_json' -- messing around ...
#    map.admin_set_current_user '/admin_set_current_user2548', :controller => 'users', :action => 'admin_set_current_user'
    map.users '/:controller/jqgrid_json/:id.:format', :action => 'jqgrid_json' # -- messing around ... -- ha, guess it works ...

    # -- find the room ...
# no longer used
#    map.conference_workspace '/byid/:id', :controller => 'conferences', :action => 'workspace', :id => /[1-9]\d*/, :conditions => { :method => :get }
#    map.conference_workspace '/*uri', :controller => 'conferences', :action => 'workspace', :conditions => { :method => :get }

#    Hobo.add_routes(map) # -- had this out, then had to add again, then out again ...

  end


    map.with_options :path_prefix => 'plugin/:style_key', :plugin => true do |rte|
        add_plugin_routes(rte)
    end
    add_common_routes(map)


    # ---> Go < ----
#    add_go_routes(map);

    
    # ---> Rooms <---
    add_rooms_routes(map);


end

