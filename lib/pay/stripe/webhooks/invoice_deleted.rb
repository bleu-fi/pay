module Pay
  module Stripe
    module Webhooks
      class InvoiceDeleted
        def call(event)
          object = event.data.object

          invoice = Pay::Invoice.find_by(processor_id: object.id)
          invoice&.destroy
        end
      end
    end
  end
end