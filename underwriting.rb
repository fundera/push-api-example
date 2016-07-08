
require_relative 'models'

class Underwriting
  def initialize(test_mode: false)
    @test_mode = test_mode
  end

  def preapprove(application)
    raise 'expected an Application' unless application.is_a?(Application)
    raise 'expected a valid Application' unless application.valid?

    if @test_mode
      case application.owners[0].first_name
      when 'approved'
        offers = (0..Random.rand(3)).map do
          Offer.new(
            loan_approval_amount: [10_000, 20_000, 50_000].sample,
            term: [12, 24, 36].sample,
            interest_rate: [15.0, 18.0, 21.0].sample,
            repayment: ['Daily', 'Weekly', 'Bi-Weekly', 'Monthly'].sample,
            origination_fee: [1.0, 2.0].sample
          )
        end
        return Decision.new(preapproved: true, offers: offers)
      when 'declined'
        return Decision.new(preapproved: false, rejection_reason: 'testing')
      end
    end

    if %w(NV VT PR DC).include?(application.company.state)
      return Decision.new(preapproved: false, rejection_reason: "can't lend to businesses in #{application.company.state}")
    end

    loan_amounts_and_terms =
      if application.company.annual_revenue > 500_000
        [
          [40_000, 12],
          [70_000, 24],
          [100_000, 36]
        ]
      elsif application.company.annual_revenue > 200_000
        [[20_000, 12]]
      end
    unless loan_amounts_and_terms
      return Decision.new(preapproved: false, rejection_reason: 'annual revenue is too low')
    end

    interest_rate =
      case application.owners[0].credit_score
      when 'Excellent (700+)', 'Excellent (660-699)'
        15.0
      when 'Good (640-659)', 'Good (620-639)'
        18.0
      when 'Fair (580-619)'
        21.0
      end
    unless interest_rate
      return Decision.new(preapproved: false, rejection_reason: 'owner credit is too low')
    end

    offers = loan_amounts_and_terms.map do |loan_amount, term|
      Offer.new(
        loan_approval_amount: loan_amount,
        term: term,
        interest_rate: interest_rate,
        repayment: term > 12 ? 'Monthly' : 'Daily',
        origination_fee: 1.0
      )
    end
    Decision.new(preapproved: true, offers: offers)
  end
end
