# frozen_string_literal: true

class LanguageDetector
  attr_reader :text, :account

  def initialize(text, account = nil)
    @text = text
    @account = account
    #@identifier = CLD3::NNetLanguageIdentifier.new(1, 2048)
  end

  def to_iso_s
    default_locale
  end

  def prepared_text
    @text
  end

  def default_locale
    account&.user_locale&.to_sym || nil
  end
end
