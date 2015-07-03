## Ruby module for working with BITSO API
## July 2015

require 'json'
require 'net/http'
require 'uri'
require 'openssl'

class Bitso
  API_BASE = 'https://api.bitso.com/v2/'
  CALLS = {
    'ticker' => [FALSE, [] ],
    'order_book' => [FALSE, ['book', 'group'] ],
    'transactions' => [TRUE, [] ],
    'balance' => [TRUE, [] ],
    'user_transactions' => [TRUE, ['offset', 'limit', 'sort', 'book'] ],
    'open_orders' => [TRUE, ['book'] ],
    'lookup_order' => [TRUE, [ 'id' ] ],
    'cancel_order' => [TRUE, [ 'id' ] ],
    'buy' => [TRUE, [ 'amount', 'price'] ],
    'sell' => [TRUE, [ 'amount', 'price'] ],
    'bitcoin_deposit_address' => [TRUE, [] ],
    'bitcoin_withdrawal' => [TRUE, [ 'address', 'amount' ] ]
  }
  @@last = Time.new(0)

  def initialize(client_id, key, secret)
    @client_id = client_id
    @key = key
    @secret = secret

    CALLS.each do |name|
      define_singleton_method name[0], lambda { |*args|
        data = CALLS[name[0]]
        api_request( [name[0],data[0]], Hash[data[1].zip( args )] )
      }
    end
  end

  def api_request( info, post_data={} )
    url, auth = info
    uri = URI.parse(API_BASE + url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl=TRUE
    # CampBX advises latency can be >4 minutes when markets are volatile
    http.read_timeout = 300
    res = nil

    request = Net::HTTP::Get.new(uri.request_uri)
    if auth then
      nonce = (Time.now.to_f*10000).to_i.to_s
      sign_string = (nonce + @client_id + @key)
      signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), @secret, sign_string)

      post_data.merge!({
        'key' => @key,
        'nonce' => nonce,
        'signature' => signature.upcase
      })

      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data( post_data )
    end

    make_request(http, request)
  end

  def make_request http, request
    # CampBX API: max 1 request per 500ms
    delta = Time.now - @@last
    #puts delta*1000
    if delta*1000 <= 500 then
      #puts "sleeping! for #{0.5 - delta}"
      sleep(0.5 - delta)
    end

    res = http.request(request)

    @@last = Time.now # Update time after request returns
    if res.message == 'OK' then # HTTP OK
      begin
        JSON.parse( res.body )
      rescue
        res.body
      end
    else # HTTP ERROR
      warn "HTTP Error: + #{res.code}"
    end
  end

end