Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  get 'welcome/index'

  # Devise_for :users
  devise_for :users, controllers: { sessions: "users/sessions", registrations: "users/registrations" }
 #devise_for :users
  resources :users, only: :show, as: :user


  # Skill routes
  get '/skills/:id' => 'skills#show', as: :skill
  get '/skills/:id/edit' => 'skills#edit', as: :edit_skill
  patch 'skills/:id' => 'skills#update'
  post 'skills' => 'skills#create'


  # User-skill routes
  get '/user_skills/:id' => 'user_skills#show', as: :user_skill
  get '/user_skills/:id/edit' => 'user_skills#edit', as: :edit_user_skill
  patch '/user_skills/:id' => 'user_skills#update'
  post '/user_skills' => 'user_skills#create'

  # Job posting routes
  get '/job_postings/:id' => 'job_postings#show', as: :job_posting
  get '/job_postings/:id/edit' => 'job_postings#edit', as: :edit_job_posting
  patch 'job_postings/:id' => 'job_postings#update'
  post 'job_postings' => 'job_postings#create'

  # Project routes
  get 'projects/:id' => 'projects#show', as: :project
  get 'projects/:id/edit' => 'projects#edit', as: :edit_project
  patch 'projects/:id' => 'projects#update'
  post 'projects' => 'projects#create'


  # Project skill routes
  get 'project_skills/:id' => 'project_skills#show', as: :project_skill
  get 'project_skills/:id/edit' => 'project_skills#edit', as: :edit_project_skill
  patch 'project_skills/:id' => 'project_skills#update'
  post 'project_skills' => 'project_skills#create'

  # Reference routes
  get 'references' => 'references#show'
  get 'references/refer' => 'references#email', as: :email_reference
  get 'references/new/:id' => 'references#new', as: :new_reference
  post 'references/refer' => 'references#sendMail', as: :reference_emails
  post 'references' => 'references#create'
  patch 'references/:id' => 'references#update', as: :update_reference
  delete 'references/:id' => 'references#delete', as: :delete_reference

  # Survey routes
  get 'surveys' => 'surveys#index'
  get 'surveys/:id' => 'surveys#show', as: :survey
  post 'surveys' => 'surveys#create'
  patch 'surveys' => 'surveys#update'


  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
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

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
