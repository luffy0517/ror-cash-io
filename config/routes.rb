Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :entries
      resources :users
      post "/auth/login", to: "authentication#login"
      get "/auth/me", to: "authentication#me"
      get "/*a", to: "application#not_found"
    end
  end
end
