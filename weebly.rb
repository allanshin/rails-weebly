#!/usr/bin/env ruby

require 'openssl'
require 'Base64'
require 'json'
require 'net/http'
require 'uri'
require 'active_support'
require 'active_support/core_ext/object/blank'

WEEBLY_BASE_API = "https://api.weeblycloud.com/"
WEEBLY_API_KEY = "your own weebly api key"
WEEBLY_API_SECRET = "your own secret hash"

def create_hmac(request_type, url, content = "[]")
	message = "#{request_type}\n#{url}\n#{content}"
	hash = OpenSSL::HMAC.hexdigest('SHA256', WEEBLY_API_SECRET, message)
	hash = Base64.strict_encode64(hash)
end

def http_send(request_type, url, hash, content = "[]")
	parsed_url = URI.parse("#{WEEBLY_BASE_API}#{url}")
	http = Net::HTTP.new(parsed_url.host, parsed_url.port)
	http.use_ssl = true
	http.set_debug_output($stdout)
	request = nil
	if request_type == "POST"
		request = Net::HTTP::Post.new(parsed_url.request_uri)
	elsif request_type == "PATCH"
		request = Net::HTTP::Patch.new(parsed_url.request_uri)
	elsif request_type == "PUT"
		request = Net::HTTP::Put.new(parsed_url.request_uri)
	elsif request_type == "DELETE"
		request = Net::HTTP::Delete.new(parsed_url.request_uri)
	else
		request = Net::HTTP::Get.new(parsed_url.request_uri)
	end
	request.body = content
	request['Content-type'] = "application/json"
	request['X-Public-Key'] = WEEBLY_API_KEY
	request['X-Signed-Request-Hash'] = hash
	response = http.request(request)
  return response
end

##################################################################
# ACCOUNT
##################################################################

#Returns all data related to a given Weebly Cloud account.
#The Weebly Cloud account is authenticated through the API key and secret hash.
def get_account
	request_type = "GET"
	url = "account"
	hash = create_hmac(request_type, url)
	response = http_send(request_type, url, hash)
end

#Updates the provided Weebly Cloud account fields for a given account.
def update_account(opts={})
	request_type = "PATCH"
	url = "account"
	data = {}
	data[:brand_name] = opts[:brand_name] unless opts[:brand_name].blank?
	data[:brand_url] = opts[:brand_url] unless opts[:brand_url].blank?
	data[:publish_upsell_url] = opts[:publish_upsell_url] unless opts[:publish_upsell_url].blank?
	data[:upgrade_url] = opts[:upgrade_url] unless opts[:upgrade_url].blank?
	data[:billing_url] = opts[:billing_url] unless opts[:billing_url].blank?
	content = data.to_json
	hash = create_hmac(request_type, url, content)
	response = http_send(request_type, url, hash, content)
end

##################################################################
# USER
##################################################################

#Returns the details for a given Weebly user associated with your Weebly Cloud account.
def get_user(user_id)
	request_type = "GET"
	url = "user/#{user_id}"
	hash = create_hmac(request_type, url)
	response = http_send(request_type, url, hash)
end

#Creates a Weebly user in your Weebly Cloud account. The email address must be unique to
#all of Weebly or an error will be thrown. If your account is in test mode, all users
#created through the API will be flagged as test users.
#Required: email
#Optional: test_mode, language
def create_user(email)
	request_type = "POST"
	url = "user"
	data = {'email'=>email}
	content = data.to_json
	hash = create_hmac(request_type, url, content)
	response = http_send(request_type, url, hash, content)
end

#Updates the provided fields of an existing Weebly user in your Weebly Cloud account.
#Optional: email, test_mode, language
def update_user(user_id, opts={})
	request_type = "PATCH"
	url = "user/#{user_id}"
	data = {}
	data[:email] = opts[:email] unless opts[:email].blank?
	data[:test_mode] = opts[:test_mode] unless opts[:test_mode].blank?
	data[:language] = opts[:language] unless opts[:language].blank?
	content = data.to_json
	hash = create_hmac(request_type, url, content)
	response = http_send(request_type, url, hash, content)
end

#Enables a user account after an account has been disabled. Enabling a user account
#will allow users to log into the editor. When a user is created, their account is
#automatically enabled.
def enable_user(user_id)
	request_type = "POST"
	url = "user/#{user_id}/enable"
	hash = create_hmac(request_type, url)
	response = http_send(request_type, url, hash)
end

#Disables a user account. When a user account is disabled, the user will no longer
#be able to log into the editor. If an attempt to create a login link is made on a
#disabled account an error is thrown.
def disable_user(user_id)
	request_type = "POST"
	url = "user/#{user_id}/disable"
	hash = create_hmac(request_type, url)
	response = http_send(request_type, url, hash)
end

#Generates a one-time link that will direct users to the editor for the last site
#that was modified in the account. This method requires that the account is enabled
#and that the account has at least one site.
def get_login_link(user_id)
	request_type = "POST"
	url = "user/#{user_id}/loginLink"
	hash = create_hmac(request_type, url)
	response = http_send(request_type, url, hash)
end

##################################################################
# SITE
##################################################################

#Retrieves site details for the given USER_ID and SITE_ID combination.
def get_site_details(user_id, site_id)
	request_type = "GET"
	url = "user/#{user_id}/site/#{site_id}"
	hash = create_hmac(request_type, url)
	response = http_send(request_type, url, hash)
end

#Retrieves all the sites for a given user
def get_sites(user_id)
	request_type = "GET"
	url = "user/#{user_id}/site"
	hash = create_hmac(request_type, url)
	response = http_send(request_type, url, hash)
end

#Creates a new site for a given user. The domain must be unique. If optional
#parameters are not provided, then defaults defined at the Weebly Cloud account
#level will be used.
#Required: domain
#Optional: brand_name, brand_url, publish_upsell_url, upgrade_url, plan_id, term, time_zone, time_format, date_format
def create_site(user_id, domain, site_title)
	request_type = "POST"
	url = "user/#{user_id}/site"
	data = {'domain'=>domain, 'site_title'=>site_title}
	content = data.to_json
	hash = create_hmac(request_type, url, content)
	response = http_send(request_type, url, hash, content)
end

#Updates the provided properties of a given user's site. The domain must be unique.
#If optional parameters are not provided, then defaults defined at the Weebly Cloud
#account level will be used.
#Optional: domain, brand_name, brand_url, publish_upsell_url, upgrade_url, allow_ssl, time_zone, time_format, date_format
def update_site(user_id, site_id, opts={})
	request_type = "PATCH"
	url = "user/#{user_id}/site/#{site_id}"
	data = {}
	data[:domain] = opts[:domain] unless opts[:domain].blank?
	data[:site_title] = opts[:site_title] unless opts[:site_title].blank?
	data[:allow_ssl] = opts[:allow_ssl] unless opts[:allow_ssl].blank?
	data[:brand_name] = opts[:brand_name] unless opts[:brand_name].blank?
	data[:brand_url] = opts[:brand_url] unless opts[:brand_url].blank?
	data[:upgrade_url] = opts[:upgrade_url] unless opts[:upgrade_url].blank?
	data[:publish_upsell_url] = opts[:publish_upsell_url] unless opts[:publish_upsell_url].blank?
	data[:suspended] = opts[:suspended] unless opts[:suspended].blank?
	data[:time_zone] = opts[:time_zone] unless opts[:time_zone].blank?
	data[:time_format] = opts[:time_format] unless opts[:time_format].blank?
	data[:date_format] = opts[:date_format] unless opts[:date_format].blank?
	content = data.to_json
	hash = create_hmac(request_type, url, content)
	response = http_send(request_type, url, hash, content)
end

#Publishes a given site for a given user.
def publish_site(user_id, site_id)
	request_type = "POST"
	url = "user/#{user_id}/site/#{site_id}/publish"
	hash = create_hmac(request_type, url)
	response = http_send(request_type, url, hash)
end

#Unpublishes the given site for a given user. The site can be published again after it is unpublished.
def unpublish_site(user_id, site_id)
	request_type = "POST"
	url = "user/#{user_id}/site/#{site_id}/unpublish"
	hash = create_hmac(request_type, url)
	response = http_send(request_type, url, hash)
end

#Generates a one-time link that will direct users to the site specified. This method requires that the account is enabled.
def get_site_login_link(user_id, site_id)
	request_type = "POST"
	url = "user/#{user_id}/site/#{site_id}/loginLink"
	hash = create_hmac(request_type, url)
	response = http_send(request_type, url, hash)
end

#Sets publish credentials for a given site. If a user's site will not be hosted by Weebly,
#publish credentials can be provided.	 When these values are set, the site will be published to the location specified.
def set_publish_credentials(user_id, site_id, opts={})
	request_type = "PATCH"
	url = "user/#{user_id}/site/#{site_id}"
	data = {}
	data[:publish_host] = opts[:publish_host] unless opts[:publish_host].blank?
	data[:publish_username] = opts[:publish_username] unless opts[:publish_username].blank?
	data[:publish_password] = opts[:publish_password] unless opts[:publish_password].blank?
	data[:publish_path] = opts[:publish_path] unless opts[:publish_path].blank?
	content = data.to_json
	hash = create_hmac(request_type, url, content)
	response = http_send(request_type, url, hash, content)
end

#When a site is restored the owner of the site is granted access to it in the exact state it was
#when it was deleted, including the Weebly plan assigned. Restoring a site does not issue an automatic publish
#Required: domain
def restore_site(user_id, site_id, domain)
	request_type = "POST"
	url = "user/#{user_id}/site/#{site_id}/restore"
	data = {'domain'=>domain}
	content = data.to_json
	hash = create_hmac(request_type, url, content)
	response = http_send(request_type, url, hash, content)
end

#Suspends access to the given user's site in the editor by setting the suspended parameter to true.
#If a user attempts to access the site in the editor, an error is thrown.
def disable_site(user_id, site_id)
	request_type = "POST"
	url = "user/#{user_id}/site/#{site_id}/disable"
	hash = create_hmac(request_type, url)
	response = http_send(request_type, url, hash)
end

#Re-enables a suspended site by setting the suspended parameter to false. Users can access the editor
#for the site. Sites are enabled by default when created.
def enable_site(user_id, site_id)
	request_type = "POST"
	url = "user/#{user_id}/site/#{site_id}/enable"
	hash = create_hmac(request_type, url)
	response = http_send(request_type, url, hash)
end

#Deletes the Weebly site. The site will no longer show up to the user.
def delete_site(user_id, site_id)
	request_type = "DELETE"
	url = "user/#{user_id}/site/#{site_id}"
	hash = create_hmac(request_type, url)
	response = http_send(request_type, url, hash)
end


##################################################################
# PLAN
##################################################################

#Returns all available plans for a Weebly Cloud account.
def get_plans
	request_type = "GET"
	url = "plan"
	hash = create_hmac(request_type, url)
	response = http_send(request_type, url, hash)
end

#Returns the settings for a given plan
def get_plan(plan_id)
	request_type = "GET"
	url = "plan/#{plan_id}"
	hash = create_hmac(request_type, url)
	response = http_send(request_type, url, hash)
end

def get_site_plan(user_id, site_id)
	request_type = "GET"
	url = "user/#{user_id}/site/#{site_id}/plan"
	hash = create_hmac(request_type, url)
	response = http_send(request_type, url, hash)
end

#Assign a plan to a given site. Takes a plan_id and an optional term field to specify
#the term length for the plan. If no term is provided a monthly term (ex. term=1) is
#used as the default. If a plan is already assigned to a site, then that plan will automatically
#expire and the new plan takes effect immediately.
def set_plan(user_id, site_id, plan_id, term=1)
	request_type = "POST"
	url = "user/#{user_id}/site/#{site_id}/plan"
	data = {'plan_id'=>plan_id, 'term'=>term}
	content = data.to_json
	hash = create_hmac(request_type, url, content)
	response = http_send(request_type, url, hash, content)
end

##################################################################
# THEME
##################################################################

#Lists all themes available to the given user. An optional flag of "custom_only"
#can be included to only show custom themes.
def get_theme(user_id)
	request_type = "GET"
	url = "user/#{user_id}/theme"
	hash = create_hmac(request_type, url)
	response = http_send(request_type, url, hash)
end

#Creates a new theme in the user account. NOTE: theme_zip must be publicly accessible
#and follow the structure for custom themes.
def set_theme(user_id, theme_name, theme_zip)
	request_type = "POST"
	url = "user/#{user_id}/theme"
	data = {'theme_name'=>theme_name, 'theme_zip'=>theme_zip}
	content = data.to_json
	hash = create_hmac(request_type, url, content)
	response = http_send(request_type, url, hash, content)
end

#Sets the theme for a given site. This theme change takes place immediately, but won't
#be seen on the published site until next publish. An "is_custom" flag is required in
#order to distinguish between Weebly themes and custom themes.
def set_theme_site(user_id, site_id, theme_id, is_custom=true)
	request_type = "POST"
	url = "user/#{user_id}/site/#{site_id}/theme"
	data = {'theme_id'=>theme_id, 'is_custom'=>is_custom}
	content = data.to_json
	hash = create_hmac(request_type, url, content)
	response = http_send(request_type, url, hash, content)
end
