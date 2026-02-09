Rails.application.routes.draw do
  mount ActionCable.server => "/cable"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "home#index"

  get "dashboard", to: "dashboard#index", as: :dashboard

  get "login", to: "sessions#new", as: :login
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout

  get "signup", to: "users#new", as: :signup
  post "signup", to: "users#create"

  get "join", to: "home#join", as: :join

  resources :pre_exams, only: [:index], path: "pre_exams" do
    get :created, on: :collection
    post :create_test, on: :collection
    post :fetch_correct_answers, on: :collection
  end

  resources :exams, only: [ :index, :create, :show ]

  get "rooms/new", to: "rooms#new", as: :new_room
  post "rooms", to: "rooms#create", as: :rooms
  get "rooms/:room_code", to: "rooms#show", as: :room, room_code: /[A-Za-z0-9]+/
  patch "rooms/:room_code/start_now", to: "rooms#start_now", as: :room_start_now, room_code: /[A-Za-z0-9]+/
  get "rooms/:room_code/participants", to: "rooms#participants", as: :room_participants, room_code: /[A-Za-z0-9]+/
  get "rooms/:room_code/results", to: "rooms#results", as: :room_results, room_code: /[A-Za-z0-9]+/
end
