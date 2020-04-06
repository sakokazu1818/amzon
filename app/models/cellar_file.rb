class CellarFile < ApplicationRecord
  has_one_attached :excel
  has_one :search_criterium, dependent: :destroy
end
