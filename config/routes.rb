Rails.application.routes.draw do
  root "cellar_files#index"
  resources :cellar_files
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
