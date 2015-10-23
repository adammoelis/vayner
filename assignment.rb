require 'pry'
require 'csv'
require 'json'

class Assignment

  attr_accessor :campaign_array

  ACTIONS_TO_COUNT = ["x", "y"]

  def initialize
    @campaign_array = []
  end

  def read_file(file_name)
    CSV.foreach("source1.csv") do |campaign_row|
      @campaign_array << convert_to_hash(campaign_row)
    end
    @campaign_array = @campaign_array.compact
  end

  def run
    read_file('source1.csv')
    unique_feb_campaigns = filter_duplicate_campaigns(campaigns_run_in(2))
    puts "The number of unique campaigns in February is #{unique_feb_campaigns.size}"
    conversions_for_plants = conversions_for('plants')
    puts "The number of conversions for plants is #{conversions_for_plants}"
    least_expensive = least_expensive_in_hash(audience_asset_combinations)
    puts "The lease expensive audience_asset combination is #{least_expensive[0][0]}"


  end

  def convert_to_hash(campaign_row)
    # Read Line 1 and dynamically name the symbols in the hash. Give campaign_row descriptive names
    campaign_details = campaign_row[0].split("_")
    if valid_json?(campaign_row[4])
      {campaign: campaign_row[0],
        initative: campaign_details[0],
        audience: campaign_details[1],
        asset: campaign_details[2],
        audience_asset: campaign_details[1] + "_" + campaign_details[2],
        date: Date.parse(campaign_row[1]),
        spend: campaign_row[2],
        impressions: campaign_row[3],
        actions: JSON.parse(campaign_row[4])
      }
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

  def filter_duplicate_campaigns(array_of_campaign_hashes)
    array_of_campaign_hashes.uniq { |campaign| campaign[:campaign] }
  end

  def campaigns_run_in(month_num)
    campaign_array.select{|campaign| campaign[:date].month == month_num}
  end

  def campaigns_for(initiative_type)
    campaign_array.select{|campaign| campaign[:initative] == initiative_type}
  end

  def conversions_for(initiative_type)
    conversions_sum = 0
    campaigns_for(initiative_type).each do |campaign|
      campaign[:actions].each do |action|
        if action["action"] == 'conversions'
          num_of_conversions = action.select {|k, v| ACTIONS_TO_COUNT.include?(k)}.values.first
          conversions_sum += num_of_conversions if num_of_conversions
        end
      end
    end
    conversions_sum
  end

  def audience_asset_combinations
    audience_asset_combo_hash = campaign_array.each_with_object({}) do |campaign, audience_asset_combo_hash|
      if audience_asset_combo_hash.keys.include?(campaign[:audience_asset])
        audience_asset_combo_hash[campaign[:audience_asset]][:spend] += campaign[:spend].to_f
        audience_asset_combo_hash[campaign[:audience_asset]][:conversions] += conversions_for_row(campaign)
      else
        audience_asset_combo_hash[campaign[:audience_asset]] = {spend: campaign[:spend].to_f, conversions: conversions_for_row(campaign)}
      end
    end
  end

  def conversions_for_row(campaign_row)
    conversions_sum = 0
    campaign_row[:actions].each do |action|
      if action["action"] == 'conversions'
        num_of_conversions = action.select {|k, v| ACTIONS_TO_COUNT.include?(k)}.values.first
        conversions_sum += num_of_conversions if num_of_conversions
      end
    end
    conversions_sum
  end

  def least_expensive_in_hash(audience_asset_combo_hash)
    audience_asset_combo_hash.sort_by{|k,v| v[:spend]/v[:conversions]}
  end




end

a = Assignment.new
a.run
