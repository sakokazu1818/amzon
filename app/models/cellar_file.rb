class CellarFile < ApplicationRecord
  has_one_attached :excel
  has_one :search_criterium, dependent: :destroy
  has_one :scraping_result, dependent: :destroy
end
