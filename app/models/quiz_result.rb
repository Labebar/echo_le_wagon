class QuizResult < ApplicationRecord
  belongs_to :user
  belongs_to :content
  has_many :elo_histories, dependent: :nullify
end
