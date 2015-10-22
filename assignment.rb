require 'pry'
require 'csv'
require 'json'

class Assignment

  attr_accessor :array

  def initialize
    @array = []
  end

  def read_file(file_name)
    CSV.foreach("source1.csv") do |row|
      @array << convert_to_hash(row)
    end
    @array = @array.compact
  end

  def run
    read_file('source1.csv')
    binding.pry
  end

  def convert_to_hash(row)
    array__for_campaign = row[0].split("_")
    if valid_json?(row[4])
      {campaign: row[0], initative: array__for_campaign[0], audience: array__for_campaign[1], asset: array__for_campaign[2], date: row[1], spend: row[2], impressions: row[3], actions: JSON.parse(row[4])}
    end
  end

  def valid_json?(json)
    begin
      JSON.parse(json)
      return true
    rescue Exception => e
      return false
  end
end


end

a = Assignment.new
a.run
