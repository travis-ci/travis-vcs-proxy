# frozen_string_literal: true

class P4ServerSetting < RailsSettings::SettingsObject
  validate do
    errors.add(:url, 'is missing') if p4host.blank?
  end
end
