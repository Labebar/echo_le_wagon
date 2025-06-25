class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  has_many :contents, dependent: :destroy
  has_many :answers, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :quiz_results, dependent: :destroy
  has_one_attached :avatar
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  validates :nickname, presence: true, uniqueness: true

  def personal_playlists
    favorite_tags = Tag.joins(:content_tags)
                      .where(content_tags: { favorite: true })
                      .distinct

    favorite_tags.each_with_object({}) do |tag, hash|
      contents = Content.joins(:content_tags)
                        .where(content_tags: { favorite: true, tag_id: tag.id })
                        .where(user: self)
      hash[tag] = contents if contents.any?
    end
  end
end
