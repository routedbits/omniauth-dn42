require 'omniauth-dn42/version'

require 'faraday'
require 'gpgme'
require 'multi_json'
require 'omniauth'
require 'securerandom'

module OmniAuth
	module Strategies
		class Dn42
			include OmniAuth::Strategy
			Faraday.default_adapter = :net_http

			option :uid_field, :asn

			# Strategy options
			option :callback_path, nil
			option :challenge_path, nil
			option :method_path, nil
			option :dn42regsrv_url, 'https://explorer.burble.com/api/registry'

			uid do
				@dn42[options[:uid_field]]
			end

			info do
				{
					asn: @dn42[:asn],
					mnt: @dn42[:mnt]
				}
			end

			def callback_phase
				return fail!(:invalid_credentials) unless identity
        super
			end

			def challenge_path
				options[:challenge_path] || "#{path_prefix}/#{name}/challenge"
			end

			def challenge_phase
				session[:omniauth_dn42_auth]   = request['auth']
				session[:omniauth_dn42_verify] = SecureRandom.hex(15)
				
				# respond with challenge form
				_build_challenge_form.to_response
			end

			def identity
				log :debug, "verification/check identity step"

				begin
					gpg_fingerprint = session[:omniauth_dn42_auth]
					public_key      = request['public_key']
					signed_text     = request['signed_message']
					verify_text     = session[:omniauth_dn42_verify]

					# import public key
					GPGME::Key.import(public_key)

					# verify key fingerprint can be loaded
					gpg_fingerprint = gpg_fingerprint.gsub(/^pgp-fingerprint (.*)/, '\1')

					begin
						key = GPGME::Key.get(gpg_fingerprint)
					rescue EOFError
						log :debug, "Cannot find key for fingerprint: #{gpg_fingerprint}"
						return false
					end

					# verify signature
					crypto = GPGME::Crypto.new
					data = crypto.verify(signed_text) do |signature|
						log :debug, "Challenge signed by: #{signature.key.fingerprint}"

						# check for valid signature
						return false unless signature.valid?
						log :debug, "Signature is valid"

						# check signature is from key in dn42_mnt_auth response
						return false if signature.key.fingerprint != gpg_fingerprint
						log :debug, "Signature fingerprint matches expected fingerprint"
					end

					# verify signed text is the verfication text
					if data.read.chomp.to_s.eql?(verify_text)
						log :debug, "Signed text matches verification text"
					else
						log :debug, "Signed text does NOT match verification text"
						return false
					end

					# Set OmniAuth user information
					@dn42 = {
						asn: session[:omniauth_dn42_asn],
						mnt: session[:omniauth_dn42_mnt]
					}

					return true
				rescue GPGME::Error
					log :error, "GPG error"
					return false
				ensure
					# ensure all omniauth-dn42 session information is deleted
					session.delete(:omniauth_dn42_asn)
					session.delete(:omniauth_dn42_auth)
					session.delete(:omniauth_dn42_keys)
					session.delete(:omniauth_dn42_mnt)
					session.delete(:omniauth_dn42_verify)

					# delete imported public key from keyring
					key.delete!
				end
			end

			def request_phase
				form = Form.new(:title => 'ASN', :url => method_path)

        form.text_field 'Enter your ASN', 'asn'
        
        form.button 'Next'
				form.to_response
			end

			def method_path
				options[:method_path] || "#{path_prefix}/#{name}/method"
			end

			def method_phase
				asn = "AS" + request['asn'].gsub(/(AS)?(\d+)$/, '\2')

				# make call to api for ASN maintainer
				mnt = _api_call("aut-num/#{asn}/mnt-by").values.first['mnt-by'].first

				# make call for maintainer auth keys
				auth = _api_call("mntner/#{mnt}/auth")
				methods = auth.values.first['auth']

				# store verification materials in session
				session[:omniauth_dn42_asn]  = asn 		  # ASN
				session[:omniauth_dn42_mnt]  = mnt      # mnt-by
				session[:omniauth_dn42_keys] = methods  # auth keys

				# respond with challenge form
				_build_method_form.to_response
			end

			def on_challenge_path?
				on_path?(challenge_path)
			end

			def on_method_path?
				on_path?(method_path)
			end

			def other_phase
				if on_challenge_path?
					if request.post?
						log :debug, "POST other_phase (send to challenge_phase)"
						challenge_phase
					else
						call_app!
					end
				elsif on_method_path?
					if request.post?
						log :debug, "POST other_phase (send to method_phase)"
						method_phase
					else
						call_app!
					end
				else
					call_app!
				end
			end

			private

			def _api_call(path)
				response = Faraday.get("#{options[:dn42regsrv_url]}/#{path}?raw")
				MultiJson.load(response.body)
			end

			def _build_method_form
				form = OmniAuth::Form.new(:title => 'Select Method', :url => challenge_path)

				# key select dropdown
				form.label_field "Select method", 'auth'
				form.html "\n<select name='auth' id='auth' class='input'>"
        session[:omniauth_dn42_keys].each do |key|
					# check supported methods (right now only pgp)
					if key =~ /^pgp-fingerprint/
          	form.html "\n<option value='#{key}'>#{key.gsub(/^(.{25})?.*(.{8,}?)$/m,'\1...\2')}</option>"
					end
        end
        form.html "\n</select>"

				form.button 'Next'

				return form
			end

			def _build_challenge_form
				form = OmniAuth::Form.new(:title => 'Verify', :url => callback_path)

				# textarea for public key
				form.label_field "Enter your PGP public key", 'public_key'
				form.html "\n<textarea name='public_key' rows='15' cols='35' placeholder='PGP Public Key'>"
				form.html "\n</textarea>"

				# random text to sign
				description = "Sign the following string (using --clear-sign) with your key and paste it below"
				form.html "\n<p>#{description}</p>"

				form.html "\n<p><pre>#{session[:omniauth_dn42_verify]}</pre></p>"

				# textarea for signed text
				form.label_field "Signed text", 'public_key'
				form.html "\n<textarea name='signed_message' rows='15' cols='35' placeholder='PGP Signature'>"
				form.html "\n</textarea>"

				# submit button
        form.button 'Next'

				return form
			end

  	end
	end
end
