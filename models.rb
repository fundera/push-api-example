
require_relative 'lib/model'
require_relative 'field_options'

class Owner < Model
  field :uuid, String
  field :email, String
  field :phone_number, String
  field :first_name, String
  field :last_name, String
  field :ownership_percentage, Integer do |value|
    'must be at least 0 and 100 or less' if value < 0 || value > 100
  end
  field :date_of_birth, String, date: true
  field :street_line1, String
  field :street_line2, String, required: false
  field :city, String
  field :state, String
  field :zip, String
  field :ssn, String
  field :credit_score, String, value_in: FieldOptions::CREDIT_SCORE
  field :drivers_license_number, String, required: false
  field :drivers_license_state, String, required: false
  field :drivers_license_expiration, String, required: false, date: true
  field :passport_number, String, required: false
  field :passport_country, String, required: false
  field :passport_expiration, String, required: false, date: true
  field :monthly_residential_payment, Integer, required: false
  field :residence_rent_or_own, String, required: false, value_in: FieldOptions::RESIDENCE_RENT_OR_OWN
  field :personal_annual_income, Integer, required: false
  field :value_of_liquid_assets, Integer, required: false
  field :value_of_nonretirement_assets, Integer, required: false
  field :value_of_retirement_assets, Integer, required: false
  field :citizenship, String, required: false, value_in: FieldOptions::CITIZENSHIP
  field :officer_in_lawsuit, String, required: false, value_in: FieldOptions::OFFICER_IN_LAWSUIT
end

class Company < Model
  field :uuid, String
  field :loan_amount, Integer
  field :loan_purpose, String, value_in: FieldOptions::LOAN_PURPOSE
  field :industry, String, value_in: FieldOptions::INDUSTRY
  field :business_name, String
  field :business_dba, String, required: false
  field :entity_type, String, value_in: FieldOptions::ENTITY_TYPE
  field :street_line1, String
  field :street_line2, String, required: false
  field :city, String
  field :state, String
  field :zip, String
  field :phone_number, String
  field :ein, String, required: false
  field :number_of_employees, Integer, required: false
  field :annual_revenue, Integer
  field :average_bank_balance, Integer, required: false
  field :accounts_receivable, Integer, required: false
  field :business_inception, String, date: true
  field :last_bankruptcy, String, required: false, value_in: FieldOptions::LAST_BANKRUPTCY
  field :outstanding_tax_lien, Integer, required: false
  field :credit_card_volume_per_month, Integer, required: false
  field :business_location_type, String, required: false, value_in: FieldOptions::BUSINESS_LOCATION_TYPE
  field :monthly_business_location_payment, Integer, required: false
  field :business_location_rent_or_own, String, required: false, value_in: FieldOptions::BUSINESS_LOCATION_RENT_OR_OWN
end

class Offer < Model
  field :loan_approval_amount, Integer
  field :term, Integer
  field :repayment, String, value_in: FieldOptions::REPAYMENT
  field :factor_rate, Float, required: false
  field :interest_rate, Float, required: false
  field :origination_fee, Float
  field :misc_fee, Float, required: false
  field :url, String, required: false

  def valid?
    super
    if factor_rate.nil? && interest_rate.nil?
      @errors << 'one of factor_rate and interest_rate are required'
    end
    @errors.empty?
  end
end

class Decision < Model
  field :preapproved, [TrueClass, FalseClass]
  field :rejection_reason, String, required: false
  field :offers, Offer, required: false, list: true
end

class Application < Model
  field :owners, Owner, list: true
  field :company, Company
  field :decision, Decision, required: false
end

# puts "\no1 valid"
# o = Owner.new(first_name: 'foo', 'last_name' => 'bar')
# puts o.valid?
# puts o.first_name
# puts o.last_name
#
# puts "\no2 invalid"
# o = Owner.new(first_name: 123)
# puts o.valid?
# puts o.errors.to_a
# puts o.first_name
# puts o.last_name
#
# puts "\nc1 invalid"
# c = Company.new(business_name: 'FooCo')
# puts c.valid?
# puts c.errors.to_a
#
# puts "\nc2 invalid"
# c = Company.new(business_name: 'FooCo', owners: [])
# puts c.valid?
# puts c.errors.to_a
#
# puts "\nc3 invalid"
# c = Company.new(business_name: 'FooCo', owners: [123])
# puts c.valid?
# puts c.errors.to_a
#
# puts "\nc4 invalid"
# c = Company.new(business_name: 'FooCo', owners: [Owner.new(first_name: 'foo', 'last_name' => 'bar')])
# puts c.valid?
# puts c.errors.to_a

# puts "\nc5 invalid"
# c = Company.new(business_name: 'FooCo', owners: [{ first_name: 'foo', 'last_name' => 'bar' }])
# puts c.valid?
# puts c.errors.to_a

# puts "\no1 invalid"
# o = Offer.new(loan_approval_amount: 10_000, term: 12, repayment: 'Daily', origination_fee: 1.0)
# puts o.valid?
# puts o.errors.to_a
#
# puts "\no2 valid"
# o = Offer.new(loan_approval_amount: 10_000, term: 12, repayment: 'Daily', origination_fee: 1.0, interest_rate: 12.12)
# puts o.valid?
#
# puts "\nd1 invalid"
# d = Decision.new(preapproved: 1)
# puts d.valid?
# puts d.errors.to_a
#
# puts "\nd2 valid"
# d = Decision.new(preapproved: true)
# puts d.valid?
#
# puts "\nd3 valid"
# d = Decision.new(preapproved: false)
# puts d.valid?
#
# puts "\na1 invalid"
# a = Application.new(company: c, decision: Decision.new(preapproved: nil))
# puts a.valid?
# puts a.errors.to_a
#
# require 'yaml'
# puts a.to_yaml

# o = Owner.new(first_name: 123, date_of_birth: '123/23', ownership_percentage: -1, credit_score: 'happy face!')
# puts o.valid?
# puts o.errors.to_a
#
# o = Owner.new(first_name: 123, date_of_birth: '1980-12-15', ownership_percentage: 99, credit_score: 'Challenged (Below 550)')
# puts o.valid?
# puts o.errors.to_a
