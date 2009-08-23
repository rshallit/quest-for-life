ActionController::Routing::Routes.draw do |map|
  map.resources :age_groups

  map.resources :survey_groups do |survey_groups|
    survey_groups.resources :surveys
  end


  map.resources :surveys
  map.with_options :controller => 'surveys' do |s|
    s.survey_demographics '/surveys/:id/demographics', :action => :edit, :parameter => 'demographics', :requirements => { :method => :get }
    s.survey_parameter '/surveys/:id/:parameter', :action => :edit, :requirements => { :method => :get }
    s.equation_parameter '/equation/:parameter', :action => :edit, :requirements => { :method => :get }
  end

  map.resources :rational_options

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

  map.resources :users do |users|
    users.resource :confirmation, :only => :new
  end

  map.open_id_complete 'session', :controller => 'sessions', :action => 'create', :requirements => { :method => :get }
  map.resource :session, :only => [:new, :create, :destroy]
  
  map.with_options :controller => 'sessions'  do |m|
    m.sign_in  '/login',  :action => 'new'
    m.sign_out '/logout', :action => 'destroy'
  end
  
  

  map.root :controller => "home"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  # map.connect ':controller/:action/:id.:format'
end
