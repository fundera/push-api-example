ENV['RACK_ENV'] = 'test'
require_relative '../app'
require_relative '../models'
require_relative '../lib/store'

require 'minitest/autorun'
require 'rack/test'

describe 'the example app' do
  include Rack::Test::Methods
  def app
    Sinatra::Application
  end

  def auth_header
    username = 'test'
    password = 'abc123'
    "Basic #{Base64.strict_encode64("#{username}:#{password}")}"
  end

  before do
    Store.delete_all('test')
  end

  describe 'APIs generally' do
    it 'responds to POST' do
      header 'Authorization', auth_header
      get '/api/v1/prequalify'
      assert_equal 404, last_response.status
    end

    it 'returns 401 with missing auth' do
      post '/api/v1/prequalify'
      assert_equal 401, last_response.status
    end

    it 'returns a 400 parse error in the response with valid auth and no post body' do
      header 'Authorization', auth_header
      post '/api/v1/prequalify'
      assert_equal 400, last_response.status
      assert_match /\w+/, last_response.body
    end

    it 'returns a 500 validation error in the response with valid auth and valid but empty JSON body' do
      header 'Authorization', auth_header
      post '/api/v1/prequalify', '{}'
      assert_equal 422, last_response.status
      assert_match(/company is required/, last_response.body)
    end
  end

  describe 'prequalifcation API' do
    before do
      @request = {
        owners: [
          {
            uuid: '96fb4br9-db62-4brv-2f4d-02b14ea3de60',
            email: 'rohan@fundera.com',
            phone_number: '6467272189',
            first_name: 'Test',
            last_name: 'Testerson',
            ownership_percentage: 96,
            date_of_birth: '1973-04-12',
            street_line1: '123 Main Street',
            street_line2: '#7',
            city: 'New York',
            state: 'NY',
            zip: '10014',
            ssn: '666006417',
            credit_score: 'Good (640-659)',
            last_bankruptcy: 'No bankruptcies',
            drivers_license_number: '123-45-678',
            drivers_license_state: 'NY',
            drivers_license_expiration: '2020-01-01',
            passport_number: '1234567',
            passport_country: 'US',
            passport_expiration: '2025-03-05',
            monthly_residential_payment: 2000,
            residence_rent_or_own: 'Rent',
            personal_annual_income: 80_000,
            value_of_liquid_assets: 20_000,
            value_of_nonretirement_assets: 40_000,
            value_of_retirement_assets: 30_000,
            citizenship: 'US Citizen',
            permission_to_pull_credit: true,
            permission_to_pull_credit_date: Date.today.to_s
          },
          {
            uuid: '62og0vw4-lt52-4qdi-2f7a-08b74mf3de32',
            email: 'kevin@fundera.com',
            phone_number: '6467272189',
            first_name: 'Kevin',
            last_name: 'Test',
            ownership_percentage: 4,
            date_of_birth: '1980-07-17',
            street_line1: '123 S. 1st St.',
            street_line2: 'Apt A',
            city: 'Omaha',
            state: 'FL',
            zip: '99123',
            ssn: '666776417',
            credit_score: 'Fair (580-619)',
            last_bankruptcy: 'No bankruptcies',
            drivers_license_number: '12-345-679',
            drivers_license_state: 'NY',
            drivers_license_expiration: '2020-01-01',
            passport_number: '1234567',
            passport_country: 'US',
            passport_expiration: '2025-03-05',
            monthly_residential_payment: 2000,
            residence_rent_or_own: 'Rent',
            personal_annual_income: 80_000,
            value_of_liquid_assets: 20_000,
            value_of_nonretirement_assets: 40_000,
            value_of_retirement_assets: 30_000,
            citizenship: 'US Citizen',
            permission_to_pull_credit: true,
            permission_to_pull_credit_date: Date.today.to_s
          }
        ],
        company: {
          uuid: '33fb0bd4-dd62-4bac-8f4a-08b14da3de60',
          loan_amount: 55_000,
          loan_purpose: 'Working capital',
          industry: 'Farm Goods Distribution',
          industry_naics: '124892',
          business_name: 'Farm Co Inc.',
          business_dba: 'FarmGood!',
          entity_type: 'C Corporation',
          street_line1: '456 Main Street',
          street_line2: 'Suite A',
          city: 'Richmond',
          state: 'VA',
          zip: '11218',
          phone_number: '6467192840',
          ein: '121234567',
          number_of_employees: 19,
          annual_revenue: 1_800_000,
          annual_profit: 250_000,
          average_bank_balance: 40_000,
          accounts_receivable: 25_000,
          business_inception: '2010-02-10',
          outstanding_tax_lien: 0,
          credit_card_volume_per_month: 20_000,
          business_location_type: 'Office',
          monthly_business_location_payment: 2_000,
          business_location_rent_or_own: 'Rent',
          officer_in_lawsuit: 'No previous or current legal actions',
          debts: [
            {
              type: 'Term Loan',
              refinance: true,
              amount_remaining: 2_000,
              original_amount_borrowed: 20_000,
              payment_amount: 200,
              payment_frequency: 'Monthly',
              lender: 'Big Bank'
            },
            {
              type: 'Line of Credit',
              refinance: false,
              amount_remaining: 500,
              original_amount_borrowed: 10_000,
              payment_amount: 100,
              payment_frequency: 'Weekly',
              lender: 'Fancy Capital LLP'
            }
          ]
        },
        fields_version: 2
      }
    end

    it 'applies and is approved' do
      header 'Authorization', auth_header
      post '/api/v1/prequalify', JSON.generate(@request)
      assert_equal 200, last_response.status
      response = JSON.parse(last_response.body)
      assert Decision.new(response).valid?

      assert_equal true, response['preapproved']
      assert !response.key?('rejection_reason')
      assert_equal false, response['updated']
      assert_equal 3, response['offers'].size
      response['offers'][0].tap do |offer|
        assert_equal offer['loan_approval_amount'], 40_000
        assert_equal offer['term'], 12
        assert_equal offer['repayment'], 'Daily'
        assert_equal offer['interest_rate'], 18.0
        assert_equal offer['origination_fee'], 1.0
        assert_match %r{^http.*\/apply-for-loan/#{@request[:company][:uuid]}\?offer=1}, offer['url']
      end
      response['offers'][1].tap do |offer|
        assert_equal offer['loan_approval_amount'], 70_000
        assert_equal offer['term'], 24
        assert_equal offer['repayment'], 'Monthly'
        assert_equal offer['interest_rate'], 18.0
        assert_equal offer['origination_fee'], 1.0
        assert_match %r{^http.*\/apply-for-loan/#{@request[:company][:uuid]}\?offer=2}, offer['url']
      end
      response['offers'][2].tap do |offer|
        assert_equal offer['loan_approval_amount'], 100_000
        assert_equal offer['term'], 36
        assert_equal offer['repayment'], 'Monthly'
        assert_equal offer['interest_rate'], 18.0
        assert_equal offer['origination_fee'], 1.0
        assert_match %r{^http.*\/apply-for-loan/#{@request[:company][:uuid]}\?offer=3}, offer['url']
      end

      Store.for(Application, 'test') do |store|
        application = store.get(@request[:company][:uuid])
        assert !application.nil?
        app_hash = application.to_hash
        app_hash.delete(:decision)
        assert @request.eql?(app_hash)
      end
    end

    it 'approves and updates returning different offers' do
      header 'Authorization', auth_header
      post '/api/v1/prequalify', JSON.generate(@request)
      assert_equal 200, last_response.status
      response = JSON.parse(last_response.body)
      assert Decision.new(response).valid?
      assert_equal true, response['preapproved']
      assert !response.key?('rejection_reason')
      assert_equal false, response['updated']
      assert_equal 3, response['offers'].size

      @request[:company][:annual_revenue] = 400_000
      post '/api/v1/prequalify', JSON.generate(@request)
      assert_equal 200, last_response.status
      response = JSON.parse(last_response.body)
      assert Decision.new(response).valid?
      assert_equal true, response['preapproved']
      assert !response.key?('rejection_reason')
      assert_equal true, response['updated']
      assert_equal 1, response['offers'].size

      Store.for(Application, 'test') do |store|
        assert_equal 1, store.all.size
      end
    end

    it 'declines' do
      @request[:company][:state] = 'NV'
      header 'Authorization', auth_header
      post '/api/v1/prequalify', JSON.generate(@request)
      assert_equal 200, last_response.status
      response = JSON.parse(last_response.body)
      assert Decision.new(response).valid?
      assert_equal false, response['preapproved']
      assert_match /lend to businesses in/, response['rejection_reason']
      assert_equal false, response['updated']
      assert !response.key?('offers')

      @request[:company][:state] = 'NY'
      post '/api/v1/prequalify', JSON.generate(@request)
      assert_equal 200, last_response.status
      response = JSON.parse(last_response.body)
      assert Decision.new(response).valid?
      assert_equal true, response['preapproved']
      assert !response.key?('rejection_reason')

      @request[:company][:annual_revenue] = 50_000
      post '/api/v1/prequalify', JSON.generate(@request)
      assert_equal 200, last_response.status
      response = JSON.parse(last_response.body)
      assert Decision.new(response).valid?
      assert_equal false, response['preapproved']
      assert_equal 'annual revenue is too low', response['rejection_reason']
      assert_equal true, response['updated']
      assert !response.key?('offers')

      @request[:company][:annual_revenue] = 1_500_000
      post '/api/v1/prequalify', JSON.generate(@request)
      assert_equal 200, last_response.status
      response = JSON.parse(last_response.body)
      assert Decision.new(response).valid?
      assert_equal true, response['preapproved']
      assert !response.key?('rejection_reason')

      @request[:owners][0][:credit_score] = 'Challenged (Below 550)'
      post '/api/v1/prequalify', JSON.generate(@request)
      assert_equal 200, last_response.status
      response = JSON.parse(last_response.body)
      assert Decision.new(response).valid?
      assert_equal false, response['preapproved']
      assert_equal 'owner credit is too low', response['rejection_reason']
      assert_equal true, response['updated']
      assert !response.key?('offers')
    end

    it 'forces approve or decline with special values' do
      header 'Authorization', auth_header
      post '/api/v1/prequalify', JSON.generate(@request)
      assert_equal 200, last_response.status
      response = JSON.parse(last_response.body)
      assert Decision.new(response).valid?
      assert_equal true, response['preapproved']
      assert !response.key?('rejection_reason')

      @request[:owners][0][:first_name] = 'declined'
      post '/api/v1/prequalify', JSON.generate(@request)
      assert_equal 200, last_response.status
      response = JSON.parse(last_response.body)
      assert Decision.new(response).valid?
      assert_equal false, response['preapproved']
      assert_equal 'testing', response['rejection_reason']

      @request[:owners][0][:first_name] = 'Janet'
      @request[:company][:annual_revenue] = 50_000
      post '/api/v1/prequalify', JSON.generate(@request)
      assert_equal 200, last_response.status
      response = JSON.parse(last_response.body)
      assert Decision.new(response).valid?
      assert_equal false, response['preapproved']
      assert_equal 'annual revenue is too low', response['rejection_reason']

      @request[:owners][0][:first_name] = 'approved'
      post '/api/v1/prequalify', JSON.generate(@request)
      assert_equal 200, last_response.status
      response = JSON.parse(last_response.body)
      assert Decision.new(response).valid?
      assert_equal true, response['preapproved']
      assert !response.key?('rejection_reason')
    end

    it 'forces a 500 error with a special value' do
      @request[:owners][0][:first_name] = 'crash'
      header 'Authorization', auth_header
      post '/api/v1/prequalify', JSON.generate(@request)
      assert_equal 500, last_response.status
      assert_match /oops/, last_response.body
    end

    it 'can approve with minimal fields' do
      @request[:owners] = [@request[:owners][0]]
      @request[:owners][0].tap do |owner|
        owner.delete(:street_line2)
        owner.delete(:drivers_license_number)
        owner.delete(:drivers_license_state)
        owner.delete(:drivers_license_expiration)
        owner.delete(:passport_number)
        owner.delete(:passport_country)
        owner.delete(:passport_expiration)
        owner.delete(:monthly_residential_payment)
        owner.delete(:residence_rent_or_own)
        owner.delete(:personal_annual_income)
        owner.delete(:value_of_liquid_assets)
        owner.delete(:value_of_nonretirement_assets)
        owner.delete(:value_of_retirement_assets)
        owner.delete(:citizenship)
        owner.delete(:officer_in_lawsuit)
      end
      @request[:company].tap do |company|
        company.delete(:business_dba)
        company.delete(:street_line2)
        company.delete(:ein)
        company.delete(:number_of_employees)
        company.delete(:annual_profit)
        company.delete(:average_bank_balance)
        company.delete(:accounts_receivable)
        company.delete(:last_bankruptcy)
        company.delete(:outstanding_tax_lien)
        company.delete(:credit_card_volume_per_month)
        company.delete(:business_location_type)
        company.delete(:monthly_business_location_payment)
        company.delete(:business_location_rent_or_own)
        company.delete(:debts)
      end

      header 'Authorization', auth_header
      post '/api/v1/prequalify', JSON.generate(@request)
      assert_equal 200, last_response.status
      response = JSON.parse(last_response.body)
      assert Decision.new(response).valid?
      assert_equal true, response['preapproved']
      assert !response.key?('rejection_reason')
      assert_equal 3, response['offers'].size
    end

    it 'returns validation errors' do
      @request[:company].delete(:business_name)
      @request[:company][:entity_type] = 'Cartel'
      @request[:owners][0][:ownership_percentage] = 120
      @request[:owners][1][:date_of_birth] = 'Jan 1, 1980'

      header 'Authorization', auth_header
      post '/api/v1/prequalify', JSON.generate(@request)
      assert_equal 422, last_response.status

      assert_match /^company: business_name is required/, last_response.body
      assert_match /^company: entity_type must be one of/, last_response.body
      assert_match /^owners \(1\): ownership_percentage must be at least 0 and 100 or less/, last_response.body
      assert_match /^owners \(2\): date_of_birth must match YYYY-MM-DD/, last_response.body
    end
  end

  describe 'documents API' do
    before do
      @uuid = '123-456'
      @application = Application.new
      Store.for(Application, 'test') do |store|
        store.put(@uuid, @application)
      end
    end

    it 'returns various errors' do
      header 'Authorization', auth_header
      post '/api/v1/documents'
      assert_equal 400, last_response.status
      assert_match /multipart/, last_response.body

      post '/api/v1/documents', file: Rack::Test::UploadedFile.new('test/fixtures/testdoc.pdf', 'application/pdf')
      assert_equal 422, last_response.status
      assert_match /^Missing parameter/, last_response.body

      post '/api/v1/documents', file: Rack::Test::UploadedFile.new('test/fixtures/testdoc.pdf', 'application/pdf'), company_uuid: @uuid
      assert_equal 422, last_response.status
      assert_match /document_type is required/, last_response.body
    end

    it 'stores the document on an application' do
      header 'Authorization', auth_header
      post '/api/v1/documents', file: Rack::Test::UploadedFile.new('test/fixtures/testdoc.pdf', 'application/pdf'), company_uuid: @uuid, document_type: 'Bank Statement'
      assert_equal 200, last_response.status

      post '/api/v1/documents', file: Rack::Test::UploadedFile.new('test/fixtures/testdoc.pdf', 'application/pdf'), company_uuid: @uuid, document_type: 'Tax Return', document_periods: '2014, 2015'
      assert_equal 200, last_response.status

      Store.for(Application, 'test') do |store|
        application = store.get(@uuid)
        assert_equal 2, application.documents.size
        assert_equal 'Bank Statement', application.documents[0].document_type
        assert_nil application.documents[0].document_periods
        assert !application.documents[0].uuid.nil?
        assert_equal 'Tax Return', application.documents[1].document_type
        assert_equal '2014, 2015', application.documents[1].document_periods
        assert !application.documents[1].uuid.nil?
      end
    end
  end
end
