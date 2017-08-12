# frozen_string_literal: true

class FetchRemoteStatusService < BaseService
  include AuthorExtractor

  def call(url, prefetched_body = nil)
    if prefetched_body.nil?
      resource_url, body, protocol = FetchAtomService.new.call(url)
    else
      resource_url = url
      body         = prefetched_body
      protocol     = :ostatus
    end

    case protocol 
    when :ostatus
      process_atom(resource_url, body)
    when :activitypub
      ActivityPub::FetchRemoteStatusService.new.call(resource_url, body)
    end
  end

  private

  def process_atom(url, body)
    Rails.logger.debug "Processing Atom for remote status at #{url}"

    xml = Nokogiri::XML(body)
    xml.encoding = 'utf-8'

    account = author_from_xml(xml.at_xpath('/xmlns:entry', xmlns: TagManager::XMLNS))
    domain  = Addressable::URI.parse(url).normalized_host

    return nil unless !account.nil? && confirmed_domain?(domain, account)

    statuses = ProcessFeedService.new.call(body, account)
    statuses.first
  rescue Nokogiri::XML::XPath::SyntaxError
    Rails.logger.debug 'Invalid XML or missing namespace'
    nil
  end

  def confirmed_domain?(domain, account)
    account.domain.nil? || domain.casecmp(account.domain).zero? || domain.casecmp(Addressable::URI.parse(account.remote_url).normalized_host).zero?
  end
end
