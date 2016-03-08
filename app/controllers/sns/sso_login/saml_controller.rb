class Sns::SsoLogin::SamlController < ApplicationController
  include Sns::BaseFilter

  skip_action_callback :verify_authenticity_token, only: :consume
  skip_action_callback :logged_in?
  before_action :set_item

  model Sys::Sso::Saml

  private
    def set_item
      @item ||= @model.find_by(filename: params[:id])
    end

    def settings
      @settings ||= begin
        idp_metadata_parser = OneLogin::RubySaml::IdpMetadataParser.new
        settings = idp_metadata_parser.parse(SS::Crypt.decrypt(@item.metadata))

        settings.assertion_consumer_service_url = "http://#{request.host_with_port}/.mypage/sso_login/saml/#{@item.filename}/consume"
        settings.issuer = "http://#{request.host_with_port}/.mypage/sso_login/saml/#{@item.filename}/"
        # settings.name_identifier_format = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
        # settings.name_identifier_format = "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified"
        settings.name_identifier_format = @item.identifier || @item.default_identifier
        # Optional for most SAML IdPs
        settings.authn_context = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"
        Rails.logger.debug("settings.name_identifier_format=#{settings.name_identifier_format}")

        settings
      end
    end

    def authorize_failure
      Rails.logger.debug("authorize failure")
      raise "403"
    end

  public

    def init
      request = OneLogin::RubySaml::Authrequest.new
      state = session['ss.sso.state'] = SecureRandom.hex(24)
      redirect_to(request.create(settings, RelayState: state))
    end

    def consume
      state = params[:RelayState]
      raise "404" if session.delete('ss.sso.state') != state

      response = OneLogin::RubySaml::Response.new(params[:SAMLResponse])
      response.settings = settings

      raise "403" unless response.is_valid?

      # Rails.logger.debug("response.nameid=#{response.nameid}")
      # Rails.logger.debug("response.attributes=#{response.attributes}")
      # if response.attributes
      #   Rails.logger.debug("response.attributes.count=#{response.attributes.count}")
      #   response.attributes.each do |name, values|
      #     Rails.logger.debug("response.attributes[#{name}]=#{values}(#{values.class})")
      #   end
      # end

      render text: response.nameid, layout: false
    end

    def metadata
      meta = OneLogin::RubySaml::Metadata.new
      render :xml => meta.generate(settings), content_type: "application/samlmetadata+xml"
    end
end
