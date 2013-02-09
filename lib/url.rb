class Url
  include Mongoid::Document

  field :url, :type => String
  field :short, :type => String

  index({ short: 1 }, { unique: true, background: true })

  validates_presence_of :url
  validates_presence_of :short
  validates_length_of :url, minimum: 4, maximum: 800
  validates_format_of :url, with: /^((?!feed\.mn).)*\.\S+$/
  validates_uniqueness_of :short

end