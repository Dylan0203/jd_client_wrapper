# frozen_string_literal: true

require 'net/http'
require 'json'
require 'jd_client_wrapper/errors'

module JdClientWrapper
  module Helpers
    CIPHER_METHOD = 'AES-256-CBC'
    # function create_mpg_aes_encrypt($parameter, $Private_Key = "", $iv = "") {
    #   $return_str = '';

    #   if (!empty($parameter)) {
    #   ksort($parameter);
    #   $return_str = http_build_query($parameter);
    #   }

    #   return trim(bin2hex(openssl_encrypt(addpadding($return_str), 'AES-256-CBC', $Private_Key, OPENSSL_RAW_DATA|OPENSSL_ZERO_PADDING, $iv)));
    # }
    def encrypt_data(params = {})
      query_string = URI.encode_www_form(params.sort)

      cipher = OpenSSL::Cipher::Cipher.new(CIPHER_METHOD)
      cipher.encrypt
      cipher.key = private_key[0..31]
      cipher.iv = iv
      cipher.padding = 0
      encrypted = cipher.update(addpadding(query_string))
      # encrypted << cipher.final
      encrypted.unpack('H*').first.strip
    end

    # function create_aes_decrypt($parameter = "", $Private_Key = "", $iv = "") {
    #   $dec_data = explode('&',strippadding(openssl_decrypt(hex2bin($parameter),'AES-256-CBC', $Private_Key, OPENSSL_RAW_DATA|OPENSSL_ZERO_PADDING, $iv)));
    #   if($dec_data) {
    #     foreach ($dec_data as $_ind => $value) {
    #     $trans_data = explode('=', $value);
    #     $return_data[$trans_data[0]] = urldecode($trans_data[1]); }
    #   }
    #   return $return_data;
    # }

    def decrypt_data(encrypted_data)
      cipher = OpenSSL::Cipher::Cipher.new(CIPHER_METHOD)
      cipher.decrypt
      cipher.key = private_key[0..31]
      cipher.iv = iv
      cipher.padding = 0
      decrypt = cipher.update([encrypted_data].pack('H*'))
      # decrypt << cipher.final

      Hash[URI.decode_www_form(strippadding(decrypt))]
    end

    def parse_json(data, parse_keys: [])
      parse_keys.each do |key|
        value = data[key]
        data[key] = JSON.parse(value) if value
      end

      data
    end

    private

    # function addpadding($string, $blocksize = 32) {
    #   $len = strlen($string);
    #   $pad = $blocksize - ($len % $blocksize);
    #   $string .= str_repeat(chr($pad), $pad);
    #   return $string;
    # }
    def addpadding(string, blocksize = 32)
      len = string.length
      pad = blocksize - (len % blocksize)
      string << pad.chr * pad
    end

    # function strippadding($string) {
    #   $slast = ord(substr($string, -1));
    #   $slastc = chr($slast);
    #   if (preg_match("/$slastc{".$slast."}/", $string)) {
    #     $string = substr($string, 0, strlen($string) - $slast);
    #     return $string;
    #   } else {
    #     return false;
    #   }
    # }

    def strippadding(str)
      slast = str[-1].ord
      slastc = slast.chr
      string_match = /#{slastc}{#{slast}}/ =~ str
      if string_match
        str[0, string_match]
      else
        false
      end
    end

    def make_sha256(data)
      Digest::SHA256.hexdigest(%Q(PublicKey=#{public_key}&#{data}&PrivateKey=#{private_key})).upcase!
    end

    def option_required!(*option_names)
      option_names.each do |option_name|
        raise MissingOption, %(option "#{option_name}" is required.) unless @options.dig(option_name)
      end
    end

    def post_request(uri, params = {})
      uri = URI.parse(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.instance_of? URI::HTTPS
      request = Net::HTTP::Post.new(uri.request_uri, 'Content-Type': 'application/json', charset: 'utf-8')
      request.body = params.to_json
      res = http.request(request)

      JSON.parse(res.body)
    end
  end
end
