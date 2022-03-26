# frozen_string_literal: true

require 'jd_client_wrapper/helpers'

module JdClientWrapper
  class Client
    include JdClientWrapper::Helpers

    AVAILABLE_MODES = %i(production test).freeze

    API_END_POINTS = {
      get_family_status: {
        test: 'https://familytest.orders.ilohas.info/API/GetFamilyStatus.php',
        production: 'https://family.orders.ilohas.info/API/GetFamilyStatus.php'
      },
      express_map: {
        test: 'https://familytest.orders.ilohas.info/map/FamilyMap.php',
        production: 'https://family.orders.ilohas.info/map/FamilyMap.php'
      }
    }.freeze

    attr_reader :options

    def initialize(options = {})
      @options = { mode: :production }.merge!(options)

      case api_mode
      when *AVAILABLE_MODES
        option_required! :merchant_id, :public_key, :private_key, :iv
      else
        raise InvalidMode, %(option :mode is either :test or :production)
      end
      @options.freeze
    end

    def get_family_status
      trade_info = encrypt_data(
        MerchantID: merchant_id,
        TimeStamp: Time.now.to_i
      )
      post_data = {
        PublicKey: public_key,
        TradeInfo: trade_info,
        TradeSha: make_sha256(trade_info)
      }
      api_uri = API_END_POINTS.dig(__method__, api_mode)
      post_result = post_request(api_uri, post_data)
      data = post_result['TradeInfo']

      raise RequestError, post_result unless data

      parse_json(decrypt_data(data), parse_keys: ['Data'])
    end

    private

    def merchant_id
      @merchant_id ||= options.fetch(:merchant_id)
    end

    def public_key
      @public_key ||= options.fetch(:public_key)
    end

    def private_key
      @private_key ||= options.fetch(:private_key)
    end

    def iv
      @iv ||= options.fetch(:iv)
    end

    def api_mode
      @api_mode ||= options.fetch(:mode)
    end
  end
end
