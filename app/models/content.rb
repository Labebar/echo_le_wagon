  require "erb"

class Content < ApplicationRecord
  belongs_to :user
  has_many :content_tags, dependent: :destroy
  has_many :tags, through: :content_tags
  has_many :questions, dependent: :destroy
  has_many :notes, dependent: :destroy
  scope :by_recent, -> { order(created_at: :desc) }
  has_many :messages, dependent: :destroy
  has_many :quiz_results, dependent: :destroy


    # after_commit :generate_stuff_content, on: [:create]

  def name
    if self[:name].blank?
      ""
    else
      super
    end
  end


    def generate_questions
      questions.destroy_all
      Rails.logger.info("Generating questions for content ID: #{id} ")
      questions_data = QuestionGeneratorService.new(self.transcription).call
      questions_data.map do |data|
        correct = data[:correct_answer]&.to_sym
        next unless correct && data[:choices]&.key?(correct)

        self.questions.create(
          statement: data[:question],
          answer_true: data[:choices][correct],
          answer_1: data[:choices].except(correct).values[0],
          answer_2: data[:choices].except(correct).values[1],
          answer_3: data[:choices].except(correct).values[2],
          explanation: data[:explanation]
        )
      end.compact

      questions = self.questions.sort_by(&:id)
      question = questions.first
      next_question = questions[1]

      broadcast_replace_to(
        "content_#{id}_details",
        target: "quizz",
        partial: "questions/question",
        locals: {
        question: question,
        questions: questions,
        next_question: next_question,
        previous_question: false,
        }
      )

    end

    def get_transcript!
      api_url = "https://api.supadata.ai/v1/youtube/transcript?url=#{ERB::Util.url_encode(url)}&lang=en"
      response = HTTParty.get(
        api_url,
        headers: {
          'x-api-key' => ENV['SUPADATA_API_KEY'],
          'Content-Type' => 'application/json'
        }
      )
      response = JSON.parse(response.body)
      if response.nil? || response["content"].nil? || response["lang"].nil?
        raise "Failed to fetch transcript or language from API"
      else
        transcript_brut = response["content"]
        transcription = transcript_brut.map { |chunk| chunk["text"] }.join(" ")
        update!(
          transcription: transcription,
          language: response["lang"]
        )
      end
    end

    def enrich!
      api_url = "https://api.supadata.ai/v1/youtube/video?id=#{ERB::Util.url_encode(url)}"
      response = HTTParty.get(
        api_url,
        headers: {
          'x-api-key' => ENV['SUPADATA_API_KEY'],
          'Content-Type' => 'application/json'
        }
      )
      response = JSON.parse(response.body)
      if response.nil? || response["title"].nil? || response["duration"].nil? || response["thumbnail"].nil?
        raise "Failed to fetch video details from API"
      else
        update!(
          name: response["title"],
          duration: response["duration"],
          thumbnail: response["thumbnail"]
        )
      end
    end

  def summarize!
    if transcription.blank?
      Rails.logger.warn("No transcription available for summarization.")
    else
      summarizer = ContentSummarizer.new(transcription: transcription)
      summary = summarizer.call
      Rails.logger.info("Generated summary: #{summary}")
      update!(summary: summary) if summary.present?
    end
    Rails.logger.info("Content summary updated for content ID: #{id} and start broadcasting.")
    broadcast_replace_to(
      "content_#{id}_details",
      target:  "summary",
      partial: "contents/summary_text",
      locals:  { content: self }
    )
    Rails.logger.info("Content summary broadcasted for content ID: #{id}. for channel: content_#{id}_details")
  end

    def self.search_by_name_and_tags(query)
      query = "%#{query.downcase}%"

      left_joins(:tags)
        .where("LOWER(contents.name) LIKE :q OR LOWER(tags.name) LIKE :q", q: query)
        .distinct
    end

end
