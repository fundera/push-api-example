require 'sinatra'
require 'json'
require 'base64'

require_relative 'underwriting'
require_relative 'models'
require_relative 'lib/store'

## configuration

configure do
  set :environments, %w(development test staging production)
  set :allow_test_responses, false
  set :organization, 'Example Capital'
  set :return_offer_urls, true
end

configure :development do
  set :api_username, 'development'
  set :api_password, 'abc123'
  set :allow_test_responses, true
end

configure :test do
  set :api_username, 'test'
  set :api_password, 'abc123'
  set :allow_test_responses, true
end

configure :staging do
  set :api_username, 'staging'
  set :api_password, 'staging_password_CHANGEME'
  set :allow_test_responses, true
end

configure :production do
  set :api_username, 'production'
  set :api_password, 'production_password_CHANGEME'
end

## API handlers

# require authorization for the API.
before '/api/v1/*' do
  unless request.env['HTTP_AUTHORIZATION'] == "Basic #{Base64.strict_encode64("#{settings.api_username}:#{settings.api_password}")}"
    halt 401, 'Not authorized'
  end
end

# handle JSON post bodies for the API.
before '/api/v1/*' do
  next if !request.post? || request.path =~ /\/documents$/
  begin
    request.body.rewind
    @request_body = JSON.parse(request.body.read)
  rescue JSON::ParserError => e
    halt 400, e.to_s
  end
end

# ensure successful API responses have a JSON content-type, if not content-type is set.
after '/api/v1/*' do
  response.headers['Content-Type'] = 'application/json; charset=utf-8' if response.status == 200 && !response.headers.key?('Content-Type')
end

# handle prequalification API requests.
post '/api/v1/prequalify' do
  Store.for(Application, settings.environment) do |store|
    application = store.get(@request_body['company']['uuid']) if @request_body['company'] && @request_body['company']['uuid']
    if application
      application.attributes = @request_body
    else
      application = Application.new(@request_body)
    end

    if application.valid?
      begin
        application.decision = Underwriting.new(test_mode: settings.allow_test_responses).preapprove(application)
      rescue => e
        return [500, e.to_s]
      end
      if application.decision.preapproved && settings.return_offer_urls
        application.decision.offers.each_with_index do |offer, i|
          offer.url = url("/apply-for-loan/#{application.company.uuid}?offer=#{i + 1}")
        end
      end
      store.put(application.company.uuid, application)

      response_hash = application.decision.to_hash
      response_hash[:updated] = application.created_at != application.updated_at
      [200, JSON.pretty_generate(response_hash)]
    else
      [422, application.errors.join("\n")]
    end
  end
end

# handle document uploads.
post '/api/v1/documents' do
  return [400, 'POST body must be multipart/form-data'] unless (request.env['CONTENT_TYPE'] || '') =~ /^multipart\/form-data/

  file = params[:file]
  filename = file && file[:filename]
  file_handle = file && file[:tempfile]
  return [422, 'Missing parameter: file'] unless file && filename && file_handle
  uuid = params[:company_uuid]
  return [422, 'Missing parameter: company_uuid'] unless uuid

  Store.for(Application, settings.environment) do |store|
    application = store.get(uuid)
    return [404, "No application for ID #{uuid}"] unless application
    document = Document.new
    document.attributes = {
      uuid: SecureRandom.uuid,
      filename: filename,
      data: file_handle.read,
      document_type: params[:document_type],
      document_periods: params[:document_periods]
    }
    return [422, document.errors.join("\n")] unless document.valid?
    application.documents << document
    store.put(uuid, application)
  end
  [200]
end

## "admin" pages, for viewing API submissions.

before '/admin/*' do
  @organization = settings.organization
end

get '/admin' do
  redirect to('/admin/applications')
end

get '/admin/applications' do
  Store.for(Application, settings.environment) do |store|
    @applications = store.all
  end
  erb 'admin/applications'.to_sym
end

get '/admin/application/:uuid' do
  Store.for(Application, settings.environment) do |store|
    @application = store.get(params[:uuid])
  end
  if @application
    erb 'admin/application'.to_sym
  else
    [404]
  end
end

get '/admin/application/:application_uuid/document/:document_uuid' do
  Store.for(Application, settings.environment) do |store|
    application = store.get(params[:application_uuid])
    document = (application.documents || []).find { |d| d.uuid == params[:document_uuid] } if application
    if document
      content_type(
        case document.filename.downcase
        when /\.pdf$/
          'application/pdf'
        when /\.jpg$/
          'image/jpeg'
        when /\.png$/
          'image/png'
        when /\.txt$/
          'text/plain'
        else
          'application/octet-stream'
        end
      )
      [200, document.data]
    else
      [404]
    end
  end
end

# landing page for URLs returned on offers from the API.
get '/apply-for-loan/:uuid' do
  @organization = settings.organization
  Store.for(Application, settings.environment) do |store|
    @application = store.get(params[:uuid])
  end
  if @application && @application.decision.preapproved
    @offer =
      if params[:offer] && params[:offer].to_i > 0
        @application.decision.offers[params[:offer].to_i - 1]
      end
    erb :apply
  else
    erb :application_not_found
  end
end
