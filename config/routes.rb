Rails.application.routes.draw do
  root "cellar_files#index"
  resources :cellar_files do
    member do
      get :search
    end
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
