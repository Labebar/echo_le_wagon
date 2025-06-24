class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  has_many :contents, dependent: :destroy
  has_many :answers, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :quiz_results, dependent: :destroy
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  validates :nickname, presence: true, uniqueness: true

end
