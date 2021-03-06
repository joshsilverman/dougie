Dougie::Application.routes.draw do

  resources :authentications

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
  
  #devise
  devise_for :users, :timeout_in => 7.days,
    :controllers => {:registrations => 'registrations'}

  #tags
  get "tag/index" # ???
  match "/explore" => "tags#index" #** public **#

  # documents
  match "/documents/create/:tag_id" => "documents#create"
  resources :documents, :only => [:edit, :update, :destroy]

  # reviwer
  match "/review/:id" => "documents#review" #** public **#
  match "/review/dir/:id" => "tags#review" #** public **#
  match "/mems/update/:id/:confidence/:importance" => "mems#update"
  resources :lines, :only => [:update]
  
  # organizer
  resources :tags, :only => [:destroy, :create, :update]
  match "/tags/json" => "tags#json"

  # home page
  match "users/welcome" => "users#home"
  root :to => "users#home"

  # authentications
  match '/auth/:provider/callback' => 'authentications#create'
  match '/users/get_email' => 'users#get_email'
  resources :authentications

  # catch-all route for static pages
  Dougie::Application.routes.draw do |map|
    map.connect ':action', :controller => "static"
  end

end
