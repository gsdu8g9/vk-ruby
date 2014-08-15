# Internal helpers

module VK::Utils

  # Get real API method name
  # 
  # @example Camelize API method
  #   VK::Utils.camelize('get_profiles') #=> 'getProfiles'

  def self.camelize(name)
    words = name.to_s.split('_')
    first_word = words.shift

    words.each{|word| word.sub! /^[a-z]/, &:upcase }

    words.unshift(first_word).join
  end
  
end