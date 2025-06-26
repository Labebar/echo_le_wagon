class EloHistory < ApplicationRecord
  belongs_to :user
  belongs_to :quiz_result, optional: true
end
