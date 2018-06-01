
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
  field :last_bankruptcy, String, required: false, value_in: FieldOptions::LAST_BANKRUPTCY
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
  field :ip_address, String, required: false
  field :permission_to_pull_credit, [TrueClass, FalseClass]
  field :permission_to_pull_credit_date, String, date: true
end

class Debt < Model
  field :type, String, value_in: FieldOptions::DEBT_TYPE
  field :refinance, [TrueClass, FalseClass]
  field :amount_remaining, Integer
  field :original_amount_borrowed, Integer
  field :payment_amount, Integer
  field :payment_frequency, String, required: false, value_in: FieldOptions::PAYMENT_FREQUENCY
  field :lender, String, required: false
end

class Company < Model
  field :uuid, String
  field :loan_amount, Integer
  field :loan_purpose, String, value_in: FieldOptions::LOAN_PURPOSE
  field :industry, String, value_in: FieldOptions::INDUSTRY
  field :industry_naics, String
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
  field :annual_profit, Integer, required: false
  field :average_bank_balance, Integer, required: false
  field :accounts_receivable, Integer, required: false
  field :business_inception, String, date: true
  field :outstanding_tax_lien, Integer, required: false
  field :credit_card_volume_per_month, Integer, required: false
  field :business_location_type, String, required: false, value_in: FieldOptions::BUSINESS_LOCATION_TYPE
  field :monthly_business_location_payment, Integer, required: false
  field :business_location_rent_or_own, String, required: false, value_in: FieldOptions::BUSINESS_LOCATION_RENT_OR_OWN
  field :officer_in_lawsuit, String, required: false, value_in: FieldOptions::OFFICER_IN_LAWSUIT
  field :debts, Debt, list: true, required: false
end

class Offer < Model
  field :loan_approval_amount, Integer
  field :term, Integer
  field :repayment, String, value_in: FieldOptions::REPAYMENT
  field :factor_rate, Float, required: false
  field :interest_rate, Float, required: false
  field :origination_fee, Float
  field :miscellaneous_fee, Integer, required: false
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

class Document < Model
  field :uuid, String
  field :filename, String
  field :data, String # binary
  field :document_type, String
  field :document_periods, String, required: false
end

class Application < Model
  field :owners, Owner, list: true
  field :company, Company
  field :decision, Decision, required: false
  field :fields_version, Integer

  def documents
    @documents ||= []
  end
end
