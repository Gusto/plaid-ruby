require 'spec_helper.rb'

# TODO:
# - Don't hardcode access tokens or banks
# - Check the responses more

describe Plaid do
  before(:all) do |_|
    keys = YAML::load(IO.read('./keys.yml'))

    Plaid.config do |p|
      p.client_id = keys.fetch("client_id")
      p.secret = keys.fetch("secret")
      p.base_url = keys.fetch("base_url")
    end
  end

  describe Plaid, 'Call' do
    it 'calls get_place and returns a response code of 200' do
      place = Plaid.call.get_place('526842af335228673f0000b7')
      expect(place[:code]).to eq(200)
    end
  end

  describe Plaid::Auth do
    describe '.add' do
      context 'when the bank does not require MFA' do
        it 'responds with a status code of 200' do
          response = Plaid::Auth.add('wells', username: 'plaid_test', password: 'plaid_good')
          expect(response[:code]).to eq(200)
        end
      end

      context 'when the bank requires MFA' do
        it 'responds with a status code of 201' do
          response = Plaid::Auth.add('chase', username: 'plaid_test', password: 'plaid_good')
          expect(response[:code]).to eq(201)
        end
      end
    end

    describe '.get' do
      it 'responds with a status code of 200' do
        response = Plaid::Auth.get('test')
        expect(response[:code]).to equal(200)
      end
    end

    describe '.step' do
      context 'when the first answer is given' do
        it 'responds with a status code of 201' do
          response = Plaid::Auth.step('test', 'again', nil, 'bofa')
          expect(response[:code]).to eq(201)
        end
      end

      context 'when the final answer is given' do
        it 'responds with a status code of 200' do
          response = Plaid::Auth.step('test', 'tomato', nil, 'bofa')
          expect(response[:code]).to eq(200)
        end
      end
    end
  end

  describe Plaid::Institution do
    describe '.all' do
      it 'responds with a status code of 200' do
        response = Plaid::Institution.all
        expect(response[:code]).to equal(200)
      end
    end

    describe 'get' do
      it 'responds with a status code of 200' do
        response = Plaid::Institution.get('5301a9d704977c52b60000db')
        expect(response[:code]).to equal(200)
      end
    end
  end

  describe Plaid::Upgrade do
    let(:account_id) { 'QPO8Jo8vdDHMepg41PBwckXm4KdK1yUdmXOwK' }
    let(:from) { '2013-06-11' }

    describe '.upgrade' do
      before do
        auth_response = Plaid::Auth.add('wells', username: 'plaid_test', password: 'plaid_good')
        expect(auth_response[:code]).to eq(200)
        @upgrade_response = Plaid::Upgrade.upgrade(auth_response.fetch(:access_token), 'connect')
      end

      it 'can upgrade the service' do
        expect(@upgrade_response[:code]).to eq(200)
      end

      it 'can retrieve the transactions after upgrading' do
        response = Plaid::Connect.get(@upgrade_response[:access_token], account: account_id, gte: from)
        expect(response.fetch(:code)).to eq(200)
        expect(response.fetch(:transactions).size).to be >= 1
        first_transaction = response.fetch(:transactions).first
        expect(first_transaction.fetch('amount')).to be
        expect(first_transaction.fetch('date')).to be
        expect(first_transaction.fetch('pending')).to_not be_nil
        expect(first_transaction.fetch('_account')).to eq account_id
        expect(first_transaction.fetch('_id')).to be
      end
    end
  end

  describe Plaid, 'Customer' do
    it 'calls get_transactions and returns a response code of 200' do
      transactions = Plaid.customer.get_transactions('test')
      expect(transactions[:code]).to eq(200)
    end

    it 'calls delete_account and returns a response code of 200' do
      message = Plaid.customer.delete_account('test')
      expect(message[:code]).to eq(200)
    end
  end
end
