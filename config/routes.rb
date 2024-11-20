Rails.application.routes.draw do
  resources :websites, only: [:new, :create, :show] do
    member do
      get "pages/:page_name", to: "websites#page", as: "page"
    end
  end
  root "websites#new"
end
