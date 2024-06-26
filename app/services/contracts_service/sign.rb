module ContractsService
  class Sign
    include TransactionMethods
    include Call::Methods

    def main_method
      execute_and_perform
    end

    private

    def execute_and_perform
      generate_pdf if sign
      sign
    end

    def sign
      @sign ||= begin
        execute_or_rollback do
          make_signature
          save_or_sign_contract!
          update_contract_blockchain!
          notify
        end
      end
    end

    def make_signature
      contract.send("#{type}=", user)
      contract.send("#{type}_signed_at=", DateTime.current)
    end

    def save_or_sign_contract!
      contract.all_signed? ? sign! : contract.save!
    end

    def sign!
      puts "!CONTRACT SIGNING!"
      contract.signed!
      contract.reload
      contract.bidding.reload
      sleep 2
      puts "!GENERATING MINUTE!"
      generate_minute
    end

    def update_contract_blockchain!
      # Blockchain::Contract::Update.call!(contract: contract)
    end

    def notify
      Notifications::Contracts::Sign::AdminUser.call(contract: contract)
    end

    def generate_pdf
      Contract::PdfGenerateWorker.perform_async(contract.id) if contract.all_signed?
    end
    def generate_minute
      Bidding::Minute::PdfGenerateWorker.perform_async(contract.bidding.id) if contract.all_signed?
    end
  end
end
