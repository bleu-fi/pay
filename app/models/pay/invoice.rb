module Pay
  class Invoice < Pay::ApplicationRecord
    # Associations
    belongs_to :customer
    belongs_to :subscription, optional: true

    # Scopes
    scope :sorted, -> { order(created_at: :desc) }
    scope :with_active_customer, -> { joins(:customer).merge(Customer.active) }
    scope :with_deleted_customer, -> { joins(:customer).merge(Customer.deleted) }

    # Validations
    validates :processor_id, presence: true, uniqueness: {scope: :customer_id, case_sensitive: true}

    # Store the invoice specific data
    store_accessor :data, :invoice_pdf_url
    store_accessor :data, :hosted_invoice_url

    # Additional invoice attributes
    store_accessor :data, :processor_plan_id
    store_accessor :data, :currency
    store_accessor :data, :line_items
    store_accessor :data, :subtotal # subtotal amount in cents
    store_accessor :data, :tax # total tax amount in cents
    store_accessor :data, :discounts # array of discount IDs applied to the invoice
    store_accessor :data, :total_discount_amounts # array of discount details
    store_accessor :data, :total_tax_amounts # array of tax details for each jurisdiction
    store_accessor :data, :credit_notes # array of credit notes for the invoice
    store_accessor :data, :refunds # array of refunds

    delegate_missing_to :pay_processor

    # Helpers for payment processors
    %w[braintree stripe paddle_billing paddle_classic fake_processor].each do |processor_name|
      define_method :"#{processor_name}?" do
        customer.processor == processor_name
      end

      scope processor_name, -> { joins(:customer).where(pay_customers: {processor: processor_name}) }
    end

    def self.pay_processor_for(name)
      "Pay::#{name.to_s.camelize}::Invoice".constantize
    end

    def payment_processor
      @payment_processor ||= self.class.pay_processor_for(customer.processor).new(self)
    end

    def sync!(**options)
      self.class.pay_processor_for(customer.processor).sync(processor_id, **options)
      reload
    end
  end
end
