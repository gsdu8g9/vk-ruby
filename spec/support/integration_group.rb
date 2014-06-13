require 'mechanize'

module IntegrationGroup

  def self.included(base)
    base.before(:all) {  WebMock.allow_net_connect! }
    base.after(:all)  {  WebMock.disable_net_connect! }
  end

  def access_token
    @access_token ||= begin
      agent = Mechanize.new
      
      agent.log = Logger.new(File.expand_path('../mechanize.log', __FILE__)).tap{ |log| log.level = Logger::DEBUG }
      agent.user_agent_alias = 'Mac Safari'

      app = VK::Application.new({
        app_id: credentials['app_id'],
        app_secret: credentials['app_secret'],
        settings: credentials['settings']
      })

      agent.get app.authorization_url(type: :client)

        agent.page.form_with(action: /login.vk.com/){ |form|
          form.email = credentials['login']
          form.pass  = credentials['password']
        }.submit

      if agent.cookies.detect{|cookie| cookie.name == 'remixsid'}
        sleep 5

        url = agent.page
                 .body
                 .gsub("\n",'')
                 .gsub("  ",'')
                 .match(/.*function allow\(\)\s?\{.*}location.href\s?=\s?[\'\"\s](.+)[\'\"].+\}/)
                 .to_a
                 .last

        agent.get(url)
      else
        raise 'invalid loging or password'
      end

      sleep 5

      agent.page.uri.fragment.split('&') \
                             .map{ |s| s.split '=' } \
                             .find{ |k,_| k == 'access_token' } \
                             .last
    end
  end

  alias authorizate! access_token

  def credentials
    @credentials ||= YAML.load_file(File.expand_path('../credentials.yml', __FILE__))
  end

end
