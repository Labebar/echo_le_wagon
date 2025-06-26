class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  has_many :contents, dependent: :destroy
  has_many :answers, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :quiz_results, dependent: :destroy
  has_many :elo_histories, dependent: :destroy
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

  def update_elo_for_quiz(score, quiz_result)
    base_elo = 1500
    current_elo = self.elo_score

    base_delta = {
      10 => 15,
      9  => 13,
      8  => 10,
      7  => 7,
      6  => 4,
      5  => 0,
      4  => -4,
      3  => -7,
      2  => -10,
      1  => -13,
      0  => -15
    }

    delta_modifier = ((current_elo - base_elo) / 100).floor * -1
    adjusted_delta = base_delta[score] + delta_modifier
    new_elo = (current_elo + adjusted_delta).clamp(0, 3000)

    update(elo_score: new_elo)
    self.elo_histories.create!(value: new_elo, quiz_result: quiz_result)
  end
end
