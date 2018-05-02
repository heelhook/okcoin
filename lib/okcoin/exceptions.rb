module Okcoin
  class Exception < RuntimeError; end
  class CreateOrderException < RuntimeError; end
  class CancelOrderException < RuntimeError; end
  class WithdrawalException < RuntimeError; end
end
