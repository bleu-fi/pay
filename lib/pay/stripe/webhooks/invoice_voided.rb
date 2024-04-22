module Pay
  module Stripe
    module Webhooks
      class InvoiceVoided
        def call(event)
          Pay::Stripe::Invoice.sync(event.data.object.id, stripe_account: event.try(:account))
        end
      end
    end
  end
end
