# frozen_string_literal: true

class InviteUser
  class InvitationFailed < StandardError
    attr_reader :message

    def initialize(message)
      @message = message
    end
  end

  def initialize(user_email, organization_id, role, current_user)
    @email = user_email
    @organization_id = organization_id
    @role = role
    @current_user = current_user
  end

  def call
    token = nil
    user_id ||= User.find_by(email: @email)&.id
    organization = Organization.find(@organization_id)

    ActiveRecord::Base.transaction do
      inv = OrganizationInvitation.new(
        organization_id: @organization_id,
        user_id: user_id,
        permission: @role
      )
      unless inv.save
        raise ActiveRecord::Rollback
      end

      token = inv.token
    end
    return unless token

    Audit.create(@current_user, "invited #{user_id} to organization #{@organization_id}")

    invitation_link = Settings.web_url + '/accept_invite?token=' + token

    InvitationMailer.with(email: @email, organization: organization.name, invitation_link: invitation_link, invited_by: @current_user.email).send_invitation.deliver_now

    token
  end
end
