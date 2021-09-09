# frozen_string_literal: true

class ApplicationSerializer
  include JSONAPI::Serializer

  def to_h
    data = serializable_hash

    if data[:data].is_a?(Hash)
      data[:data][:attributes]
    elsif data[:data].is_a?(Array)
      data[:data].map { |x| x[:attributes] }
    elsif data[:data].nil?
      nil
    else
      data
    end
  end
end
