require 'gpgme'
require 'logger'

class NilClass
  def blank?
    true
  end
end

class String
  def blank?
    self.strip.empty?
  end
end

class Object
  def try method, *args, &block
    respond_to?(method) ? send(method, *args, &block) : nil
  end
end

$DATA_DIR = ENV['APP_DATA_DIR'] || '/tmp/gpgme'
$SERVER_PORT = ENV['APP_SERVER_PORT'].try(:to_i) || 8080

# Set up server
set :bind, '0.0.0.0'
set :port, $SERVER_PORT

# Set up logger Docker compatible logging
set :logger, Logger.new(STDOUT)

get '/' do
  'YAKS for GPG!'
end

post '/pks/add' do
  GPGME::Engine.home_dir = $DATA_DIR
  GPGME::Key.import(params[:keytext])
end

# TODO: return human readable output for params[:options] != 'mr'

# https://tools.ietf.org/html/draft-shaw-openpgp-hkp-00#section-5
get '/pks/lookup' do
  GPGME::Engine.home_dir = $DATA_DIR
  case params[:op]
  when 'get'
    keys = GPGME::Key.find(:public, params[:search])
    status(404) && return unless keys.size > 0
    headers \
      'Content-Type' => 'application/pgp-keys; charset=utf-8',
      'Content-Disposition' => 'attachment; filename=openpgpkey.asc'
    keys.first.export(:armor => true).read
  when /^v?index$/
    keys = GPGME::Key.find(:public, params[:search])
    status(404) && return unless keys.size > 0
    headers 'Content-Type' => 'text/plain; charset=utf-8'

    # optional info ling
    version = 1
    results = [ "info:#{version}:#{keys.size}" ]

    # add keys and uids
    keys.each do |key|
      # "pub" key info
      primary = key.primary_subkey
      results << [
        'pub', # header
        primary.fingerprint,
        primary.pubkey_algo,
        primary.length,
        primary.timestamp.to_i,
        primary.expires.to_i,
        primary.expired ? 'e' : '', # TODO (r)evoked / (d)isabled
      ].join(?:)

      # "uid" info
      key.uids.each do |uid|
        results << [
          'uid', # header
          # Name (comment) <email> formatting
          # TODO: use URI.encode_www_form_component here
          [
            !uid.name.blank? ? uid.name : nil,
            !uid.comment.blank? ? "(#{uid.comment})" : nil,
            !uid.email.blank? ? "<#{uid.email}>" : nil,
          ].compact.join(' '),
          '', # creation date
          '', # expiration date
          '', # flags
        ].join(?:)
      end
    end

    # return results and add an extra newline
    results.join(?\n) + ?\n
  else
    status 404
    "Not supported op (#{params[:op]}) found!"
  end
end

not_found do
  status 404
  'Not found!'
end
